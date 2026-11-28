import Foundation
import PofuCore
import PofuDesignSystem

/// The world's weather (sky and weather v1 section 2.2) and the player's
/// screen haze (section 2.2b). Two layers that never mix: weather is the
/// world's and follows only the calendar (a seeded, shuffled bag per half
/// day); the haze follows the player's wellbeing and nothing else. Pure, so
/// it is tested on any platform.
public enum Weather: String, CaseIterable, Hashable, Sendable {
    case clear
    case overcast
    case lightRain
    case mist
    case goldenHaze
    /// Winter's own weather (island calendar v1, C2): soft flakes under an
    /// overcast sky. Only the island's winter rolls it.
    case snow

    /// The colour script's row for this weather; `nil` for clear. Snow
    /// takes the overcast row: a snowy sky is a quiet grey one.
    var stateName: String? {
        switch self {
        case .clear: nil
        case .snow: Weather.overcast.rawValue
        default: rawValue
        }
    }

    /// The colour script's row, layered over the hour like the unwell state.
    public var state: ColourState? {
        stateName.map { ColourScript.weather(named: $0) }
    }

    /// The extra depth fog at every tier behind the front one (0...1).
    public var mist: Double {
        self == .mist ? 1 : 0
    }

    /// Whether this weather draws falling rain.
    public var isRaining: Bool {
        self == .lightRain
    }

    /// Whether this weather draws falling snow.
    public var isSnowing: Bool {
        self == .snow
    }
}

/// Which half of the day a weather roll covers.
public enum WeatherHalf: Int, Hashable, Sendable {
    case morning
    case afternoon

    public init(hour: Double) {
        self = hour < 12 ? .morning : .afternoon
    }
}

/// What the sky is doing at one moment.
public struct WeatherConditions: Hashable, Sendable {
    /// The weather being drawn now (clear once rain has ended).
    public var weather: Weather
    /// The pastel arc: only within an hour after rain ends, by day.
    public var rainbow: Bool
    /// Wet ground: puddle glints, while it rains and through the rainbow hour.
    public var wet: Bool

    public init(weather: Weather = .clear, rainbow: Bool = false, wet: Bool? = nil) {
        self.weather = weather
        self.rainbow = rainbow
        self.wet = wet ?? (weather.isRaining || rainbow)
    }

    public static let clear = WeatherConditions()
}

/// The shuffled bag (founder, 2026-11-06): every weather, and a rainbow
/// after the rain, appears within the first 14 days; then the bag refills
/// with the shares of section 2.2. Weather never follows behaviour.
public enum WeatherForecast {
    /// A bag covers two weeks of half days.
    public static let bagDays = 14
    public static let bagSlots = bagDays * 2

    /// What one bag holds, in slots: shares 55 / 20 / 10 / 8 / 4 % of 28,
    /// rounded so every weather is in the bag at least once.
    public static let bagCounts: [Weather: Int] = [
        .clear: 16, .overcast: 6, .lightRain: 3, .mist: 2, .goldenHaze: 1,
    ]

    /// Rain falls until noon in a morning slot, until five in an afternoon
    /// one; it never falls in the night's deepest hours.
    static let morningRain = 4.0 ..< 12.0
    static let afternoonRain = 12.0 ..< 17.0
    /// Snow keeps falling into the evening; like rain it leaves the night's
    /// deepest hours alone.
    static let afternoonSnow = 12.0 ..< 23.0
    static let mistHours = 4.5 ..< 10.5
    static let goldenHours = 17.5 ..< 19.5
    /// The rainbow lasts an hour after the rain ends.
    static let rainbowHours = 1.0

    /// The weather of every slot of bag `index`: slot 2k is a morning, 2k+1
    /// the afternoon after it. Mist only fills mornings, golden haze only
    /// afternoons, and no two rains touch, so every rain has a clearing.
    public static func bag(_ index: Int, start: LocalDay) -> [Weather] {
        var rng = SplitMix64(seed: UInt64(truncatingIfNeeded: dayNumber(start)) &* 0x9E37_79B9_7F4A_7C15 &+ UInt64(truncatingIfNeeded: index) &* 0xD1B5_4A32_D192_ED03 &+ 0x5EED)
        var slots = [Weather?](repeating: nil, count: bagSlots)
        func free(_ parity: Int?) -> [Int] {
            slots.indices.filter { i in slots[i] == nil && (parity == nil || i % 2 == parity) }
        }
        func place(_ weather: Weather, parity: Int?, avoidingRain: Bool = false) {
            var options = free(parity)
            if avoidingRain {
                options = options.filter { i in
                    !(i > 0 && slots[i - 1] == .lightRain) && !(i + 1 < bagSlots && slots[i + 1] == .lightRain)
                }
            }
            guard !options.isEmpty else { return }
            slots[options[Int(rng.next() % UInt64(options.count))]] = weather
        }
        for _ in 0 ..< (bagCounts[.goldenHaze] ?? 0) { place(.goldenHaze, parity: 1) }
        for _ in 0 ..< (bagCounts[.mist] ?? 0) { place(.mist, parity: 0) }
        for _ in 0 ..< (bagCounts[.lightRain] ?? 0) { place(.lightRain, parity: nil, avoidingRain: true) }
        var rest: [Weather] = []
        for weather in [Weather.overcast, .clear] {
            rest += Array(repeating: weather, count: bagCounts[weather] ?? 0)
        }
        // Fisher-Yates over the rest.
        for i in stride(from: rest.count - 1, to: 0, by: -1) {
            rest.swapAt(i, Int(rng.next() % UInt64(i + 1)))
        }
        var next = rest.makeIterator()
        return slots.map { $0 ?? next.next() ?? .clear }
    }

