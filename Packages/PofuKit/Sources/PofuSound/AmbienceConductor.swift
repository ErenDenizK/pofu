import Foundation
import PofuTuning

#if canImport(AVFoundation)
import AVFoundation
#if os(iOS)
import UIKit
#endif

/// Plays the world's ambience: four looping beds, gull calls and the
/// breath pad, on their own small engine at 8 kHz. The decisions (which
/// beds, how loud, when to stop) are `AmbienceMixer` and `AmbiencePolicy`;
/// this class only follows them. A 10 Hz tick runs only while something
/// is audible; when everything is silent, backgrounded or settled long, the
/// engine stops and no audio work remains.
@MainActor
public final class AmbienceConductor {
    public static let shared = AmbienceConductor()

    /// Whether the engine is up (the cue engine keeps the audio session
    /// alive while this is true).
    public private(set) var isRunning = false

    private let engine = AVAudioEngine()
    private var players: [AmbienceBed: AVAudioPlayerNode] = [:]
    private var playing: Set<AmbienceBed> = []
    private var current: [AmbienceBed: Float] = [:]
    private let gullPlayer = AVAudioPlayerNode()
    private let breathPlayer = AVAudioPlayerNode()
    private let breathSpeed = AVAudioUnitVarispeed()
    private var graphBuilt = false
    private var buffers: [String: AVAudioPCMBuffer] = [:]

    private var scene: AmbienceScene?
    private var isActive = false
    private var interrupted = false
    private var lastActivity: TimeInterval
    private var lastCue: TimeInterval?
    private var tickTask: Task<Void, Never>?
    private var gullTask: Task<Void, Never>?
    private var breath: (direction: BreathSwell.Direction, start: TimeInterval, seconds: TimeInterval)?
    private var observing = false
    private let clock: @MainActor () -> TimeInterval

    private static let tick: Duration = .milliseconds(100)

    public init(clock: @escaping @MainActor () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.clock = clock
        lastActivity = clock()
    }

    // MARK: - What the app tells it

    /// The world as it is now. Call on appearing, when the hour or the
    /// weather changes, and with `isActive` false when the app resigns.
    public func update(scene: AmbienceScene?, isActive: Bool) {
        self.scene = scene
        self.isActive = isActive
        observeIfNeeded()
        evaluate()
    }

    /// A setting changed: start or stop to match.
    public func refresh() {
        evaluate()
    }

    /// A new island visit: wakes the beds after a long settle or an
    /// interruption.
    public func beginVisit() {
        interrupted = false
        noteActivity()
    }

    /// Any cue, tap or visit: the player is here, so ambience may go on.
    public func noteActivity() {
        lastActivity = clock()
        if !isRunning { evaluate() }
    }

    /// A cue played: the beds duck under it.
    func noteCue() {
        lastCue = clock()
        noteActivity()
    }

    /// The breath guide: a pad that follows the orb.
    public func swell(_ direction: BreathSwell.Direction, seconds: TimeInterval) {
        guard SoundEngine.shared.settings.isAmbienceOn, !SoundEngine.shared.settings.isMuted,
            SoundEngine.shared.volumes.master > 0, startEngine(), let pad = buffer(named: "breath-pad")
        else { return }
        breath = (direction, clock(), max(seconds, 0.5))
        if !breathPlayer.isPlaying {
            breathPlayer.volume = 0
            breathPlayer.scheduleBuffer(pad, at: nil, options: .loops)
            breathPlayer.play()
        }
        startTicking()
    }

    public func endBreath() {
        breath = nil
        breathPlayer.stop()
        stopIfSilent()
    }

