import Foundation

/// What the app has learned from the Screen Time extensions: measured
/// guarded time, reaches at the shield not yet resolved, a pending "Open
/// with Pofu", and which records it has already taken in. Owned and
/// persisted by the app; the extensions never read it.
public struct ScreenTimeLedger: Hashable, Sendable {
    /// An "Open with Pofu" waiting for the user to come to Pofu.
    public struct OpenRequest: Hashable, Sendable, Codable {
        public var app: ShieldedApp
        public var requestedAt: Date

        public init(app: ShieldedApp, requestedAt: Date) {
            self.app = app
            self.requestedAt = requestedAt
        }
    }

    /// A shield the user saw, waiting for what they do next: a tap, a
    /// request, a quick check, or nothing (a silent leave).
    public struct PendingReach: Hashable, Sendable, Codable, Identifiable {
        /// The id of the `shieldShown` record (or of the action record
        /// when no shown record arrived); becomes the check-in's id.
        public var id: UUID
        public var app: ShieldedApp
        public var shownAt: Date
        /// When the user asked to open with Pofu from this shield.
        public var requestedAt: Date?

        public init(id: UUID, app: ShieldedApp, shownAt: Date, requestedAt: Date? = nil) {
            self.id = id
            self.app = app
            self.shownAt = shownAt
            self.requestedAt = requestedAt
        }
    }

    /// How many ingested record ids are remembered, to drop duplicates if
    /// the app stops between ingesting a record and deleting its file.
    public static let rememberedRecordCount = 256

    /// Record ids already ingested, oldest first.
    public private(set) var ingestedIDs: [UUID]
    /// The latest measured guarded time.
    public private(set) var usage: GuardedUsageDay?
    /// The newest "Open with Pofu" not yet answered by Hop!.
    public private(set) var openRequest: OpenRequest?
    /// Reaches at the shield not yet resolved, oldest first.
    public private(set) var pendingReaches: [PendingReach]
    /// Opens past the daily hour today, which make the breath longer.
    public private(set) var overLimitOpens: DayCount?

    public init(
        ingestedIDs: [UUID] = [],
        usage: GuardedUsageDay? = nil,
        openRequest: OpenRequest? = nil,
        pendingReaches: [PendingReach] = [],
        overLimitOpens: DayCount? = nil
    ) {
        self.ingestedIDs = ingestedIDs
        self.usage = usage
        self.openRequest = openRequest
        self.pendingReaches = pendingReaches
        self.overLimitOpens = overLimitOpens
    }

    /// Guarded minutes measured on `day`; zero when nothing was measured
    /// that day.
    public func measuredMinutes(on day: LocalDay) -> Int {
        usage.flatMap { $0.day == day ? $0.measuredMinutes : nil } ?? 0
    }

    /// Opens past the daily hour on `day` so far.
    public func overLimitOpens(on day: LocalDay) -> Int {
        overLimitOpens.flatMap { $0.day == day ? $0.count : nil } ?? 0
    }

    /// Counts one more open past the daily hour on `day`.
    ///
    /// - Returns: Its ordinal among the day's over-limit opens, from 1.
    @discardableResult
    public mutating func noteOverLimitOpen(on day: LocalDay) -> Int {
        let count = overLimitOpens(on: day) + 1
        overLimitOpens = DayCount(day: day, count: count)
        return count
    }

    /// Whether the record `id` was already taken in.
    public func hasIngested(_ id: UUID) -> Bool {
        ingestedIDs.contains(id)
    }

    /// Reaches at the shield on `day` still waiting to be resolved.
    public func pendingReaches(on day: LocalDay, calendar: Calendar) -> [PendingReach] {
        pendingReaches.filter { LocalDay(containing: $0.shownAt, in: calendar) == day }
    }

    /// Takes the open request if it is still fresh at `date`. A fresh
    /// request is answered by Hop!, which counts the reach itself, so the
    /// shield's pending reach for it goes too.
    ///
    /// A request that is too old stays for `ScreenTimeIngestion.settle`,
    /// which counts it as abandoned: a "Pofu'yla aç" from long ago is not
    /// what the user wants when they open Pofu now.
    public mutating func takeOpenRequest(at date: Date, maximumAge: TimeInterval) -> OpenRequest? {
        guard let request = openRequest else { return nil }
        let age = date.timeIntervalSince(request.requestedAt)
        guard age >= 0, age <= maximumAge else { return nil }
        openRequest = nil
        if let index = pendingReaches.lastIndex(where: { $0.requestedAt != nil && $0.app.target == request.app.target }) {
            pendingReaches.remove(at: index)
        }
        return request
    }

