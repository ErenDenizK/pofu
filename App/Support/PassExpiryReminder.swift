import Foundation
import PofuCore
import UserNotifications

/// The one notification Pofu sends: a gentle line when a pass expires
/// (decision audit C1).
///
/// Before Screen Time, nothing closes the guarded app at expiry, and the
/// automation does not fire while the user stays in it. The reminder is
/// the only nudge back; tapping it opens Pofu, which counts as a sign of
/// life for quiet time.
///
/// Permission is asked at the moment of the first pass, never in
/// onboarding, so the question arrives with its reason. If it is denied,
/// passes work exactly as before, without the reminder.
enum PassExpiryReminder {
    private static let identifierPrefix = "pass-expiry."

    /// Receives taps and foreground deliveries. The notification center
    /// holds its delegate weakly, so it lives here.
    private static let delegate = PofuNotificationDelegate()

    /// Becomes the notification center's delegate. Call once at launch,
    /// before the app finishes launching, so a tap that launches Pofu is
    /// delivered.
    static func install() {
        UNUserNotificationCenter.current().delegate = delegate
    }

    /// Asks for permission if Pofu never has, then schedules the reminder
    /// for `pass`'s expiry. Returns once the user has answered, so the
    /// hand-off to the app can wait for the system prompt.
    static func schedule(for pass: Pass, now: Date) async {
        guard await isAllowed() else {
            Log.economy.info("Pass reminder not scheduled: notifications are off")
            return
        }
        let interval = pass.expiresAt.timeIntervalSince(now)
        guard interval >= 1 else { return }

        let content = UNMutableNotificationContent()
        content.body = String(localized: "Time's up. Back to me?", comment: "The pass-expiry notification, in Pofu's voice.")
        content.sound = .default
        content.threadIdentifier = "pass-expiry"
        let request = UNNotificationRequest(
            identifier: identifier(for: pass.id),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        )
        do {
            try await UNUserNotificationCenter.current().add(request)
            Log.economy.info("Pass reminder scheduled in \(Int(interval), privacy: .public) s")
        } catch {
            Log.economy.error("Scheduling the pass reminder failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Withdraws the reminder for a pass that ended before its expiry.
    static func cancel(passID: UUID) {
        let center = UNUserNotificationCenter.current()
        let identifiers = [identifier(for: passID)]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    static func isPassReminder(_ identifier: String) -> Bool {
        identifier.hasPrefix(identifierPrefix)
    }

    private static func identifier(for passID: UUID) -> String {
        identifierPrefix + passID.uuidString
    }

    /// Whether Pofu may post the reminder, asking first if it never has.
    private static func isAllowed() async -> Bool {
        let center = UNUserNotificationCenter.current()
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound])
            } catch {
                Log.economy.error("Asking for notifications failed: \(error.localizedDescription, privacy: .public)")
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }
}

/// Relays notification events to the app model on the main actor: the pass
/// reminder (free build) and the shield's "Open with Pofu" answer (live
/// build, gate v2 section 5.7). It has no state, so the system may call it
/// from any queue.
final class PofuNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, Sendable {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        if PassExpiryReminder.isPassReminder(identifier) {
            // Pofu opens, and the tap is a sign of life.
            Task { @MainActor in
                AppModel.shared.passReminderTapped()
            }
        } else if identifier == GateNotificationCopy.identifier {
            // The user asked the shield to open with Pofu: Hop! for that
            // app, from a cold launch too.
            Task { @MainActor in
                AppModel.shared.gateNotificationTapped()
            }
        }
        completionHandler()
    }

    /// Pofu is on screen already: the user is here, so no banner. Rehearsal
    /// mode's "Open with Pofu" is the exception: on screen, Pofu stands in
    /// for the app behind the shield, so its banner shows as on a device.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let isRehearsal = notification.request.content.userInfo[RehearsalScreenTime.rehearsalKey] as? Bool == true
        completionHandler(isRehearsal ? [.banner, .list] : [])
    }
}