    /// Days one season bag covers: the island season's own length.
    public static let seasonBagDays = 7
    public static let seasonBagSlots = seasonBagDays * 2

    /// What one season's bag holds, in slots out of 14 (island calendar v1,
    /// C2): summer is clear with a shower and a golden evening, autumn
    /// grey with rain and mist, winter's snow instead of rain. `nil` for
    /// spring, whose bag is the shipped one (`bagCounts`), so every spring
    /// frame stays as it was.
    public static func seasonCounts(_ season: Season) -> [Weather: Int]? {
        switch season {
        case .spring: nil
        case .summer: [.clear: 8, .overcast: 2, .lightRain: 2, .goldenHaze: 2]
        case .autumn: [.clear: 4, .overcast: 4, .lightRain: 3, .mist: 2, .goldenHaze: 1]
        case .winter: [.clear: 6, .overcast: 3, .snow: 4, .mist: 1]
        }
    }

    /// The weather of every slot of one season bag (`block` counts weeks
    /// from the first day): the same placing rules as `bag`.
    public static func seasonBag(block: Int, season: Season, start: LocalDay) -> [Weather] {
        let counts = seasonCounts(season) ?? bagCounts
        let salt: UInt64 = switch season {
        case .spring: 0
        case .summer: 1
        case .autumn: 2
        case .winter: 3
        }
        var rng = SplitMix64(seed: UInt64(truncatingIfNeeded: dayNumber(start)) &* 0x9E37_79B9_7F4A_7C15 &+ UInt64(truncatingIfNeeded: block) &* 0xD1B5_4A32_D192_ED03 &+ salt &* 0x2545_F491_4F6C_DD1D &+ 0x5EA5)
        var slots = [Weather?](repeating: nil, count: seasonBagSlots)
        func place(_ weather: Weather, parity: Int?, avoidingRain: Bool = false) {
            var options = slots.indices.filter { i in slots[i] == nil && (parity == nil || i % 2 == parity) }
            if avoidingRain {
                options = options.filter { i in
                    !(i > 0 && slots[i - 1] == .lightRain) && !(i + 1 < seasonBagSlots && slots[i + 1] == .lightRain)
                }
            }
            guard !options.isEmpty else { return }
            slots[options[Int(rng.next() % UInt64(options.count))]] = weather
        }
        for _ in 0 ..< (counts[.goldenHaze] ?? 0) { place(.goldenHaze, parity: 1) }
        for _ in 0 ..< (counts[.mist] ?? 0) { place(.mist, parity: 0) }
        for _ in 0 ..< (counts[.lightRain] ?? 0) { place(.lightRain, parity: nil, avoidingRain: true) }
        for _ in 0 ..< (counts[.snow] ?? 0) { place(.snow, parity: nil) }
        var rest: [Weather] = []
        for weather in [Weather.overcast, .clear] {
            rest += Array(repeating: weather, count: counts[weather] ?? 0)
        }
        for i in stride(from: rest.count - 1, to: 0, by: -1) {
            rest.swapAt(i, Int(rng.next() % UInt64(i + 1)))
        }
        var next = rest.makeIterator()
        return slots.map { $0 ?? next.next() ?? .clear }
    }

    /// The weather rolled for a half day (before the hour trims it). The
    /// island's `season` picks the bag: spring (or none) is the shipped one.
    public static func weather(on day: LocalDay, half: WeatherHalf, start: LocalDay, season: Season? = nil) -> Weather {
        let n = max(0, dayNumber(day) - dayNumber(start))
        let slot = n * 2 + half.rawValue
        if let season, seasonCounts(season) != nil {
            return seasonBag(block: slot / seasonBagSlots, season: season, start: start)[slot % seasonBagSlots]
        }
        return bag(slot / bagSlots, start: start)[slot % bagSlots]
    }

