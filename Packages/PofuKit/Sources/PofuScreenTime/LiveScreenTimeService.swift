#if os(iOS) && canImport(FamilyControls) && canImport(ManagedSettings) && canImport(DeviceActivity)
import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import os
import PofuCore
import PofuPersistence

/// Screen Time for real: FamilyControls for authorization and the picked
/// selection, ManagedSettings for shields, DeviceActivity for usage
/// thresholds and for putting shields back when a pass ends (ADR-0003,
/// ADR-0013).
///
/// It runs only in the `PofuLive` build, which carries the Family Controls
/// entitlement and needs the paid membership. Everything it sets up is also
/// written to the App Group (`LiveShieldState`), so the monitor extension
/// can rebuild the shields without the app.
///
/// System tokens are opaque and Codable; Pofu stores them as base64 JSON
/// strings in its own token types (`ScreenTimeTokenCoding`).
@MainActor
public final class LiveScreenTimeService: ScreenTimeService {
    private static let log = Logger(subsystem: "com.erendenizk.pofu", category: "screentime")

    private let stateFile: JSONFile<LiveShieldState>
    private let calendar: Calendar
    private var continuations: [UUID: AsyncStream<ScreenTimeEvent>.Continuation] = [:]
    private var lastStatus: ScreenTimeAuthorizationStatus?

    /// - Parameters:
    ///   - location: Where the shared state lives: the App Group container,
    ///     so the extensions see it.
    ///   - calendar: Defines local time for schedules.
    public init(location: StorageLocation, calendar: Calendar = .autoupdatingCurrent) {
        self.stateFile = LiveShieldState.file(in: location)
        self.calendar = calendar
    }

    // MARK: - Authorization

    public func authorizationStatus() -> ScreenTimeAuthorizationStatus {
        let status = Self.status(of: AuthorizationCenter.shared.authorizationStatus)
        noteStatus(status)
        return status
    }

    public func requestAuthorization() async throws -> ScreenTimeAuthorizationStatus {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch let error as FamilyControlsError {
            Self.log.error("Authorization request failed: \(String(describing: error), privacy: .public)")
            if case .authorizationCanceled = error {
                noteStatus(.denied)
                return .denied
            }
            let status = authorizationStatus()
            guard status != .notDetermined else { throw ScreenTimeError.unavailable }
            return status
        } catch {
            Self.log.error("Authorization request failed: \(error.localizedDescription, privacy: .public)")
            let status = authorizationStatus()
            guard status != .notDetermined else { throw ScreenTimeError.unavailable }
            return status
        }
        return authorizationStatus()
    }

    // MARK: - Selection

    public func distractingSelection() -> DistractionSelection {
        loadState().selection
    }

    public func updateDistractingSelection(_ selection: DistractionSelection) throws {
        try requireAuthorization()
        var state = loadState()
        state.selection = selection
        try save(state)
    }

    /// Stores what the user picked in `FamilyActivityPicker`, keeping the
    /// picker's own encoding so it can show the same choice again.
    ///
    /// - Returns: The selection as Pofu's tokens.
    @discardableResult
    public func updatePickedSelection(_ picked: FamilyActivitySelection) throws -> DistractionSelection {
        try requireAuthorization()
        var state = loadState()
        state.selection = ScreenTimeTokenCoding.selection(from: picked)
        state.pickerData = try? JSONEncoder().encode(picked)
        try save(state)
        return state.selection
    }

