import Foundation

/// A day with a kit (island calendar v1, decision C2).
public enum SpecialDay: String, CaseIterable, Codable, Hashable, Sendable {
    case newYear
    case hidirellez
    case ramazanBayrami
    case kurbanBayrami
    case halloween
    /// The last evening of each island season, on the island's own clock.
    case festivalNight
}

/// The table of special days (`special-days.json`) and the rule that says
/// which are on at a moment. Pure.
public struct SpecialDays: Sendable {
    struct YearlyRange: Decodable, Sendable {
        var from: String
        var to: String

        func contains(month: Int, day: Int) -> Bool {
            guard let a = Self.key(from), let b = Self.key(to) else { return false }
            let k = month * 100 + day
            return a <= b ? (a...b).contains(k) : (k >= a || k <= b)
        }

        private static func key(_ text: String) -> Int? {
            let parts = text.split(separator: "-").compactMap { Int($0) }
            return parts.count == 2 ? parts[0] * 100 + parts[1] : nil
        }
    }

    struct DatedRange: Decodable, Sendable {
        var from: String
        var to: String

        var days: ClosedRange<LocalDay>? {
            guard let a = Self.day(from), let b = Self.day(to), a <= b else { return nil }
            return a...b
        }

        static func day(_ text: String) -> LocalDay? {
            let parts = text.split(separator: "-").compactMap { Int($0) }
            return parts.count == 3 ? LocalDay(year: parts[0], month: parts[1], day: parts[2]) : nil
        }
    }

    struct Entry: Decodable, Sendable {
        var id: SpecialDay
        var yearly: [YearlyRange]?
        var dated: [DatedRange]?
        var islandClock: Bool?
    }

    private struct File: Decodable {
        var eveningBeforeMinute: Int
        var days: [Entry]
    }

    private let entries: [Entry]
    /// Minute of the day from which tomorrow's kit already shows.
    public let eveningBeforeMinute: Int

    init(entries: [Entry], eveningBeforeMinute: Int) {
        self.entries = entries
        self.eveningBeforeMinute = eveningBeforeMinute
    }

    /// Decodes the bundled `special-days.json`.
    public static func bundled() throws -> SpecialDays {
        guard let url = Bundle.module.url(forResource: "special-days", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let file = try JSONDecoder().decode(File.self, from: Data(contentsOf: url))
        return SpecialDays(entries: file.days, eveningBeforeMinute: file.eveningBeforeMinute)
    }

    /// The bundled table. A test proves the file decodes.
    public static let shipped: SpecialDays = {
        do {
            return try bundled()
        } catch {
            preconditionFailure("special-days.json does not decode: \(error)")
        }
    }()

    /// The last day of the last dated entry (the last bayram listed), for
    /// the test that says when to add more years.
    public var lastDatedDay: LocalDay? {
        entries.flatMap { $0.dated ?? [] }.compactMap { $0.days?.upperBound }.max()
    }

    /// The special days on at `minute` (minutes since local midnight) of
    /// `day`, in table order. The island's festival night needs the player's
    /// first day and the island year's rules; without them it is left out.
    public func active(
        on day: LocalDay,
        at minute: Int,
        firstDay: LocalDay? = nil,
        rules: IslandYear.Rules? = nil
    ) -> [SpecialDay] {
        let tomorrow = day.adding(days: 1)
        return entries.compactMap { entry in
            let evening = minute >= eveningBeforeMinute
            if entry.islandClock == true {
                guard evening, let firstDay, let rules else { return nil }
                return IslandYear.position(on: day, firstDay: firstDay, rules: rules).isLastDayOfSeason ? entry.id : nil
            }
            let on = covers(entry, day) || (evening && covers(entry, tomorrow))
            return on ? entry.id : nil
        }
    }

    /// The one special day to show: the first of `active`.
    public func current(
        on day: LocalDay,
        at minute: Int,
        firstDay: LocalDay? = nil,
        rules: IslandYear.Rules? = nil
    ) -> SpecialDay? {
        active(on: day, at: minute, firstDay: firstDay, rules: rules).first
    }

    /// `active` on the bundled table.
    public static func active(
        on day: LocalDay,
        at minute: Int,
        firstDay: LocalDay? = nil,
        rules: IslandYear.Rules? = nil
    ) -> [SpecialDay] {
        shipped.active(on: day, at: minute, firstDay: firstDay, rules: rules)
    }

    private func covers(_ entry: Entry, _ day: LocalDay) -> Bool {
        if entry.yearly?.contains(where: { $0.contains(month: day.month, day: day.day) }) == true { return true }
        return entry.dated?.contains { $0.days?.contains(day) == true } == true
    }
}
