import PofuCore
import UIKit

// Shared by the shield configuration extension and the app (Rehearsal
// mode's shield replica), so both draw the shield in the same colors with
// the same icon. Kept out of PofuKit because it is UIKit and only these
// two targets need it.

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
    /// - Parameter locate: Finds a PNG by resource name: the main bundle in
    ///   the extension; the app adds PofuCompanion's bundle, where the
    ///   portrait lives.
    static func image(for icon: ShieldIcon, locate: (String) -> URL? = mainBundlePNG) -> UIImage? {
        if let mood = load(icon.rawValue, locate: locate) {
            return mood
        }
        guard let base = load("pofu-hamster", locate: locate) else { return nil }
        return icon == .unwell ? desaturated(base) : base
    }

    static func mainBundlePNG(named name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "png")
    }

    private static func load(_ name: String, locate: (String) -> URL?) -> UIImage? {
        guard
            let url = locate(name),
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
