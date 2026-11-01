import Foundation
import ManagedSettings
import PofuCore
import PofuPersistence
import PofuScreenTime
import UserNotifications

/// Answers the shield's buttons (ADR-0013).
///
/// - Primary, "Skip it": the reach is resisted. The record goes to the App
///   Group inbox and the app counts it with the day's skips; the shield
///   closes the app.
/// - Secondary, "Talk to Pofu": the user wants to open the app. The shield
///   cannot open Pofu, so this records the request and posts a local
///   notification; tapping it opens Pofu, which runs Hop! for that app and
///   lifts the shield for the pass it grants.
final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ManagedSettings.ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        let app = ScreenTimeTokenCoding.encode(application).map { ShieldedApp(kind: .application, token: $0) }
        completionHandler(Self.respond(to: action, for: app))
    }

    override func handle(
        action: ShieldAction,
        for webDomain: ManagedSettings.WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        let app = ScreenTimeTokenCoding.encode(webDomain).map { ShieldedApp(kind: .webDomain, token: $0) }
        completionHandler(Self.respond(to: action, for: app))
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        let app = ScreenTimeTokenCoding.encode(category).map { ShieldedApp(kind: .category, token: $0) }
        completionHandler(Self.respond(to: action, for: app))
    }

    private static func respond(to action: ShieldAction, for app: ShieldedApp?) -> ShieldActionResponse {
        guard let app, let location = StorageLocation.appGroup() else { return .close }
        let resolved = ShieldDirectory(location: location).resolve(app)
        let inbox = ScreenTimeInbox(location: location)
        let now = Date()
        switch action {
        case .primaryButtonPressed:
            try? inbox.post(ScreenTimeRecord(at: now, kind: .shieldResisted(app: resolved)))
            return .close
        case .secondaryButtonPressed:
            try? inbox.post(ScreenTimeRecord(at: now, kind: .openRequested(app: resolved)))
            postTalkToPofu(about: resolved)
            return .close
        default:
            // iOS 26 adds secondary submenu items; Pofu offers none.
            return .close
        }
    }

    /// Posts "Tap to talk to Pofu" and waits briefly for the system to take
    /// it, because the extension may be suspended as soon as it answers.
    private static func postTalkToPofu(about app: ShieldedApp) {
        let content = UNMutableNotificationContent()
        content.title = "Pofu"
        if let name = app.displayName, !name.isEmpty {
            content.body = String(localized: "Tap to talk to Pofu about \(name).")
        } else {
            content.body = String(localized: "Tap to talk to Pofu")
        }
        content.threadIdentifier = "pofu.shield"
        content.interruptionLevel = .active
        let request = UNNotificationRequest(identifier: "pofu.shield.talk", content: content, trigger: nil)
        let posted = DispatchSemaphore(value: 0)
        UNUserNotificationCenter.current().add(request) { _ in
            posted.signal()
        }
        _ = posted.wait(timeout: .now() + 2)
    }
}