    /// The selection as the picker last saved it; empty when there is none.
    public func pickedSelection() -> FamilyActivitySelection {
        guard
            let data = loadState().pickerData,
            let picked = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            return FamilyActivitySelection()
        }
        return picked
    }

    // MARK: - Shields

    public func applyShield(_ id: ShieldID, to selection: DistractionSelection) throws {
        try requireAuthorization()
        guard !selection.isEmpty else { throw ScreenTimeError.emptySelection }
        var state = loadState()
        state.shields[id.rawValue] = selection
        try save(state)
        LiveShieldEnforcer.apply(state, at: Date())
    }

    public func removeShield(_ id: ShieldID) {
        var state = loadState()
        state.shields[id.rawValue] = nil
        try? save(state)
        LiveShieldEnforcer.clear(id)
    }

    public func activeShields() -> [ShieldID: DistractionSelection] {
        var shields: [ShieldID: DistractionSelection] = [:]
        for (name, selection) in loadState().shields {
            shields[ShieldID(rawValue: name)] = selection
        }
        return shields
    }

    // MARK: - Passes

    public func liftShields(from app: ShieldedApp, passID: UUID, at date: Date, until: Date) throws {
        try requireAuthorization()
        guard until > date else { throw ScreenTimeError.invalidLift }
        var state = loadState()
        state.pruneLifts(at: date)
        state.lifts.removeAll { $0.passID == passID }
        state.lifts.append(ShieldLift(passID: passID, app: app, from: date, until: until))
        try save(state)
        LiveShieldEnforcer.apply(state, at: date)
        scheduleRestore(passID: passID, liftingAt: date, until: until)
    }

    public func restoreShields(passID: UUID) {
        var state = loadState()
        guard state.lifts.contains(where: { $0.passID == passID }) else { return }
        state.lifts.removeAll { $0.passID == passID }
        try? save(state)
        LiveShieldEnforcer.apply(state, at: Date())
        DeviceActivityCenter().stopMonitoring([LiveShieldEnforcer.activityName(forPass: passID)])
    }

    public func shieldLifts() -> [ShieldLift] {
        loadState().lifts
    }

    /// Brings the shields in line with the state at `date`: drops lifts
    /// whose passes have ended, re-applies every shield, and stops pass
    /// monitors that are no longer needed. The app calls it on every
    /// foreground, so a late or missing monitor callback never leaves an
    /// app unguarded once the user is back in Pofu.
    public func reconcile(at date: Date) {
        guard authorizationStatus() == .approved else { return }
        var state = loadState()
        let ended = state.pruneLifts(at: date)
        if !ended.isEmpty {
            try? save(state)
        }
        LiveShieldEnforcer.apply(state, at: date)
        let live = Set(state.lifts.map { LiveShieldEnforcer.activityName(forPass: $0.passID) })
        let stale = DeviceActivityCenter().activities.filter { name in
            ScreenTimeNames.passID(fromActivity: name.rawValue) != nil && !live.contains(name)
        }
        if !stale.isEmpty {
            DeviceActivityCenter().stopMonitoring(stale)
        }
    }

    // MARK: - Thresholds

    public func scheduleThreshold(_ schedule: ThresholdSchedule) throws {
        try requireAuthorization()
        guard !schedule.selection.isEmpty else { throw ScreenTimeError.emptySelection }
        guard schedule.threshold > 0, schedule.threshold.isFinite else {
            throw ScreenTimeError.invalidThreshold
        }
        let seconds = Int(schedule.threshold.rounded())
        let event = DeviceActivityEvent(
            applications: ScreenTimeTokenCoding.applications(schedule.selection.applications),
            categories: ScreenTimeTokenCoding.categories(schedule.selection.categories),
            webDomains: ScreenTimeTokenCoding.webDomains(schedule.selection.webDomains),
            threshold: DateComponents(minute: seconds / 60, second: seconds % 60),
            includesPastActivity: true
        )
        let name = DeviceActivityName(rawValue: schedule.id.rawValue)
        do {
            try DeviceActivityCenter().startMonitoring(
                name,
                during: Self.dailySchedule(for: schedule.window),
                events: [DeviceActivityEvent.Name(rawValue: schedule.id.rawValue): event]
            )
        } catch {
            Self.log.error("Could not monitor \(schedule.id.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw ScreenTimeError.unavailable
        }
        var state = loadState()
        state.thresholds.removeAll { $0.id == schedule.id }
        state.thresholds.append(schedule)
        try save(state)
    }

    public func cancelThreshold(_ id: ThresholdID) {
        DeviceActivityCenter().stopMonitoring([DeviceActivityName(rawValue: id.rawValue)])
        var state = loadState()
        state.thresholds.removeAll { $0.id == id }
        try? save(state)
    }

    public func scheduledThresholds() -> [ThresholdSchedule] {
        loadState().thresholds.sorted { $0.id.rawValue < $1.id.rawValue }
    }

    // MARK: - Events

    /// Authorization changes the app sees. Shield and monitor events reach
    /// the app through the App Group inbox instead (`ScreenTimeInbox`),
    /// because the extensions run in their own processes.
    public func events() -> AsyncStream<ScreenTimeEvent> {
        let (stream, continuation) = AsyncStream.makeStream(of: ScreenTimeEvent.self, bufferingPolicy: .unbounded)
        continuations[UUID()] = continuation
        return stream
    }

    // MARK: - Private

    private func requireAuthorization() throws {
        guard authorizationStatus() == .approved else { throw ScreenTimeError.notAuthorized }
    }

    private func loadState() -> LiveShieldState {
        stateFile.read() ?? LiveShieldState()
    }

    private func save(_ state: LiveShieldState) throws {
        try stateFile.write(state)
    }

    private func noteStatus(_ status: ScreenTimeAuthorizationStatus) {
        defer { lastStatus = status }
        guard let lastStatus, lastStatus != status else { return }
        for (id, continuation) in continuations {
            if case .terminated = continuation.yield(.authorizationChanged(status)) {
                continuations[id] = nil
            }
        }
    }

    private func scheduleRestore(passID: UUID, liftingAt date: Date, until: Date) {
        guard let plan = ShieldRestoreSchedule(liftingAt: date, until: until) else { return }
        let components = plan.intervalComponents(in: calendar)
        let schedule = DeviceActivitySchedule(
            intervalStart: components.start,
            intervalEnd: components.end,
            repeats: false,
            warningTime: plan.warningComponents
        )
        do {
            try DeviceActivityCenter().startMonitoring(LiveShieldEnforcer.activityName(forPass: passID), during: schedule)
        } catch {
            // The app restores on its next foreground instead.
            Self.log.error("Could not schedule the shield's return: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func dailySchedule(for window: DailyWindow?) -> DeviceActivitySchedule {
        guard let window, !window.isEmpty else {
            return DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
                intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
                repeats: true
            )
        }
        return DeviceActivitySchedule(
            intervalStart: DateComponents(hour: window.start.hour, minute: window.start.minute),
            intervalEnd: DateComponents(hour: window.end.hour, minute: window.end.minute),
            repeats: true
        )
    }

    private static func status(of status: AuthorizationStatus) -> ScreenTimeAuthorizationStatus {
        switch status {
        case .approved, .approvedWithDataAccess: .approved
        case .denied: .denied
        case .notDetermined: .notDetermined
        @unknown default: .notDetermined
        }
    }
}

/// Applies `LiveShieldState` to ManagedSettings. Shared by the app and the
/// monitor extension, which calls `restoreAfterPass` when a pass ends.
public enum LiveShieldEnforcer {
    /// The DeviceActivity name of the monitor that ends pass `passID`.
    public static func activityName(forPass passID: UUID) -> DeviceActivityName {
        DeviceActivityName(rawValue: ScreenTimeNames.passActivity(passID))
    }

    /// Applies every named shield as it should be at `date`.
    public static func apply(_ state: LiveShieldState, at date: Date, excluding passID: UUID? = nil) {
        for (id, shield) in state.effectiveShields(at: date, excluding: passID) {
            let store = ManagedSettingsStore(named: ManagedSettingsStore.Name(rawValue: id.rawValue))
            guard !shield.isEmpty else {
                store.clearAllSettings()
                continue
            }
            let applications = ScreenTimeTokenCoding.applications(shield.applications)
            let categories = ScreenTimeTokenCoding.categories(shield.categories)
            let exceptions = ScreenTimeTokenCoding.applications(shield.exceptApplications)
            let domains = ScreenTimeTokenCoding.webDomains(shield.webDomains)
            store.shield.applications = applications.isEmpty ? nil : applications
            store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories, except: exceptions)
            store.shield.webDomains = domains.isEmpty ? nil : domains
        }
    }

    /// Removes the shield named `id`.
    public static func clear(_ id: ShieldID) {
        ManagedSettingsStore(named: ManagedSettingsStore.Name(rawValue: id.rawValue)).clearAllSettings()
    }

    /// Puts the shields back after pass `passID`, from the state in the App
    /// Group, and stops the pass's monitor. For the monitor extension.
    public static func restoreAfterPass(_ passID: UUID, at date: Date, location: StorageLocation) {
        let state = LiveShieldState.file(in: location).read() ?? LiveShieldState()
        apply(state, at: date, excluding: passID)
        DeviceActivityCenter().stopMonitoring([activityName(forPass: passID)])
    }

    /// Re-applies every shield from the App Group state, for example at
    /// the start of a new monitoring day.
    public static func reapply(at date: Date, location: StorageLocation) {
        guard let state = LiveShieldState.file(in: location).read() else { return }
        apply(state, at: date)
    }
}

