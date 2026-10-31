#if canImport(SwiftUI)
import SwiftUI

/// An sRGB color value. Tokens are stored as plain numbers so they can be
/// mixed (for example by vitality) and compared in tests.
public struct PofuRGB: Hashable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Creates a color from a 24-bit hex value such as `0xB9A2FF`.
    public init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// Linear interpolation toward `other`; `amount` is clamped to `0...1`.
    public func mixed(with other: PofuRGB, amount: Double) -> PofuRGB {
        let t = amount.isNaN ? 0 : min(max(amount, 0), 1)
        return PofuRGB(
            red: red + (other.red - red) * t,
            green: green + (other.green - green) * t,
            blue: blue + (other.blue - blue) * t
        )
    }

    public var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

/// Brand palette from the character bible (docs/brand/character.md).
public enum PofuPalette {
    /// `pofu.body.thriving`: Pofu at full vitality.
    public static let lilac = PofuRGB(hex: 0xB9A2FF)
    /// `pofu.body.shade`: lower body shading.
    public static let violet = PofuRGB(hex: 0x8F74F0)
    /// `pofu.body.light`: top highlight.
    public static let lavenderMist = PofuRGB(hex: 0xE4DAFF)
    /// `pofu.body.wilted`: Pofu at zero vitality.
    public static let ashLilac = PofuRGB(hex: 0xA8A3B3)
    /// `pofu.cheek`: blush.
    public static let rose = PofuRGB(hex: 0xFF9EC1)
    /// `pofu.eye`: eyes, and the darkest ink of the brand.
    public static let ink = PofuRGB(hex: 0x1E1A2E)
    /// UI accent for text and controls on light backgrounds. Not a body
    /// color: lilac on white is 2.2:1, below WCAG AA, while this deep
    /// violet is 5.6:1. Dark mode uses lilac (7.8:1 on dark surfaces).
    public static let violetDeep = PofuRGB(hex: 0x6C4FD8)

    /// Pofu's body color for a vitality in `0...1`: ash lilac when wilted,
    /// lilac when thriving.
    public static func body(vitality: Double) -> PofuRGB {
        ashLilac.mixed(with: lilac, amount: vitality)
    }
}

/// Semantic colors for UI. Prefer these over raw palette values.
public enum PofuColor {
    /// The app accent, from the `AccentColor` asset (deep violet in light
    /// mode, lilac in dark mode).
    public static var accent: Color { .accentColor }
    public static var lilac: Color { PofuPalette.lilac.color }
    public static var lavenderMist: Color { PofuPalette.lavenderMist.color }
    public static var ink: Color { PofuPalette.ink.color }
    public static var rose: Color { PofuPalette.rose.color }

    /// Soft brand wash for backgrounds behind cards.
    public static var canvasGradient: LinearGradient {
        LinearGradient(
            colors: [PofuPalette.lavenderMist.color.opacity(0.55), Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
#endif
