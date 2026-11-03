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
    /// Yıldız, the night observatory.
    public static let yildiz: IslandID = "yildiz"
    /// Kaplıca, the hot-spring hamam.
    public static let kaplica: IslandID = "kaplica"
    /// Kitap, the library island (arrives with a season update).
    public static let kitap: IslandID = "kitap"
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
    public static let observatory: StationID = "observatory"
    public static let fireflies: StationID = "fireflies"
    public static let hammock: StationID = "hammock"
    public static let spring: StationID = "spring"
    public static let hamam: StationID = "hamam"
    public static let serbet: StationID = "serbet"
    public static let readingTree: StationID = "readingTree"
    public static let bookHouse: StationID = "bookHouse"
    public static let press: StationID = "press"
}

/// One station's five designed levels (game design §5, "Idle production
/// and stations"; ADR-0016).
public struct StationSpec: Hashable, Sendable, Codable, Identifiable {
    public var id: StationID
    public var island: IslandID
    /// When the station's slot opens. On the home island: the island stage
    /// (1–5). On other islands: tended days after the island arrived.
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

    /// Seeds an hour per built level at economy scale A: 0.03 of a seed, so
    /// about 0.6 seeds a day per level at calm ×1.0 while Pofu is away and
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
    /// Tended days that open each home stage: stage 1 at index 0.
    public var homeStageTendedDays: [Int]
    public var islands: [IslandSpec]
    public var stations: [StationSpec]

    public init(home: IslandID, homeStageTendedDays: [Int], islands: [IslandSpec], stations: [StationSpec]) {
        self.home = home
        self.homeStageTendedDays = homeStageTendedDays
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

    /// The home island's stage after `tendedDays`, from 1.
    public func homeStage(tendedDays: Int) -> Int {
        max(1, homeStageTendedDays.filter { tendedDays >= $0 }.count)
    }

    /// Every level of every station on `island`, in seeds.
    public func totalCost(of island: IslandID) -> Energy {
        stations(on: island).flatMap(\.levelCosts).reduce(.zero, +)
    }

    /// Every level of every station, in seeds.
    public var totalCost: Energy {
        stations.flatMap(\.levelCosts).reduce(.zero, +)
    }

    /// Game design v2 at economy scale A: five islands, 17 stations, every
    /// level 5 to 200 seeds.
    public static let standard = ArchipelagoCatalog(
        home: .home,
        homeStageTendedDays: [0, 1, 4, 10, 24],
        islands: [
            IslandSpec(id: .home, arrival: IslandArrival()),
            IslandSpec(id: .harbor, arrival: IslandArrival(tendedDays: 8, requires: StationLevelRequirement(station: .teaStall, level: 3))),
            IslandSpec(id: .yildiz, arrival: IslandArrival(tendedDays: 21, calmNights: 10)),
            IslandSpec(id: .kaplica, arrival: IslandArrival(tendedDays: 35, requires: StationLevelRequirement(station: .pier, level: 3))),
            IslandSpec(id: .kitap, arrival: IslandArrival(tendedDays: 50, needsRelease: true)),
        ],
        stations: [
            .ladder(.garden, island: .home, opensAt: 1, costs: [0, 5, 9, 15, 25], startsBuilt: true),
            .ladder(.teaStall, island: .home, opensAt: 2, costs: [8, 14, 24, 38, 60]),
            .ladder(.pond, island: .home, opensAt: 3, costs: [15, 25, 40, 60, 85]),
            .ladder(.workshop, island: .home, opensAt: 4, costs: [30, 50, 75, 105, 140]),
            .ladder(.windmill, island: .home, opensAt: 5, costs: [50, 80, 110, 150, 190]),
            .ladder(.bagelCart, island: .harbor, opensAt: 0, costs: [25, 40, 60, 85, 115]),
            .ladder(.pier, island: .harbor, opensAt: 3, costs: [40, 60, 85, 115, 150]),
            .ladder(.lighthouse, island: .harbor, opensAt: 7, costs: [60, 85, 115, 150, 200]),
            .ladder(.observatory, island: .yildiz, opensAt: 0, costs: [45, 70, 100, 135, 170]),
            .ladder(.fireflies, island: .yildiz, opensAt: 3, costs: [55, 80, 110, 145, 180]),
            .ladder(.hammock, island: .yildiz, opensAt: 7, costs: [65, 90, 120, 155, 190]),
            .ladder(.spring, island: .kaplica, opensAt: 0, costs: [50, 75, 105, 140, 175]),
            .ladder(.hamam, island: .kaplica, opensAt: 3, costs: [60, 85, 115, 150, 185]),
            .ladder(.serbet, island: .kaplica, opensAt: 7, costs: [70, 95, 125, 160, 195]),
            .ladder(.readingTree, island: .kitap, opensAt: 0, costs: [55, 80, 110, 145, 180]),
            .ladder(.bookHouse, island: .kitap, opensAt: 3, costs: [65, 90, 120, 155, 190]),
            .ladder(.press, island: .kitap, opensAt: 7, costs: [75, 100, 130, 165, 200]),
        ]
    )
}
