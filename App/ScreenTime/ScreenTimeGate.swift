import FamilyControls
import Foundation
import Observation
import os
import PofuCore
import PofuPersistence
import PofuScreenTime
import UserNotifications

/// What the gate needs from Screen Time: the live system
/// (`LiveScreenTimeService`) or Rehearsal mode's simulation
/// (`RehearsalScreenTime`).
@MainActor
protocol GateSystem: AnyObject {
    func authorizationStatus() -> ScreenTimeAuthorizationStatus
    func distractingSelection() -> DistractionSelection
    func applyShield(_ id: ShieldID, to selection: DistractionSelection) throws
    func removeShield(_ id: ShieldID)
    func liftShields(from app: ShieldedApp, passID: UUID, at date: Date, until: Date) throws
    func restoreShields(passID: UUID)
    func reconcile(at date: Date)
    func scheduleThreshold(_ schedule: ThresholdSchedule) throws
    func cancelThresholds(withPrefix prefix: String)
}

extension LiveScreenTimeService: GateSystem {}

/// The app's side of the Screen Time gate (ADR-0013): authorization, the
/// picked apps, the shield, the usage thresholds, and the records the
/// extensions leave in the App Group.
///
/// It is live only in the `PofuLive` build, which carries the Family
/// Controls entitlement (`POFU_SCREEN_TIME_LIVE`). In Rehearsal mode (the
/// free build's default) the same gate runs on `RehearsalScreenTime`, which
/// simulates the system and the extensions in the app's own folder. Without
/// either, `isAvailable` is false and nothing here touches Screen Time, so
/// the soft gate runs alone as before.
@MainActor
@Observable
final class ScreenTimeGate {
    /// The one shield Pofu applies over the picked apps.
    static let gateShield: ShieldID = "pofu.gate"

    /// Whether this build was made with the Family Controls entitlement.
    static var isLiveBuild: Bool {
        #if POFU_SCREEN_TIME_LIVE
        return true
        #else
        return false
        #endif
    }

    private let live: LiveScreenTimeService?
    /// Rehearsal mode's simulated Screen Time, when it runs.
    let rehearsal: RehearsalScreenTime?
    private let system: (any GateSystem)?
    private let inbox: ScreenTimeInbox?
    private let directory: ShieldDirectory?
    private let contextStore: ShieldContextStore?
    /// The gate's rules with the user's daily hour; the model keeps them
    /// current. Changing the daily hour reschedules the ladder.
    private(set) var rules = ScreenTimeGateRules.standard

    private(set) var authorization: ScreenTimeAuthorizationStatus = .notDetermined
    private(set) var selection: DistractionSelection = .empty

    /// - Parameter location: Where the shared files live. The live build
    ///   uses the App Group so the extensions see them.
    init(location: StorageLocation?) {
        if Self.isLiveBuild, let location {
            let live = LiveScreenTimeService(location: location)
            self.live = live
            system = live
            inbox = ScreenTimeInbox(location: location)
            directory = ShieldDirectory(location: location)
            contextStore = ShieldContextStore(location: location)
        } else {
            live = nil
            system = nil
            inbox = nil
            directory = nil
            contextStore = nil
        }
        rehearsal = nil
        refreshStatus()
    }

    /// The gate on Rehearsal mode's simulated Screen Time.
    init(rehearsal: RehearsalScreenTime) {
        live = nil
        self.rehearsal = rehearsal
        system = rehearsal
        inbox = ScreenTimeInbox(location: rehearsal.location)
        directory = ShieldDirectory(location: rehearsal.location)
        contextStore = ShieldContextStore(location: rehearsal.location)
        refreshStatus()
    }

    /// The gate exists in this build: live, or rehearsed.
    var isAvailable: Bool { system != nil }

    /// The gate runs on Rehearsal mode's simulation.
    var isRehearsal: Bool { rehearsal != nil }

    /// The shield stands in front of something.
    var isOn: Bool {
        authorization == .approved && !selection.isEmpty
    }

    /// How many apps, categories, and sites the user picked.
    var selectionCount: Int {
        selection.applications.count + selection.categories.count + selection.webDomains.count
    }

    func refreshStatus() {
        guard let system else { return }
        authorization = system.authorizationStatus()
        selection = system.distractingSelection()
    }

    /// Takes the rules with the user's daily hour; reschedules the usage
    /// ladder when the hour changed.
    func update(rules newRules: ScreenTimeGateRules) {
        guard newRules != rules else { return }
        let ladderChanged = newRules.ladder != rules.ladder
        rules = newRules
        if ladderChanged, isOn {
            activate()
        }
    }

    // MARK: Setup

    /// Asks iOS for Screen Time access.
    ///
    /// - Throws: `ScreenTimeError.unavailable` when iOS could not ask.
    @discardableResult
    func requestAuthorization() async throws -> ScreenTimeAuthorizationStatus {
        guard let live else { return .notDetermined }
        let status = try await live.requestAuthorization()
        refreshStatus()
        if status == .approved, !selection.isEmpty {
            activate()
        }
        return status
    }

