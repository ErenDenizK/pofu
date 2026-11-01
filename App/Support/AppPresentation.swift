import Foundation
import PofuCore
import SwiftUI
import UIKit

extension ProtectedApp {
    /// The name shown in the UI: the brand, or "Another app".
    var displayName: String {
        brandName ?? String(localized: "Another app")
    }

    /// The name as the object of a verb ("open Instagram"). Turkish needs
    /// the accusative suffix, which follows how the brand is pronounced,
    /// not how it is spelled ("YouTube'u", "Snapchat'i"), so the forms are
    /// listed rather than derived (information architecture, section 7).
    var objectName: String {
        guard AppLanguage.isTurkish else { return displayName }
        switch self {
        case .instagram: return "Instagram'ı"
        case .youtube: return "YouTube'u"
        case .tiktok: return "TikTok'u"
        case .x: return "X'i"
        case .snapchat: return "Snapchat'i"
        case .reddit: return "Reddit'i"
        case .facebook: return "Facebook'u"
        case .other: return "uygulamayı"
        }
    }

    /// A neutral SF Symbol for the app. Brand logos are not ours to draw.
    var symbolName: String {
        switch self {
        case .instagram: "camera"
        case .youtube: "play.rectangle"
        case .tiktok: "music.note"
        case .x: "text.bubble"
        case .snapchat: "bolt.horizontal.circle"
        case .reddit: "bubble.left.and.bubble.right"
        case .facebook: "person.2"
        case .other: "app"
        }
    }
}

/// The language the app's strings are shown in.
enum AppLanguage {
    static var code: String {
        Bundle.main.preferredLocalizations.first ?? "en"
    }

    static var isTurkish: Bool {
        code.hasPrefix("tr")
    }

    static var locale: Locale {
        Locale(identifier: code)
    }

    /// "2nd" in English, "2." in Turkish.
    static func ordinal(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

/// Hands the user over to other apps.
@MainActor
enum AppOpener {
    /// Opens `app`: its custom schemes first (only those iOS reports as
    /// installed), then its universal link with "universal links only",
    /// which opens the app if installed and nothing otherwise.
    ///
    /// - Returns: Whether the app opened.
    static func open(_ app: ProtectedApp) async -> Bool {
        let application = UIApplication.shared
        for url in app.launchURLs where application.canOpenURL(url) {
            if await application.open(url) {
                return true
            }
        }
        if let link = app.universalLink {
            return await application.open(link, options: [.universalLinksOnly: true])
        }
        return false
    }

    /// Whether iOS reports one of the app's schemes as installed; `nil` for
    /// apps Pofu cannot check.
    static func isInstalled(_ app: ProtectedApp) -> Bool? {
        guard !app.launchURLs.isEmpty else { return nil }
        return app.launchURLs.contains { UIApplication.shared.canOpenURL($0) }
    }

    /// Opens the Shortcuts app.
    @discardableResult
    static func openShortcuts() async -> Bool {
        guard let url = URL(string: "shortcuts://") else { return false }
        return await UIApplication.shared.open(url)
    }
}
