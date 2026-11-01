import Foundation

/// The developer readout's numbers for one local day (gate v2, section 10):
/// every reach, how each ended, and the strict number (taps only) next to
/// the full one, so a generous rule never hides in the north star.
public struct GateReadoutDay: Hashable, Sendable {
    public var day: LocalDay
    /// Every reach, at the shield and in Hop!.
    public var reaches: Int
    /// Every resisted reach, whatever the kind.
    public var resisted: Int
    /// Reaches met on the shield.
    public var shieldReaches: Int
    /// Resisted on the shield, by kind.
    public var shieldSkips: Int
    public var silentLeaves: Int
    public var abandonedRequests: Int
    public var cancelledRequests: Int
    /// Quick checks started on the shield.
    public var quickChecks: Int
    /// Hop! outcomes.
    public var hopSkips: Int
    public var hopOpens: Int

    public init(day: LocalDay) {
        self.day = day
        reaches = 0
        resisted = 0
        shieldReaches = 0
        shieldSkips = 0
        silentLeaves = 0
        abandonedRequests = 0
        cancelledRequests = 0
        quickChecks = 0
        hopSkips = 0
        hopOpens = 0
    }

    /// Resisted with a tap ("Skip it" on the shield or in Hop!): the
    /// strict count, without silent leaves and abandoned requests.
    public var resistedByTap: Int {
        shieldSkips + cancelledRequests + hopSkips
    }

    /// The day as one line of text, for the weekly report.
    public var summary: String {
        "\(day): \(resisted)/\(reaches) resisted (\(resistedByTap) by tap) · shield: \(shieldSkips) skips, "
            + "\(silentLeaves) silent leaves, \(abandonedRequests) abandoned, \(cancelledRequests) cancelled, "
            + "\(quickChecks) quick checks · Hop!: \(hopSkips) skips, \(hopOpens) opens"
    }
}

public enum GateReadout {
    /// The readout of the `count` local days ending on `lastDay`, newest
    /// first, attributing each check-in to the day its reach started on.
    public static func days(
        endingOn lastDay: LocalDay,
        count: Int,
        from records: [CheckInRecord],
        calendar: Calendar
    ) -> [GateReadoutDay] {
        let days = (0..<max(0, count)).map { lastDay.adding(days: -$0) }
        var byDay: [LocalDay: GateReadoutDay] = [:]
        for day in days {
            byDay[day] = GateReadoutDay(day: day)
        }
        for record in records {
            let day = LocalDay(containing: record.attemptedAt, in: calendar)
            guard var entry = byDay[day] else { continue }
            entry.reaches += 1
            if record.outcome.isResisted {
                entry.resisted += 1
            }
            if let resolution = record.shieldResolution {
                entry.shieldReaches += 1
                switch resolution {
                case .skipped: entry.shieldSkips += 1
                case .silentLeave: entry.silentLeaves += 1
                case .abandonedRequest: entry.abandonedRequests += 1
                case .requestCancelled: entry.cancelledRequests += 1
                case .quickCheck: entry.quickChecks += 1
                }
            } else if record.resolvedChannel == .shield {
                // A skip at the shield from before gate v2.
                entry.shieldReaches += 1
                if record.outcome.isResisted {
                    entry.shieldSkips += 1
                }
            } else if record.outcome.isResisted {
                entry.hopSkips += 1
            } else {
                entry.hopOpens += 1
            }
            byDay[day] = entry
        }
        return days.compactMap { byDay[$0] }
    }
}
