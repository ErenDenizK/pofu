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

    /// A tap belongs to the shield drawn for the app within this window.
    private static let shownWindow: TimeInterval = 30 * 60

    static func respond(to action: ShieldAction, for app: ShieldedApp?) -> ShieldActionResponse {
        guard let app, let location = StorageLocation.appGroup() else { return .close }
        let now = Date()
        let store = ShieldContextStore(location: location)
        let inbox = ScreenTimeInbox(location: location)
        let resolved = ShieldDirectory(location: location).resolve(app)
        let appState = store.appState.read()
        let rules = ScreenTimeGateRules.standard.withDailyHour(appState?.dailyHourMinutes)
        let shown = store.memory.read()?.lastShown(for: app.tokenKey, at: now, within: shownWindow)
        guard let intent = intent(for: action, shown: shown) else { return .close }
        log.info("Shield action: \(intent.rawValue, privacy: .public)")

        switch intent {
        case .skip:
            try? inbox.post(ScreenTimeRecord(at: now, kind: .shieldResisted(app: resolved)))
            return .close

        case .closeAfterPass:
            try? inbox.post(ScreenTimeRecord(at: now, kind: .passEndedClosed(app: resolved)))
            return .close

        case .cancelRequest:
            store.openRequest.remove()
            GateNotification.withdraw()
            try? inbox.post(ScreenTimeRecord(at: now, kind: .openRequestCancelled(app: resolved)))
            return .close

        case .quickCheck:
            let passID = UUID()
            let until = now.addingTimeInterval(TimeInterval(rules.quickCheckMinutes) * 60)
            do {
                try LiveShieldEnforcer.liftForQuickCheck(app, passID: passID, at: now, until: until, location: location, calendar: .autoupdatingCurrent)
            } catch {
                // Could not lift here: the way through Pofu still works.
                log.error("Quick check lift failed: \(error.localizedDescription, privacy: .public)")
                return requestOpen(resolved, breath: false, at: now, store: store, inbox: inbox, appState: appState)
            }
            try? inbox.post(ScreenTimeRecord(at: now, kind: .quickCheckStarted(app: resolved, passID: passID, until: until)))
            // The store change removes the shield (day-1 case 24).
            return .none

        case .openWithPofu:
            return requestOpen(resolved, breath: false, at: now, store: store, inbox: inbox, appState: appState)

        case .breatheWithPofu:
            return requestOpen(resolved, breath: true, at: now, store: store, inbox: inbox, appState: appState)
        }
    }

    /// What `action` means on the shield `shown`. Without a remembered
    /// shield, the buttons keep their default meaning.
    static func intent(for action: ShieldAction, shown: ShieldCopy?) -> ShieldIntent? {
        switch action {
        case .primaryButtonPressed:
            return shown?.primary.intent ?? .skip
        case .secondaryButtonPressed:
            return shown?.secondaryIntent ?? .openWithPofu
        default:
            if #available(iOS 26.4, *) {
                if action == .firstSecondarySubmenuItemPressed {
                    return shown?.submenuIntent(at: 0) ?? .quickCheck
                }
                if action == .secondSecondarySubmenuItemPressed {
                    return shown?.submenuIntent(at: 1) ?? .openWithPofu
                }
                if action == .thirdSecondarySubmenuItemPressed {
                    return shown?.submenuIntent(at: 2) ?? .openWithPofu
                }
            }
            return nil
        }
    }

    /// Records the request, posts the notification, and leaves a note so
    /// the redrawn shield waits for the user.
    private static func requestOpen(
        _ app: ShieldedApp,
        breath: Bool,
        at now: Date,
        store: ShieldContextStore,
        inbox: ScreenTimeInbox,
        appState: ShieldAppState?
    ) -> ShieldActionResponse {
        try? inbox.post(ScreenTimeRecord(at: now, kind: .openRequested(app: app)))
        let posted = GateNotification.post(about: app, breath: breath)
        try? store.openRequest.write(
            ShieldOpenRequestNote(token: app.token, requestedAt: now, notificationsAllowed: posted, breath: breath)
        )
        if #available(iOS 26.5, *), appState?.tryOpenParentalControlsApp == true {
            // Day-1 spike (case 23): whether this opens Pofu with
            // individual authorization is unknown. The notification above
            // stays as the fallback.
            return .openParentalControlsApp
        }
        // Redraws the shield into its waiting state.
        return .defer
    }
}

/// The notification that answers "Pofu'yla aç" (gate v2, section 5.7).
enum GateNotification {
    /// Posts it if notifications are allowed, waiting briefly for the
    /// system, because the extension may be suspended as soon as it
    /// answers.
    ///
    /// - Returns: Whether it was handed to the system.
    static func post(about app: ShieldedApp, breath: Bool) -> Bool {
        let center = UNUserNotificationCenter.current()
        guard isAllowed(center) else { return false }
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
