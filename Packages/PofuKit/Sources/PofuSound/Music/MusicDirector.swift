import Foundation
import PofuTuning

/// What the island is now, as the director needs it (music-system-v1
/// section 6). Plain values: this module does not link the world.
public struct MusicState: Equatable, Sendable {
    public var island: MusicIsland
    public var hour: Int
    public var weather: AmbienceWeather
    public var season: MusicSeason
    /// The island's level, 1 to 10: a healing island has less music.
    public var stage: Int
    /// Pofu's wellbeing, 0 to 100 (the world's scale).
    public var wellbeing: Double

    public init(island: MusicIsland, hour: Int, weather: AmbienceWeather, season: MusicSeason, stage: Int, wellbeing: Double) {
        self.island = island
        self.hour = ((hour % 24) + 24) % 24
        self.weather = weather
        self.season = season
        self.stage = stage
        self.wellbeing = wellbeing
    }
}

/// One stem of a phrase and how loud it plays, relative to the music's gain.
public struct MusicStemPlay: Equatable, Sendable {
    public var stem: MusicStem
    /// The file name in `music.json`.
    public var file: String
    public var gain: Double
}

/// The next thing to play: a cell with the stems the state allows, and the
/// island's own air that follows it.
public struct MusicPhrase: Equatable, Sendable {
    public var tune: String
    public var cell: String
    /// The lead instrument the stems carry.
    public var lead: String
    public var stems: [MusicStemPlay]
    /// The cell's length, tail included.
    public var seconds: Double
    /// Seconds of silence (the island's air) between this cell's end and the next phrase.
    public var pause: Double
}

/// Why nothing plays, when nothing does. The player stays silent (or leaves
/// the ambience alone) and asks again later; it never plays a wrong tune.
public enum MusicSilence: Equatable, Sendable {
    /// The user's switch, the silent setting or a zero volume.
    case off
    /// 23:00 to 06:00 with the islands.
    case bedtime
    /// No tune is written for this island at this hour.
    case noTune
}

/// The music director: pure, deterministic and seeded (music-system-v1 D2,
/// D6). It plays a tune's cells in their order, leaves 4 to 12 seconds of the
/// island's own air between them, and turns stems on and off by the state.
/// The same inputs and seed give the same phrases.
public struct MusicDirector: Sendable {
    /// Hours of the day tune, and the bedtime window that stays silent.
    public static let dayHours: Range<Int> = 6..<17
    public static let nightHours: Range<Int> = 17..<23
    /// 23:00 to 06:00 is silent (music-system-v1 D7); the ambience's own window ends an hour earlier.
    public static let bedtime: [Int] = [23, 0, 1, 2, 3, 4, 5]
    /// A cell is not played again while this many cells came after it.
    public static let noRepeatWindow = 3
    /// Pofu's wellbeing below `tiredBelow` begins to lengthen the pauses; at
    /// `tiredBelow - tiredSpan` they are longest (the world's own scale,
    /// `WorldLight`).
    public static let tiredBelow = 55.0
    public static let tiredSpan = 25.0

    public var index: MusicIndex
    public var tuning: TuningValues.Sound

    private var random: MusicSeededRandom
    private var tune: String?
    private var position = 0
    private var recent: [String] = []

    public init(index: MusicIndex, tuning: TuningValues.Sound = TuningValues.defaults.sound, seed: UInt64) {
        self.index = index
        self.tuning = tuning
        random = MusicSeededRandom(seed: seed)
    }

    /// Why `state` has no music, or `nil` when a tune can play.
    public func silence(for state: MusicState, isMusicOn: Bool) -> MusicSilence? {
        guard isMusicOn else { return .off }
        guard !Self.bedtime.contains(state.hour) else { return .bedtime }
        guard resolve(state) != nil else { return .noTune }
        return nil
    }

    /// Seconds to wait before the first phrase after the app opens (3 to 8).
    public mutating func openingDelay() -> Double {
        let low = tuning.musicFirstMin
        return low + (max(tuning.musicFirstMax, low) - low) * random.unit()
    }

    /// The next phrase, or `nil` when nothing plays: music off, the bedtime
    /// window, or an island and hour with no tune yet.
    public mutating func next(for state: MusicState, isMusicOn: Bool) -> MusicPhrase? {
        guard silence(for: state, isMusicOn: isMusicOn) == nil, let (name, tune) = resolve(state) else { return nil }
        let order = tune.order.filter { tune.cells[$0] != nil }
        guard !order.isEmpty else { return nil }
        let cell = nextCell(in: order, of: name)
        guard let row = tune.cells[cell] else { return nil }
        let stems = Self.stems(for: row, state: state, tuning: tuning)
        guard !stems.isEmpty else { return nil }
        return MusicPhrase(
            tune: name, cell: cell, lead: tune.lead, stems: stems,
            seconds: row.seconds, pause: pause(for: state)
        )
    }

