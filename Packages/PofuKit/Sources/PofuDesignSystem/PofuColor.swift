#if canImport(SwiftUI)
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension PofuRGB {
    public var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

extension Color {
    /// A color that follows the system appearance.
    public static func pofuAdaptive(light: PofuRGB, dark: PofuRGB) -> Color {
        pofuAdaptive(light: light, lightOpacity: 1, dark: dark, darkOpacity: 1)
    }

    /// A translucent color that follows the system appearance, for ink that
    /// must read differently on cream and on night surfaces.
    public static func pofuAdaptive(light: PofuRGB, lightOpacity: Double, dark: PofuRGB, darkOpacity: Double) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let rgb = isDark ? dark : light
            return UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: isDark ? darkOpacity : lightOpacity)
        })
        #else
        // macOS is only a test host for the package; it gets light mode.
        return light.color.opacity(lightOpacity)
        #endif
    }

    /// The semantic token in the current appearance.
    public init(token: PofuSemanticColor) {
        self = Color.pofuAdaptive(light: token.light.rgb, dark: token.dark.rgb)
    }
}

/// Semantic colors for UI (docs/design/design-language.md, section 3).
/// Warm is the world; violet is the action.
public enum PofuColor {
    public static var canvas: Color { Color(token: .backgroundCanvas) }
    public static var sunken: Color { Color(token: .backgroundSunken) }
    public static var card: Color { Color(token: .surfaceCard) }
    public static var raised: Color { Color(token: .surfaceRaised) }
    public static var textPrimary: Color { Color(token: .textPrimary) }
    public static var textSecondary: Color { Color(token: .textSecondary) }
    public static var textTertiary: Color { Color(token: .textTertiary) }
    public static var onAccent: Color { Color(token: .textOnAccent) }
    public static var accent: Color { Color(token: .accent) }
    public static var accentPressed: Color { Color(token: .accentPressed) }
    public static var accentTint: Color { Color(token: .accentTint) }
    public static var success: Color { Color(token: .success) }
    public static var warning: Color { Color(token: .warning) }
    public static var energyFill: Color { Color(token: .energyFill) }
    public static var energyOnFill: Color { Color(token: .energyOnFill) }
    public static var blush: Color { Color(token: .decorBlush) }
    /// The stage disc behind Pofu on plain surfaces (blush-200).
    public static var stage: Color { PofuPrimitive.blush200.rgb.color }
    /// The core of the glow behind Pofu in a scene: a warm blush that lifts
    /// the cream belly off cream by day, and a faint ember by night, so it
    /// never reads as a plate on the dark room.
    public static var halo: Color {
        Color.pofuAdaptive(light: PofuPrimitive.blush200.rgb, lightOpacity: 0.85, dark: PofuPrimitive.blush500.rgb, darkOpacity: 0.2)
    }

    /// A soft radial glow of `halo` that falls off to nothing at `radius`.
    public static func haloGlow(radius: CGFloat) -> RadialGradient {
        RadialGradient(
            stops: [
                .init(color: halo, location: 0),
                .init(color: halo.opacity(0.7), location: 0.45),
                .init(color: halo.opacity(0.25), location: 0.75),
                .init(color: halo.opacity(0), location: 1),
            ],
            center: .center,
            startRadius: 0,
            endRadius: radius
        )
    }
    /// The 1 pt hairline on cards, chips, and bar edges: warm ink on cream,
    /// cream on night, so the edge stays visible in both appearances.
    public static var hairline: Color {
        Color.pofuAdaptive(light: PofuPrimitive.ink900.rgb, lightOpacity: 0.08, dark: PofuPrimitive.cream100.rgb, darkOpacity: 0.12)
    }
    /// Warm shadow ink: never black.
    public static var shadow: Color { PofuPrimitive.ink900.rgb.color }

    /// The warm wash behind Pofu's room and Hop! by day: cream at the top,
    /// a peach blush toward the floor.
    public static var dayWash: LinearGradient {
        LinearGradient(
            colors: [
                Color.pofuAdaptive(light: PofuPrimitive.cream100.rgb, dark: PofuPrimitive.night950.rgb),
                Color.pofuAdaptive(light: PofuPrimitive.blush200.rgb.mixed(with: PofuPrimitive.cream100.rgb, amount: 0.35), dark: PofuPrimitive.night900.rgb),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// The bedtime wash: deep plum to indigo, in both appearances.
    public static var nightWash: LinearGradient {
        LinearGradient(
            colors: [PofuPrimitive.night900.rgb.color, PofuRGB(hex: 0x2E2650).color],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
#endif
