import Foundation

/// A wonder island of the story (the healing arc): Koke and Çağlayan now,
/// the others later. Not a station island, so it never joins `arrivalOrder`.
public struct WonderIslandID: RawRepresentable, Hashable, Comparable, Sendable, Codable,
    ExpressibleByStringLiteral, CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public init(from decoder: any Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var description: String {
        rawValue
    }

    public static func < (lhs: WonderIslandID, rhs: WonderIslandID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Koke, the sleeping moss hump (the first wonder island).
    public static let koke: WonderIslandID = "koke"
    /// Çağlayan, the waterfall that stopped (the second wonder island).
    public static let caglayan: WonderIslandID = "caglayan"
}

/// Where one wonder island stands: its rumour, its arrival and how healed
/// it is. Never goes back (A4): a skipped day only pauses.
public struct WonderIslandState: Hashable, Sendable, Codable {
    /// The day the hump first showed on the horizon.
    public var rumouredOn: LocalDay?
    /// The day the island became reachable.
    public var arrivedOn: LocalDay?
    /// 0 (stuck) to `WonderIslands.healedStage` (healed).
    public var stage: Int
    /// The last day a visit advanced the stage: one stage a day at most.
    public var lastAdvanceDay: LocalDay?

    public init(rumouredOn: LocalDay? = nil, arrivedOn: LocalDay? = nil, stage: Int = 0, lastAdvanceDay: LocalDay? = nil) {
        self.rumouredOn = rumouredOn
        self.arrivedOn = arrivedOn
        self.stage = stage
        self.lastAdvanceDay = lastAdvanceDay
    }
}

/// The wonder islands in the saved game state. Old saves have none.
public struct WonderLedger: Hashable, Sendable, Codable {
    public internal(set) var islands: [WonderIslandID: WonderIslandState]

    public init(islands: [WonderIslandID: WonderIslandState] = [:]) {
        self.islands = islands
    }

    public subscript(id: WonderIslandID) -> WonderIslandState {
        islands[id] ?? WonderIslandState()
    }

    private enum CodingKeys: String, CodingKey {
        case islands
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Stored as a plain string-keyed map so it stays readable.
        let raw = try container.decodeIfPresent([String: WonderIslandState].self, forKey: .islands) ?? [:]
        islands = Dictionary(uniqueKeysWithValues: raw.map { (WonderIslandID(rawValue: $0.key), $0.value) })
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let raw = Dictionary(uniqueKeysWithValues: islands.map { ($0.key.rawValue, $0.value) })
        try container.encode(raw, forKey: .islands)
    }
}

/// What the world shows of a wonder island today.
public struct WonderStatus: Hashable, Sendable {
    public enum Phase: Int, Hashable, Sendable {
        /// Nothing yet.
        case hidden
        /// The hump is on the horizon, seen from the harbor.
        case rumoured
        /// The island can be visited.
        case arrived
    }

    public var phase: Phase
    /// 0 to 4.
    public var stage: Int
    /// A visit today would advance the stage: a day with a resisted reach,
    /// not advanced yet today.
    public var canAdvance: Bool
    /// Bedtime: the island sleeps and a visit changes nothing.
    public var isAsleep: Bool

    public init(phase: Phase = .hidden, stage: Int = 0, canAdvance: Bool = false, isAsleep: Bool = false) {
        self.phase = phase
        self.stage = stage
        self.canAdvance = canAdvance
        self.isAsleep = isAsleep
    }

    public var isArrived: Bool {
        phase == .arrived
    }

    public var isHealed: Bool {
        isArrived && stage >= WonderIslands.healedStage
    }

    /// Koke's moss decor at home and the faint light on the harbor horizon;
    /// Çağlayan's thin stream off home's edge.
    public var giftUnlocked: Bool {
        isHealed
    }
}

/// The rules of the wonder islands (Koke prototype spec §1). Pure.
public enum WonderIslands {
    /// The stage of a healed island.
    public static let healedStage = 4
    /// Tended days before the first rumour.
    public static let rumourTendedDays = 5

    /// Tended days before Çağlayan's rumour (the water noise stops somewhere,
    /// game plan day 8), and only once Koke is healed.
    public static let caglayanRumourTendedDays = 8
    /// Tended days after which Çağlayan's rumour comes even if Koke is not
    /// healed (a filler island never blocks the main road).
    public static let caglayanFallbackTendedDays = 12
    /// Days from Çağlayan's rumour to its arrival (a rumour two days before
    /// each island, game plan §3).
    public static let caglayanArrivalDays = 2

    /// Starts `day`: Koke's rumour on the first tended day from the fifth
    /// with the harbor open and its arrival on the next day; Çağlayan's
    /// rumour from the eighth tended day once Koke is healed, or from the
    /// twelfth tended day whatever Koke's state, its arrival two days later. Each island moves at most one step a day.
    static func roll(_ ledger: inout WonderLedger, to day: LocalDay, tendedDays: Int, harborOpen: Bool) {
        var koke = ledger[.koke]
        if koke.rumouredOn == nil {
            if tendedDays >= rumourTendedDays, harborOpen {
                koke.rumouredOn = day
                ledger.islands[.koke] = koke
            }
        } else if koke.arrivedOn == nil, let rumoured = koke.rumouredOn, rumoured < day {
            koke.arrivedOn = day
            ledger.islands[.koke] = koke
        }
        var caglayan = ledger[.caglayan]
        if caglayan.rumouredOn == nil {
            if tendedDays >= caglayanRumourTendedDays, harborOpen,
                (koke.arrivedOn != nil && koke.stage >= healedStage) || tendedDays >= caglayanFallbackTendedDays
            {
                caglayan.rumouredOn = day
                ledger.islands[.caglayan] = caglayan
            }
        } else if caglayan.arrivedOn == nil, let rumoured = caglayan.rumouredOn, rumoured.adding(days: caglayanArrivalDays) <= day {
            caglayan.arrivedOn = day
            ledger.islands[.caglayan] = caglayan
        }
    }

    /// Whether a visit on `day` would advance `state`.
    public static func canAdvance(_ state: WonderIslandState, day: LocalDay, resistedToday: Bool) -> Bool {
        state.arrivedOn != nil && state.stage < healedStage && resistedToday && state.lastAdvanceDay != day
    }

    /// A visit on `day`: one stage on a day with a resisted reach, at most
    /// one a day; otherwise the state is unchanged.
    public static func advance(state: WonderIslandState, day: LocalDay, resistedToday: Bool) -> WonderIslandState {
        guard canAdvance(state, day: day, resistedToday: resistedToday) else { return state }
        var next = state
        next.stage += 1
        next.lastAdvanceDay = day
        return next
    }

    /// Koke's status on `day` (`nil` before the clock has started).
    public static func status(game: GameState, day: LocalDay?) -> WonderStatus {
        status(of: .koke, game: game, day: day)
    }

    /// A wonder island's status on `day` (`nil` before the clock has started).
    public static func status(of island: WonderIslandID, game: GameState, day: LocalDay?) -> WonderStatus {
        let state = game.wonders[island]
        let phase: WonderStatus.Phase = state.arrivedOn != nil ? .arrived : state.rumouredOn != nil ? .rumoured : .hidden
        var resisted = false
        if let day, let today = game.today, today.day == day {
            resisted = today.resistedReaches > 0
        }
        let can = day.map { canAdvance(state, day: $0, resistedToday: resisted) } ?? false
        return WonderStatus(phase: phase, stage: state.stage, canAdvance: can)
    }
}
