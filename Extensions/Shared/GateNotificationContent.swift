import Foundation
import PofuCore
import UserNotifications

// Shared by the shield action extension and the app (Rehearsal mode), so
// the "Open with Pofu" notification reads the same in both.

/// The notification that answers "Pofu'yla aç" (gate v2, section 5.7).
enum GateNotificationContent {
    /// The content about `app`, in the system's language.
    static func make(about app: ShieldedApp, breath: Bool) -> UNMutableNotificationContent {
        let copy = GateNotificationCopy(
            appName: app.displayName,
            bundleIdentifier: app.bundleIdentifier,
            breath: breath,
            language: ShieldLanguage(localization: Locale.preferredLanguages.first)
        )
        let content = UNMutableNotificationContent()
        content.title = copy.title
        content.body = copy.body
        content.threadIdentifier = GateNotificationCopy.threadIdentifier
        // The user asked for it a second ago; Focus would otherwise hide
        // it. Needs the Time Sensitive Notifications entitlement.
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1
        return content
    }
}
