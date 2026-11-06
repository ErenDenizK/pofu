import Foundation
import ManagedSettings
import ManagedSettingsUI
import PofuCore
import PofuPersistence
import PofuScreenTime
import UIKit

/// The shield over a guarded app (ADR-0013, gate v2 section 5): Pofu's
/// line from the copy engine (`ShieldCopy`), his mood as the icon, today's
/// tally, and the buttons of the shield's state: "Boş ver" first, "Açmam
/// lazım" with its submenu (iOS 26.4) second.
///
/// The shield is a fixed system template and cannot open Pofu; the action
/// extension answers the buttons, reading back the shield drawn here from
/// `ShieldMemory`. Every new reach is recorded as `shieldShown`, so a
/// shield left without a tap still counts (section 12). The system also
/// tells this extension the app's bundle identifier and name, which the
/// action extension does not get; they go to the shield directory.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let app = application.token
            .flatMap { ScreenTimeTokenCoding.encode($0) }
            .map { ShieldedApp(kind: .application, token: $0, bundleIdentifier: application.bundleIdentifier, displayName: application.localizedDisplayName) }
        remember(app)
        return ShieldPresenter.configuration(for: app, fallbackName: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        // The action extension sees only the category here, so the
        // category's token is the unit; the app's name rides along.
        let app = category.token
            .flatMap { ScreenTimeTokenCoding.encode($0) }
            .map { ShieldedApp(kind: .category, token: $0, bundleIdentifier: application.bundleIdentifier, displayName: application.localizedDisplayName) }
        remember(app)
        return ShieldPresenter.configuration(for: app, fallbackName: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        let app = webDomain.token
            .flatMap { ScreenTimeTokenCoding.encode($0) }
            .map { ShieldedApp(kind: .webDomain, token: $0, displayName: webDomain.domain) }
        remember(app)
        return ShieldPresenter.configuration(for: app, fallbackName: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        let app = category.token
            .flatMap { ScreenTimeTokenCoding.encode($0) }
            .map { ShieldedApp(kind: .category, token: $0, displayName: webDomain.domain) }
        remember(app)
        return ShieldPresenter.configuration(for: app, fallbackName: webDomain.domain)
    }

    /// Notes what the system says about the app behind a token. Best
    /// effort: if the App Group cannot be written here, Hop! still works
    /// and asks the user to return to the app themselves.
    private func remember(_ app: ShieldedApp?) {
        guard let app, let location = StorageLocation.appGroup() else { return }
        ShieldExtensionCore(location: location, calendar: .autoupdatingCurrent).remember(app)
    }
}

/// Draws the shield for one app from the App Group state. The decisions
/// are `ShieldExtensionCore`'s, shared with Rehearsal mode's replica.
enum ShieldPresenter {
    static func configuration(for app: ShieldedApp?, fallbackName: String?) -> ShieldConfiguration {
        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let language = ShieldLanguage(localization: Locale.preferredLanguages.first)
        guard let app, let location = StorageLocation.appGroup() else {
            return render(ShieldExtensionCore.fallbackShield(appName: fallbackName, at: now, calendar: calendar, language: language))
        }
        let core = ShieldExtensionCore(location: location, calendar: calendar)
        return render(core.drawShield(for: app, at: now, language: language, submenuAvailable: submenuAvailable))
    }

    /// Whether this iOS shows the secondary button's submenu (26.4).
    private static var submenuAvailable: Bool {
        if #available(iOS 26.4, *) {
            return true
        }
        return false
    }

    static func render(_ copy: ShieldCopy) -> ShieldConfiguration {
        let colors = ShieldColors(palette: copy.palette)
        let title = ShieldConfiguration.Label(text: copy.title, color: colors.title)
        let subtitle = ShieldConfiguration.Label(text: copy.subtitle, color: colors.subtitle)
        let primary = ShieldConfiguration.Label(text: copy.primary.label, color: colors.primaryLabel)
        let secondary = copy.secondary.map { ShieldConfiguration.Label(text: $0.label, color: colors.secondaryLabel) }
        let icon = ShieldIconImage.image(for: copy.icon, palette: copy.palette)
        if #available(iOS 26.4, *), !copy.submenu.isEmpty {
            return ShieldConfiguration(
                backgroundBlurStyle: nil,
                backgroundColor: colors.background,
                icon: icon,
                title: title,
                subtitle: subtitle,
                primaryButtonLabel: primary,
                primaryButtonBackgroundColor: colors.primaryFill,
                secondaryButtonLabel: secondary,
                secondaryButtonSubmenuItems: copy.submenu.map(\.label)
            )
        }
        // The shield is opaque: no blur, so the feed never peeks through.
        return ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: colors.background,
            icon: icon,
            title: title,
            subtitle: subtitle,
            primaryButtonLabel: primary,
            primaryButtonBackgroundColor: colors.primaryFill,
            secondaryButtonLabel: secondary
        )
    }
}
