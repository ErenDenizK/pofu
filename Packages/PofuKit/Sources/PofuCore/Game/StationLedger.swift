import Foundation

/// Seeds waiting to be collected, by where they came from.
public struct SeedPouch: Hashable, Sendable, Codable {
    /// The stations' idle production.
    public var stations: Energy
    /// Pofu's quiet gathering: 1 per 10 quiet waking minutes (ADR-0014).
    public var gathered: Energy
    /// The slept-on-it bonus for calm nights.
    public var sleepBonus: Energy
    /// The thank-you for resisted reaches.
    public var skips: Energy

    public init(stations: Energy = .zero, gathered: Energy = .zero, sleepBonus: Energy = .zero, skips: Energy = .zero) {
        self.stations = stations
        self.gathered = gathered
        self.sleepBonus = sleepBonus
        self.skips = skips
    }

    public var total: Energy {
        stations + gathered + sleepBonus + skips
    }

    public var isEmpty: Bool {
        total == .zero
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

    // MARK: - Reading

    /// The station's level; zero when not built.
    public func level(of station: StationID) -> Int {
        levels[station] ?? 0
    }

    public func hasArrived(_ island: IslandID) -> Bool {
        arrivals[island] != nil
    }

    /// Whether the station's slot is open after `tendedDays`.
    public func isOpen(_ station: StationSpec, tendedDays: Int, catalog: ArchipelagoCatalog) -> Bool {
        guard let arrivedAt = arrivals[station.island] else { return false }
        if station.island == catalog.home {
            return catalog.homeStage(tendedDays: tendedDays) >= station.opensAt
        }
        return tendedDays - arrivedAt >= station.opensAt
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
        guard used < rules.giftedSkipsPerDay, rules.skipGift > .zero else { return .zero }
        giftedSkips = DayCount(day: day, count: used + 1)
        pending.skips += rules.skipGift
        return rules.skipGift
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
