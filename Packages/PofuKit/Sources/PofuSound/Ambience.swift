import Foundation
import PofuTuning

/// The world's weather as sound sees it. Mirrors `PofuWorld.Weather` by
/// raw value, so this module does not link the world; the app maps with
/// `init(weatherName:)`.
public enum AmbienceWeather: String, CaseIterable, Sendable {
    case clear, overcast, lightRain, mist, goldenHaze

    public init(weatherName: String) {
        self = AmbienceWeather(rawValue: weatherName) ?? .clear
    }
}

/// One looping bed. Each is a seamless 3 s file (`tools/sound/world.py`).
public enum AmbienceBed: String, CaseIterable, Hashable, Sendable {
    case wind, crickets, rain, hush

    public var assetName: String { "ambience-\(rawValue)" }
}

/// What the world sounds like right now: the hour, the weather and how far
/// the island has grown (gulls come with the harbor at level 3).
public struct AmbienceScene: Equatable, Sendable {
    public var hour: Int
    public var weather: AmbienceWeather
    public var islandLevel: Int

    public init(hour: Int, weather: AmbienceWeather, islandLevel: Int) {
        self.hour = ((hour % 24) + 24) % 24
        self.weather = weather
        self.islandLevel = islandLevel
    }
}

/// The relative level of each bed (0...1) and whether gulls may call.
public struct AmbienceMix: Equatable, Sendable {
    public var beds: [AmbienceBed: Double]
    public var gulls: Bool

    public static let silent = AmbienceMix(beds: [:], gulls: false)

    public var isSilent: Bool { beds.values.allSatisfy { $0 <= 0 } && !gulls }

    public func level(of bed: AmbienceBed) -> Double { beds[bed] ?? 0 }
}

/// Which beds sound for which scene (sound identity §1.3: ambience is the
/// island's, never the bedtime window's).
public enum AmbienceMixer {
    /// The bedtime window: silence, whatever the weather (A21).
    public static let bedtimeHours: [Int] = [23, 0, 1, 2, 3, 4]
    /// Crickets sing in the evening, after the light goes.
    public static let cricketHours: Range<Int> = 20..<23
    /// Gulls call by daylight over the harbor.
    public static let gullHours: Range<Int> = 6..<19
    public static let gullLevel = 3

    public static func mix(for scene: AmbienceScene) -> AmbienceMix {
        if bedtimeHours.contains(scene.hour) { return .silent }
        let isEvening = cricketHours.contains(scene.hour)
        switch scene.weather {
        case .mist:
            // A hush: no wind, no birds, nothing sharp.
            return AmbienceMix(beds: [.hush: 1], gulls: false)
        case .lightRain:
            return AmbienceMix(beds: [.rain: 1, .wind: 0.2], gulls: false)
        case .clear, .overcast, .goldenHaze:
            var beds: [AmbienceBed: Double] = [:]
            if isEvening {
                beds[.crickets] = scene.weather == .overcast ? 0.6 : 0.8
                beds[.wind] = 0.15
            } else {
                beds[.wind] = scene.weather == .overcast ? 1.0 : 0.7
            }
            let gulls = scene.islandLevel >= gullLevel
                && gullHours.contains(scene.hour)
                && scene.weather != .overcast
            return AmbienceMix(beds: beds, gulls: gulls)
        }
    }
}

/// How loud ambience is. Very low: a bed you notice only when it stops.
public enum AmbienceLevels {
    /// The runtime gain of a bed at relative level 1, before the master.
    public static let bed: Double = 0.16
    /// Gull calls sit a little above the bed, still under the cues.
    public static let gull: Double = 0.2
    /// The breath pad.
    public static let breath: Double = 0.22
    /// VoiceOver running: 10 dB lower (sound identity §1.4).
    public static let voiceOverFactor: Double = 0.316
    /// Seconds a bed takes to fade in or out.
    public static let fadeSeconds: Double = 2.5
    /// Quiet this long (no cue, no visit) and the beds fade and stop.
    public static let idleSeconds: TimeInterval = 300
    /// Seconds between gull calls, picked inside this range.
    public static let gullGap: ClosedRange<Double> = 28...75
}

