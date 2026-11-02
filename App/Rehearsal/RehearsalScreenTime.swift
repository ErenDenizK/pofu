import Foundation
import os
import PofuCore
import PofuPersistence
import PofuScreenTime
import UserNotifications

/// Rehearsal mode's Screen Time: the system and the three extensions,
/// simulated inside the app, in Rehearsal mode's own folder.
///
/// It mirrors the live build part for part, so everything above it runs
/// the real code paths:
///
/// - **The system.** `SimulatedScreenTimeService` stands in for
///   FamilyControls and DeviceActivity: the authorization the mocked alert
///   grants, and the usage thresholds the "+15 dk" control crosses (once
///   per threshold per day, like DeviceActivity). Shields follow
///   `LiveShieldState`, the same file and the same `effectiveShields` the
///   live build applies to ManagedSettings.
/// - **The extensions.** `ShieldExtensionCore` draws the shield and
///   answers its buttons exactly as the configuration and action
///   extensions do, writing the same records to the same kind of inbox.
///   The monitor's part (the shield returns when a pass ends, measured
///   usage) is here too.
///
/// The app ingests the inbox through `ScreenTimeIngestion` as it does live.
@MainActor
final class RehearsalScreenTime {
    /// What the simulated device remembers across launches: the
    /// authorization answer and today's simulated usage.
    private struct Device: Codable {
        var authorization: ScreenTimeAuthorizationStatus = .notDetermined
        var usage = RehearsalUsage()
    }

    let location: StorageLocation
    let clock: RehearsalClock
    let calendar: Calendar
    let core: ShieldExtensionCore
    private let system: SimulatedScreenTimeService
    private let stateFile: JSONFile<LiveShieldState>
    private let deviceFile: JSONFile<Device>
    private var device: Device
    /// Calls into the simulated system, in order.
    private var pending: Task<Void, Never>?

    init(location: StorageLocation, clock: RehearsalClock, calendar: Calendar = .autoupdatingCurrent) {
        self.location = location
        self.clock = clock
        self.calendar = calendar
        self.core = ShieldExtensionCore(location: location, calendar: calendar)
        let stateFile = LiveShieldState.file(in: location)
        let deviceFile = JSONFile<Device>(url: location.directory.appendingPathComponent("rehearsal-device.json"))
        self.stateFile = stateFile
        self.deviceFile = deviceFile
        let device = deviceFile.read() ?? Device()
        self.device = device
        let state = stateFile.read() ?? LiveShieldState()
        let system = SimulatedScreenTimeService(
            authorizationStatus: device.authorization,
            selection: state.selection,
            applicationCategories: RehearsalCatalog.applicationCategories,
            calendar: calendar
        )
        self.system = system
        // A relaunch: the simulated system schedules the thresholds again;
        // `addUsage` brings its counters back to today's usage.
        enqueue { system in
            for schedule in state.thresholds {
                try? await system.scheduleThreshold(schedule)
            }
        }
    }

    // MARK: - Authorization and selection

    var authorization: ScreenTimeAuthorizationStatus {
        device.authorization
    }

    var selection: DistractionSelection {
        loadState().selection
    }

    /// The answer to the mocked Screen Time alert. Like the system, a
    /// status other than approved removes every shield and schedule.
    func setAuthorization(_ status: ScreenTimeAuthorizationStatus) {
        device.authorization = status
        saveDevice()
        if status != .approved {
            var state = loadState()
            state.shields.removeAll()
            state.thresholds.removeAll()
            state.lifts.removeAll()
            try? saveState(state)
        }
        enqueue { system in
            await system.setAuthorizationStatus(status)
        }
        Log.screenTime.info("Rehearsal: Screen Time \(status.rawValue, privacy: .public)")
    }

    /// What the mocked picker returned.
    func updateSelection(_ selection: DistractionSelection) throws {
        try requireAuthorization()
        var state = loadState()
        state.selection = selection
        try saveState(state)
        enqueue { system in
            try? await system.updateDistractingSelection(selection)
        }
    }

    // MARK: - Reaching for an app

    /// How the system names `app` to the shield: by its own token when it
    /// was picked, by its category's when the whole category was (as the
    /// configuration extension's `shielding:in:` does); `nil` when nothing
    /// picked covers it.
    func shieldedApp(for app: ProtectedApp) -> ShieldedApp? {
        guard let entry = RehearsalCatalog.app(for: app) else { return nil }
        let picked = selection
        if picked.applications.contains(entry.token) {
            return ShieldedApp(kind: .application, token: entry.token.rawValue, bundleIdentifier: entry.bundleIdentifier, displayName: entry.name)
        }
        if picked.categories.contains(entry.category.token) {
            return ShieldedApp(kind: .category, token: entry.category.token.rawValue, bundleIdentifier: entry.bundleIdentifier, displayName: entry.name)
        }
        return nil
    }

