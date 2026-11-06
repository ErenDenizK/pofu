#if canImport(SwiftUI)
import SwiftUI

// Core components of the design language (section 14). Controls are native
// SwiftUI shapes and tokens, never painted.

/// The one primary action of a screen: an accent capsule, 52 pt tall.
public struct PofuPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PofuFont.headline)
            .multilineTextAlignment(.center)
            .foregroundStyle(PofuColor.onAccent)
            .padding(.horizontal, PofuSpacing.xl)
            .frame(maxWidth: .infinity, minHeight: PofuSize.buttonHeight)
            .background { face(pressed: configuration.isPressed) }
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(PofuMotion.respecting(reduceMotion, PofuMotion.squish), value: configuration.isPressed)
            .contentShape(Capsule(style: .continuous))
    }

    /// The painted primary face (a violet pill), or the accent capsule when
    /// the bundle lacks it.
    @ViewBuilder
    private func face(pressed: Bool) -> some View {
        #if canImport(UIKit)
        PofuPaintedFace(.facePrimary)
            .brightness(pressed ? -0.08 : 0)
            .shadow(color: PofuColor.accent.opacity(isEnabled ? 0.28 : 0), radius: 14, y: 6)
        #else
        Capsule(style: .continuous)
            .fill(pressed ? PofuColor.accentPressed : PofuColor.accent)
            .shadow(color: PofuColor.accent.opacity(isEnabled ? 0.28 : 0), radius: 14, y: 6)
        #endif
    }
}

/// A plainly labeled, quieter action: a raised capsule with ink text. Used
/// for "Open for 5 min" in Hop!, one step below the primary. With a
/// `progress`, the capsule fills from the leading edge like a progress bar
/// (the pause rung's breath).
public struct PofuQuietButtonStyle: ButtonStyle {
    public var progress: Double?

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(progress: Double? = nil) {
        self.progress = progress
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PofuFont.headline)
            .multilineTextAlignment(.center)
            .foregroundStyle(isEnabled ? PofuColor.textPrimary : PofuColor.textTertiary)
            .padding(.horizontal, PofuSpacing.xl)
            .frame(maxWidth: .infinity, minHeight: PofuSize.buttonHeight)
            .background {
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(PofuColor.raised.opacity(configuration.isPressed ? 0.7 : 0.92))
                    if let progress {
                        GeometryReader { proxy in
                            Rectangle()
                                .fill(PofuColor.accentTint)
                                .frame(width: proxy.size.width * min(max(progress, 0), 1))
                        }
                    }
                }
                .clipShape(Capsule(style: .continuous))
            }
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(PofuColor.hairline, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(PofuMotion.respecting(reduceMotion, PofuMotion.squish), value: configuration.isPressed)
            .contentShape(Capsule(style: .continuous))
    }
}

/// A secondary action: accent tint with an accent label.
public struct PofuSecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PofuFont.headline)
            .foregroundStyle(PofuColor.accent)
            .padding(.horizontal, PofuSpacing.l)
            .frame(minWidth: PofuSize.minimumTouch, minHeight: PofuSize.minimumTouch)
            .background(Capsule(style: .continuous).fill(PofuColor.accentTint))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(PofuMotion.respecting(reduceMotion, PofuMotion.squish), value: configuration.isPressed)
            .contentShape(Capsule(style: .continuous))
    }
}

/// The quietest action: an accent label with no fill, at least 44 pt tall.
/// One shared look for every "text button" (a skip, a later, a close), so
/// no screen hand-rolls its own.
public struct PofuTextButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PofuFont.headline)
            .multilineTextAlignment(.center)
            .foregroundStyle(isEnabled ? PofuColor.accent : PofuColor.textTertiary)
            .padding(.horizontal, PofuSpacing.l)
            .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .contentShape(Rectangle())
    }
}

/// A selectable chip or card. Selected: accent tint, accent label, and a
/// heavier accent border, so selection never relies on color alone (the
/// caller adds a checkmark where the content allows it).
public struct PofuChoiceStyle: ButtonStyle {
    public var isSelected: Bool
    public var cornerRadius: CGFloat

    @Environment(\.isEnabled) private var isEnabled

    public init(isSelected: Bool, cornerRadius: CGFloat = PofuRadius.medium) {
        self.isSelected = isSelected
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return configuration.label
            .font(PofuFont.subheadline)
            .foregroundStyle(isSelected ? PofuColor.accent : (isEnabled ? PofuColor.textPrimary : PofuColor.textTertiary))
            .padding(.horizontal, PofuSpacing.m)
            .padding(.vertical, PofuSpacing.s)
            .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch)
            .background(shape.fill(isSelected ? PofuColor.accentTint : PofuColor.raised))
            .overlay(
                shape.strokeBorder(
                    isSelected ? PofuColor.accent : PofuColor.hairline,
                    lineWidth: isSelected ? 2 : 1
                )
            )
            .opacity(configuration.isPressed ? 0.75 : (isEnabled ? 1 : 0.6))
            .contentShape(shape)
    }
}