    // MARK: - Internal (ingestion)

    mutating func remember(_ id: UUID) {
        ingestedIDs.append(id)
        if ingestedIDs.count > Self.rememberedRecordCount {
            ingestedIDs.removeFirst(ingestedIDs.count - Self.rememberedRecordCount)
        }
    }

    mutating func measure(_ minutes: Int, on day: LocalDay) {
        if let usage, usage.day > day {
            return
        }
        if let usage, usage.day == day {
            self.usage = GuardedUsageDay(day: day, measuredMinutes: max(usage.measuredMinutes, minutes))
        } else {
            self.usage = GuardedUsageDay(day: day, measuredMinutes: minutes)
        }
    }

    mutating func request(_ app: ShieldedApp, at date: Date) {
        if let current = openRequest, current.requestedAt > date {
            return
        }
        openRequest = OpenRequest(app: app, requestedAt: date)
    }

    mutating func clearOpenRequest(for target: TargetGroupID) {
        if openRequest?.app.target == target {
            openRequest = nil
        }
    }

    mutating func clearOpenRequest() {
        openRequest = nil
    }

    mutating func addPending(_ reach: PendingReach) {
        pendingReaches.append(reach)
        pendingReaches.sort { $0.shownAt < $1.shownAt }
    }

    /// The newest pending reach for `target` shown by `date` (with a
    /// second of slack for clocks), with or without a request.
    func pendingIndex(for target: TargetGroupID, by date: Date, requested: Bool) -> Int? {
        pendingReaches.lastIndex { reach in
            reach.app.target == target
                && reach.shownAt <= date.addingTimeInterval(1)
                && (reach.requestedAt != nil) == requested
        }
    }

    mutating func markRequested(at index: Int, on date: Date) {
        pendingReaches[index].requestedAt = date
    }

    mutating func removePending(at index: Int) -> PendingReach {
        pendingReaches.remove(at: index)
    }
}

/// A count that belongs to one local day.
public struct DayCount: Hashable, Sendable, Codable {
    public var day: LocalDay
    public var count: Int

    public init(day: LocalDay, count: Int) {
        self.day = day
        self.count = count
    }
}

extension ScreenTimeLedger: Codable {
    private enum CodingKeys: String, CodingKey {
        case ingestedIDs, usage, openRequest, pendingReaches, overLimitOpens
    }

    /// Fields added by gate v2 are optional, so a ledger from before loads.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            ingestedIDs: try container.decodeIfPresent([UUID].self, forKey: .ingestedIDs) ?? [],
            usage: try container.decodeIfPresent(GuardedUsageDay.self, forKey: .usage),
            openRequest: try container.decodeIfPresent(OpenRequest.self, forKey: .openRequest),
            pendingReaches: try container.decodeIfPresent([PendingReach].self, forKey: .pendingReaches) ?? [],
            overLimitOpens: try container.decodeIfPresent(DayCount.self, forKey: .overLimitOpens)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ingestedIDs, forKey: .ingestedIDs)
        try container.encodeIfPresent(usage, forKey: .usage)
        try container.encodeIfPresent(openRequest, forKey: .openRequest)
        try container.encode(pendingReaches, forKey: .pendingReaches)
        try container.encodeIfPresent(overLimitOpens, forKey: .overLimitOpens)
    }
}

/// Turns extension records into app state (gate v2, section 12).
///
/// Every reach at the shield becomes exactly one check-in with
/// `channel: .shield`, so the north-star metric counts it once:
///
/// - **Reach:** a `shieldShown` in a scene that counts, deduplicated (the
///   same app within `reachDeduplicationWindow`) and dropped when Hop!
///   met the same open (a soft-gate check-in within
///   `softGateOverlapWindow`).
/// - **Resisted:** "Skip it" on the shield; a **silent leave** (shown,
///   nothing else for `silentLeaveDelay`); an **abandoned request** (no
///   Hop! within `openRequestLifetime`); "Skip it" while waiting for the
///   notification tap. Each is tagged with its `ShieldResolution`.
/// - **Opened:** a quick check from the shield (a pass) or Hop! (which
///   records its own check-in, so the shield's reach is dropped when Hop!
///   takes the request).
/// - **Not a reach:** the shield that returns when a pass ends, and its
///   "Done, close it".
public struct ScreenTimeIngestion: Sendable {
    /// Defines the local day a measurement belongs to.
    public let calendar: Calendar
    public let rules: ScreenTimeGateRules

