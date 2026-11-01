import ManagedSettings
import ManagedSettingsUI
import PofuCore
import PofuDesignSystem
import PofuPersistence
import PofuScreenTime
import UIKit

/// The shield over a guarded app (ADR-0013): Pofu's line in a calm, warm
/// card, with "Skip it" as the primary button and "Talk to Pofu" as the
/// secondary one.
///
/// The shield is a fixed system template and cannot open Pofu; the action
/// extension answers the buttons. Here the system tells Pofu the app's
/// bundle identifier and name, which the action extension does not get,
/// so they are noted in the App Group for Hop! to hand the user back to
/// the right app.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        remember(application)
        return Self.pofuShield(appName: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        remember(application)
        return Self.pofuShield(appName: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        Self.pofuShield(appName: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        Self.pofuShield(appName: webDomain.domain)
    }

    /// Notes what the system says about the app behind `application`'s
    /// token. Best effort: if the App Group cannot be written here, Hop!
    /// still works and asks the user to return to the app themselves.
    private func remember(_ application: Application) {
        guard
            let token = application.token,
            let encoded = ScreenTimeTokenCoding.encode(token),
            let location = StorageLocation.appGroup()
        else { return }
        let entry = ShieldDirectoryEntry(
            token: encoded,
            bundleIdentifier: application.bundleIdentifier,
            displayName: application.localizedDisplayName
        )
        try? ShieldDirectory(location: location).record(entry)
    }

    private static func pofuShield(appName: String?) -> ShieldConfiguration {
        let subtitle: String
        if let appName, !appName.isEmpty {
            subtitle = String(localized: "\(appName) can wait. I'm right here.")
        } else {
            subtitle = String(localized: "This can wait. I'm right here.")
        }
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: color(.backgroundCanvas),
            icon: icon,
            title: ShieldConfiguration.Label(text: String(localized: "Hop! Where to?"), color: color(.textPrimary)),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: color(.textSecondary)),
            primaryButtonLabel: ShieldConfiguration.Label(text: String(localized: "Skip it"), color: color(.textOnAccent)),
            primaryButtonBackgroundColor: color(.accent),
            secondaryButtonLabel: ShieldConfiguration.Label(text: String(localized: "Talk to Pofu"), color: color(.accent))
        )
    }

    /// Pofu, small: the shield draws its icon at about 60 points, and the
    /// extension has only a few megabytes to work with.
    private static var icon: UIImage? {
        guard
            let url = Bundle.main.url(forResource: "pofu-hamster", withExtension: "png"),
            let image = UIImage(contentsOfFile: url.path)
        else { return nil }
        return image.preparingThumbnail(of: CGSize(width: 180, height: 171)) ?? image
    }

    /// A design-language color that follows the system appearance.
    private static func color(_ token: PofuSemanticColor) -> UIColor {
        UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? token.dark.rgb : token.light.rgb
            return UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
        }
    }
}