    /// The sky at a local hour (0...24) of a day, for a game that began on
    /// `start`. Same on every launch that day.
    public static func conditions(on day: LocalDay, hour: Double, start: LocalDay, season: Season? = nil) -> WeatherConditions {
        let h = hour.isFinite ? min(max(hour, 0), 24) : 12
        let half = WeatherHalf(hour: h)
        let morning = weather(on: day, half: .morning, start: start, season: season)
        let afternoon = weather(on: day, half: .afternoon, start: start, season: season)

        // The payoff: the hour after rain, a break in the clouds and a rainbow.
        if morning == .lightRain, h >= morningRain.upperBound, h < morningRain.upperBound + rainbowHours {
            return WeatherConditions(weather: .clear, rainbow: true)
        }
        if afternoon == .lightRain, h >= afternoonRain.upperBound, h < afternoonRain.upperBound + rainbowHours {
            return WeatherConditions(weather: .clear, rainbow: true)
        }

        let rolled = half == .morning ? morning : afternoon
        switch rolled {
        case .clear, .overcast:
            return WeatherConditions(weather: rolled)
        case .lightRain:
            let hours = half == .morning ? morningRain : afternoonRain
            return WeatherConditions(weather: hours.contains(h) ? .lightRain : .clear)
        case .snow:
            let hours = half == .morning ? morningRain : afternoonSnow
            return WeatherConditions(weather: hours.contains(h) ? .snow : .clear)
        case .mist:
            return WeatherConditions(weather: mistHours.contains(h) ? .mist : .clear)
        case .goldenHaze:
            return WeatherConditions(weather: goldenHours.contains(h) ? .goldenHaze : .clear)
        }
    }

    /// The sky for a snapshot's clock, falling back to a fixed first day
    /// when the game has not recorded one.
    public static func conditions(clock: Date?, firstDay: LocalDay?, hour: Double, calendar: Calendar, season: Season? = nil) -> WeatherConditions {
        guard let clock else { return .clear }
        let day = LocalDay(containing: clock, in: calendar)
        return conditions(on: day, hour: hour, start: firstDay ?? day, season: season)
    }

    /// Days since 1970-01-01 of a calendar day (proleptic Gregorian).
    static func dayNumber(_ day: LocalDay) -> Int {
        let y = day.month <= 2 ? day.year - 1 : day.year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (day.month + 9) % 12
        let doy = (153 * mp + 2) / 5 + day.day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }
}

/// A small deterministic generator: the same seed gives the same bag on
/// every device and every launch.
struct SplitMix64 {
    var state: UInt64

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
}

// MARK: - The screen haze