    public init(calendar: Calendar, rules: ScreenTimeGateRules = .standard) {
        self.calendar = calendar
        self.rules = rules
    }

    /// Ingests `records` in the order they happened, skipping any already
    /// taken in, then settles what `now` resolves (`settle`).
    ///
    /// - Parameter passes: Receives the passes of quick checks started on
    ///   the shield, so the soft gate honours them too.
    /// - Returns: The events to append to the event log, with their times.
    @discardableResult
    public func ingest(
        _ records: [ScreenTimeRecord],
        at now: Date,
        into ledger: inout ScreenTimeLedger,
        checkIns: inout [CheckInRecord],
        passes: inout PassLedger
    ) -> [LoggedEvent] {
        var events: [LoggedEvent] = []
        let ordered = records.sorted { ($0.at, $0.id.uuidString) < ($1.at, $1.id.uuidString) }
        for record in ordered where !ledger.hasIngested(record.id) {
            ledger.remember(record.id)
            events += take(record, into: &ledger, checkIns: &checkIns, passes: &passes)
        }
        events += settle(at: now, ledger: &ledger, checkIns: &checkIns)
        return events
    }

    /// Resolves what time alone decides at `now`: requests older than
    /// their lifetime are abandoned, and shields left without a tap for
    /// `silentLeaveDelay` are silent leaves. Both count as resisted.
    @discardableResult
    public func settle(
        at now: Date,
        ledger: inout ScreenTimeLedger,
        checkIns: inout [CheckInRecord]
    ) -> [LoggedEvent] {
        var events: [LoggedEvent] = []
        if let request = ledger.openRequest, now.timeIntervalSince(request.requestedAt) > rules.openRequestLifetime {
            ledger.clearOpenRequest()
        }
        var index = 0
        while index < ledger.pendingReaches.count {
            let reach = ledger.pendingReaches[index]
            if metBySoftGate(reach, checkIns: checkIns) {
                // Hop! met the same open after the shield was ingested.
                _ = ledger.removePending(at: index)
                continue
            }
            let resolution: ShieldResolution?
            if let requestedAt = reach.requestedAt {
                let stillWaiting = ledger.openRequest.map { $0.app.target == reach.app.target && $0.requestedAt == requestedAt } ?? false
                resolution = !stillWaiting && now.timeIntervalSince(requestedAt) > rules.openRequestLifetime ? .abandonedRequest : nil
            } else {
                resolution = now.timeIntervalSince(reach.shownAt) >= rules.silentLeaveDelay ? .silentLeave : nil
            }
            guard let resolution else {
                index += 1
                continue
            }
            let resolved = ledger.removePending(at: index)
            let at = reach.requestedAt.map { $0.addingTimeInterval(rules.openRequestLifetime) }
                ?? reach.shownAt.addingTimeInterval(rules.silentLeaveDelay)
            checkIns.append(resisted(resolved, at: at, as: resolution))
            events.append(LoggedEvent(at: at, event: .shieldReachResolved(target: resolved.app.target, resolution: resolution)))
        }
        return events
    }

    // MARK: - One record

