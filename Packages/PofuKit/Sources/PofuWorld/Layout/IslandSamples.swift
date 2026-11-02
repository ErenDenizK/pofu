import Foundation
import PofuCore

/// Worlds for previews and screenshots, built from the standard catalog
/// so their stations and costs are the real ones.
public enum IslandSamples {
    /// Day 3 of a good week: the garden at level 2, Mochi's çay ocağı at
    /// level 1, the pond's slot open and empty, İskele on the horizon.
    public static func dayThree(clock: Date = Date(timeIntervalSinceReferenceDate: 815_000_000)) -> WorldSnapshot {
        world(
            clock: clock,
            tendedDays: 4,
            levels: [.garden: 2, .cay: 1],
            jar: Energy(60),
            islands: [.aycicegi, .iskele]
        )
    }

    /// A first day: the garden only.
    public static func firstDay(clock: Date = Date(timeIntervalSinceReferenceDate: 815_000_000)) -> WorldSnapshot {
        world(clock: clock, tendedDays: 0, levels: [.garden: 1], jar: .zero, islands: [.aycicegi])
    }

    /// A world with the given levels, read through the standard catalog.
    public static func world(
        clock: Date?,
        tendedDays: Int,
        levels: [StationID: Int],
        jar: Energy,
        islands: [IslandID],
        wellbeing: Double = 78,
        calm: Double = 1.4,
        isBedtime: Bool = false
    ) -> WorldSnapshot {
        let catalog = ArchipelagoCatalog.standard
        let stage = catalog.homeStage(tendedDays: tendedDays)
        let stations = catalog.stations.filter { islands.contains($0.island) }.map { spec in
            let level = levels[spec.id] ?? 0
            let isOpen = spec.island == catalog.home ? stage >= spec.opensAt : true
            let next = spec.cost(toReach: level + 1)
            return StationStatus(
                id: spec.id,
                island: spec.island,
                level: level,
                maxLevel: spec.maxLevel,
                isOpen: isOpen,
                nextCost: next,
                canAfford: next.map { jar >= $0 } ?? false,
                seedsPerHour: spec.seedsPerHour(at: level)
            )
        }
        let rate = stations.reduce(0) { $0 + $1.seedsPerHour }
        return WorldSnapshot(
            clock: clock,
            activity: .away,
            isBedtime: isBedtime,
            wellbeing: wellbeing,
            band: wellbeing >= 80 ? .cozy : wellbeing >= 55 ? .content : wellbeing >= 30 ? .tired : .unwell,
            calm: calm,
            calmProgress: 0.4,
            calmIsFull: false,
            pending: SeedPouch(stations: Energy(12), gathered: Energy(3)),
            jar: jar,
            isHolding: false,
            tendedDays: tendedDays,
            calmNights: 2,
            homeStage: stage,
            islands: islands,
            stations: stations,
            seedsPerHour: rate * calm,
            guardedMinutesToday: 22,
            dailyHourMinutes: 60,
            overLimitOpensToday: 0,
            nextBreath: nil
        )
    }
}
