import Foundation
import PofuTuning

/// The user's switch. Pofu's sounds are on by default; the shield never
/// plays regardless (it is a separate target that does not link this one).
public struct SoundSettings: Equatable, Sendable {
    public var isMuted: Bool
    /// The world's ambience and the breath guide's pad. Off by default
    /// (sound identity §1.4: ambience is optional, offered, never forced).
    public var isAmbienceOn: Bool

    public init(isMuted: Bool = false, isAmbienceOn: Bool = false) {
        self.isMuted = isMuted
        self.isAmbienceOn = isAmbienceOn
    }

    public static let mutedKey = "pofu.sound.muted"
    public static let ambienceKey = "pofu.sound.ambience"

    public static func load(from defaults: UserDefaults = .standard) -> SoundSettings {
        SoundSettings(isMuted: defaults.bool(forKey: mutedKey), isAmbienceOn: defaults.bool(forKey: ambienceKey))
    }

    public func save(to defaults: UserDefaults = .standard) {
        defaults.set(isMuted, forKey: Self.mutedKey)
        defaults.set(isAmbienceOn, forKey: Self.ambienceKey)
    }
}

/// Per-cue rate limiting: a minimum gap between two plays of the same cue
/// kind, and a quiet-down for runs ("the hundredth time": the gain steps
/// down while a cue repeats quickly, and returns after a pause).
public struct CueLimiter: Sendable {
    public struct Rule: Sendable, Equatable {
        /// Plays closer than this to the last one of the kind are dropped.
        public var minimumGap: TimeInterval
        /// A pause this long ends a run.
        public var runReset: TimeInterval
        /// Gain removed per repeat inside a run (0 keeps the level).
        public var runDecay: Double
        /// The quietest a run gets; it stays here instead of vanishing.
        public var runFloor: Double

        public init(minimumGap: TimeInterval, runReset: TimeInterval = 1, runDecay: Double = 0, runFloor: Double = 1) {
            self.minimumGap = minimumGap
            self.runReset = runReset
            self.runDecay = runDecay
            self.runFloor = runFloor
        }
    }

    public static func rule(for cue: SoundCue) -> Rule {
        switch cue {
        case .bloom: Rule(minimumGap: 0.03, runReset: 0.4)
        case .seedPop: Rule(minimumGap: 0.04, runReset: 0.6, runDecay: 0.06, runFloor: 0.4)
        case .comboRise: Rule(minimumGap: 0.5)
        case .pieceSnap: Rule(minimumGap: 0.08, runReset: 0.5, runDecay: 0.15, runFloor: 0.3)
        case .piecePickup, .piecePutBack, .pieceDrop: Rule(minimumGap: 0.1)
        case .deal: Rule(minimumGap: 0.15)
        case .cheek: Rule(minimumGap: 0.1, runReset: 0.8, runDecay: 0.1, runFloor: 0.4)
        case .gulp, .collect: Rule(minimumGap: 0.4)
        case .waterSplash: Rule(minimumGap: 0.12, runReset: 0.6, runDecay: 0.12, runFloor: 0.4)
        case .waterWheel: Rule(minimumGap: 1.5)
        case .doorKnock, .kettle, .levelUp: Rule(minimumGap: 2.0)
        case .waterPour: Rule(minimumGap: 1.0)
        // Rationed: the chime and the hop wear out by day 3 (sound identity §1.3).
        case .skipChime, .roundEnd, .pofuHop: Rule(minimumGap: 1.0)
        }
    }

    private struct State: Sendable {
        var last: TimeInterval
        var run: Int
    }

    private var states: [String: State] = [:]

    public init() {}

    /// The gain multiplier (0...1) for `cue` at `now`, or `nil` when it is
    /// rate-limited. Records the play when it is allowed.
    public mutating func admit(_ cue: SoundCue, at now: TimeInterval) -> Double? {
        let rule = Self.rule(for: cue)
        let key = cue.kind
        let previous = states[key]
        let gap = previous.map { now - $0.last } ?? .infinity
        if gap < rule.minimumGap { return nil }
        let run = gap > rule.runReset ? 0 : (previous?.run ?? 0) + 1
        states[key] = State(last: now, run: run)
        return max(1 - rule.runDecay * Double(run), min(rule.runFloor, 1))
    }
}

extension SoundCue {
    /// The cue without its pitch: what rate limits are counted per.
    var kind: String {
        switch self {
        case .seedPop: "seedPop"
        case .bloom: "bloom"
        case .comboRise: "comboRise"
        default: assetName
        }
    }
}

/// The decision for one cue: which file, how loud.
public struct PlaybackDecision: Equatable, Sendable {
    public var assetName: String
    public var gain: Float
}

/// Pure sound logic: settings and tuning in, a decision out. The engine
/// plays what this admits and nothing else.
public struct SoundPolicy: Sendable {
    public var settings: SoundSettings
    public var volumes: TuningValues.Sound
    private var limiter = CueLimiter()

    public init(settings: SoundSettings = SoundSettings(), volumes: TuningValues.Sound = TuningValues.defaults.sound) {
        self.settings = settings
        self.volumes = volumes
    }

    public mutating func decide(_ cue: SoundCue, at now: TimeInterval) -> PlaybackDecision? {
        guard !settings.isMuted, volumes.master > 0 else { return nil }
        let group: Double
        switch cue.group {
        case .seeds: group = volumes.seeds
        case .pieces: group = volumes.pieces
        case .pofu: group = volumes.pofu
        }
        guard group > 0, let run = limiter.admit(cue, at: now) else { return nil }
        let gain = min(max(volumes.master * group * run, 0), 1)
        return PlaybackDecision(assetName: cue.assetName, gain: Float(gain))
    }
}