    private func resolve(_ state: MusicState) -> (name: String, tune: MusicIndex.Tune)? {
        let time: String
        if Self.dayHours.contains(state.hour) {
            time = "day"
        } else if Self.nightHours.contains(state.hour) {
            time = "night"
        } else {
            return nil
        }
        return index.tune(island: state.island, time: time)
    }

    /// The cells run in order and wrap. A tune's first cell of a visit is any
    /// but its ending (every cell ends on a note any other may follow), picked
    /// by the seed; a cell played in the last few is passed over.
    private mutating func nextCell(in order: [String], of name: String) -> String {
        if tune != name {
            tune = name
            let openers = max(order.count - 1, 1)
            position = Int(random.unit() * Double(openers)) % openers
        } else {
            position += 1
        }
        var cell = order[position % order.count]
        var guardCount = 0
        while recent.suffix(Self.noRepeatWindow).contains("\(name)/\(cell)"), guardCount < order.count {
            position += 1
            cell = order[position % order.count]
            guardCount += 1
        }
        recent.append("\(name)/\(cell)")
        if recent.count > 16 { recent.removeFirst(recent.count - 16) }
        return cell
    }

    /// 4 to 12 seconds. Rain and a tired Pofu raise the floor; nothing leaves the range.
    private mutating func pause(for state: MusicState) -> Double {
        let low = tuning.musicPauseMin
        let high = max(tuning.musicPauseMax, low)
        let tired = min(max((Self.tiredBelow - state.wellbeing) / Self.tiredSpan, 0), 1)
        let lift = min(tired * 0.6 + (state.weather == .lightRain ? 0.4 : 0), 1)
        let floor = low + (high - low) * 0.5 * lift
        return floor + (high - floor) * random.unit()
    }

    /// Which stems sound (section 6): the island's stage decides first, the
    /// weather thins the rest. The bed always sounds.
    static func stems(for cell: MusicIndex.Cell, state: MusicState, tuning: TuningValues.Sound) -> [MusicStemPlay] {
        var wanted: [MusicStem: Double] = [.bed: 1]
        if Double(state.stage) >= tuning.musicLeadStage { wanted[.lead] = 1 }
        if Double(state.stage) >= tuning.musicPulseStage { wanted[.pulse] = 1 }
        switch state.weather {
        case .clear:
            break
        case .goldenHaze:
            if wanted[.lead] != nil { wanted[.lead] = tuning.musicHazeLead }
        case .overcast, .lightRain:
            wanted[.pulse] = nil
        case .mist:
            wanted[.lead] = nil
            wanted[.pulse] = nil
        }
        return MusicStem.allCases.compactMap { stem in
            guard let gain = wanted[stem], let file = cell.stems[stem.rawValue] else { return nil }
            return MusicStemPlay(stem: stem, file: file, gain: gain)
        }
    }
}

/// Whether the music may sound at all, and how loud.
public struct MusicPolicy: Sendable {
    public var settings: SoundSettings
    public var volumes: TuningValues.Sound
    /// The app is in the foreground and the island is on screen.
    public var isActive: Bool
    /// Other audio is playing (`secondaryAudioShouldBeSilencedHint`).
    public var otherAudioPlaying: Bool
    public var voiceOverRunning: Bool

    public init(
        settings: SoundSettings = SoundSettings(),
        volumes: TuningValues.Sound = TuningValues.defaults.sound,
        isActive: Bool = true,
        otherAudioPlaying: Bool = false,
        voiceOverRunning: Bool = false
    ) {
        self.settings = settings
        self.volumes = volumes
        self.isActive = isActive
        self.otherAudioPlaying = otherAudioPlaying
        self.voiceOverRunning = voiceOverRunning
    }

    /// The music's own switch and the mute, the volumes, the foreground and
    /// the user's own audio.
    public var mayPlay: Bool {
        settings.isMusicOn && !settings.isMuted && volumes.master > 0 && volumes.music > 0
            && isActive && !otherAudioPlaying
    }

    /// The gain (0...1) of a stem at relative `level`, ducked by the last
    /// cue with the ambience's own rule (`AmbienceDucking`).
    public func gain(level: Double, secondsSinceCue: TimeInterval?) -> Float {
        guard mayPlay else { return 0 }
        var gain = volumes.master * volumes.music * level * AmbienceDucking.factor(secondsSinceCue: secondsSinceCue)
        if voiceOverRunning { gain *= AmbienceLevels.voiceOverFactor }
        return Float(min(max(gain, 0), 1))
    }
}

/// SplitMix64: small, seeded, and the same on every platform.
struct MusicSeededRandom: Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// 0 up to, not including, 1.
    mutating func unit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}
