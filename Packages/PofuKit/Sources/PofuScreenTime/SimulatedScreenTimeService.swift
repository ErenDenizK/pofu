import Foundation
import PofuCore

/// A deterministic, scriptable stand-in for Screen Time.
///
/// It behaves like the real frameworks where it matters (authorization
/// gates every operation, named shields are independent, thresholds fire
/// once per day) and lets tests and the development build drive what the
/// system would otherwise do: usage, app opens, new days, and authorization
/// changes. Every emitted event is also kept in `eventLog`.
public actor SimulatedScreenTimeService: ScreenTimeService {
    private var status: ScreenTimeAuthorizationStatus
    private let authorizationResponse: ScreenTimeAuthorizationStatus
    private var selection: DistractionSelection
    private let applicationCategories: [ApplicationToken: CategoryToken]
    private let calendar: Calendar
    private var shields: [ShieldID: DistractionSelection] = [:]
    private var schedules: [ThresholdID: ThresholdSchedule] = [:]
    private var usage: [ThresholdID: TimeInterval] = [:]
    private var reached: Set<ThresholdID> = []
    private var continuations: [Int: AsyncStream<ScreenTimeEvent>.Continuation] = [:]
    private var nextContinuationID = 0

    /// Every event emitted so far, in order.
    public private(set) var eventLog: [ScreenTimeEvent] = []

    /// - Parameters:
    ///   - authorizationStatus: The status before any request.
    ///   - authorizationResponse: What the simulated user answers when
    ///     `requestAuthorization()` asks.
    ///   - selection: The initial distracting selection.
    ///   - applicationCategories: Which category each app belongs to, so
    ///     category selections can match apps.
    ///   - calendar: Defines local time for threshold windows.
    public init(
        authorizationStatus: ScreenTimeAuthorizationStatus = .notDetermined,
        authorizationResponse: ScreenTimeAuthorizationStatus = .approved,
        selection: DistractionSelection = .empty,
        applicationCategories: [ApplicationToken: CategoryToken] = [:],
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.status = authorizationStatus
        self.authorizationResponse = authorizationResponse
        self.selection = selection
        self.applicationCategories = applicationCategories
        self.calendar = calendar
    }

    // MARK: - ScreenTimeService

    public func authorizationStatus() -> ScreenTimeAuthorizationStatus {
        status
    }

    public func requestAuthorization() -> ScreenTimeAuthorizationStatus {
        // Like the system, ask only once; later requests return the answer.
        if status == .notDetermined {
            setAuthorizationStatus(authorizationResponse)
        }
        return status
    }

    public func distractingSelection() -> DistractionSelection {
        selection
    }

    public func updateDistractingSelection(_ selection: DistractionSelection) throws {
        try requireAuthorization()
        self.selection = selection
    }

    public func applyShield(_ id: ShieldID, to selection: DistractionSelection) throws {
        try requireAuthorization()
        guard !selection.isEmpty else { throw ScreenTimeError.emptySelection }
        shields[id] = selection
    }

    public func removeShield(_ id: ShieldID) {
        shields[id] = nil
    }

    public func activeShields() -> [ShieldID: DistractionSelection] {
        shields
    }

    public func scheduleThreshold(_ schedule: ThresholdSchedule) throws {
        try requireAuthorization()
        guard !schedule.selection.isEmpty else { throw ScreenTimeError.emptySelection }
        guard schedule.threshold > 0, schedule.threshold.isFinite else {
            throw ScreenTimeError.invalidThreshold
        }
        schedules[schedule.id] = schedule
        usage[schedule.id] = 0
        reached.remove(schedule.id)
    }

    public func cancelThreshold(_ id: ThresholdID) {
        schedules[id] = nil
        usage[id] = nil
        reached.remove(id)
    }

    public func scheduledThresholds() -> [ThresholdSchedule] {
        schedules.values.sorted { $0.id.rawValue < $1.id.rawValue }
    }

    public func events() -> AsyncStream<ScreenTimeEvent> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: ScreenTimeEvent.self,
            bufferingPolicy: .unbounded
        )
        continuations[nextContinuationID] = continuation
        nextContinuationID += 1
        return stream
    }

    // MARK: - Scripting

    /// Changes authorization as if the user toggled it in Settings.
    /// Revoking access removes every shield and schedule, as the system does.
    public func setAuthorizationStatus(_ newStatus: ScreenTimeAuthorizationStatus) {
        guard newStatus != status else { return }
        status = newStatus
        if newStatus != .approved {
            shields.removeAll()
            schedules.removeAll()
            usage.removeAll()
            reached.removeAll()
        }
        emit(.authorizationChanged(newStatus))
    }

    /// Simulates `duration` seconds of use of `application` at `date`.
    /// Fires `thresholdReached` for every schedule whose threshold this use
    /// crosses, once per day.
    public func simulateUsage(of application: ApplicationToken, for duration: TimeInterval, at date: Date) {
        guard duration > 0, duration.isFinite else { return }
        let category = applicationCategories[application]
        for schedule in scheduledThresholds() {
            guard
                schedule.selection.covers(application, category: category),
                schedule.window.map({ $0.contains(date, in: calendar) }) ?? true
            else {
                continue
            }
            let total = usage[schedule.id, default: 0] + duration
            usage[schedule.id] = total
            if total >= schedule.threshold, !reached.contains(schedule.id) {
                reached.insert(schedule.id)
                emit(.thresholdReached(schedule.id))
            }
        }
    }

    /// Simulates the user tapping `application`. When a shield covers it,
    /// emits `shieldShown` and returns the shield's name; otherwise the app
    /// opens and this returns `nil`. With several shields, the first by
    /// name wins, so results are deterministic.
    @discardableResult
    public func simulateOpen(of application: ApplicationToken) -> ShieldID? {
        let category = applicationCategories[application]
        let blocking = shields
            .filter { $0.value.covers(application, category: category) }
            .map(\.key)
            .min { $0.rawValue < $1.rawValue }
        if let blocking {
            emit(.shieldShown(blocking, application: application))
        }
        return blocking
    }

    /// Starts a new monitoring day: usage counters reset and thresholds can
    /// fire again.
    public func simulateNewDay() {
        for id in schedules.keys {
            usage[id] = 0
        }
        reached.removeAll()
    }

    /// Usage counted toward the schedule `id` today, in seconds.
    public func recordedUsage(for id: ThresholdID) -> TimeInterval {
        usage[id, default: 0]
    }

    /// Ends every event stream, so consumers' loops finish.
    public func finishEvents() {
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll()
    }

    // MARK: - Private

    private func requireAuthorization() throws {
        guard status == .approved else { throw ScreenTimeError.notAuthorized }
    }

    private func emit(_ event: ScreenTimeEvent) {
        eventLog.append(event)
        for (id, continuation) in continuations {
            if case .terminated = continuation.yield(event) {
                continuations[id] = nil
            }
        }
    }
}
