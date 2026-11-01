import Foundation

/// Something that happened, appended to the event log (ADR-0003).
///
/// The log is append-only and never read back to rebuild state: the
/// snapshot is the source of truth. It exists for honest history (the
/// recap, "why did Pofu do that?"), for debugging the soft gate on a real
/// device, and as the channel future extensions will write to.
public enum PofuEvent: Hashable, Sendable, Codable {
    /// The automation ran `CheckInIntent` for `app`.
    case checkInRequested(app: ProtectedApp, foreground: Bool)
    /// A valid pass covered the open; Pofu stayed in the background.
    case passThrough(app: ProtectedApp, passID: UUID)
    /// Hop! appeared on `rung`.
    case hopShown(attemptID: UUID, app: ProtectedApp, rung: FrictionRung)
    /// Hop! was needed but the system did not let Pofu come forward.
    case hopUnavailable(app: ProtectedApp)
    /// The user picked a reason on the `intent` rung.
    case reasonChosen(attemptID: UUID, reason: IntentReason)
    /// A check-in ended.
    case checkInResolved(CheckInRecord)
    /// The user ended a pass early from Pofu.
    case passEnded(passID: UUID, refund: Energy)
    /// A pass was voided because its app could not be opened.
    case passVoided(passID: UUID, refund: Energy)
    /// Pofu could not open `app` after granting a pass.
    case handoffFailed(app: ProtectedApp)
    /// An activity was credited.
    case activityCredited(ActivitySession, earned: Energy, forfeited: Energy)
    /// The user collected the seeds quiet time put in Pofu's cheeks
    /// (ADR-0014).
    case quietSeedsCollected(quietSeeds: Energy, sleepBonus: Energy)
    /// The user tapped "Skip it" on the Screen Time shield.
    case shieldResisted(target: TargetGroupID)
    /// The user tapped "Talk to Pofu" on the Screen Time shield.
    case shieldOpenRequested(target: TargetGroupID)
    /// A pass lifted the shield from `target` until the pass ends.
    case shieldLifted(passID: UUID, target: TargetGroupID)
    /// The shield came back after the pass `passID`.
    case shieldRestored(passID: UUID)
    /// DeviceActivity measured at least `minutes` of guarded use today.
    case guardedUsageMeasured(minutes: Int)
}

/// One entry of the event log.
public struct LoggedEvent: Hashable, Sendable, Codable, Identifiable {
    public let id: UUID
    public let at: Date
    public let event: PofuEvent

    public init(id: UUID = UUID(), at: Date, event: PofuEvent) {
        self.id = id
        self.at = at
        self.event = event
    }
}
