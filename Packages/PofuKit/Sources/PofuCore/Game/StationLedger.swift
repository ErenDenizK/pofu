import Foundation

/// Seeds waiting to be collected, by where they came from.
public struct SeedPouch: Hashable, Sendable, Codable {
    /// The stations' idle production.
    public var stations: Energy
    /// Pofu's quiet gathering: 1 per quiet waking hour at scale A.
    public var gathered: Energy
    /// The slept-on-it bonus for calm nights.
    public var sleepBonus: Energy
    /// The thank-you for resisted reaches.
    public var skips: Energy
    /// Island-game rounds' yields ("+3 yanaklarına").
    public var rounds: Energy

    public init(stations: Energy = .zero, gathered: Energy = .zero, sleepBonus: Energy = .zero, skips: Energy = .zero, rounds: Energy = .zero) {
        self.stations = stations
        self.gathered = gathered
        self.sleepBonus = sleepBonus
        self.skips = skips
        self.rounds = rounds
    }

    public var total: Energy {
        stations + gathered + sleepBonus + skips + rounds
    }

    public var isEmpty: Bool {
        total == .zero
    }

    private enum CodingKeys: String, CodingKey {
        case stations, gathered, sleepBonus, skips, rounds
    }

    /// Pouches saved before rounds existed read with no round seeds.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stations = try container.decodeIfPresent(Energy.self, forKey: .stations) ?? .zero
        gathered = try container.decodeIfPresent(Energy.self, forKey: .gathered) ?? .zero
        sleepBonus = try container.decodeIfPresent(Energy.self, forKey: .sleepBonus) ?? .zero
        skips = try container.decodeIfPresent(Energy.self, forKey: .skips) ?? .zero
        rounds = try container.decodeIfPresent(Energy.self, forKey: .rounds) ?? .zero
    }
}

/// A level built.
public struct BuildReceipt: Hashable, Sendable {
    public var station: StationID
    public var level: Int
    public var cost: Energy

    public init(station: StationID, level: Int, cost: Energy) {
        self.station = station
        self.level = level
        self.cost = cost
    }
}

/// Why a level could not be built.
public enum BuildError: Error, Hashable, Sendable {
    case unknownStation(StationID)
    /// The station's slot has not opened yet (stage or island).
    case notOpen(StationID)
    case maxLevel(StationID)
    /// The island level caps the station below the next level: it lifts at
    /// `islandLevel` ("Ada seviyesi 3'te açılır"). Nothing is locked for
    /// good; the cap rises by itself.
    case capped(StationID, cap: Int, liftsAtIslandLevel: Int?)
    case notEnoughSeeds(needed: Energy, have: Energy)
    /// The islands sleep from bedtime to morning: you can look, not build
    /// (A5).
    case islandsAsleep
}

/// The archipelago as built: station levels, the islands that arrived,
/// and the seeds (game design §5 and §7; ADR-0015, ADR-0016).
///
/// Seeds are **world material only**. They are credited by the stations'
/// idle production, Pofu's quiet gathering, calm nights, and a capped
/// thank-you per resisted reach, wait in a pouch until collected into the
/// jar, and are debited **only** by `build`. Nothing here reads or writes
/// the gate (A13): seeds never buy screen time, calm, wellbeing, or a
/// breath.
///
/// Levels and arrivals only ever go up (A4): nothing built is ever taken
/// away (ADR-0017).
public struct StationLedger: Hashable, Sendable, Codable {
    /// One seed in production units: rates are in hundredths of a seed an
    /// hour, calm and the care factor in tenths, and production runs per
    /// minute, so a minute at `rate` makes `rate × calm × care` units.
    public static let unitsPerSeed = 100 * 60 * 10 * 10

    /// Built levels; a station absent here is not built.
    public internal(set) var levels: [StationID: Int]
    /// The tended-day count at which each island arrived.
    public internal(set) var arrivals: [IslandID: Int]
    /// Islands in the order they arrived.
    public internal(set) var arrivalOrder: [IslandID]
    /// Collected seeds, ready to build with.
    public internal(set) var jar: Energy
    /// Seeds waiting to be collected.
    public internal(set) var pending: SeedPouch
    /// Production not yet a whole seed, in production units.
    public internal(set) var productionCarry: Int
    /// Resisted reaches that earned the thank-you today, for the cap.
    public internal(set) var giftedSkips: DayCount?

