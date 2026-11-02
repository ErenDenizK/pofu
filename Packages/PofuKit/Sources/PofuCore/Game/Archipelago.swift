import Foundation

/// Identifies an island of the archipelago, such as "aycicegi".
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

    /// Ayçiçeği, Pofu's home island.
    public static let aycicegi: IslandID = "aycicegi"
    /// İskele, the tea-and-simit harbor.
    public static let iskele: IslandID = "iskele"
    /// Yıldız, the night observatory.
    public static let yildiz: IslandID = "yildiz"
    /// Kaplıca, the hot-spring hamam.
    public static let kaplica: IslandID = "kaplica"
    /// Kitap, the library island (arrives with a season update).
    public static let kitap: IslandID = "kitap"
}

/// Identifies a station, such as "cay" (Mochi's çay ocağı).
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
    public static let cay: StationID = "cay"
    public static let pond: StationID = "pond"
    public static let workshop: StationID = "workshop"
    public static let windmill: StationID = "windmill"
    public static let simit: StationID = "simit"
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
    /// the designed rates (+55 % of base per level) stay exact.
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

    /// The pattern every designed ladder follows: costs grow ×2.2 per
    /// level (rounded), rates +55 % of the base per level.
    public static func designed(
        _ id: StationID,
        island: IslandID,
        opensAt: Int,
        firstCost: Int,
        baseSeedsPerHour: Int,
        startsBuilt: Bool = false
    ) -> StationSpec {
        // The garden starts built; its ladder starts at level 2.
        let costs: [Energy] = (1...5).map { level in
            if startsBuilt {
                return level == 1 ? .zero : Energy(Int((Double(firstCost) * pow(2.2, Double(level - 2))).rounded()))
            }
            return Energy(Int((Double(firstCost) * pow(2.2, Double(level - 1))).rounded()))
        }
        let rates = (1...5).map { level in baseSeedsPerHour * 100 + baseSeedsPerHour * 55 * (level - 1) }
        return StationSpec(id: id, island: island, opensAt: opensAt, levelCosts: costs, centiSeedsPerHour: rates, startsBuilt: startsBuilt)
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

    /// Game design v2: five islands, 17 stations, 1,944,103 seeds.
    public static let standard = ArchipelagoCatalog(
        home: .aycicegi,
        homeStageTendedDays: [0, 1, 4, 10, 24],
        islands: [
            IslandSpec(id: .aycicegi, arrival: IslandArrival()),
            IslandSpec(id: .iskele, arrival: IslandArrival(tendedDays: 8, requires: StationLevelRequirement(station: .cay, level: 3))),
            IslandSpec(id: .yildiz, arrival: IslandArrival(tendedDays: 21, calmNights: 10)),
            IslandSpec(id: .kaplica, arrival: IslandArrival(tendedDays: 35, requires: StationLevelRequirement(station: .pier, level: 3))),
            IslandSpec(id: .kitap, arrival: IslandArrival(tendedDays: 50, needsRelease: true)),
        ],
        stations: [
            .designed(.garden, island: .aycicegi, opensAt: 1, firstCost: 30, baseSeedsPerHour: 6, startsBuilt: true),
            .designed(.cay, island: .aycicegi, opensAt: 2, firstCost: 40, baseSeedsPerHour: 5),
            .designed(.pond, island: .aycicegi, opensAt: 3, firstCost: 160, baseSeedsPerHour: 6),
            .designed(.workshop, island: .aycicegi, opensAt: 4, firstCost: 500, baseSeedsPerHour: 9),
            .designed(.windmill, island: .aycicegi, opensAt: 5, firstCost: 1400, baseSeedsPerHour: 12),
            .designed(.simit, island: .iskele, opensAt: 0, firstCost: 300, baseSeedsPerHour: 8),
            .designed(.pier, island: .iskele, opensAt: 3, firstCost: 550, baseSeedsPerHour: 9),
            .designed(.lighthouse, island: .iskele, opensAt: 7, firstCost: 1000, baseSeedsPerHour: 11),
            .designed(.observatory, island: .yildiz, opensAt: 0, firstCost: 2000, baseSeedsPerHour: 12),
            .designed(.fireflies, island: .yildiz, opensAt: 3, firstCost: 2400, baseSeedsPerHour: 11),
            .designed(.hammock, island: .yildiz, opensAt: 7, firstCost: 3000, baseSeedsPerHour: 13),
            .designed(.spring, island: .kaplica, opensAt: 0, firstCost: 3600, baseSeedsPerHour: 13),
            .designed(.hamam, island: .kaplica, opensAt: 3, firstCost: 4400, baseSeedsPerHour: 14),
            .designed(.serbet, island: .kaplica, opensAt: 7, firstCost: 5200, baseSeedsPerHour: 15),
            .designed(.readingTree, island: .kitap, opensAt: 0, firstCost: 6000, baseSeedsPerHour: 14),
            .designed(.bookHouse, island: .kitap, opensAt: 3, firstCost: 7200, baseSeedsPerHour: 15),
            .designed(.press, island: .kitap, opensAt: 7, firstCost: 8400, baseSeedsPerHour: 16),
        ]
    )
}
