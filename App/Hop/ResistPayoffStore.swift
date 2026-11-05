import Foundation
import PofuDesignSystem

/// Remembers which resists have had their payoff (experience v1 section
/// 3.4). "Boş ver" leaves no trace in the app, so the shield's resists are
/// celebrated the next time Pofu is on screen; a resist made inside Hop!
/// plays at once and is marked here so it is not celebrated twice.
struct ResistPayoffStore {
    private let defaults: UserDefaults
    private let calendar: Calendar
    private static let key = "pofu.resistPayoff.record"

    init(defaults: UserDefaults = .standard, calendar: Calendar = .autoupdatingCurrent) {
        self.defaults = defaults
        self.calendar = calendar
    }

    /// Resists since the last payoff, for today's tally of `resisted`.
    /// Everything up to `resisted` counts as seen afterwards.
    func takeUnseen(resisted: Int, at date: Date = Date()) -> Int {
        let day = ResistPayoffLedger.day(for: date, calendar: calendar)
        let unseen = ResistPayoffLedger.unseen(resisted: resisted, day: day, record: record)
        save(ResistPayoffRecord(day: day, seen: max(resisted, 0)))
        return unseen
    }

    /// Marks today's `resisted` as seen (a payoff that played in Hop!).
    func markSeen(resisted: Int, at date: Date = Date()) {
        save(ResistPayoffRecord(day: ResistPayoffLedger.day(for: date, calendar: calendar), seen: max(resisted, 0)))
    }

    private var record: ResistPayoffRecord? {
        defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(ResistPayoffRecord.self, from: $0) }
    }

    private func save(_ record: ResistPayoffRecord) {
        if let data = try? JSONEncoder().encode(record) {
            defaults.set(data, forKey: Self.key)
        }
    }
}
