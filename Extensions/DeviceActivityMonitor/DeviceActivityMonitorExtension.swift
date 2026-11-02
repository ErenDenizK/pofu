import DeviceActivity
import Foundation
import PofuCore
import PofuPersistence
import PofuScreenTime

/// Runs when DeviceActivity says so, even while Pofu is closed:
///
/// - A usage threshold (every 15 guarded minutes up to the daily hour) is
///   recorded, so the app knows today's guarded time instead of estimating
///   it, and the shield knows at once when the daily hour is reached.
/// - A pass's monitor ends (or warns at the pass's end, for passes shorter
///   than DeviceActivity's 15-minute minimum): the shield goes back on.
///
/// Everything goes through the App Group; the extension never touches the
/// app's snapshot.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard
            let minutes = GuardedUsageLadder.parseMinutes(fromThresholdName: event.rawValue),
            let location = StorageLocation.appGroup()
        else { return }
        let now = Date()
        try? ScreenTimeInbox(location: location)
            .post(ScreenTimeRecord(at: now, kind: .usageThresholdReached(minutes: minutes)))
        try? ShieldContextStore(location: location)
            .noteMeasured(minutes, on: LocalDay(containing: now, in: .autoupdatingCurrent))
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
        guard
            GuardedUsageLadder.parseMinutes(fromThresholdName: activity.rawValue) != nil,
            let location = StorageLocation.appGroup()
        else { return }
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
