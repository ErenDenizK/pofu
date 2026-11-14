#if canImport(SwiftUI)
import SwiftUI

/// Which plaque (UI v3 section 5): honey wood for the one action, cream
/// linen for its companion, a bare text-weight plaque for the quiet exit.
public enum PofuPlaqueKind: Sendable {
    case primary
    case secondary
    case quiet
}

/// The plaque button style: a carved plaque, not a system capsule.
///
/// - rest: a gradient face with a bevel, grain and a soft shadow;
/// - pressed: sinks 2 pt, 6 % darker, the shadow tightens, a 0.12 s
///   squash, and a soft haptic on release;
/// - disabled: bare unstained wood (never transparent), label at 60 %;
/// - focused: a 2 pt ring in ink and a warm glow;
/// - Increase Contrast: a flat fill with a solid 2 pt edge.
///
/// Text is always live text and the label reflows with Dynamic Type: the
/// plaque grows, it never clips.
public struct PofuPlaqueStyle: ButtonStyle {
    public var kind: PofuPlaqueKind
    /// Honey fills the plaque from the leading edge (the pause rung).
    public var progress: Double?
    /// The feeling played on release; `nil` plays none.
    public var haptic: PofuHapticName?

    public init(_ kind: PofuPlaqueKind = .primary, progress: Double? = nil, haptic: PofuHapticName? = .tap) {
        self.kind = kind
        self.progress = progress
        self.haptic = haptic
    }

    public func makeBody(configuration: Configuration) -> some View {
        PofuPlaqueBody(configuration: configuration, kind: kind, progress: progress, haptic: haptic)
    }
}

/// The styled button. A view of its own, so the environment (enabled,
/// focused, Reduce Motion, night, contrast) is read where it is true.
struct PofuPlaqueBody: View {
    let configuration: ButtonStyleConfiguration
    let kind: PofuPlaqueKind
    let progress: Double?
    let haptic: PofuHapticName?

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var focusedByFocus
    @Environment(\.pofuForcePressed) private var forcePressed
    @Environment(\.pofuForceFocused) private var forceFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let resolver = PofuKitStyleResolver(night: night, scheme: scheme, contrast: contrast)
        let palette = resolver.palette
        let pressed = configuration.isPressed || forcePressed
        let isFocused = focusedByFocus || forceFocused
        let shape = Capsule(style: .continuous)
        let isQuiet = kind == .quiet
        configuration.label
            .font(PofuFont.headline)
            .multilineTextAlignment(.center)
            .foregroundStyle(labelColor(palette, onPaintedFace: !resolver.isHighContrast && kind != .quiet && PofuPlaqueFace.art(kind: kind, enabled: isEnabled, pressed: pressed).isPainted))
            .padding(.horizontal, PofuSpacing.xl)
            .padding(.vertical, PofuSpacing.s)
            .frame(maxWidth: .infinity, minHeight: kind == .primary ? PofuSize.buttonHeight : PofuSize.minimumTouch + 4)
            .background {
                if !isQuiet {
                    PofuPlaqueFace(
                        kind: kind, palette: palette, pressed: pressed, enabled: isEnabled,
                        focused: isFocused, highContrast: resolver.isHighContrast, progress: progress
                    )
                    .shadow(color: palette.edge.opacity(isEnabled ? 0.3 : 0.1), radius: pressed ? 3 : 8, y: pressed ? 1.5 : 4)
                } else if isFocused {
                    shape.strokeBorder(palette.focus, lineWidth: 2)
                }
            }
            .overlay(alignment: .bottom) {
                if isQuiet {
                    // The swash draws under the label on press.
                    Capsule()
                        .fill(palette.onPaper)
                        .frame(height: 2)
                        .padding(.horizontal, PofuSpacing.xxl)
                        .padding(.bottom, PofuSpacing.s)
                        .scaleEffect(x: pressed ? 1 : 0.001, anchor: .leading)
                        .opacity(pressed ? 0.8 : 0)
                }
            }
            .offset(y: pressed && !reduceMotion ? 2 : 0)
            .scaleEffect(pressed && !reduceMotion ? 0.97 : 1)
            .animation(
                reduceMotion ? PofuMotion.reduced : (pressed ? Animation.easeOut(duration: 0.12) : PofuMotion.squish),
                value: pressed
            )
            .contentShape(shape)
            .onChange(of: pressed) { was, now in
                #if os(iOS)
                if was, !now, isEnabled, let haptic { PofuHaptics.shared.play(haptic) }
                #endif
            }
    }

    /// The painted plaques are all light (honey, cream, bare wood), so their label is ink at night too.
    private func labelColor(_ palette: PofuKitPalette, onPaintedFace: Bool) -> Color {
        let color: Color = onPaintedFace ? palette.ink : (kind == .quiet || kind == .secondary ? palette.onPaper : palette.ink)
        return isEnabled ? color : color.opacity(0.6)
    }
}

