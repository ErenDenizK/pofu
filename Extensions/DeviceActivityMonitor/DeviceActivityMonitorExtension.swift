import DeviceActivity
import Foundation
import PofuCore
import PofuPersistence
import PofuScreenTime

/// Runs when DeviceActivity says so, even while Pofu is closed:
///
/// - A usage threshold (15, 30, 45, 60 guarded minutes) is recorded, so
///   the app knows today's guarded time instead of estimating it.
/// - A pass's monitor ends (or warns at the pass's end, for passes shorter
///   than DeviceActivity's 15-minute minimum): the shield goes back on.
///
/// Everything goes through the App Group; the extension never touches the
/// app's snapshot.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let ladder = GuardedUsageLadder.standard

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard
            let minutes = ladder.minutes(forThresholdName: event.rawValue),
            let location = StorageLocation.appGroup()
        else { return }
        try? ScreenTimeInbox(location: location)
            .post(ScreenTimeRecord(at: Date(), kind: .usageThresholdReached(minutes: minutes)))
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        restoreIfPassEnded(activity)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        restoreIfPassEnded(activity)
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // A new monitoring day: make sure the shield is where it should be,
        // in case anything cleared it.
        guard ladder.minutes(forThresholdName: activity.rawValue) != nil, let location = StorageLocation.appGroup() else { return }
        LiveShieldEnforcer.reapply(at: Date(), location: location)
    }

    private func restoreIfPassEnded(_ activity: DeviceActivityName) {
        guard
            let passID = ScreenTimeNames.passID(fromActivity: activity.rawValue),
            let location = StorageLocation.appGroup()
        else { return }
        LiveShieldEnforcer.restoreAfterPass(passID, at: Date(), location: location)
        try? ScreenTimeInbox(location: location)
            .post(ScreenTimeRecord(at: Date(), kind: .shieldRestored(passID: passID)))
    }
}