/// Converts system tokens to Pofu's opaque string tokens and back. Tokens
/// are Codable; their JSON is stable for the same token, so the string can
/// be compared and used as a key.
public enum ScreenTimeTokenCoding {
    public static func encode<Token: Encodable>(_ token: Token) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return (try? encoder.encode(token))?.base64EncodedString()
    }

    public static func decode<Token: Decodable>(_ type: Token.Type, from string: String) -> Token? {
        guard let data = Data(base64Encoded: string) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// The picker's selection as Pofu's tokens.
    public static func selection(from picked: FamilyActivitySelection) -> DistractionSelection {
        DistractionSelection(
            applications: Set(picked.applicationTokens.compactMap { encode($0).map { PofuScreenTime.ApplicationToken($0) } }),
            categories: Set(picked.categoryTokens.compactMap { encode($0).map { PofuScreenTime.CategoryToken($0) } }),
            webDomains: Set(picked.webDomainTokens.compactMap { encode($0).map { PofuScreenTime.WebDomainToken($0) } })
        )
    }

    public static func applications(_ tokens: Set<PofuScreenTime.ApplicationToken>) -> Set<ManagedSettings.ApplicationToken> {
        Set(tokens.compactMap { decode(ManagedSettings.ApplicationToken.self, from: $0.rawValue) })
    }

    public static func categories(_ tokens: Set<PofuScreenTime.CategoryToken>) -> Set<ActivityCategoryToken> {
        Set(tokens.compactMap { decode(ActivityCategoryToken.self, from: $0.rawValue) })
    }

    public static func webDomains(_ tokens: Set<PofuScreenTime.WebDomainToken>) -> Set<ManagedSettings.WebDomainToken> {
        Set(tokens.compactMap { decode(ManagedSettings.WebDomainToken.self, from: $0.rawValue) })
    }
}
#endif