    /// Whether the shield stands in front of `app` at `date`: the same
    /// `effectiveShields` the live build applies, so a running pass or
    /// quick check lets it through.
    func isShielded(_ app: ProtectedApp, at date: Date) -> Bool {
        guard authorization == .approved, let entry = RehearsalCatalog.app(for: app) else { return false }
        return loadState().effectiveShields(at: date).values.contains { shield in
            shield.applications.contains(entry.token)
                || (shield.categories.contains(entry.category.token) && !shield.exceptApplications.contains(entry.token))
        }
    }

    /// The lift that lets `app` through at `date`, if any.
    func activeLift(for app: ShieldedApp, at date: Date) -> ShieldLift? {
        loadState().lifts.active(at: date).last { $0.app.token == app.token }
    }

    // MARK: - The extensions

    /// The configuration extension: the shield over `app` now.
    func drawShield(for app: ShieldedApp) -> ShieldCopy {
        core.remember(app)
        return core.drawShield(for: app, at: clock.now, language: Self.language, submenuAvailable: true)
    }

    /// The action extension: what `intent` does for `app`. The
    /// notification is posted for real, as a local notification Pofu shows
    /// even while it is on screen (it stands in for the app behind the
    /// shield).
    func respond(to intent: ShieldIntent, for app: ShieldedApp, notificationsAllowed: Bool) -> ShieldExtensionCore.Outcome {
        let effects = ShieldExtensionCore.Effects(
            liftForQuickCheck: { [self] app, passID, from, until in
                try liftForQuickCheck(app, passID: passID, from: from, until: until)
            },
            postNotification: { app, breath in
                guard notificationsAllowed else { return false }
                Task {
                    await Self.postNotification(about: app, breath: breath)
                }
                return true
            },
            withdrawNotification: { Self.withdrawNotification() }
        )
        Log.screenTime.info("Rehearsal shield action: \(intent.rawValue, privacy: .public)")
        return core.respond(to: intent, for: app, at: clock.now, effects: effects)
    }

    /// The monitor extension: puts the shield back on every pass that has
    /// ended by `date` and records it, as the pass's monitor does at its
    /// end.
    ///
    /// - Returns: The lifts that ended.
    @discardableResult
    func runMonitor(at date: Date) -> [ShieldLift] {
        var state = loadState()
        let ended = state.lifts.filter { $0.until <= date }
        guard !ended.isEmpty else { return [] }
        state.pruneLifts(at: date)
        try? saveState(state)
        let inbox = ScreenTimeInbox(location: location)
        for lift in ended {
            try? inbox.post(ScreenTimeRecord(at: lift.until, kind: .shieldRestored(passID: lift.passID)))
        }
        return ended
    }

    /// The monitor extension's usage events: `minutes` more guarded use
    /// now. Each threshold the simulated DeviceActivity reports is
    /// recorded as the monitor records it.
    ///
    /// - Returns: The thresholds reached, in minutes.
    func addUsage(minutes: Int) async -> [Int] {
        let now = clock.now
        let today = LocalDay(containing: now, in: calendar)
        guard authorization == .approved, let token = Self.usageToken(for: selection) else { return [] }
        let used = device.usage.add(minutes, on: today)
        saveDevice()
        await drain()
        // DeviceActivity counts the day from its start, also for schedules
        // made later (`includesPastActivity`). The simulated system starts a
        // schedule at zero, so after a reschedule, a relaunch or a new day,
        // its counters are rebuilt from today's usage first.
        var inStep = true
        for schedule in await system.scheduledThresholds() {
            if await system.recordedUsage(for: schedule.id) != TimeInterval(used.before) * 60 {
                inStep = false
            }
        }
        if !inStep {
            await system.simulateNewDay()
            if used.before > 0 {
                await system.simulateUsage(of: token, for: TimeInterval(used.before) * 60, at: now)
            }
        }
        let before = await system.eventLog.count
        await system.simulateUsage(of: token, for: TimeInterval(minutes) * 60, at: now)
        let reached = await system.eventLog.dropFirst(before)
            .compactMap { event -> Int? in
                guard case .thresholdReached(let id) = event else { return nil }
                return GuardedUsageLadder.parseMinutes(fromThresholdName: id.rawValue)
            }
            .sorted()
        let inbox = ScreenTimeInbox(location: location)
        let context = ShieldContextStore(location: location)
        for step in reached {
            try? inbox.post(ScreenTimeRecord(at: now, kind: .usageThresholdReached(minutes: step)))
            try? context.noteMeasured(step, on: today)
        }
        Log.screenTime.info("Rehearsal: \(used.after, privacy: .public) guarded min today, thresholds \(String(describing: reached), privacy: .public)")
        return reached
    }

    /// Guarded minutes simulated today.
    var usedMinutesToday: Int {
        device.usage.minutes(on: LocalDay(containing: clock.now, in: calendar))
    }

    // MARK: - Reset

    /// A fresh device: no permission, no apps, no files.
    func reset() {
        try? FileManager.default.removeItem(at: location.directory)
        device = Device()
        enqueue { system in
            await system.setAuthorizationStatus(.notDetermined)
            await system.simulateNewDay()
        }
        Self.withdrawNotification()
    }

    // MARK: - Private

