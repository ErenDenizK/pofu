import Foundation
import ManagedSettings
import os
import PofuCore
import PofuPersistence
import PofuScreenTime
import UserNotifications

/// Answers the shield's buttons (ADR-0013, gate v2 section 5.5).
///
/// The configuration extension remembers the shield it drew
/// (`ShieldMemory`), so each button does what its label said:
///
/// - "Boş ver" / "İyi geceler": the reach is resisted; the app closes.
/// - "Bitti, kapat" on the shield that returned at a pass's end: logged as
///   such, never as a skip.
/// - "Boş ver" while waiting for the notification tap: the request and its
///   notification are withdrawn, and the reach is resisted.
/// - "3 dakika bakacağım" (submenu, iOS 26.4): the shield lifts from the app
///   right here for a quick check, with no app round trip.
/// - "Pofu'yla aç" / "Pofu'yla nefes al": the shield cannot open Pofu, so
///   this records the request, posts a time-sensitive notification, and
///   answers `.defer`, which redraws the shield into its waiting state
///   ("Bildirime dokun ↑", or "Pofu'yu kendin aç" when notifications are
///   off: opening Pofu by hand within 10 minutes starts Hop! too).
final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ManagedSettings.ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        let app = ScreenTimeTokenCoding.encode(application).map { ShieldedApp(kind: .application, token: $0) }
        completionHandler(ShieldResponder.respond(to: action, for: app))
    }

    override func handle(
        action: ShieldAction,
        for webDomain: ManagedSettings.WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        let app = ScreenTimeTokenCoding.encode(webDomain).map { ShieldedApp(kind: .webDomain, token: $0) }
        completionHandler(ShieldResponder.respond(to: action, for: app))
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        let app = ScreenTimeTokenCoding.encode(category).map { ShieldedApp(kind: .category, token: $0) }
        completionHandler(ShieldResponder.respond(to: action, for: app))
    }
}

enum ShieldResponder {
    private static let log = Logger(subsystem: "com.erendenizk.pofu", category: "shield")

    static func respond(to action: ShieldAction, for app: ShieldedApp?) -> ShieldActionResponse {
        guard let app, let location = StorageLocation.appGroup() else { return .close }
        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let core = ShieldExtensionCore(location: location, calendar: calendar)
        guard let button = button(for: action) else { return .close }
        let intent = ShieldExtensionCore.intent(for: button, shown: core.shownShield(for: app, at: now))
        log.info("Shield action: \(intent.rawValue, privacy: .public)")

        let effects = ShieldExtensionCore.Effects(
            liftForQuickCheck: { app, passID, from, until in
                try LiveShieldEnforcer.liftForQuickCheck(app, passID: passID, at: from, until: until, location: location, calendar: calendar)
            },
            postNotification: { app, breath in GateNotification.post(about: app, breath: breath) },
            withdrawNotification: { GateNotification.withdraw() }
        )
        switch core.respond(to: intent, for: app, at: now, effects: effects) {
        case .close:
            return .close
        case .lifted:
            // The store change removes the shield (day-1 case 24).
            return .none
        case .requested(let tryOpenParentalControlsApp):
            if #available(iOS 26.5, *), tryOpenParentalControlsApp {
                // Day-1 spike (case 23): whether this opens Pofu with
                // individual authorization is unknown. The notification
                // stays as the fallback.
                return .openParentalControlsApp
            }
            // Redraws the shield into its waiting state.
            return .defer
        }
    }

    /// The button `action` names; `nil` for actions the shield never shows.
    static func button(for action: ShieldAction) -> ShieldButton? {
        switch action {
        case .primaryButtonPressed:
            return .primary
        case .secondaryButtonPressed:
            return .secondary
        default:
            if #available(iOS 26.4, *) {
                if action == .firstSecondarySubmenuItemPressed {
                    return .submenuItem(0)
                }
                if action == .secondSecondarySubmenuItemPressed {
                    return .submenuItem(1)
                }
                if action == .thirdSecondarySubmenuItemPressed {
                    return .submenuItem(2)
                }
            }
            return nil
        }
    }
}

/// Posts and withdraws the notification that answers "Pofu'yla aç" (gate
/// v2, section 5.7); its content is shared with Rehearsal mode.
enum GateNotification {
    /// Posts it if notifications are allowed, waiting briefly for the
    /// system, because the extension may be suspended as soon as it
    /// answers.
    ///
    /// - Returns: Whether it was handed to the system.
    static func post(about app: ShieldedApp, breath: Bool) -> Bool {
        let center = UNUserNotificationCenter.current()
        guard isAllowed(center) else { return false }
        let content = GateNotificationContent.make(about: app, breath: breath)
        let request = UNNotificationRequest(identifier: GateNotificationCopy.identifier, content: content, trigger: nil)
        let added = OSAllocatedUnfairLock(initialState: false)
        let done = DispatchSemaphore(value: 0)
        center.add(request) { error in
            added.withLock { $0 = error == nil }
            done.signal()
        }
        _ = done.wait(timeout: .now() + 2)
        return added.withLock { $0 }
    }

    /// Removes the notification, delivered or not.
    static func withdraw() {
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [GateNotificationCopy.identifier])
        center.removePendingNotificationRequests(withIdentifiers: [GateNotificationCopy.identifier])
    }

    private static func isAllowed(_ center: UNUserNotificationCenter) -> Bool {
        let allowed = OSAllocatedUnfairLock(initialState: false)
        let done = DispatchSemaphore(value: 0)
        center.getNotificationSettings { settings in
            let status = settings.authorizationStatus
            allowed.withLock { $0 = status == .authorized || status == .provisional || status == .ephemeral }
            done.signal()
        }
        _ = done.wait(timeout: .now() + 1)
        return allowed.withLock { $0 }
    }
}