/// A cue ducks the beds: they drop at once, hold, and come back.
public enum AmbienceDucking {
    public static let depth: Double = 0.45
    public static let hold: TimeInterval = 0.5
    public static let release: TimeInterval = 1.2

    /// The multiplier (depth...1) `seconds` after a cue started.
    public static func factor(secondsSinceCue seconds: TimeInterval?) -> Double {
        guard let seconds, seconds >= 0 else { return 1 }
        if seconds <= hold { return depth }
        let back = min((seconds - hold) / release, 1)
        return depth + (1 - depth) * back
    }
}

/// Whether the beds may run at all, and at what overall gain.
public struct AmbiencePolicy: Sendable {
    public var settings: SoundSettings
    public var volumes: TuningValues.Sound
    /// The app is in the foreground and the island is on screen.
    public var isActive: Bool
    /// Other audio is playing (`secondaryAudioShouldBeSilencedHint`).
    public var otherAudioPlaying: Bool
    public var voiceOverRunning: Bool
    /// Seconds since the last cue, tap or visit; `nil` counts as just now.
    public var secondsIdle: TimeInterval?

    public init(
        settings: SoundSettings = SoundSettings(),
        volumes: TuningValues.Sound = TuningValues.defaults.sound,
        isActive: Bool = true,
        otherAudioPlaying: Bool = false,
        voiceOverRunning: Bool = false,
        secondsIdle: TimeInterval? = nil
    ) {
        self.settings = settings
        self.volumes = volumes
        self.isActive = isActive
        self.otherAudioPlaying = otherAudioPlaying
        self.voiceOverRunning = voiceOverRunning
        self.secondsIdle = secondsIdle
    }

    /// Off when muted, when ambience is not switched on, in the background,
    /// when settled long, or when the user's own audio is playing.
    public var mayPlay: Bool {
        settings.isAmbienceOn && !settings.isMuted && volumes.master > 0
            && isActive && !otherAudioPlaying
            && (secondsIdle ?? 0) < AmbienceLevels.idleSeconds
    }

    /// The gain (0...1) for a relative level, ducked by the last cue.
    public func gain(level: Double, secondsSinceCue: TimeInterval?, base: Double = AmbienceLevels.bed) -> Float {
        guard mayPlay else { return 0 }
        var gain = volumes.master * base * level * AmbienceDucking.factor(secondsSinceCue: secondsSinceCue)
        if voiceOverRunning { gain *= AmbienceLevels.voiceOverFactor }
        return Float(min(max(gain, 0), 1))
    }
}

/// The breath guide: a soft pad that rises over the in-breath and falls
/// over the out-breath. Only with ambience on (sound identity §1.3).
public enum BreathPhaseCue: Sendable, Equatable {
    case opens, closes, chime
}

public enum BreathSwell {
    public enum Direction: Sendable { case rising, falling }

    /// Pitch rate of the pad (varispeed), from a little below to a little
    /// above: enough to follow the orb.
    public static let lowRate: Double = 0.94
    public static let highRate: Double = 1.12
    public static let floorGain: Double = 0.15

    /// The pad at `progress` (0...1) through a phase: (rate, gain 0...1).
    public static func shape(_ direction: Direction, progress: Double) -> (rate: Double, gain: Double) {
        let p = min(max(progress, 0), 1)
        let eased = 0.5 - 0.5 * cos(Double.pi * p)
        switch direction {
        case .rising:
            return (lowRate + (highRate - lowRate) * eased, floorGain + (1 - floorGain) * eased)
        case .falling:
            return (highRate - (highRate - lowRate) * eased, 1 - eased)
        }
    }

    /// What a phase cue asks for: the pad's direction, or a cue to play.
    public static func response(to cue: BreathPhaseCue) -> (direction: Direction?, chime: SoundCue?) {
        switch cue {
        case .opens: (.rising, nil)
        case .closes: (.falling, nil)
        case .chime: (nil, .skipChime)
        }
    }
}
