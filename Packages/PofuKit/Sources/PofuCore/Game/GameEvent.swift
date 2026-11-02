import Foundation

/// Something the game model needs to know, at the time it happened.
///
/// The vocabulary is what Pofu can honestly measure (game design §6): signs
/// of life, reaches and how they ended, passes and how they ended, measured
/// usage, and Pofu's own foreground time. Adapters build it from the gate's
/// event log (`LoggedEvent`) or its check-in records.
public struct GameEvent: Hashable, Sendable, Codable {
    public enum Kind: Hashable, Sendable, Codable {
        /// The automation or the shield showed it is alive: a check-in
        /// request, a pass-through, a shield drawn. Keeps Pofu observing,
        /// and ends the unobserved time after a pass expired.
        case signOfLife
        /// The user is back in Pofu without Pofu coming forward (the
        /// pass-expiry notification was tapped). Ends the unobserved time
        /// after a pass expired; says nothing about the automation.
        case returned
        /// Pofu came to the foreground: like `returned`, and starts A20's
        /// foreground session.
        case foregroundBegan
        /// Pofu left the foreground.
        case foregroundEnded
        /// A reach ended without opening: a skip in Hop! or on the shield,
        /// "Not now" or "I'm good, skip it" at a breath, a silent leave, an
        /// abandoned or cancelled request. Also a sign of life.
        case resisted
        /// A guarded app opened with `pass`. Also a sign of life.
        case opened(Pass)
        /// The pass ended before its expiry, in Pofu (ended early or
        /// voided): the user is demonstrably out of the guarded app.
        case passEndedEarly(passID: UUID)
        /// Screen Time put the shield back when the pass ended.
        case shieldRestored(passID: UUID)
        /// DeviceActivity measured at least `minutes` of guarded use today.
        case usageMeasured(minutes: Int)
    }

    public var at: Date
    public var kind: Kind

    public init(at: Date, kind: Kind) {
        self.at = at
        self.kind = kind
    }

    public static func signOfLife(at date: Date) -> GameEvent {
        GameEvent(at: date, kind: .signOfLife)
    }

    public static func resisted(at date: Date) -> GameEvent {
        GameEvent(at: date, kind: .resisted)
    }

    public static func opened(_ pass: Pass) -> GameEvent {
        GameEvent(at: pass.grantedAt, kind: .opened(pass))
    }
}

extension GameEvent {
    /// The game events in one entry of the gate's event log.
    ///
    /// The log alone is complete: Hop! logs every check-in it resolves, and
    /// the shield logs its skips, its other resisted reaches, and its quick
    /// checks. Feed either the log or the check-in records
    /// (`events(for:)`), not both, or reaches count twice.
    public static func events(for logged: LoggedEvent) -> [GameEvent] {
        let at = logged.at
        switch logged.event {
        case .checkInRequested, .passThrough, .shieldShown:
            return [.signOfLife(at: at)]
        case .checkInResolved(let record):
            return events(for: record)
        case .passEnded(let passID, _), .passVoided(let passID, _):
            return [GameEvent(at: at, kind: .passEndedEarly(passID: passID))]
        case .shieldResisted, .shieldReachResolved, .shieldOpenRequestCancelled:
            return [.resisted(at: at)]
        case .quickCheckStarted(let passID, let target, let until):
            let pass = Pass(id: passID, target: target, grantedAt: at, expiresAt: max(until, at), source: .free(.pause))
            return [.opened(pass)]
        case .shieldRestored(let passID):
            return [GameEvent(at: at, kind: .shieldRestored(passID: passID))]
        case .guardedUsageMeasured(let minutes):
            return [GameEvent(at: at, kind: .usageMeasured(minutes: minutes))]
        case .hopShown, .hopUnavailable, .reasonChosen, .handoffFailed, .activityCredited, .quietSeedsCollected,
            .shieldOpenRequested, .passEndedClosed, .shieldLifted:
            return []
        }
    }

    /// The game events of one check-in: the reach is a sign of life, then
    /// it was resisted or opened.
    public static func events(for record: CheckInRecord) -> [GameEvent] {
        var events: [GameEvent] = [.signOfLife(at: record.attemptedAt)]
        if let pass = record.outcome.pass {
            events.append(.opened(pass))
        } else {
            events.append(.resisted(at: record.resolvedAt))
        }
        return events
    }

    /// A pass-through: proof that the automation is alive.
    public static func event(for passThrough: PassThrough) -> GameEvent {
        .signOfLife(at: passThrough.at)
    }
}