    /// The selection as the picker should show it.
    func pickedSelection() -> FamilyActivitySelection {
        live?.pickedSelection() ?? FamilyActivitySelection()
    }

    /// Stores the picker's result and puts the shield and the usage
    /// thresholds on it.
    func applyPicked(_ picked: FamilyActivitySelection) throws {
        guard let live else { return }
        try live.updatePickedSelection(picked)
        refreshStatus()
        activate()
    }

    /// Rehearsal mode: the answer to the mocked Screen Time alert.
    func answerRehearsalAuthorization(approved: Bool) {
        guard let rehearsal else { return }
        rehearsal.setAuthorization(approved ? .approved : .denied)
        refreshStatus()
        if approved, !selection.isEmpty {
            activate()
        }
    }

    /// Rehearsal mode: what the mocked picker returned.
    func applyRehearsalSelection(_ picked: DistractionSelection) throws {
        guard let rehearsal else { return }
        try rehearsal.updateSelection(picked)
        refreshStatus()
        activate()
    }

    /// Shields the selection and schedules the usage thresholds; with an
    /// empty selection, removes both.
    private func activate() {
        guard let system, authorization == .approved else { return }
        let ladder = rules.ladder
        // Every Pofu threshold, also those of another daily hour.
        system.cancelThresholds(withPrefix: GuardedUsageLadder.namePrefix)
        guard !selection.isEmpty else {
            system.removeShield(Self.gateShield)
            Log.screenTime.info("Selection is empty: shield and thresholds removed")
            return
        }
        do {
            try system.applyShield(Self.gateShield, to: selection)
        } catch {
            Log.screenTime.error("Applying the shield failed: \(String(describing: error), privacy: .public)")
        }
        for (name, seconds) in ladder.thresholds {
            do {
                try system.scheduleThreshold(ThresholdSchedule(id: ThresholdID(rawValue: name), selection: selection, threshold: seconds))
            } catch {
                Log.screenTime.error("Scheduling \(name, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            }
        }
        Log.screenTime.info("Shield on \(self.selectionCount, privacy: .private) items; \(ladder.thresholds.count, privacy: .public) thresholds")
    }

    // MARK: Passes

    /// Lifts the shield from `app` for `pass`, before Hop! hands the user
    /// back to it.
    func lift(_ app: ShieldedApp, for pass: Pass, at date: Date) {
        guard let system else { return }
        do {
            try system.liftShields(from: app, passID: pass.id, at: date, until: pass.expiresAt)
            Log.screenTime.info("Shield lifted for \(pass.durationMinutes, privacy: .public) min")
        } catch {
            Log.screenTime.error("Lifting the shield failed: \(String(describing: error), privacy: .public)")
        }
    }

    /// Puts the shield back when `passID` ended early or was voided.
    func restore(passID: UUID) {
        system?.restoreShields(passID: passID)
    }

    /// Brings the shields in line with the time, in case a monitor
    /// callback was late or missed.
    func reconcile(at date: Date) {
        guard let system else { return }
        refreshStatus()
        system.reconcile(at: date)
    }

    // MARK: Inbox

    /// Everything the extensions left, with the app names the shield
    /// configuration extension learned filled in.
    func readInbox() -> ScreenTimeInbox.Contents? {
        guard let inbox else { return nil }
        let contents = inbox.read()
        if contents.newerVersionCount > 0 {
            Log.screenTime.notice("\(contents.newerVersionCount, privacy: .public) records from a newer version left in the inbox")
        }
        return contents
    }

    /// `record` with its app resolved through the shield directory.
    func resolved(_ record: ScreenTimeRecord) -> ScreenTimeRecord {
        guard let directory else { return record }
        return record.mappingApp { directory.resolve($0) }
    }

    /// Deletes files the app has taken in.
    func acknowledge(_ contents: ScreenTimeInbox.Contents) {
        inbox?.remove(contents.consumable)
    }

    // MARK: Shield context (gate v2)

    /// Tells the shield extensions about the day.
    func writeShieldState(_ state: ShieldAppState) {
        guard let contextStore else { return }
        do {
            try contextStore.appState.write(state)
        } catch {
            Log.screenTime.error("Writing the shield context failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// The "Open with Pofu" the shield is waiting on, if any.
    func openRequestNote() -> ShieldOpenRequestNote? {
        contextStore?.openRequest.read()
    }

    /// Hop! answered the request (or it is over): the shield stops
    /// waiting, and the notification goes.
    func clearOpenRequest() {
        contextStore?.openRequest.remove()
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [GateNotificationCopy.identifier])
        center.removePendingNotificationRequests(withIdentifiers: [GateNotificationCopy.identifier])
    }
}
