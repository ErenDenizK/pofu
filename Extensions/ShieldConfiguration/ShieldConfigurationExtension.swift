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
        let entry = ShieldDirectoryEntry(token: app.token, bundleIdentifier: app.bundleIdentifier, displayName: app.displayName)
        try? ShieldDirectory(location: location).record(entry)
    }
}

/// Draws the shield for one app from the App Group state.
enum ShieldPresenter {
    static func configuration(for app: ShieldedApp?, fallbackName: String?) -> ShieldConfiguration {
        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let language = ShieldLanguage(localization: Locale.preferredLanguages.first)
        guard let app, let location = StorageLocation.appGroup() else {
            let context = ShieldContext(
                appName: fallbackName,
                hour: calendar.component(.hour, from: now),
                submenuAvailable: false
            )
            return render(ShieldCopy.make(context: context, language: language))
        }
        let store = ShieldContextStore(location: location)
        let inbox = ScreenTimeInbox(location: location)
        let live = LiveShieldState.file(in: location).read()
        var memory = store.memory.read() ?? ShieldMemory()
        let ended = live?.lastEndedLift(for: [app.token], at: now)
        let inputs = ShieldContextInputs(
            app: app,
            now: now,
            calendar: calendar,
            appState: store.appState.read(),
            pendingRecords: inbox.read().records,
            measuredUsage: store.usage.read(),
            memory: memory,
            openRequest: store.openRequest.read(),
            endedPass: ended.map { (end: $0.until, minutes: $0.minutes) },
            lastQuickCheckEnd: live?.lastQuickCheckEnd,
            submenuAvailable: submenuAvailable
        )
        let context = inputs.context
        let rules = inputs.effectiveRules
        if let redraw = memory.recent(for: app.tokenKey, scene: context.scene, at: now, window: rules.reachDeduplicationWindow) {
            // The system drew the same shield again within seconds (the
            // app switcher, a re-render): the same reach, the same words.
            return render(redraw)
        }
        let copy = ShieldCopy.make(context: context, language: language, rules: rules)
        try? inbox.post(ScreenTimeRecord(at: now, kind: .shieldShown(app: app, scene: copy.scene)))
        memory.note(copy, for: app.tokenKey, at: now, on: LocalDay(containing: now, in: calendar))
        try? store.memory.write(memory)
        return render(copy)
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
        let icon = ShieldIconImage.image(for: copy.icon)
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

/// The shield's colors per palette (gate v2, section 5.2). Day follows the
/// system appearance; bedtime is always dark.
struct ShieldColors {
    let background: UIColor
    let title: UIColor
    let subtitle: UIColor
    let primaryFill: UIColor
    let primaryLabel: UIColor
    let secondaryLabel: UIColor

    init(palette: ShieldPalette) {
        let cream = Self.hex(0xFFF6EC)
        let night = Self.hex(0x15111C)
        let ink900 = Self.hex(0x2A1F2D)
        let ink600 = Self.hex(0x66555F)
        let mist300 = Self.hex(0xB8A8B1)
        let violet600 = Self.hex(0x6C4FD8)
        let violet300 = Self.hex(0xB9A2FF)
        let violet500 = Self.hex(0x8F74F0)
        switch palette {
        case .day, .breath:
            let lightBackground = palette == .breath ? Self.hex(0xF1ECFF) : cream
            let darkBackground = palette == .breath ? Self.hex(0x1E1828) : night
            background = Self.dynamic(light: lightBackground, dark: darkBackground)
            title = Self.dynamic(light: ink900, dark: cream)
            subtitle = Self.dynamic(light: ink600, dark: mist300)
            primaryFill = Self.dynamic(light: violet600, dark: violet300)
            primaryLabel = Self.dynamic(light: .white, dark: night)
            secondaryLabel = Self.dynamic(light: violet600, dark: violet300)
        case .night:
            background = night
            title = cream.withAlphaComponent(0.92)
            subtitle = mist300
            primaryFill = violet500
            primaryLabel = night
            secondaryLabel = mist300
        }
    }

    private static func hex(_ value: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }

    private static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}

/// Pofu's face for the shield, small: the shield draws its icon at about
/// 60 points, and the extension has only a few megabytes to work with.
///
/// A mood image (`pofu-proud.png`, …) is used when the bundle carries one;
/// until the approved mood art is in the bundle, every mood is the base
/// portrait, and "unwell" is the base desaturated (never a guilt picture).
enum ShieldIconImage {
    static func image(for icon: ShieldIcon) -> UIImage? {
        if let mood = load(icon.rawValue) {
            return mood
        }
        guard let base = load("pofu-hamster") else { return nil }
        return icon == .unwell ? desaturated(base) : base
    }

    private static func load(_ name: String) -> UIImage? {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "png"),
            let image = UIImage(contentsOfFile: url.path)
        else { return nil }
        let side: CGFloat = 180
        let scale = min(side / max(image.size.width, 1), side / max(image.size.height, 1), 1)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return image.preparingThumbnail(of: size) ?? image
    }

    /// The image at about a third of its color, keeping its alpha.
    private static func desaturated(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: image.size)
            image.draw(in: rect)
            UIColor(white: 0.5, alpha: 0.65).setFill()
            context.fill(rect, blendMode: .saturation)
            image.draw(in: rect, blendMode: .destinationIn, alpha: 1)
        }
    }
}
