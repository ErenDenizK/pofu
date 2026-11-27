import Foundation
import PofuTuning

#if canImport(AVFoundation)
import AVFoundation
#if os(iOS)
import UIKit
#endif

/// Plays what `MusicDirector` chooses, on one `AVAudioEngine`. A phrase's
/// stems are one player node each, scheduled and started at one host time,
/// so they stay sample-aligned. The music ducks under a cue with the rule
/// the ambience uses (`AmbienceDucking`, driven by `SoundEngine.play`), and
/// stops whenever `MusicPolicy` says so: off, muted, in the background, or
/// while the user's own audio plays. Only the app links this module.
@MainActor
public final class MusicPlayer {
    public static let shared = MusicPlayer()

    /// Whether the engine is up.
    public private(set) var isRunning = false

    private let engine = AVAudioEngine()
    private var nodes: [MusicStem: AVAudioPlayerNode] = [:]
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var format: AVAudioFormat?
    private var director: MusicDirector?
    private var state: MusicState?
    private var isActive = false
    private var loopTask: Task<Void, Never>?
    private var duckTask: Task<Void, Never>?
    private var levels: [MusicStem: Double] = [:]
    private var lastCue: TimeInterval?
    private var observing = false
    private let clock: @MainActor () -> TimeInterval
    private let seed: UInt64

    private static let startLead = 0.15

    public init(
        seed: UInt64 = UInt64.random(in: .min ... .max),
        clock: @escaping @MainActor () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.seed = seed
        self.clock = clock
    }

    // MARK: - What the app tells it

    /// The island as it is now; `nil` (or `isActive` false) when it is off
    /// screen or the app resigned. Call on appearing and when anything in
    /// the state changes.
    public func update(state: MusicState?, isActive: Bool) {
        self.state = state
        self.isActive = isActive
        observeIfNeeded()
        evaluate()
    }

    /// A setting changed.
    public func refresh() {
        evaluate()
    }

    /// A cue played: the music ducks under it.
    func noteCue() {
        lastCue = clock()
    }

    /// Stops everything now (backgrounding, a changed setting).
    public func stop() {
        loopTask?.cancel()
        loopTask = nil
        duckTask?.cancel()
        duckTask = nil
        for node in nodes.values { node.stop() }
        if engine.isRunning { engine.stop() }
        isRunning = false
        #if os(iOS)
        if !SoundEngine.shared.isRunning, !AmbienceConductor.shared.isRunning {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        #endif
    }

    // MARK: - Following the policy

    private var policy: MusicPolicy {
        var otherAudio = false
        var voiceOver = false
        #if os(iOS)
        otherAudio = AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint
        voiceOver = UIAccessibility.isVoiceOverRunning
        #endif
        return MusicPolicy(
            settings: SoundEngine.shared.settings, volumes: SoundEngine.shared.volumes,
            isActive: isActive && state != nil, otherAudioPlaying: otherAudio, voiceOverRunning: voiceOver
        )
    }

    private func evaluate() {
        guard policy.mayPlay else {
            if loopTask != nil || isRunning { stop() }
            return
        }
        if loopTask == nil { startLoop() }
    }

    private func startLoop() {
        guard let index = try? MusicIndex.bundled() else { return }
        var director = self.director ?? MusicDirector(index: index, tuning: SoundEngine.shared.volumes, seed: seed)
        director.tuning = SoundEngine.shared.volumes
        let opening = self.director == nil ? director.openingDelay() : 0
        self.director = director
        loopTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(opening))
            while !Task.isCancelled {
                guard let self else { return }
                let wait = self.playNextPhrase()
                try? await Task.sleep(for: .seconds(wait))
            }
        }
    }

    /// Plays the next phrase if the state has one, and returns the seconds to wait before asking again.
    private func playNextPhrase() -> Double {
        guard let state, policy.mayPlay, var director else { return 30 }
        defer { self.director = director }
        director.tuning = SoundEngine.shared.volumes
        guard let phrase = director.next(for: state, isMusicOn: SoundEngine.shared.settings.isMusicOn) else {
            return 30
        }
        guard play(phrase) else { return 30 }
        return phrase.seconds + phrase.pause
    }

    private func play(_ phrase: MusicPhrase) -> Bool {
        guard startEngine() else { return false }
        var loaded: [(MusicStem, AVAudioPCMBuffer, Double)] = []
        for part in phrase.stems {
            guard let buffer = buffer(named: part.file), buffer.format == format else { return false }
            loaded.append((part.stem, buffer, part.gain))
        }
        levels = [:]
        // One start time for every stem: this is what keeps them aligned.
        let start = AVAudioTime(hostTime: mach_absolute_time() + AVAudioTime.hostTime(forSeconds: Self.startLead))
        for stem in MusicStem.allCases { nodes[stem]?.stop() }
        for (stem, buffer, gain) in loaded {
            guard let node = nodes[stem] else { continue }
            levels[stem] = gain
            node.volume = currentGain(level: gain)
            node.scheduleBuffer(buffer, at: nil, options: [])
            node.play(at: start)
        }
        startDucking()
        return true
    }

    private func currentGain(level: Double) -> Float {
        policy.gain(level: level, secondsSinceCue: lastCue.map { clock() - $0 })
    }

    /// The ducking is applied at the node, 10 times a second, while a phrase sounds.
    private func startDucking() {
        duckTask?.cancel()
        duckTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self else { return }
                for (stem, level) in self.levels {
                    self.nodes[stem]?.volume = self.currentGain(level: level)
                }
            }
        }
    }

    // MARK: - Engine

    private func startEngine() -> Bool {
        observeIfNeeded()
        if engine.isRunning { return true }
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            return false
        }
        #endif
        if nodes.isEmpty {
            // Every stem is mono at one rate, so one connection format fits.
            guard let index = try? MusicIndex.bundled(),
                let file = index.tunes.values.first?.cells.values.first?.stems.values.first,
                let first = buffer(named: file)
            else { return false }
            format = first.format
            for stem in MusicStem.allCases {
                let node = AVAudioPlayerNode()
                engine.attach(node)
                engine.connect(node, to: engine.mainMixerNode, format: first.format)
                nodes[stem] = node
            }
        }
        do {
            try engine.start()
            isRunning = true
            return true
        } catch {
            return false
        }
    }

    private func buffer(named file: String) -> AVAudioPCMBuffer? {
        if let cached = buffers[file] { return cached }
        guard let url = MusicAssets.url(forFile: file),
            let audio = try? AVAudioFile(forReading: url),
            let buffer = AVAudioPCMBuffer(pcmFormat: audio.processingFormat, frameCapacity: AVAudioFrameCount(audio.length)),
            (try? audio.read(into: buffer)) != nil
        else { return nil }
        buffers[file] = buffer
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
        center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.stop() }
        }
        #endif
    }
}
#endif
