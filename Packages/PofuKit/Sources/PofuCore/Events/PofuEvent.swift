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
    /// The user tapped "Open with Pofu" on the Screen Time shield.
    case shieldOpenRequested(target: TargetGroupID)
    /// The shield was drawn over `target` in `scene` (gate v2).
    case shieldShown(target: TargetGroupID, scene: ShieldScene)
    /// A reach at the shield was resolved as resisted without a tap on
    /// "Skip it": `resolution` says how.
    case shieldReachResolved(target: TargetGroupID, resolution: ShieldResolution)
    /// "Just 3 minutes" on the shield lifted it until `until`.
    case quickCheckStarted(passID: UUID, target: TargetGroupID, until: Date)
    /// "Done, close it" on the shield that returned at a pass's end.
    case passEndedClosed(target: TargetGroupID)
    /// The user tapped "Skip it" on the shield waiting for the
    /// notification tap.
    case shieldOpenRequestCancelled(target: TargetGroupID)
    /// A pass lifted the shield from `target` until the pass ends.
    case shieldLifted(passID: UUID, target: TargetGroupID)
    /// The shield came back after the pass `passID`.
    case shieldRestored(passID: UUID)
    /// DeviceActivity measured at least `minutes` of guarded use today.
    case guardedUsageMeasured(minutes: Int)
}

/// Where an event came from: the real gate, or Rehearsal mode, which
/// simulates the Screen Time system inside the app (free build).
///
/// Simulated events are kept apart from live ones twice over: Rehearsal
/// mode writes to its own store, and every event it logs carries
/// `.simulated`, so no readout can count one as real.
public enum EventSource: String, Hashable, Sendable, Codable, CaseIterable {
    case live
    case simulated
}

/// Which events a readout shows, by `EventSource`.
public enum EventSourceFilter: String, Hashable, Sendable, CaseIterable {
    case all
    case live
    case simulated

    public func includes(_ source: EventSource) -> Bool {
        switch self {
        case .all: true
        case .live: source == .live
        case .simulated: source == .simulated
        }
    }
}

/// One entry of the event log.
public struct LoggedEvent: Hashable, Sendable, Identifiable {
    public let id: UUID
    public let at: Date
    public let event: PofuEvent
    /// `.live` unless Rehearsal mode logged it.
    public let source: EventSource

    public init(id: UUID = UUID(), at: Date, event: PofuEvent, source: EventSource = .live) {
        self.id = id
        self.at = at
        self.event = event
        self.source = source
    }

    /// The same entry, from `source`.
    public func tagged(_ source: EventSource) -> LoggedEvent {
        LoggedEvent(id: id, at: at, event: event, source: source)
    }
}

extension LoggedEvent: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, at, event, source
    }

    /// Lines written before sources existed are live.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            at: try container.decode(Date.self, forKey: .at),
            event: try container.decode(PofuEvent.self, forKey: .event),
            source: try container.decodeIfPresent(EventSource.self, forKey: .source) ?? .live
        )
    }

    /// Live entries are written exactly as before; only simulated ones
    /// carry the tag.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(at, forKey: .at)
        try container.encode(event, forKey: .event)
        if source != .live {
            try container.encode(source, forKey: .source)
        }
    }
}

extension Sequence where Element == LoggedEvent {
    /// The entries `filter` lets through, in order.
    public func filtered(by filter: EventSourceFilter) -> [LoggedEvent] {
        self.filter { filter.includes($0.source) }
    }
}
