import Foundation

/// A pass that lifted the shield from one shielded app (or category) for
/// the pass's duration. When it ends, the shield comes back.
public struct ShieldLift: Hashable, Sendable, Codable, Identifiable {
    /// Who lifted the shield.
    public enum Origin: String, Hashable, Sendable, Codable {
        /// A pass granted in Hop!.
        case hop
        /// "Just 3 minutes" on the shield itself (gate v2).
        case shieldQuickCheck
    }

    public let passID: UUID
    public let app: ShieldedApp
    public let from: Date
    public let until: Date
    /// `nil` in lifts from before gate v2, which all came from Hop!.
    public let origin: Origin?

    public init(passID: UUID, app: ShieldedApp, from: Date, until: Date, origin: Origin? = nil) {
        self.passID = passID
        self.app = app
        self.from = from
        self.until = until
        self.origin = origin
    }

    /// Length in whole minutes, rounded.
    public var minutes: Int {
        max(0, Int((until.timeIntervalSince(from) / 60).rounded()))
    }

    public var id: UUID { passID }

    /// Lifted from `from` (inclusive) until `until` (exclusive), like a
    /// pass.
    public func isActive(at date: Date) -> Bool {
        from <= date && date < until
    }
}

extension Sequence where Element == ShieldLift {
    /// The lifts in effect at `date`, leaving out `excluding` (a pass the
    /// monitor was just told has ended, even if its callback came a little
    /// early).
    public func active(at date: Date, excluding passID: UUID? = nil) -> [ShieldLift] {
        filter { $0.isActive(at: date) && $0.passID != passID }
    }

    /// The tokens of each kind that no shield should cover at `date`.
    public func exemptTokens(at date: Date, excluding passID: UUID? = nil) -> [ShieldedApp.Kind: Set<String>] {
        var exempt: [ShieldedApp.Kind: Set<String>] = [:]
        for lift in active(at: date, excluding: passID) {
            exempt[lift.app.kind, default: []].insert(lift.app.token)
        }
        return exempt
    }
}

/// When to put the shield back after a pass, in the terms DeviceActivity
/// understands.
///
/// DeviceActivity refuses intervals shorter than 15 minutes, and most
/// passes are shorter (a 3-minute quick check, a 5-minute free pass). For
/// those, the interval is stretched to the minimum and its warning is set
/// to fire when the pass ends: `intervalWillEndWarning` arrives
/// `warningLead` before the interval's end. Passes of 15 minutes or more
/// restore at `intervalDidEnd`.
///
/// Everything is in whole minutes, because schedules are wall-clock
/// components and the system may ignore seconds: the interval starts on
/// the minute the shield is lifted and the shield returns on the first
/// whole minute at or after the pass ends. So it never returns early and
/// is at most a minute late. The app also re-checks on every foreground,
/// so a late or missing callback cannot leave an app unguarded once the
/// user is back in Pofu.
public struct ShieldRestoreSchedule: Hashable, Sendable {
    /// DeviceActivity's minimum monitoring interval.
    public static let minimumInterval: TimeInterval = 15 * 60

    /// Which callback restores the shield.
    public enum Trigger: Hashable, Sendable {
        case intervalWillEndWarning
        case intervalDidEnd
    }

    public let intervalStart: Date
    public let intervalEnd: Date
    /// How long before `intervalEnd` the warning fires, in whole minutes;
    /// `nil` when the shield is restored at the end of the interval.
    public let warningLead: TimeInterval?

    /// - Parameters:
    ///   - start: When the shield is lifted.
    ///   - expiry: When the pass ends.
    /// - Returns: `nil` when the pass has already ended at `start`.
    public init?(liftingAt start: Date, until expiry: Date) {
        guard expiry > start else { return nil }
        let startMinute = (start.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60
        let endMinute = (expiry.timeIntervalSinceReferenceDate / 60).rounded(.up) * 60
        let duration = endMinute - startMinute
        guard duration > 0, duration.isFinite else { return nil }
        intervalStart = Date(timeIntervalSinceReferenceDate: startMinute)
        if duration >= Self.minimumInterval {
            intervalEnd = Date(timeIntervalSinceReferenceDate: endMinute)
            warningLead = nil
        } else {
            intervalEnd = intervalStart.addingTimeInterval(Self.minimumInterval)
            warningLead = Self.minimumInterval - duration
        }
    }

    public var trigger: Trigger {
        warningLead == nil ? .intervalDidEnd : .intervalWillEndWarning
    }

    /// When the shield comes back: the first whole minute at or after the
    /// pass ends.
    public var restoresAt: Date {
        intervalEnd.addingTimeInterval(-(warningLead ?? 0))
    }

    /// The interval as local wall-clock components (hour, minute, second),
    /// the form a non-repeating `DeviceActivitySchedule` takes. An interval
    /// that crosses midnight ends on the next day, which DeviceActivity
    /// reads from an end earlier than the start.
    public func intervalComponents(in calendar: Calendar) -> (start: DateComponents, end: DateComponents) {
        (
            calendar.dateComponents([.hour, .minute, .second], from: intervalStart),
            calendar.dateComponents([.hour, .minute, .second], from: intervalEnd)
        )
    }

    /// The warning lead as components (whole minutes), or `nil` when there
    /// is none.
    public var warningComponents: DateComponents? {
        warningLead.map { DateComponents(minute: Int(($0 / 60).rounded())) }
    }
}
