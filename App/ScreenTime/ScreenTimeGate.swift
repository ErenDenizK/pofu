import FamilyControls
import Foundation
import Observation
import os
import PofuCore
import PofuPersistence
import PofuScreenTime

/// The app's side of the Screen Time gate (ADR-0013): authorization, the
/// picked apps, the shield, the usage thresholds, and the records the
/// extensions leave in the App Group.
///
/// It is live only in the `PofuLive` build, which carries the Family
/// Controls entitlement (`POFU_SCREEN_TIME_LIVE`). In the default build,
/// signed by a free Personal Team, `isAvailable` is false and nothing here
/// touches Screen Time, so the soft gate runs alone as before.
@MainActor
@Observable
final class ScreenTimeGate {
    /// The one shield Pofu applies over the picked apps.
    static let gateShield: ShieldID = "pofu.gate"
    /// How long a "Talk to Pofu" stays an invitation to Hop!.
    static let openRequestMaximumAge: TimeInterval = 10 * 60

    /// Whether this build was made with the Family Controls entitlement.
    static var isLiveBuild: Bool {
        #if POFU_SCREEN_TIME_LIVE
        return true
        #else
        return false
        #endif
    }

    private let live: LiveScreenTimeService?
    private let inbox: ScreenTimeInbox?
    private let directory: ShieldDirectory?
    private let ladder = GuardedUsageLadder.standard

    private(set) var authorization: ScreenTimeAuthorizationStatus = .notDetermined
    private(set) var selection: DistractionSelection = .empty

    /// - Parameter location: Where the shared files live. The live build
    ///   uses the App Group so the extensions see them.
    init(location: StorageLocation?) {
        if Self.isLiveBuild, let location {
            live = LiveScreenTimeService(location: location)
            inbox = ScreenTimeInbox(location: location)
            directory = ShieldDirectory(location: location)
        } else {
            live = nil
            inbox = nil
            directory = nil
        }
        refreshStatus()
    }

    /// The live gate exists in this build.
    var isAvailable: Bool { live != nil }

    /// The shield stands in front of something.
    var isOn: Bool {
        authorization == .approved && !selection.isEmpty
    }

    /// How many apps, categories, and sites the user picked.
    var selectionCount: Int {
        selection.applications.count + selection.categories.count + selection.webDomains.count
    }

    func refreshStatus() {
        guard let live else { return }
        authorization = live.authorizationStatus()
        selection = live.distractingSelection()
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

    /// Shields the selection and schedules the usage thresholds; with an
    /// empty selection, removes both.
    private func activate() {
        guard let live, authorization == .approved else { return }
        for (name, _) in ladder.thresholds {
            live.cancelThreshold(ThresholdID(rawValue: name))
        }
        guard !selection.isEmpty else {
            live.removeShield(Self.gateShield)
            Log.screenTime.info("Selection is empty: shield and thresholds removed")
            return
        }
        do {
            try live.applyShield(Self.gateShield, to: selection)
        } catch {
            Log.screenTime.error("Applying the shield failed: \(String(describing: error), privacy: .public)")
        }
        for (name, seconds) in ladder.thresholds {
            do {
                try live.scheduleThreshold(ThresholdSchedule(id: ThresholdID(rawValue: name), selection: selection, threshold: seconds))
            } catch {
                Log.screenTime.error("Scheduling \(name, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            }
        }
        Log.screenTime.info("Shield on \(self.selectionCount, privacy: .private) items; \(self.ladder.thresholds.count, privacy: .public) thresholds")
    }

    // MARK: Passes

    /// Lifts the shield from `app` for `pass`, before Hop! hands the user
    /// back to it.
    func lift(_ app: ShieldedApp, for pass: Pass, at date: Date) {
        guard let live else { return }
        do {
            try live.liftShields(from: app, passID: pass.id, at: date, until: pass.expiresAt)
            Log.screenTime.info("Shield lifted for \(pass.durationMinutes, privacy: .public) min")
        } catch {
            Log.screenTime.error("Lifting the shield failed: \(String(describing: error), privacy: .public)")
        }
    }

    /// Puts the shield back when `passID` ended early or was voided.
    func restore(passID: UUID) {
        live?.restoreShields(passID: passID)
    }

    /// Brings the shields in line with the time, in case a monitor
    /// callback was late or missed.
    func reconcile(at date: Date) {
        guard let live else { return }
        refreshStatus()
        live.reconcile(at: date)
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
        switch record.kind {
        case .shieldResisted(let app):
            return ScreenTimeRecord(id: record.id, at: record.at, kind: .shieldResisted(app: directory.resolve(app)), version: record.version)
        case .openRequested(let app):
            return ScreenTimeRecord(id: record.id, at: record.at, kind: .openRequested(app: directory.resolve(app)), version: record.version)
        case .usageThresholdReached, .shieldRestored:
            return record
        }
    }

    /// Deletes files the app has taken in.
    func acknowledge(_ contents: ScreenTimeInbox.Contents) {
        inbox?.remove(contents.consumable)
    }
}
