import Foundation

/// Identifies an island of the archipelago, such as "home".
public struct IslandID: RawRepresentable, Hashable, Comparable, Sendable, Codable,
    ExpressibleByStringLiteral, CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public var description: String {
        rawValue
    }

    public static func < (lhs: IslandID, rhs: IslandID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// The home island (Ayçiçeği).
    public static let home: IslandID = "home"
    /// The harbor, the tea-and-bagel harbor (İskele).
    public static let harbor: IslandID = "harbor"
    // Yıldız, Kaplıca and Kitap were retired as station islands (game plan
    // §2); their ids live in `RetiredIds` so old saves still decode.
}

/// Identifies a station, such as "teaStall" (Mochi's çay ocağı).
public struct StationID: RawRepresentable, Hashable, Comparable, Sendable, Codable,
    ExpressibleByStringLiteral, CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public var description: String {
        rawValue
    }

    public static func < (lhs: StationID, rhs: StationID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static let garden: StationID = "garden"
    public static let teaStall: StationID = "teaStall"
    public static let pond: StationID = "pond"
    public static let workshop: StationID = "workshop"
    public static let windmill: StationID = "windmill"
    public static let bagelCart: StationID = "bagelCart"
    public static let pier: StationID = "pier"
    public static let lighthouse: StationID = "lighthouse"
}

/// One station's five designed levels (game design §5, "Idle production
/// and stations"; ADR-0016).
public struct StationSpec: Hashable, Sendable, Codable, Identifiable {
    public var id: StationID
    public var island: IslandID
    /// The island level (1–10) at which the station's slot opens, on every
    /// island (home progression §3). A harbor station also needs the
    /// harbor to have arrived.
    public var opensAt: Int
    /// The seeds it costs to reach each level, 1 to 5. A station that
    /// starts built has a zero first entry.
    public var levelCosts: [Energy]
    /// Seeds an hour at each level, 1 to 5, before calm, in hundredths so
    /// the designed rates stay exact.
    public var centiSeedsPerHour: [Int]
    /// Whether the station exists at level 1 from the start (Pofu's
    /// sunflower garden).
    public var startsBuilt: Bool

    public init(
        id: StationID,
        island: IslandID,
        opensAt: Int,
        levelCosts: [Energy],
        centiSeedsPerHour: [Int],
        startsBuilt: Bool = false
    ) {
        self.id = id
        self.island = island
        self.opensAt = opensAt
        self.levelCosts = levelCosts
        self.centiSeedsPerHour = centiSeedsPerHour
        self.startsBuilt = startsBuilt
    }

    /// The highest level.
    public var maxLevel: Int {
        min(levelCosts.count, centiSeedsPerHour.count)
    }

    /// What reaching `level` costs; `nil` outside `1...maxLevel`.
    public func cost(toReach level: Int) -> Energy? {
        guard level >= 1, level <= maxLevel else { return nil }
        return levelCosts[level - 1]
    }

    /// Hundredths of a seed an hour at `level`; zero when not built.
    public func centiRate(at level: Int) -> Int {
        guard level >= 1, level <= maxLevel else { return 0 }
        return max(0, centiSeedsPerHour[level - 1])
    }

    /// Seeds an hour at `level`, before calm.
    public func seedsPerHour(at level: Int) -> Double {
        Double(centiRate(at: level)) / 100
    }

    /// Seeds an hour per built level at economy scale A: 0.02 of a seed, so
    /// about 0.5 seeds a day per level at calm ×1.0 while Pofu is away and
    /// observing (archipelago system §7.3). Stations add up by level, not
    /// by station, so what you build matters less than that you build.
    public static let scaleACentiSeedsPerHourPerLevel = 2

    /// A ladder at economy scale A (founder, 2026-11-02): small, legible
    /// prices (5 to 200) and a rate that grows by the same step each level.
    /// `costs` are the prices of levels 1 to 5 (a station that starts built
    /// has a zero first entry).
    public static func ladder(
        _ id: StationID,
        island: IslandID,
        opensAt: Int,
        costs: [Int],
        startsBuilt: Bool = false
    ) -> StationSpec {
        let rates = (1...costs.count).map { $0 * scaleACentiSeedsPerHourPerLevel }
        return StationSpec(
            id: id,
            island: island,
            opensAt: opensAt,
            levelCosts: costs.map { Energy($0) },
            centiSeedsPerHour: rates,
            startsBuilt: startsBuilt
        )
    }
}