/// The plaque's face: the painted plaque when it is baked (a pressed face
/// falls back to the rest face, darkened), code-drawn otherwise.
struct PofuPlaqueFace: View {
    let kind: PofuPlaqueKind
    let palette: PofuKitPalette
    let pressed: Bool
    let enabled: Bool
    let focused: Bool
    let highContrast: Bool
    let progress: Double?

    var body: some View {
        let shape = Capsule(style: .continuous)
        ZStack {
            if focused, !highContrast, art.isPainted {
                // The ring follows the painted silhouette: its white shape, tinted and pushed out
                // in eight directions, under the face.
                focusRing
            }
            if highContrast {
                shape.fill(solid)
                shape.strokeBorder(palette.onPaper, lineWidth: 2)
            } else {
                PofuKitFace(art) {
                    drawn(shape)
                }
            }
            if focused, highContrast || !art.isPainted {
                shape.strokeBorder(palette.focus, lineWidth: 2)
                    .shadow(color: palette.glow.opacity(0.8), radius: 6)
            }
        }
        // Only the drawn face is clipped to a capsule: the painted plaque
        // keeps its own scalloped silhouette.
        .brightness(pressed ? -0.06 : 0)
        .compositingGroup()
    }

    private var art: PofuKitArt { Self.art(kind: kind, enabled: enabled, pressed: pressed) }

    static func art(kind: PofuPlaqueKind, enabled: Bool, pressed: Bool) -> PofuKitArt {
        guard enabled else { return .plaqueBare }
        switch kind {
        case .primary: return pressed ? .plaqueHoneyPressed : .plaqueHoney
        case .secondary, .quiet: return pressed ? .plaqueCreamPressed : .plaqueCream
        }
    }

    /// A 2.5 pt ring that follows the painted plaque, with a warm glow.
    private var focusRing: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { step in
                let angle = Double(step) * .pi / 4
                PofuKitFace(art) { EmptyView() }
                    .brightness(1)
                    .colorMultiply(palette.focus)
                    .offset(x: CGFloat(cos(angle)) * 2.5, y: CGFloat(sin(angle)) * 2.5)
            }
        }
        .shadow(color: palette.glow.opacity(0.8), radius: 6)
        .allowsHitTesting(false)
    }

    private var solid: Color {
        guard enabled else { return palette.woodTop }
        return kind == .primary ? palette.honey : palette.cream
    }

    private var colors: [Color] {
        guard enabled else { return [palette.woodTop, palette.woodBottom] }
        switch kind {
        case .primary: return [palette.honeyTop, palette.honey, palette.honeyBottom]
        case .secondary, .quiet: return [palette.creamTop, palette.cream, palette.creamBottom]
        }
    }

    private func drawn(_ shape: Capsule) -> some View {
        ZStack(alignment: .leading) {
            shape.fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            if let progress, enabled {
                GeometryReader { proxy in
                    Rectangle()
                        .fill(LinearGradient(colors: [palette.honeyTop, palette.honey, palette.honeyBottom], startPoint: .top, endPoint: .bottom))
                        .frame(width: proxy.size.width * min(max(progress, 0), 1))
                }
            }
            PofuGrainOverlay(opacity: enabled ? 0.07 : 0.12)
            // The carved bevel: a soft cocoa rim pushed down, a bright top
            // edge, and a fine dark line under the lip.
            shape.pofuInnerShadow(palette.edge.opacity(palette.isNight ? 0.35 : 0.2))
            shape.strokeBorder(
                LinearGradient(colors: [.white.opacity(palette.isNight ? 0.25 : 0.85), palette.edge.opacity(0.18)], startPoint: .top, endPoint: .bottom),
                lineWidth: 1.5
            )
        }
        .clipShape(shape)
    }
}

/// A plaque with its reason: a disabled plaque says why, on the wood
/// below it (UI v3 principle 8: never a dead state).
public struct PofuPlaqueButton: View {
    let title: LocalizedStringKey
    let kind: PofuPlaqueKind
    let reason: LocalizedStringKey?
    let isDisabled: Bool
    let haptic: PofuHapticName?
    let action: () -> Void

    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme

    public init(
        _ title: LocalizedStringKey,
        kind: PofuPlaqueKind = .primary,
        reason: LocalizedStringKey? = nil,
        isDisabled: Bool = false,
        haptic: PofuHapticName? = .tap,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.kind = kind
        self.reason = reason
        self.isDisabled = isDisabled
        self.haptic = haptic
        self.action = action
    }

    public var body: some View {
        let palette = PofuKitStyleResolver(night: night, scheme: scheme, contrast: .standard).palette
        VStack(spacing: PofuSpacing.xs) {
            Button(action: action) {
                Text(title)
            }
            .buttonStyle(PofuPlaqueStyle(kind, haptic: haptic))
            .disabled(isDisabled)
            if isDisabled, let reason {
                Text(reason)
                    .font(PofuFont.footnote)
                    .foregroundStyle(palette.isNight ? palette.onPaper.opacity(0.8) : palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
#endif