/// The sunflower seed: the currency's glyph, drawn as a vector so it scales
/// and tints like a symbol.
public struct SeedGlyph: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        // A teardrop leaning right, pointed at the top.
        let width = rect.width
        let height = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + width * 0.62, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX + width * 0.38, y: rect.maxY),
            control1: CGPoint(x: rect.minX + width * 1.08, y: rect.minY + height * 0.32),
            control2: CGPoint(x: rect.minX + width * 0.92, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + width * 0.62, y: rect.minY),
            control1: CGPoint(x: rect.minX - width * 0.12, y: rect.maxY - height * 0.04),
            control2: CGPoint(x: rect.minX + width * 0.12, y: rect.minY + height * 0.36)
        )
        path.closeSubpath()
        return path
    }
}

/// The seed glyph with its stripes, sized like an inline symbol.
public struct SeedIcon: View {
    public var size: CGFloat

    public init(size: CGFloat = 16) {
        self.size = size
    }

    public var body: some View {
        #if canImport(UIKit)
        if PofuPaint.iconSeed.isAvailable {
            PofuPaintedIcon(.iconSeed, size: size * 1.2, scales: false)
        } else {
            drawn
        }
        #else
        drawn
        #endif
    }

    private var drawn: some View {
        ZStack {
            SeedGlyph()
                .fill(PofuColor.energyOnFill.opacity(0.85))
            SeedGlyph()
                .stroke(PofuColor.energyFill.opacity(0.9), lineWidth: max(1, size * 0.07))
                .scaleEffect(x: 0.38, y: 0.82)
        }
        .frame(width: size * 0.62, height: size)
        .rotationEffect(.degrees(18))
        .accessibilityHidden(true)
    }
}

/// The energy pill: honey capsule, seed glyph, and an ink numeral.
public struct SeedPill: View {
    public var count: Int

    @ScaledMetric(relativeTo: .headline) private var glyphSize: CGFloat = 16

    public init(count: Int) {
        self.count = count
    }

    public var body: some View {
        HStack(spacing: PofuSpacing.s) {
            SeedIcon(size: glyphSize)
            Text(count, format: .number)
                .font(PofuFont.headline.monospacedDigit())
                .contentTransition(.numericText(value: Double(count)))
        }
        .foregroundStyle(PofuColor.energyOnFill)
        .padding(.horizontal, PofuSpacing.m)
        .frame(minHeight: PofuSize.minimumTouch)
        .background(Capsule(style: .continuous).fill(PofuColor.energyFill))
    }
}

/// Pofu's speech bubble: a solid card with a tail toward Pofu below it.
public struct SpeechBubble<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .font(PofuFont.headline)
            .foregroundStyle(PofuColor.textPrimary)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .padding(.horizontal, PofuSpacing.l)
            .padding(.vertical, PofuSpacing.m)
            .background(
                BubbleShape()
                    .fill(PofuColor.raised)
                    .shadow(color: PofuColor.shadow.opacity(0.1), radius: 12, y: 8)
            )
            .padding(.bottom, BubbleShape.tailHeight)
    }
}

/// A rounded rectangle with a small tail centered on its bottom edge.
struct BubbleShape: Shape {
    static let tailHeight: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: PofuRadius.large, style: .continuous)
        let tail = Self.tailHeight
        path.move(to: CGPoint(x: rect.midX - tail, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY + tail),
            control: CGPoint(x: rect.midX - tail * 0.2, y: rect.maxY + tail * 0.2)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX + tail, y: rect.maxY),
            control: CGPoint(x: rect.midX + tail * 0.2, y: rect.maxY + tail * 0.2)
        )
        path.closeSubpath()
        return path
    }
}

/// A row of beads, one per reach: filled when skipped, an empty ring when
/// opened. Shape tells them apart, not only color.
public struct BeadRow: View {
    public var skipped: [Bool]
    public var beadSize: CGFloat

    public init(skipped: [Bool], beadSize: CGFloat = 18) {
        self.skipped = skipped
        self.beadSize = beadSize
    }

    public var body: some View {
        // Wraps onto more lines on busy days instead of shrinking.
        BeadLayout(spacing: beadSize * 0.45) {
            ForEach(Array(skipped.enumerated()), id: \.offset) { item in
                Group {
                    if item.element {
                        Circle().fill(PofuColor.accent)
                    } else {
                        Circle().strokeBorder(PofuColor.textTertiary, lineWidth: 2)
                    }
                }
                .frame(width: beadSize, height: beadSize)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .accessibilityHidden(true)
    }
}

/// A minimal flow layout for beads.
struct BeadLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: widest, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
#endif