    public init(catalog: ArchipelagoCatalog = .standard) {
        var levels: [StationID: Int] = [:]
        for station in catalog.stations where station.startsBuilt && station.island == catalog.home {
            levels[station.id] = 1
        }
        self.levels = levels
        self.arrivals = [catalog.home: 0]
        self.arrivalOrder = [catalog.home]
        self.jar = .zero
        self.pending = SeedPouch()
        self.productionCarry = 0
        self.giftedSkips = nil
    }

    private enum CodingKeys: String, CodingKey {
        case levels, arrivals, arrivalOrder, jar, pending, productionCarry, giftedSkips
    }

    /// Reads a saved ledger. Islands and stations retired on 2026-11-05
    /// (Yıldız, Kaplıca, Kitap) are dropped and the seeds their levels cost
    /// go back into the jar; everything else reads as saved.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var levels = try container.decode([StationID: Int].self, forKey: .levels)
        var arrivals = try container.decode([IslandID: Int].self, forKey: .arrivals)
        var arrivalOrder = try container.decode([IslandID].self, forKey: .arrivalOrder)
        var jar = try container.decode(Energy.self, forKey: .jar)
        for (station, costs) in RetiredIds.stationCosts {
            guard let level = levels.removeValue(forKey: station), level > 0 else { continue }
            jar += Energy(costs.prefix(level).reduce(0, +))
        }
        for island in RetiredIds.islands {
            arrivals[island] = nil
        }
        arrivalOrder.removeAll { RetiredIds.islands.contains($0) }
        self.levels = levels
        self.arrivals = arrivals
        self.arrivalOrder = arrivalOrder
        self.jar = jar
        self.pending = try container.decode(SeedPouch.self, forKey: .pending)
        self.productionCarry = try container.decode(Int.self, forKey: .productionCarry)
        self.giftedSkips = try container.decodeIfPresent(DayCount.self, forKey: .giftedSkips)
    }

    // MARK: - Reading

    /// The station's level; zero when not built.
    public func level(of station: StationID) -> Int {
        levels[station] ?? 0
    }

    public func hasArrived(_ island: IslandID) -> Bool {
        arrivals[island] != nil
    }

    /// Built station levels summed over the catalog's stations: what the
    /// island level calls growth.
    public func growth(catalog: ArchipelagoCatalog) -> Int {
        catalog.stations.reduce(0) { $0 + level(of: $1.id) }
    }

    /// The island level (1–10) after `tendedDays` completed tended days. It
    /// is derived from two counts that only grow, so it never falls.
    public func islandLevel(tendedDays: Int, catalog: ArchipelagoCatalog) -> Int {
        catalog.islandLevel(tendedDays: tendedDays, growth: growth(catalog: catalog))
    }

    /// What the next island level waits for; `nil` at the top.
    public func nextIslandLevelRequirement(tendedDays: Int, catalog: ArchipelagoCatalog) -> IslandLevelRequirement? {
        let growth = growth(catalog: catalog)
        let level = catalog.islandLevel(tendedDays: tendedDays, growth: growth)
        return catalog.requirement(afterIslandLevel: level, tendedDays: tendedDays, growth: growth)
    }

    /// Whether the station's slot is open: its island has arrived and the
    /// island level has reached the slot's level.
    public func isOpen(_ station: StationSpec, tendedDays: Int, catalog: ArchipelagoCatalog) -> Bool {
        guard hasArrived(station.island) else { return false }
        return islandLevel(tendedDays: tendedDays, catalog: catalog) >= station.opensAt
    }

    /// The highest level `station` may be built to right now: the island
    /// level's cap, never above the station's own top (the soft cap).
    public func maxLevel(of station: StationSpec, tendedDays: Int, catalog: ArchipelagoCatalog) -> Int {
        let cap = catalog.stationCap(atIslandLevel: islandLevel(tendedDays: tendedDays, catalog: catalog))
        return min(station.maxLevel, cap)
    }

    /// What the next level of `station` costs; `nil` at the top.
    public func nextCost(of station: StationSpec) -> Energy? {
        station.cost(toReach: level(of: station.id) + 1)
    }

    /// Hundredths of a seed an hour, before calm, across every built
    /// station.
    public func centiRate(catalog: ArchipelagoCatalog) -> Int {
        var total = 0
        for station in catalog.stations {
            if let level = levels[station.id] {
                total += station.centiRate(at: level)
            }
        }
        return total
    }

    // MARK: - Seeds in

    /// One minute of production while the user is away: the stations'
    /// rate × calm × the care factor. Fractions carry to the next minute,
    /// so production is the same however the minutes are grouped.
    ///
    /// - Returns: The whole seeds it made.
    @discardableResult
    public mutating func produceMinute(calmTenths: Int, careTenths: Int, catalog: ArchipelagoCatalog) -> Energy {
        let units = centiRate(catalog: catalog) * max(0, calmTenths) * max(0, careTenths)
        guard units > 0 else { return .zero }
        productionCarry += units
        let seeds = productionCarry / Self.unitsPerSeed
        productionCarry -= seeds * Self.unitsPerSeed
        pending.stations += Energy(seeds)
        return Energy(seeds)
    }

    /// Pofu gathered `seeds` in a quiet block.
    public mutating func gather(_ seeds: Energy) {
        pending.gathered += max(seeds, .zero)
    }

    /// The slept-on-it bonus for a calm night.
    public mutating func addSleepBonus(_ seeds: Energy) {
        pending.sleepBonus += max(seeds, .zero)
    }

    /// The thank-you for a resisted reach on `day`, for at most
    /// `giftedSkipsPerDay`.
    ///
    /// - Returns: The seeds it gave; zero past the cap.
    @discardableResult
    public mutating func giftSkip(on day: LocalDay, rules: SeedRules) -> Energy {
        let used = giftedSkips.flatMap { $0.day == day ? $0.count : nil } ?? 0
        guard rules.skipGift > .zero, used < rules.giftedSkipsPerDay else { return .zero }
        giftedSkips = DayCount(day: day, count: used + 1)
        pending.skips += rules.skipGift
        return rules.skipGift
    }

    /// A played round's yield, into the pouch with the other seeds.
    mutating func creditRound(_ seeds: Energy) {
        pending.rounds += max(seeds, .zero)
    }

    /// Moves every waiting seed into the jar.
    ///
    /// - Returns: What was collected, or `nil` when nothing was waiting.
    @discardableResult
    public mutating func collect() -> SeedPouch? {
        guard !pending.isEmpty else { return nil }
        let collected = pending
        jar += collected.total
        pending = SeedPouch()
        return collected
    }

    // MARK: - Seeds out

    /// Builds the next level of `id`, paid from the jar: the only way seeds
    /// are ever spent.
    @discardableResult
    public mutating func build(_ id: StationID, tendedDays: Int, catalog: ArchipelagoCatalog) throws -> BuildReceipt {
        guard let station = catalog.station(id) else { throw BuildError.unknownStation(id) }
        guard isOpen(station, tendedDays: tendedDays, catalog: catalog) else { throw BuildError.notOpen(id) }
        let next = level(of: id) + 1
        guard let cost = station.cost(toReach: next) else { throw BuildError.maxLevel(id) }
        let cap = maxLevel(of: station, tendedDays: tendedDays, catalog: catalog)
        guard next <= cap else {
            throw BuildError.capped(id, cap: cap, liftsAtIslandLevel: catalog.islandLevel(allowingStationLevel: next))
        }
        guard jar >= cost else { throw BuildError.notEnoughSeeds(needed: cost, have: jar) }
        jar -= cost
        levels[id] = next
        return BuildReceipt(station: id, level: next, cost: cost)
    }

    // MARK: - Islands

    /// Lets every island whose arrival rule now holds drift close.
    ///
    /// - Returns: The islands that arrived, in catalog order.
    @discardableResult
    public mutating func settleArrivals(
        tendedDays: Int,
        calmNights: Int,
        released: Set<IslandID>,
        catalog: ArchipelagoCatalog
    ) -> [IslandID] {
        var arrived: [IslandID] = []
        for island in catalog.islands where arrivals[island.id] == nil {
            let rule = island.arrival
            guard tendedDays >= rule.tendedDays, calmNights >= rule.calmNights else { continue }
            if let requirement = rule.requires, level(of: requirement.station) < requirement.level { continue }
            if rule.needsRelease, !released.contains(island.id) { continue }
            arrivals[island.id] = tendedDays
            arrivalOrder.append(island.id)
            arrived.append(island.id)
        }
        return arrived
    }
}