    /// Stops everything now (backgrounding, a changed setting).
    public func stop() {
        tickTask?.cancel()
        tickTask = nil
        gullTask?.cancel()
        gullTask = nil
        guard isRunning else { return }
        for player in players.values { player.stop() }
        gullPlayer.stop()
        breathPlayer.stop()
        playing.removeAll()
        current.removeAll()
        breath = nil
        engine.stop()
        isRunning = false
        #if os(iOS)
        if !SoundEngine.shared.isRunning {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        #endif
    }

    // MARK: - The decision

    private func currentPolicy() -> AmbiencePolicy {
        var otherAudio = false
        var voiceOver = false
        #if os(iOS)
        otherAudio = AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint
        voiceOver = UIAccessibility.isVoiceOverRunning
        #endif
        return AmbiencePolicy(
            settings: SoundEngine.shared.settings,
            volumes: SoundEngine.shared.volumes,
            isActive: isActive && !interrupted,
            otherAudioPlaying: otherAudio,
            voiceOverRunning: voiceOver,
            secondsIdle: clock() - lastActivity
        )
    }

    private func mix() -> AmbienceMix {
        scene.map(AmbienceMixer.mix(for:)) ?? .silent
    }

    private func evaluate() {
        let policy = currentPolicy()
        guard policy.mayPlay, !mix().isSilent else {
            if breath == nil { fadeOutOrStop() }
            return
        }
        guard startEngine() else { return }
        startTicking()
        startGullsIfNeeded()
    }

    private func fadeOutOrStop() {
        if isRunning, !current.isEmpty, tickTask != nil { return }  // the tick fades and stops
        stop()
    }

    // MARK: - The tick

    private func startTicking() {
        guard tickTask == nil else { return }
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.tick)
                guard let self, !Task.isCancelled else { return }
                self.step(dt: 0.1)
            }
        }
    }

    private func step(dt: Double) {
        let now = clock()
        let policy = currentPolicy()
        let mix = policy.mayPlay ? mix() : .silent
        let sinceCue = lastCue.map { now - $0 }
        let ease = min(1, dt / (AmbienceLevels.fadeSeconds / 3))
        for bed in AmbienceBed.allCases {
            // Ducking is applied at the node, so it bites at once; the
            // smoothed value is the fade.
            let target = policy.gain(level: mix.level(of: bed), secondsSinceCue: nil)
            var gain = current[bed] ?? 0
            gain += (target - gain) * Float(ease)
            if target == 0, gain < 0.0004 { gain = 0 }
            current[bed] = gain
            guard gain > 0 else {
                if playing.remove(bed) != nil { players[bed]?.stop() }
                continue
            }
            ensurePlaying(bed)
            let swell = bed == .wind || bed == .rain ? 1 + 0.14 * Float(sin(now * 2 * .pi / 17)) : 1
            players[bed]?.volume = gain * swell * Float(AmbienceDucking.factor(secondsSinceCue: sinceCue))
        }
        stepBreath(now: now, policy: policy)
        stopIfSilent()
    }

    private func stepBreath(now: TimeInterval, policy: AmbiencePolicy) {
        guard let breath else { return }
        let progress = (now - breath.start) / breath.seconds
        let allowed = SoundEngine.shared.settings.isAmbienceOn && !SoundEngine.shared.settings.isMuted
        if !allowed || progress > 1.0 + (breath.direction == .rising ? 2 : 0) {
            endBreath()
            return
        }
        let shape = BreathSwell.shape(breath.direction, progress: progress)
        breathSpeed.rate = Float(shape.rate)
        var gain = SoundEngine.shared.volumes.master * AmbienceLevels.breath * shape.gain
        #if os(iOS)
        if UIAccessibility.isVoiceOverRunning { gain *= AmbienceLevels.voiceOverFactor }
        #endif
        breathPlayer.volume = Float(min(max(gain, 0), 1))
        if breath.direction == .falling, progress >= 1 { endBreath() }
    }

    private func stopIfSilent() {
        guard breath == nil, isRunning, playing.isEmpty, gullTask == nil || !mayCallGulls() else { return }
        if !currentPolicy().mayPlay || mix().isSilent { stop() }
    }

    // MARK: - Gulls

    private func mayCallGulls() -> Bool {
        currentPolicy().mayPlay && mix().gulls
    }

    private func startGullsIfNeeded() {
        guard gullTask == nil, mayCallGulls() else { return }
        gullTask = Task { [weak self] in
            while !Task.isCancelled {
                let gap = Double.random(in: AmbienceLevels.gullGap)
                try? await Task.sleep(for: .seconds(gap))
                guard let self, !Task.isCancelled else { return }
                self.callGull()
            }
        }
    }

    private func callGull() {
        guard mayCallGulls(), isRunning else { return }
        let name = "gull-\(Int.random(in: 0...1))"
        guard let buffer = buffer(named: name) else { return }
        let now = clock()
        gullPlayer.volume = currentPolicy().gain(level: 1, secondsSinceCue: lastCue.map { now - $0 }, base: AmbienceLevels.gull)
        gullPlayer.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !gullPlayer.isPlaying { gullPlayer.play() }
    }

    // MARK: - The engine

    private func ensurePlaying(_ bed: AmbienceBed) {
        guard !playing.contains(bed), let player = players[bed], let buffer = buffer(named: bed.assetName) else { return }
        player.volume = 0
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()
        playing.insert(bed)
    }

    private func startEngine() -> Bool {
        if isRunning, engine.isRunning { return true }
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            return false
        }
        #endif
        if !graphBuilt {
            guard let first = buffer(named: AmbienceBed.wind.assetName) else { return false }
            let format = first.format
            for bed in AmbienceBed.allCases {
                let node = AVAudioPlayerNode()
                engine.attach(node)
                engine.connect(node, to: engine.mainMixerNode, format: format)
                players[bed] = node
            }
            engine.attach(gullPlayer)
            engine.connect(gullPlayer, to: engine.mainMixerNode, format: format)
            engine.attach(breathPlayer)
            engine.attach(breathSpeed)
            engine.connect(breathPlayer, to: breathSpeed, format: format)
            engine.connect(breathSpeed, to: engine.mainMixerNode, format: format)
            graphBuilt = true
        }
        do {
            try engine.start()
            isRunning = true
            return true
        } catch {
            return false
        }
    }

    private func buffer(named name: String) -> AVAudioPCMBuffer? {
        if let cached = buffers[name] { return cached }
        guard let url = SoundAssets.url(for: name),
            let file = try? AVAudioFile(forReading: url),
            let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
            (try? file.read(into: buffer)) != nil
        else { return nil }
        buffers[name] = buffer
        return buffer
    }

    private func observeIfNeeded() {
        #if os(iOS)
        guard !observing else { return }
        observing = true
        let center = NotificationCenter.default
        center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isActive = false
                self?.stop()
            }
        }
        center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let began = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                == AVAudioSession.InterruptionType.began.rawValue
            MainActor.assumeIsolated {
                // A call or Siri: stop, and do not resume until the next visit.
                if began {
                    self?.interrupted = true
                    self?.stop()
                }
            }
        }
        center.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.isRunning else { return }
                self.stop()
                self.evaluate()
            }
        }
        #endif
    }
}
#endif