    private static var language: ShieldLanguage {
        ShieldLanguage(localization: Locale.preferredLanguages.first)
    }

    private func liftForQuickCheck(_ app: ShieldedApp, passID: UUID, from: Date, until: Date) throws {
        var state = loadState()
        state.pruneLifts(at: from)
        state.lifts.removeAll { $0.passID == passID }
        state.lifts.append(ShieldLift(passID: passID, app: app, from: from, until: until, origin: .shieldQuickCheck))
        try saveState(state)
    }

    /// Posts the "Open with Pofu" notification, marked as Rehearsal mode's.
    private nonisolated static func postNotification(about app: ShieldedApp, breath: Bool) async {
        let content = GateNotificationContent.make(about: app, breath: breath)
        content.userInfo = [rehearsalKey: true]
        let request = UNNotificationRequest(identifier: GateNotificationCopy.identifier, content: content, trigger: nil)
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            Log.screenTime.error("Rehearsal notification failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func withdrawNotification() {
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [GateNotificationCopy.identifier])
        center.removePendingNotificationRequests(withIdentifiers: [GateNotificationCopy.identifier])
    }

    /// Marks Rehearsal mode's notifications, which Pofu shows as banners
    /// although it is on screen.
    nonisolated static let rehearsalKey = "pofu.rehearsal"

    /// Whether notifications may be posted.
    nonisolated static func notificationsAllowed() async -> Bool {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: true
        default: false
        }
    }

    /// An app the selection covers, for counting usage against it.
    private static func usageToken(for selection: DistractionSelection) -> ApplicationToken? {
        if let app = selection.applications.sorted(by: { $0.rawValue < $1.rawValue }).first {
            return app
        }
        return RehearsalCatalog.apps.first { selection.categories.contains($0.category.token) }?.token
    }

    private func requireAuthorization() throws {
        guard authorization == .approved else { throw ScreenTimeError.notAuthorized }
    }

    private func loadState() -> LiveShieldState {
        stateFile.read() ?? LiveShieldState()
    }

    private func saveState(_ state: LiveShieldState) throws {
        try stateFile.write(state)
    }

    private func saveDevice() {
        do {
            try deviceFile.write(device)
        } catch {
            Log.screenTime.error("Rehearsal: saving the device failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func enqueue(_ work: @escaping @Sendable (SimulatedScreenTimeService) async -> Void) {
        let previous = pending
        let system = system
        pending = Task {
            await previous?.value
            await work(system)
        }
    }

    /// Waits for the calls already made to the simulated system.
    private func drain() async {
        await pending?.value
    }
}

// MARK: - The gate's system

extension RehearsalScreenTime: GateSystem {
    func authorizationStatus() -> ScreenTimeAuthorizationStatus {
        authorization
    }

    func distractingSelection() -> DistractionSelection {
        selection
    }

    func applyShield(_ id: ShieldID, to selection: DistractionSelection) throws {
        try requireAuthorization()
        guard !selection.isEmpty else { throw ScreenTimeError.emptySelection }
        var state = loadState()
        state.shields[id.rawValue] = selection
        try saveState(state)
    }

    func removeShield(_ id: ShieldID) {
        var state = loadState()
        state.shields[id.rawValue] = nil
        try? saveState(state)
    }

    func liftShields(from app: ShieldedApp, passID: UUID, at date: Date, until: Date) throws {
        try requireAuthorization()
        guard until > date else { throw ScreenTimeError.invalidLift }
        var state = loadState()
        state.pruneLifts(at: date)
        state.lifts.removeAll { $0.passID == passID }
        state.lifts.append(ShieldLift(passID: passID, app: app, from: date, until: until, origin: .hop))
        try saveState(state)
    }

    /// A pass ended early: its monitor is stopped, so no record, as live.
    func restoreShields(passID: UUID) {
        var state = loadState()
        guard state.lifts.contains(where: { $0.passID == passID }) else { return }
        state.endLift(passID, at: clock.now)
        try? saveState(state)
    }

    func reconcile(at date: Date) {
        guard authorization == .approved else { return }
        runMonitor(at: date)
    }

    func scheduleThreshold(_ schedule: ThresholdSchedule) throws {
        try requireAuthorization()
        guard !schedule.selection.isEmpty else { throw ScreenTimeError.emptySelection }
        guard schedule.threshold > 0, schedule.threshold.isFinite else { throw ScreenTimeError.invalidThreshold }
        var state = loadState()
        state.thresholds.removeAll { $0.id == schedule.id }
        state.thresholds.append(schedule)
        try saveState(state)
        enqueue { system in
            try? await system.scheduleThreshold(schedule)
        }
    }

    func cancelThresholds(withPrefix prefix: String) {
        var state = loadState()
        let cancelled = state.thresholds.filter { $0.id.rawValue.hasPrefix(prefix) }.map(\.id)
        state.thresholds.removeAll { $0.id.rawValue.hasPrefix(prefix) }
        try? saveState(state)
        enqueue { system in
            for id in cancelled {
                await system.cancelThreshold(id)
            }
        }
    }
}
