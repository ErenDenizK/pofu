import Foundation
import PofuTuning

#if canImport(AVFoundation)
import AVFoundation
#if os(iOS)
import UIKit
#endif

/// Plays the pre-rendered cues. `.ambient` mixes under the user's music and
/// obeys the Silent switch (sound identity §1.4). Only the app links this
/// module: the shield and the other extensions never do, so they never play.
///
/// The decisions (mute, volumes, rate limits) are `SoundPolicy`; this class
/// only schedules what the policy admits on a small pool of player nodes.
@MainActor
public final class SoundEngine {
    public static let shared = SoundEngine()

    public var settings: SoundSettings {
        get { policy.settings }
        set {
            policy.settings = newValue
            newValue.save()
        }
    }

    public var volumes: TuningValues.Sound {
        get { policy.volumes }
        set { policy.volumes = newValue }
    }

    private var policy: SoundPolicy
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var format: AVAudioFormat?
    private var started = false
    private var idleTask: Task<Void, Never>?
    private var observesBackground = false
    private let clock: @MainActor () -> TimeInterval

    private static let polyphony = 6
    /// How long the engine stays up after the last cue; a running engine
    /// keeps the audio hardware, and the phone, awake.
    private static let idleSeconds = 3.0

    public init(
        settings: SoundSettings = .load(),
        volumes: TuningValues.Sound = TuningValues.defaults.sound,
        clock: @escaping @MainActor () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        policy = SoundPolicy(settings: settings, volumes: volumes)
        self.clock = clock
    }

    public func play(_ cue: SoundCue) {
        guard let decision = policy.decide(cue, at: clock()) else { return }
        guard startIfNeeded(), let buffer = buffer(named: decision.assetName) else { return }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.volume = decision.gain
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
        scheduleIdleStop()
    }

    /// Stops the engine and releases the audio session; the next cue
    /// starts them again.
    public func stop() {
        idleTask?.cancel()
        idleTask = nil
        guard started || engine.isRunning else { return }
        for player in players { player.stop() }
        engine.stop()
        started = false
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    private func scheduleIdleStop() {
        idleTask?.cancel()
        idleTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.idleSeconds))
            guard !Task.isCancelled else { return }
            self?.stop()
        }
    }

    private func observeBackgroundingIfNeeded() {
        #if os(iOS)
        guard !observesBackground else { return }
        observesBackground = true
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.stop() }
        }
        #endif
    }

    private func startIfNeeded() -> Bool {
        observeBackgroundingIfNeeded()
        if started, engine.isRunning { return true }
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            return false
        }
        #endif
        if players.isEmpty {
            // All assets share one format (mono CAF), so one connection format fits.
            guard let first = buffer(named: SoundCue.skipChime.assetName) else { return false }
            format = first.format
            for _ in 0..<Self.polyphony {
                let node = AVAudioPlayerNode()
                engine.attach(node)
                engine.connect(node, to: engine.mainMixerNode, format: first.format)
                players.append(node)
            }
        }
        do {
            try engine.start()
            started = true
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
}
#endif
