#if canImport(SwiftUI)
import SwiftUI

/// Spacing scale on a 4-point grid.
public enum PofuSpacing {
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    /// The standard screen margin (iOS readable margin).
    public static let screen: CGFloat = 20
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

/// Sizes that are part of the component specs.
public enum PofuSize {
    /// Primary and secondary buttons.
    public static let buttonHeight: CGFloat = 52
    /// Chips.
    public static let chipHeight: CGFloat = 32
    /// The smallest touch target.
    public static let minimumTouch: CGFloat = 44
}

/// The type scale of the design language (section 4), on SF Pro Rounded.
/// Every style is built on a Dynamic Type text style, so it scales with the
/// user's settings. Display tiers use SF Pro Rounded Heavy until Baloo 2 is
/// bundled with corrected metrics.
public enum PofuFont {
    public static var largeTitle: Font { .system(.largeTitle, design: .rounded, weight: .heavy) }
    public static var title: Font { .system(.title, design: .rounded, weight: .bold) }
    public static var title2: Font { .system(.title2, design: .rounded, weight: .bold) }
    public static var title3: Font { .system(.title3, design: .rounded, weight: .semibold) }
    public static var headline: Font { .system(.headline, design: .rounded, weight: .semibold) }
    public static var body: Font { .system(.body, design: .rounded) }
    public static var callout: Font { .system(.callout, design: .rounded) }
    public static var subheadline: Font { .system(.subheadline, design: .rounded, weight: .medium) }
    public static var footnote: Font { .system(.footnote, design: .rounded) }
    public static var caption: Font { .system(.caption, design: .rounded, weight: .medium) }
    /// Large numerals, such as the seed balance and timers.
    public static var numeral: Font { .system(.largeTitle, design: .rounded, weight: .heavy).monospacedDigit() }
}

/// The display tier: the Hop! headline and celebration lines. Scales with
/// Dynamic Type relative to `.largeTitle`, capped at twice its base size so
/// a one-word headline never pushes the skip action off screen.
public struct PofuDisplayFont: ViewModifier {
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat
    private let base: CGFloat

    public init(size: CGFloat = 56) {
        self.base = size
        self._size = ScaledMetric(wrappedValue: size, relativeTo: .largeTitle)
    }

    public func body(content: Content) -> some View {
        content.font(.system(size: min(size, base * 2), weight: .heavy, design: .rounded))
    }
}

extension View {
    /// Sets the display font (design language, section 4).
    public func pofuDisplayFont(size: CGFloat = 56) -> some View {
        modifier(PofuDisplayFont(size: size))
    }
}

/// Motion presets. Pofu moves on springs, never on linear or eased curves
/// (design language, section 10).
public enum PofuMotion {
    /// A tap or a landing: quick and bouncy.
    public static var squish: Animation { .spring(duration: 0.28, bounce: 0.45) }
    /// A state change settling into place.
    public static var settle: Animation { .spring(duration: 0.5, bounce: 0.2) }
    /// Slow, calm transitions such as mood shifts.
    public static var gentle: Animation { .spring(duration: 0.9, bounce: 0.1) }
    /// Chrome and UI feedback that must not wobble.
    public static var snappy: Animation { .spring(duration: 0.25, bounce: 0) }
    /// Stickers, badges, and seeds hopping.
    public static var hop: Animation { .spring(duration: 0.42, bounce: 0.35) }
    /// Badge reveals and counters landing.
    public static var pop: Animation { .spring(duration: 0.55, bounce: 0.5) }
    /// What Reduce Motion gets instead of springs: a 200 ms cross-fade.
    public static var reduced: Animation { .easeInOut(duration: 0.2) }

    /// `animation`, or the reduced cross-fade when Reduce Motion is on.
    public static func respecting(_ reduceMotion: Bool, _ animation: Animation) -> Animation {
        reduceMotion ? reduced : animation
    }
}

/// The standard content card: `surface.card`, radius 24, elevation 1.
public struct PofuCardStyle: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .padding(PofuSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: PofuRadius.large, style: .continuous)
                    .fill(PofuColor.card)
                    .shadow(color: PofuColor.shadow.opacity(0.06), radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PofuRadius.large, style: .continuous)
                    .strokeBorder(PofuColor.shadow.opacity(0.05), lineWidth: 1)
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