/// Which station level an island's arrival waits for.
public struct StationLevelRequirement: Hashable, Sendable, Codable {
    public var station: StationID
    public var level: Int

    public init(station: StationID, level: Int) {
        self.station = station
        self.level = level
    }
}

/// When an island drifts close. Every count is cumulative, never "in a
/// row" (A4, A19), so arrivals never go back.
public struct IslandArrival: Hashable, Sendable, Codable {
    public var tendedDays: Int
    public var calmNights: Int
    public var requires: StationLevelRequirement?
    /// Arrives with an app update ("with a season"), for everyone, once
    /// released (`GameRules.releasedIslands`), after `tendedDays`.
    public var needsRelease: Bool

    public init(tendedDays: Int = 0, calmNights: Int = 0, requires: StationLevelRequirement? = nil, needsRelease: Bool = false) {
        self.tendedDays = tendedDays
        self.calmNights = calmNights
        self.requires = requires
        self.needsRelease = needsRelease
    }
}

/// One island level (*Ada seviyesi*, home progression §3): the tended-day
/// floor and the growth that together reach it, and the station cap it
/// sets. Slots open by level through `StationSpec.opensAt`.
public struct IslandLevelRule: Hashable, Sendable, Codable {
    public var level: Int
    /// The tended day (the first is 1) from which the level can be reached.
    public var tendedDayFloor: Int
    /// Built station levels, summed over every station, it needs.
    public var growth: Int
    /// The highest level any station may reach while the island is here.
    public var stationCap: Int

    public init(level: Int, tendedDayFloor: Int, growth: Int, stationCap: Int) {
        self.level = level
        self.tendedDayFloor = tendedDayFloor
        self.growth = growth
        self.stationCap = stationCap
    }
}

/// What the next island level still waits for, for the short line "Ada 6
/// için: 2 seviye daha" (never a timer).
public struct IslandLevelRequirement: Hashable, Sendable {
    public var level: Int
    /// Tended days still to pass; zero once the floor is met.
    public var tendedDaysLeft: Int
    /// Station levels still to build; zero once the growth is met.
    public var levelsLeft: Int

    public init(level: Int, tendedDaysLeft: Int, levelsLeft: Int) {
        self.level = level
        self.tendedDaysLeft = tendedDaysLeft
        self.levelsLeft = levelsLeft
    }

    /// Nothing is left: the level is reached, so there is no goal to
    /// show. The real game never reports one (the level would have risen);
    /// a sample that pins a lower level for its look can.
    public var isMet: Bool { tendedDaysLeft == 0 && levelsLeft == 0 }
}

public struct IslandSpec: Hashable, Sendable, Codable, Identifiable {
    public var id: IslandID
    public var arrival: IslandArrival

    public init(id: IslandID, arrival: IslandArrival) {
        self.id = id
        self.arrival = arrival
    }
}

/// The pre-planned archipelago (ADR-0016): islands, their arrival rules,
/// the home island's stages, and every station's designed ladder.
public struct ArchipelagoCatalog: Hashable, Sendable, Codable {
    /// The island the player starts on.
    public var home: IslandID
    /// The island levels, 1 first (home progression §3). Extension point:
    /// residents, decor and seasons hang their openings off these.
    public var islandLevels: [IslandLevelRule]
    public var islands: [IslandSpec]
    public var stations: [StationSpec]

    public init(home: IslandID, islandLevels: [IslandLevelRule], islands: [IslandSpec], stations: [StationSpec]) {
        self.home = home
        self.islandLevels = islandLevels
        self.islands = islands
        self.stations = stations
    }

    public func station(_ id: StationID) -> StationSpec? {
        stations.first { $0.id == id }
    }

    public func island(_ id: IslandID) -> IslandSpec? {
        islands.first { $0.id == id }
    }

    public func stations(on island: IslandID) -> [StationSpec] {
        stations.filter { $0.island == island }
    }

    // MARK: - Island levels

    /// The highest island level; every count stops here.
    public var maxIslandLevel: Int {
        islandLevels.map(\.level).max() ?? 1
    }

    public func islandLevelRule(_ level: Int) -> IslandLevelRule? {
        islandLevels.first { $0.level == level }
    }

    /// The island level after `tendedDays` completed tended days and
    /// `growth` built station levels, from 1. Both inputs only grow, so
    /// the level never falls (A4).
    public func islandLevel(tendedDays: Int, growth: Int) -> Int {
        islandLevels
            .filter { tendedDays + 1 >= $0.tendedDayFloor && growth >= $0.growth }
            .map(\.level)
            .max() ?? 1
    }

