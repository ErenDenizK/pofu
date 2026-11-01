import Foundation

/// What the app has learned from the Screen Time extensions: measured
/// guarded time, a pending "Talk to Pofu", and which records it has already
/// taken in. Owned and persisted by the app; the extensions never read it.
public struct ScreenTimeLedger: Hashable, Sendable, Codable {
    /// A "Talk to Pofu" waiting for the user to come to Pofu.
    public struct OpenRequest: Hashable, Sendable, Codable {
        public var app: ShieldedApp
        public var requestedAt: Date

        public init(app: ShieldedApp, requestedAt: Date) {
            self.app = app
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
    /// The newest "Talk to Pofu" not yet answered by Hop!.
    public private(set) var openRequest: OpenRequest?

    public init(ingestedIDs: [UUID] = [], usage: GuardedUsageDay? = nil, openRequest: OpenRequest? = nil) {
        self.ingestedIDs = ingestedIDs
        self.usage = usage
        self.openRequest = openRequest
    }

    /// Guarded minutes measured on `day`; zero when nothing was measured
    /// that day.
    public func measuredMinutes(on day: LocalDay) -> Int {
        usage.flatMap { $0.day == day ? $0.measuredMinutes : nil } ?? 0
    }

    /// Whether the record `id` was already taken in.
    public func hasIngested(_ id: UUID) -> Bool {
        ingestedIDs.contains(id)
    }

    /// Takes the open request if it is still fresh at `date`, and clears it
    /// either way: a "Talk to Pofu" from long ago is not what the user
    /// wants when they open Pofu now.
    public mutating func takeOpenRequest(at date: Date, maximumAge: TimeInterval) -> OpenRequest? {
        defer { openRequest = nil }
        guard let request = openRequest else { return nil }
        let age = date.timeIntervalSince(request.requestedAt)
        return age >= 0 && age <= maximumAge ? request : nil
    }

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
}

/// Turns extension records into app state: shield skips become resisted
/// check-ins (the north-star metric counts them), threshold events become
/// measured guarded time, and "Talk to Pofu" becomes a pending request.
public struct ScreenTimeIngestion: Sendable {
    /// Defines the local day a measurement belongs to.
    public let calendar: Calendar

    public init(calendar: Calendar) {
        self.calendar = calendar
    }

    /// Ingests `records` in the order they happened, skipping any already
    /// taken in.
    ///
    /// - Returns: The events to append to the event log, with their times.
    @discardableResult
    public func ingest(
        _ records: [ScreenTimeRecord],
        into ledger: inout ScreenTimeLedger,
        checkIns: inout [CheckInRecord]
    ) -> [LoggedEvent] {
        var events: [LoggedEvent] = []
        let ordered = records.sorted { ($0.at, $0.id.uuidString) < ($1.at, $1.id.uuidString) }
        for record in ordered where !ledger.hasIngested(record.id) {
            ledger.remember(record.id)
            switch record.kind {
            case .shieldResisted(let app):
                checkIns.append(
                    CheckInRecord(
                        id: record.id,
                        target: app.target,
                        attemptedAt: record.at,
                        resolvedAt: record.at,
                        rung: .pause,
                        outcome: .resisted,
                        channel: .shield
                    )
                )
                events.append(LoggedEvent(id: record.id, at: record.at, event: .shieldResisted(target: app.target)))

            case .openRequested(let app):
                ledger.request(app, at: record.at)
                events.append(LoggedEvent(id: record.id, at: record.at, event: .shieldOpenRequested(target: app.target)))

            case .usageThresholdReached(let minutes):
                guard minutes > 0 else { continue }
                ledger.measure(minutes, on: LocalDay(containing: record.at, in: calendar))
                events.append(LoggedEvent(id: record.id, at: record.at, event: .guardedUsageMeasured(minutes: minutes)))

            case .shieldRestored(let passID):
                events.append(LoggedEvent(id: record.id, at: record.at, event: .shieldRestored(passID: passID)))
            }
        }
        return events
    }
}
