import Foundation
import PofuCore
import PofuScreenTime

/// The apps and categories Rehearsal mode's picker offers, with the
/// opaque tokens the simulated system gives them. Like real tokens, they
/// say nothing about the app; the shield learns its name and bundle
/// identifier separately, as the configuration extension does.
enum RehearsalCatalog {
    struct CatalogApp: Identifiable, Hashable {
        let id: String
        let name: String
        let bundleIdentifier: String
        let category: Category
        /// The guarded app Hop! knows it as, when Pofu has one.
        var protectedApp: ProtectedApp? {
            ProtectedApp(bundleIdentifier: bundleIdentifier)
        }

        var token: ApplicationToken {
            ApplicationToken("rehearsal.app.\(id)")
        }
    }

    enum Category: String, CaseIterable, Identifiable {
        case social
        case entertainment

        var id: String { rawValue }

        var token: CategoryToken {
            CategoryToken("rehearsal.category.\(rawValue)")
        }

        var symbolName: String {
            switch self {
            case .social: "bubble.left.and.bubble.right.fill"
            case .entertainment: "popcorn.fill"
            }
        }
    }

    /// The picker's apps, by category, in the order the picker lists them.
    static let apps: [CatalogApp] = [
        CatalogApp(id: "instagram", name: "Instagram", bundleIdentifier: "com.burbn.instagram", category: .social),
        CatalogApp(id: "tiktok", name: "TikTok", bundleIdentifier: "com.zhiliaoapp.musically", category: .social),
        CatalogApp(id: "whatsapp", name: "WhatsApp", bundleIdentifier: "net.whatsapp.WhatsApp", category: .social),
        CatalogApp(id: "youtube", name: "YouTube", bundleIdentifier: "com.google.ios.youtube", category: .entertainment),
        CatalogApp(id: "netflix", name: "Netflix", bundleIdentifier: "com.netflix.Netflix", category: .entertainment),
    ]

    /// The apps the Prova panel can reach for.
    static let reachable: [ProtectedApp] = [.instagram, .youtube, .tiktok]

    static func apps(in category: Category) -> [CatalogApp] {
        apps.filter { $0.category == category }
    }

    static func app(for protectedApp: ProtectedApp) -> CatalogApp? {
        apps.first { $0.protectedApp == protectedApp }
    }

    /// Which category each app belongs to, for the simulated system.
    static var applicationCategories: [ApplicationToken: CategoryToken] {
        Dictionary(uniqueKeysWithValues: apps.map { ($0.token, $0.category.token) })
    }
}