    /// The station cap at `islandLevel`.
    public func stationCap(atIslandLevel islandLevel: Int) -> Int {
        islandLevelRule(islandLevel)?.stationCap ?? islandLevels.map(\.stationCap).max() ?? 1
    }

    /// The lowest island level whose cap lets a station reach `level`;
    /// `nil` if none does.
    public func islandLevel(allowingStationLevel level: Int) -> Int? {
        islandLevels.filter { $0.stationCap >= level }.map(\.level).min()
    }

    /// What the island level after `islandLevel` waits for; `nil` at the top.
    public func requirement(afterIslandLevel islandLevel: Int, tendedDays: Int, growth: Int) -> IslandLevelRequirement? {
        guard let rule = islandLevelRule(islandLevel + 1) else { return nil }
        return IslandLevelRequirement(
            level: rule.level,
            tendedDaysLeft: max(0, rule.tendedDayFloor - (tendedDays + 1)),
            levelsLeft: max(0, rule.growth - growth)
        )
    }

    /// The home island's art stage (1–5), from its open slots: one stage
    /// per home station that has opened.
    public func homeStage(islandLevel: Int) -> Int {
        max(1, stations(on: home).filter { $0.opensAt <= islandLevel }.count)
    }

    /// Every level of every station on `island`, in seeds.
    public func totalCost(of island: IslandID) -> Energy {
        stations(on: island).flatMap(\.levelCosts).reduce(.zero, +)
    }

    /// Every level of every station, in seeds.
    public var totalCost: Energy {
        stations.flatMap(\.levelCosts).reduce(.zero, +)
    }

    /// Home progression at economy scale A: two islands, eight stations,
    /// every level 5 to 130 seeds, 1,950 in all (home 1,173, harbor 777).
    /// Floors are tended days counted from 1 (day 3 is the third tended
    /// day).
    public static let standard = ArchipelagoCatalog(
        home: .home,
        islandLevels: [
            IslandLevelRule(level: 1, tendedDayFloor: 1, growth: 0, stationCap: 2),
            IslandLevelRule(level: 2, tendedDayFloor: 2, growth: 2, stationCap: 2),
            IslandLevelRule(level: 3, tendedDayFloor: 3, growth: 3, stationCap: 3),
            IslandLevelRule(level: 4, tendedDayFloor: 4, growth: 6, stationCap: 3),
            IslandLevelRule(level: 5, tendedDayFloor: 6, growth: 10, stationCap: 4),
            IslandLevelRule(level: 6, tendedDayFloor: 10, growth: 15, stationCap: 4),
            IslandLevelRule(level: 7, tendedDayFloor: 14, growth: 20, stationCap: 5),
            IslandLevelRule(level: 8, tendedDayFloor: 20, growth: 26, stationCap: 5),
            IslandLevelRule(level: 9, tendedDayFloor: 30, growth: 34, stationCap: 5),
            // Tam Çiçek: every one of the eight stations at level 5.
            IslandLevelRule(level: 10, tendedDayFloor: 36, growth: 40, stationCap: 5),
        ],
        islands: [
            IslandSpec(id: .home, arrival: IslandArrival()),
            // The fog lifts on the third tended day, once the tea stall is
            // built (two days have completed by then).
            IslandSpec(id: .harbor, arrival: IslandArrival(tendedDays: 2, requires: StationLevelRequirement(station: .teaStall, level: 1))),
        ],
        stations: [
            .ladder(.garden, island: .home, opensAt: 1, costs: [0, 5, 9, 15, 25], startsBuilt: true),
            .ladder(.teaStall, island: .home, opensAt: 2, costs: [8, 14, 24, 38, 60]),
            .ladder(.pond, island: .home, opensAt: 4, costs: [15, 25, 40, 60, 85]),
            .ladder(.workshop, island: .home, opensAt: 6, costs: [30, 45, 65, 90, 120]),
            .ladder(.windmill, island: .home, opensAt: 8, costs: [40, 55, 75, 100, 130]),
            .ladder(.bagelCart, island: .harbor, opensAt: 3, costs: [12, 20, 32, 48, 70]),
            .ladder(.pier, island: .harbor, opensAt: 5, costs: [20, 32, 48, 70, 100]),
            .ladder(.lighthouse, island: .harbor, opensAt: 6, costs: [25, 40, 60, 85, 115]),
        ]
    )
}
