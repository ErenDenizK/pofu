#if canImport(SwiftUI)
import SwiftUI

/// Spacing scale on a 4-point grid.
public enum PofuSpacing {
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 48
}

/// Corner radii. Pofu is soft, so the scale leans round; always use with
/// `.continuous` corners.
public enum PofuRadius {
    public static let small: CGFloat = 10
    public static let medium: CGFloat = 16
    public static let large: CGFloat = 24
    public static let extraLarge: CGFloat = 32
}

/// Type styles. All are built on Dynamic Type text styles, so they scale
/// with the user's settings; rounded design matches Pofu's softness.
public enum PofuFont {
    public static var display: Font { .system(.largeTitle, design: .rounded, weight: .bold) }
    public static var title: Font { .system(.title2, design: .rounded, weight: .semibold) }
    public static var headline: Font { .system(.headline, design: .rounded, weight: .semibold) }
    public static var body: Font { .system(.body, design: .rounded) }
    public static var caption: Font { .system(.footnote, design: .rounded) }
    /// Large numerals, such as the energy balance.
    public static var numeral: Font { .system(.largeTitle, design: .rounded, weight: .heavy).monospacedDigit() }
}

/// Motion presets. Pofu moves on springs, never on linear or eased curves
/// (docs/brand/character.md, "Motion language").
public enum PofuMotion {
    /// A tap or a landing: quick and bouncy.
    public static var squish: Animation { .spring(duration: 0.28, bounce: 0.45) }
    /// A state change settling into place.
    public static var settle: Animation { .spring(duration: 0.5, bounce: 0.2) }
    /// Slow, calm transitions such as mood shifts.
    public static var gentle: Animation { .spring(duration: 0.9, bounce: 0.1) }
    /// UI feedback that must not wobble.
    public static var snappy: Animation { .spring(duration: 0.25, bounce: 0) }
}

/// The standard content card: generous padding on a soft material.
public struct PofuCardStyle: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .padding(PofuSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: PofuRadius.large, style: .continuous)
            )
    }
}

extension View {
    /// Wraps the view in Pofu's standard card.
    public func pofuCard() -> some View {
        modifier(PofuCardStyle())
    }
}
#endif
