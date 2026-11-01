/// An sRGB color value. Tokens are plain numbers so they can be mixed and
/// compared in tests, on any platform.
public struct PofuRGB: Hashable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Creates a color from a 24-bit hex value such as `0x6C4FD8`.
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
}

/// The color primitives of `design/tokens/pofu-tokens.json`, ported by
/// hand. `PofuDesignSystemTests` fails if they drift from the file.
/// Use semantic tokens (`PofuSemanticColor`) in UI code.
public enum PofuPrimitive: String, CaseIterable, Sendable {
    case cream50 = "cream-50"
    case cream100 = "cream-100"
    case cream200 = "cream-200"
    case cream300 = "cream-300"
    case peach300 = "peach-300"
    case peach400 = "peach-400"
    case peach600 = "peach-600"
    case peach800 = "peach-800"
    case blush200 = "blush-200"
    case blush400 = "blush-400"
    case blush500 = "blush-500"
    case ink900 = "ink-900"
    case ink700 = "ink-700"
    case ink600 = "ink-600"
    case ink400 = "ink-400"
    case ink300 = "ink-300"
    case violet100 = "violet-100"
    case violet300 = "violet-300"
    case violet500 = "violet-500"
    case violet600 = "violet-600"
    case violet700 = "violet-700"
    case meadow300 = "meadow-300"
    case meadow400 = "meadow-400"
    case meadow700 = "meadow-700"
    case honey300 = "honey-300"
    case honey400 = "honey-400"
    case honey800 = "honey-800"
    case rose300 = "rose-300"
    case rose700 = "rose-700"
    case night950 = "night-950"
    case night900 = "night-900"
    case night800 = "night-800"
    case night700 = "night-700"
    case mist300 = "mist-300"
    case mist500 = "mist-500"
    case violetNight200 = "violet-night-200"
    case white = "white"

    public var hex: UInt32 {
        switch self {
        case .cream50: 0xFFFBF5
        case .cream100: 0xFFF6EC
        case .cream200: 0xFBEBDD
        case .cream300: 0xF3DCC8
        case .peach300: 0xF4C7A4
        case .peach400: 0xECA96E
        case .peach600: 0xD69069
        case .peach800: 0x8A4F2B
        case .blush200: 0xFDD9CF
        case .blush400: 0xFDC1B0
        case .blush500: 0xF6A290
        case .ink900: 0x2A1F2D
        case .ink700: 0x4A3B4A
        case .ink600: 0x66555F
        case .ink400: 0x8E7D88
        case .ink300: 0xA99AA3
        case .violet100: 0xEEE8FF
        case .violet300: 0xB9A2FF
        case .violet500: 0x8F74F0
        case .violet600: 0x6C4FD8
        case .violet700: 0x553BB8
        case .meadow300: 0x8FD4A4
        case .meadow400: 0x8CC084
        case .meadow700: 0x2F7349
        case .honey300: 0xF7C873
        case .honey400: 0xF5B83D
        case .honey800: 0x8A5A00
        case .rose300: 0xFF9EB5
        case .rose700: 0xB23A5A
        case .night950: 0x15111C
        case .night900: 0x1E1828
        case .night800: 0x2A2236
        case .night700: 0x3A3048
        case .mist300: 0xB8A8B1
        case .mist500: 0x85768A
        case .violetNight200: 0x2E2547
        case .white: 0xFFFFFF
        }
    }

    public var rgb: PofuRGB {
        PofuRGB(hex: hex)
    }
}

/// The semantic color tokens of `design/tokens/pofu-tokens.json`: each
/// names a role and maps to one primitive in light mode and one in dark
/// mode. Dark mode is a night meadow, not inverted light mode.
public enum PofuSemanticColor: String, CaseIterable, Sendable {
    case backgroundCanvas = "background.canvas"
    case backgroundSunken = "background.sunken"
    case surfaceCard = "surface.card"
    case surfaceRaised = "surface.raised"
    case textPrimary = "text.primary"
    case textSecondary = "text.secondary"
    case textTertiary = "text.tertiary"
    case textOnAccent = "text.onAccent"
    case accent = "accent"
    case accentPressed = "accent.pressed"
    case accentTint = "accent.tint"
    case success = "success"
    case warning = "warning"
    case critical = "critical"
    case energyFill = "energy.fill"
    case energyOnFill = "energy.onFill"
    case decorBlush = "decor.blush"
    case decorPeach = "decor.peach"

    public var light: PofuPrimitive {
        switch self {
        case .backgroundCanvas: .cream100
        case .backgroundSunken: .cream200
        case .surfaceCard: .cream50
        case .surfaceRaised: .white
        case .textPrimary: .ink900
        case .textSecondary: .ink600
        case .textTertiary: .ink400
        case .textOnAccent: .white
        case .accent: .violet600
        case .accentPressed: .violet700
        case .accentTint: .violet100
        case .success: .meadow700
        case .warning: .honey800
        case .critical: .rose700
        case .energyFill: .honey400
        case .energyOnFill: .ink900
        case .decorBlush: .blush400
        case .decorPeach: .peach400
        }
    }

    public var dark: PofuPrimitive {
        switch self {
        case .backgroundCanvas: .night950
        case .backgroundSunken: .night950
        case .surfaceCard: .night900
        case .surfaceRaised: .night800
        case .textPrimary: .cream100
        case .textSecondary: .mist300
        case .textTertiary: .mist500
        case .textOnAccent: .night950
        case .accent: .violet300
        case .accentPressed: .violet500
        case .accentTint: .violetNight200
        case .success: .meadow300
        case .warning: .honey300
        case .critical: .rose300
        case .energyFill: .honey400
        case .energyOnFill: .ink900
        case .decorBlush: .blush500
        case .decorPeach: .peach300
        }
    }
}