/// The player's sky (section 2.2b): the unwell state (wellbeing 55 to 30)
/// drawn as a cool lilac-grey haze that rolls in from the harbor side. It
/// reads wellbeing and nothing else; weather has no way in. A resisted reach
/// parts it a little with a shaft of light.
public enum ScreenHaze {
    /// 0 at wellbeing 55 and above, 1 at 30 and below, eased: the same
    /// ramp as `WorldLight.unwell`.
    public static func amount(wellbeing: Double) -> Double {
        let t = min(max(((wellbeing.isFinite ? 55 - wellbeing : 0) / 25), 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// The most a part can lift the haze, as a share of it.
    public static let partingDepth = 0.4
    /// The shaft rises in this long, holds, then the haze closes over this.
    public static let partingRise = 1.5
    public static let partingHold = 20.0
    public static let partingFall = 90.0

    /// How open the parting is, 0...1, `seconds` after a resisted reach.
    public static func parting(secondsSince seconds: Double?) -> Double {
        guard let s = seconds, s.isFinite, s >= 0 else { return 0 }
        if s < partingRise { return smooth(s / partingRise) }
        if s < partingRise + partingHold { return 1 }
        let t = (s - partingRise - partingHold) / partingFall
        return t >= 1 ? 0 : 1 - smooth(t)
    }

    /// The haze left after a parting.
    public static func parted(_ amount: Double, parting: Double) -> Double {
        amount * (1 - partingDepth * min(max(parting, 0), 1))
    }

    /// The haze's colour: lilac-grey, blue-dominant.
    public static var colour: PofuRGB {
        ColourScript.weather(named: "screenHaze").skyToward
    }

    private static func smooth(_ t: Double) -> Double {
        let t = min(max(t, 0), 1)
        return t * t * (3 - 2 * t)
    }
}

/// The two skies together: the world's weather and the player's haze.
public struct Atmosphere: Hashable, Sendable {
    public var conditions: WeatherConditions
    /// The screen haze after any parting, 0...1.
    public var haze: Double

    public init(conditions: WeatherConditions = .clear, haze: Double = 0) {
        self.conditions = conditions
        self.haze = min(max(haze.isFinite ? haze : 0, 0), 1)
    }

    public static let clear = Atmosphere()

    /// Depth fog added at every tier behind the front one, 0...1 of
    /// `LookTuning.fogMistExtra`: mist's, the rain's small share, the haze's.
    public var mist: Double {
        let weather = conditions.weather.state?.fogExtra ?? 0
        let haze = ColourScript.weather(named: "screenHaze").fogExtra * self.haze
        return min((weather + haze) / LookTuning.fogMistExtra, 1)
    }

    /// Whether any particle or drawn layer is needed.
    public var isClear: Bool {
        conditions.weather == .clear && !conditions.rainbow && haze <= 0.001
    }
}

extension WorldLight {
    /// This light under the world's weather and the player's haze: the
    /// weather row and the haze row layered over the hour's grade, the key
    /// and fill carried by the grade's gain, the practicals dimmed by the
    /// haze and kept lit by the rain.
    public func withAtmosphere(_ atmosphere: Atmosphere) -> WorldLight {
        guard !atmosphere.isClear else { return self }
        var copy = self
        if let state = atmosphere.conditions.weather.state {
            // The island takes a rain or overcast sky through the rain LUT,
            // which is already fitted to the rain reference; the row's own
            // grade (contrast 0.8, gain 0.92) only covers what the LUT does
            // not (night, dusk, mist), so the island is never graded twice.
            let rain = LookLUT.rainAmount(atmosphere.conditions.weather)
            let lut = LookLUT.Blend(group: .island, cells: cellWeights, rain: rain)
            // The sun-lit share of the hour is graded by the LUT alone.
            let sunlit = rain > 0 ? min(max((lut.weights[.rain] ?? 0) / rain, 0), 1) : 0
            copy.grade = copy.grade.layered(with: state.grade, amount: 1 - sunlit)
            copy.characterGrade = copy.characterGrade.layered(with: state.character, amount: 1)
            // The backdrop takes the weather as overcast colour, never as a
            // darkening grade (look pipeline v2 §6.3): `SkyPalette.atmospheric`
            // and `CloudSea.Colours(weather:)`.
            // Rain moves the sun-lit cells to the rain LUT (look pipeline v2).
            if rain > 0 {
                copy.grade.lut = lut
                copy.characterGrade.lut = lut.for(.characters)
            }
            copy.practicals.window = max(copy.practicals.window, state.windowFloor * (1 - night))
            // Overcast and rain put the sun out; golden haze blooms.
            let dull = atmosphere.conditions.weather == .overcast || atmosphere.conditions.weather.isRaining || atmosphere.conditions.weather.isSnowing
            copy.shafts *= dull ? 0.3 : 1
            copy.bloom *= dull ? 0.8 : 1.2
            copy.pollen *= atmosphere.conditions.weather.isRaining || atmosphere.conditions.weather.isSnowing ? 0 : 1
            copy.fireflies *= atmosphere.conditions.weather.isRaining ? 0.4 : 1
        }
        if atmosphere.haze > 0 {
            let haze = ColourScript.weather(named: "screenHaze")
            copy.grade = copy.grade.layered(with: haze.grade, amount: atmosphere.haze)
            copy.backdropGrade = copy.backdropGrade.layered(with: haze.grade, amount: atmosphere.haze)
            copy.characterGrade = copy.characterGrade.layered(with: haze.character, amount: atmosphere.haze)
            // Practicals dim but never go out.
            copy.practicals.ember *= 1 - 0.4 * atmosphere.haze
            copy.practicals.window *= 1 - 0.2 * atmosphere.haze
            copy.bloom *= 1 - 0.25 * atmosphere.haze
            copy.shafts *= 1 - atmosphere.haze
        }
        return copy
    }
}

extension SkyPalette {
    /// The sky under the world's weather and the player's haze: cooler
    /// and lower in chroma (or peach in mist), never brighter than the
    /// hour's, with denser cloud in overcast and rain.
    public func atmospheric(_ atmosphere: Atmosphere) -> SkyPalette {
        guard !atmosphere.isClear else { return self }
        var copy = self
        if let state = atmosphere.conditions.weather.state {
            copy = copy.overcast(state, amount: 1)
            if state.keyIntensity < 0.8 {
                copy.cloudOpacity = min(copy.cloudOpacity * 1.3 + 0.1, 1)
            }
        }
        if atmosphere.haze > 0 {
            copy = copy.overcast(ColourScript.weather(named: "screenHaze"), amount: atmosphere.haze)
        }
        return copy.luminousNight()
    }
}
