import Foundation

/// A season on the island's own clock.
public enum Season: String, CaseIterable, Codable, Hashable, Sendable {
    case spring
    case summer
    case autumn
    case winter
}

/// The island year (island calendar v1, decision C1): seasons of
/// `seasonDays` days each, counted from the player's first day, in the
/// order the rules give. Pure: the length, the order and the seasons with
/// no look yet are data in `tuning.json` (`calendar`), never here.
public enum IslandYear {
    public struct Rules: Hashable, Sendable {
        /// Days one season lasts (at least 1).
        public var seasonDays: Int
        /// The seasons in the order the year turns.
        public var order: [Season]
        /// Seasons with no look yet: left out of the cycle.
        public var disabled: Set<Season>

        public init(seasonDays: Int, order: [Season], disabled: Set<Season> = []) {
            self.seasonDays = max(1, seasonDays)
            self.order = order
            self.disabled = disabled
        }

        /// From the names in `tuning.json`; a name that is no season is dropped.
        public init(seasonDays: Int, order: [String], disabled: [String]) {
            self.init(
                seasonDays: seasonDays,
                order: order.compactMap(Season.init(rawValue:)),
                disabled: Set(disabled.compactMap(Season.init(rawValue:)))
            )
        }

        /// The seasons that turn, in order, each once. Never empty: a rule
        /// that disables everything falls back to spring.
        public var cycle: [Season] {
            var seen: Set<Season> = []
            let seasons = order.filter { !disabled.contains($0) && seen.insert($0).inserted }
            return seasons.isEmpty ? [.spring] : seasons
        }
    }

    /// Where a day sits in the island year.
    public struct Position: Hashable, Sendable {
        public var season: Season
        /// 1 to `seasonDays`.
        public var dayOfSeason: Int
        public var isLastDayOfSeason: Bool
    }

    public static func position(on day: LocalDay, firstDay: LocalDay, rules: Rules) -> Position {
        let cycle = rules.cycle
        let n = max(0, day.epochDay - firstDay.epochDay)
        let slot = (n / rules.seasonDays) % cycle.count
        let dayOfSeason = n % rules.seasonDays + 1
        return Position(season: cycle[slot], dayOfSeason: dayOfSeason, isLastDayOfSeason: dayOfSeason == rules.seasonDays)
    }

    /// The island's season on `day`. Day 1 (`firstDay`) opens the first
    /// season of the cycle; a day before it counts as day 1.
    public static func season(on day: LocalDay, firstDay: LocalDay, rules: Rules) -> Season {
        position(on: day, firstDay: firstDay, rules: rules).season
    }
}

extension LocalDay {
    /// Days since 1970-01-01 in the proleptic Gregorian calendar, by pure
    /// arithmetic (no `Calendar`, so no time zone or DST).
    var epochDay: Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let doy = (153 * (month + (month > 2 ? -3 : 9)) + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }
}