    private func take(
        _ record: ScreenTimeRecord,
        into ledger: inout ScreenTimeLedger,
        checkIns: inout [CheckInRecord],
        passes: inout PassLedger
    ) -> [LoggedEvent] {
        var events: [LoggedEvent] = []
        func log(_ event: PofuEvent) {
            events.append(LoggedEvent(id: record.id, at: record.at, event: event))
        }
        switch record.kind {
        case .shieldShown(let app, let scene):
            log(.shieldShown(target: app.target, scene: scene))
            guard scene.countsAsReach, !isDuplicateReach(app, at: record.at, ledger: ledger, checkIns: checkIns) else { break }
            ledger.addPending(ScreenTimeLedger.PendingReach(id: record.id, app: app, shownAt: record.at))

        case .shieldResisted(let app):
            let reach = ledger.pendingIndex(for: app.target, by: record.at, requested: false).map { ledger.removePending(at: $0) }
                ?? ScreenTimeLedger.PendingReach(id: record.id, app: app, shownAt: record.at)
            checkIns.append(resisted(reach, at: record.at, as: .skipped))
            log(.shieldResisted(target: app.target))

        case .openRequested(let app):
            ledger.request(app, at: record.at)
            if let index = ledger.pendingIndex(for: app.target, by: record.at, requested: false) {
                ledger.markRequested(at: index, on: record.at)
            } else if ledger.pendingIndex(for: app.target, by: record.at, requested: true) == nil {
                // No shown record arrived (or it was a redraw): the request
                // is the reach.
                ledger.addPending(ScreenTimeLedger.PendingReach(id: record.id, app: app, shownAt: record.at, requestedAt: record.at))
            }
            log(.shieldOpenRequested(target: app.target))

        case .openRequestCancelled(let app):
            ledger.clearOpenRequest(for: app.target)
            let reach = ledger.pendingIndex(for: app.target, by: record.at, requested: true).map { ledger.removePending(at: $0) }
                ?? ScreenTimeLedger.PendingReach(id: record.id, app: app, shownAt: record.at)
            checkIns.append(resisted(reach, at: record.at, as: .requestCancelled))
            log(.shieldOpenRequestCancelled(target: app.target))

        case .quickCheckStarted(let app, let passID, let until):
            let reach = ledger.pendingIndex(for: app.target, by: record.at, requested: false).map { ledger.removePending(at: $0) }
                ?? ScreenTimeLedger.PendingReach(id: record.id, app: app, shownAt: record.at)
            let pass = Pass(id: passID, target: app.target, grantedAt: record.at, expiresAt: max(until, record.at), source: .free(.pause))
            if until > record.at {
                passes.grant(pass)
            }
            checkIns.append(
                CheckInRecord(
                    id: reach.id,
                    target: app.target,
                    attemptedAt: reach.shownAt,
                    resolvedAt: record.at,
                    rung: .pause,
                    outcome: .proceeded(pass),
                    channel: .shield,
                    shieldResolution: .quickCheck
                )
            )
            log(.quickCheckStarted(passID: passID, target: app.target, until: until))

        case .passEndedClosed(let app):
            log(.passEndedClosed(target: app.target))

        case .usageThresholdReached(let minutes):
            guard minutes > 0 else { break }
            ledger.measure(minutes, on: LocalDay(containing: record.at, in: calendar))
            log(.guardedUsageMeasured(minutes: minutes))

        case .shieldRestored(let passID):
            log(.shieldRestored(passID: passID))
        }
        return events
    }

    /// Whether a shield for `app` at `date` is a reach already counted: a
    /// redraw of a recent shield, or the same open Hop! met.
    private func isDuplicateReach(_ app: ShieldedApp, at date: Date, ledger: ScreenTimeLedger, checkIns: [CheckInRecord]) -> Bool {
        let target = app.target
        let window = rules.reachDeduplicationWindow
        if ledger.pendingReaches.contains(where: { $0.app.target == target && abs(date.timeIntervalSince($0.shownAt)) < window }) {
            return true
        }
        return checkIns.reversed().prefix(64).contains { record in
            guard record.target == target else { return false }
            let distance = abs(date.timeIntervalSince(record.attemptedAt))
            switch record.resolvedChannel {
            case .shield: return distance < window
            case .softGate: return distance <= rules.softGateOverlapWindow
            }
        }
    }

    /// Whether Hop! (the soft gate) recorded the same open as `reach`.
    private func metBySoftGate(_ reach: ScreenTimeLedger.PendingReach, checkIns: [CheckInRecord]) -> Bool {
        checkIns.reversed().prefix(64).contains { record in
            record.target == reach.app.target
                && record.resolvedChannel == .softGate
                && abs(reach.shownAt.timeIntervalSince(record.attemptedAt)) <= rules.softGateOverlapWindow
        }
    }

    private func resisted(_ reach: ScreenTimeLedger.PendingReach, at date: Date, as resolution: ShieldResolution) -> CheckInRecord {
        CheckInRecord(
            id: reach.id,
            target: reach.app.target,
            attemptedAt: reach.shownAt,
            resolvedAt: max(date, reach.shownAt),
            rung: .pause,
            outcome: .resisted,
            channel: .shield,
            shieldResolution: resolution
        )
    }
}
