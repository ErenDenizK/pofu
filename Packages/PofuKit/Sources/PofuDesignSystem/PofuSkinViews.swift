#if os(iOS)
import SwiftUI

// The views of the skin switch (UI system v2 §3 and §4): the four
// over-world chrome roles drawn as Liquid Glass or as crafted clay and
// paper. Behaviour is always a native `Button`; only the material changes.
// The crafted faces are clean vector stand-ins until the painted 9-slice
// faces land (`PofuCraftedAsset.isPainted`).

// MARK: - Environment

private struct PofuSkinKey: EnvironmentKey {
    static let defaultValue: PofuSkin = .glass
}

extension EnvironmentValues {
    /// The skin of the over-world chrome. Set once at the root from
    /// `PofuSkinPolicy`; views never read the policy themselves. Reduce
    /// Transparency overrides it where the faces are drawn.
    public var pofuSkin: PofuSkin {
        get { self[PofuSkinKey.self] }
        set { self[PofuSkinKey.self] = newValue }
    }
}

/// The crafted faces that have a painted master. One switch per asset: an
/// asset stays a vector stand-in until the pipeline slices its master into
/// the catalog and it is listed here.
public enum PofuCraftedAsset: String, CaseIterable, Sendable {
    case primaryFace
    case secondaryFace
    case disc
    case tagPaper
    case panelPaper

    /// No painted face is in the asset catalog yet.
    public var isPainted: Bool {
        false
    }
}

// MARK: - Crafted palette

enum PofuCraftedPalette {
    static var paper: Color {
        Color.pofuAdaptive(light: PofuPrimitive.cream100.rgb, dark: PofuPrimitive.night800.rgb)
    }

    static var paperEdge: Color {
        Color.pofuAdaptive(light: PofuPrimitive.peach300.rgb, dark: PofuPrimitive.night700.rgb)
    }

    static var stitch: Color {
        Color.pofuAdaptive(light: PofuPrimitive.peach600.rgb, dark: PofuPrimitive.cocoaNight200.rgb)
    }

    static var clayTop: Color {
        Color.pofuAdaptive(light: PofuPrimitive.cream50.rgb, dark: PofuPrimitive.night700.rgb)
    }

    static var clayBottom: Color {
        Color.pofuAdaptive(light: PofuPrimitive.cream300.rgb, dark: PofuPrimitive.night800.rgb)
    }

    static var clayLip: Color {
        Color.pofuAdaptive(light: PofuPrimitive.peach400.rgb, dark: PofuPrimitive.night950.rgb)
    }

    // The one verb colour: honey wood with cocoa ink (UI v3 section 1).
    static var honeyTop: Color { PofuKitPalette.day.honeyTop }
    static var honeyBottom: Color { PofuKitPalette.day.honeyBottom }
    static var honeyLip: Color { PofuPrimitive.honey800.rgb.color }
    static var cocoaInk: Color { PofuKitPalette.day.ink }

    /// The label on a cream face.
    static var onFace: Color {
        Color.pofuAdaptive(light: PofuPrimitive.ink900.rgb, dark: PofuPrimitive.cream100.rgb)
    }
}

/// A glazed clay face: a soft top light, a darker lip below.
struct PofuClayFace<S: InsettableShape>: View {
    let shape: S
    let top: Color
    let bottom: Color
    let lip: Color

    var body: some View {
        shape
            .fill(LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom))
            .overlay {
                shape.strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: lip, radius: 0, y: 3)
    }
}

// MARK: - Press feedback

/// Scale on press for round icon buttons, keeping the system button's hit
/// testing and haptics.
struct PofuPressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(PofuMotion.snappy, value: configuration.isPressed)
    }
}

// MARK: - Action buttons

/// The two weights of an action over the world.
public enum PofuActionWeight: Sendable {
    case primary
    case secondary
}

struct PofuCraftedActionStyle: ButtonStyle {
    let weight: PofuActionWeight
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let isPrimary = weight == .primary
        configuration.label
            .font(PofuFont.headline)
            .foregroundStyle(isPrimary ? PofuCraftedPalette.cocoaInk : PofuCraftedPalette.onFace)
            .padding(.horizontal, PofuSpacing.l)
            .frame(minHeight: PofuSize.minimumTouch)
            .background {
                PofuClayFace(
                    shape: Capsule(style: .continuous),
                    top: isPrimary ? PofuCraftedPalette.honeyTop : PofuCraftedPalette.clayTop,
                    bottom: isPrimary ? PofuCraftedPalette.honeyBottom : PofuCraftedPalette.clayBottom,
                    lip: isPrimary ? PofuCraftedPalette.honeyLip : PofuCraftedPalette.clayLip
                )
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed && !isPrimary ? -0.08 : 0)
            .saturation(isEnabled ? 1 : 0.4)
            .opacity(isEnabled ? 1 : 0.55)
            .animation(PofuMotion.snappy, value: configuration.isPressed)
    }
}

private struct PofuActionStyleModifier: ViewModifier {
    let weight: PofuActionWeight
    @Environment(\.pofuSkin) private var skin
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ViewBuilder
    func body(content: Content) -> some View {
        if PofuSkinPolicy.effective(skin, reduceTransparency: reduceTransparency) == .glass {
            if weight == .primary {
                content.foregroundStyle(PofuKitPalette.day.ink).buttonStyle(.glassProminent).tint(PofuKitPalette.day.honey)
            } else {
                content.buttonStyle(.glass)
            }
        } else {
            content.buttonStyle(PofuCraftedActionStyle(weight: weight))
        }
    }
}

// MARK: - Icon button

/// A system verb over the world (settings, map): an SF Symbol in a 44 pt
/// glass circle or on a clay disc. Never a painted symbol.
public struct PofuIconButton: View {
    public let systemName: String
    public let label: String
    /// A painted icon drawn in place of the symbol (the map's island).
    public let paint: PofuPaint?
    public let action: @MainActor () -> Void

    @Environment(\.pofuSkin) private var skin
    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = PofuSize.minimumTouch

    public init(systemName: String, label: String, paint: PofuPaint? = nil, action: @escaping @MainActor () -> Void) {
        self.systemName = systemName
        self.label = label
        self.paint = paint
        self.action = action
    }

    public var body: some View {
        let size = min(max(diameter, PofuSize.minimumTouch), 52)
        Button(action: action) {
            symbol
                .frame(width: size, height: size)
                .modifier(PofuChromeSurface(role: .iconButton))
                .contentShape(Circle())
        }
        .buttonStyle(PofuPressScaleStyle())
        .accessibilityLabel(Text(verbatim: label))
    }

    @ViewBuilder
    private var symbol: some View {
        #if canImport(UIKit)
        if let paint, paint.isAvailable {
            // Day: the glyph's cream fill sits on a cream disc, so it gets a heavier cocoa line.
            let palette = PofuKitStyleResolver(night: night, scheme: scheme, contrast: .standard).palette
            PofuPaintedIcon(paint, size: 30, outline: PofuKitArt.discClay.isPainted && !palette.isNight ? palette.onPaper : nil)
        } else {
            symbolImage
        }
        #else
        symbolImage
        #endif
    }

    private var symbolImage: some View {
        Image(systemName: systemName)
            .font(PofuFont.title3)
            .foregroundStyle(skinIsGlass ? PofuColor.textPrimary : PofuCraftedPalette.onFace)
    }

    private var skinIsGlass: Bool {
        PofuSkinPolicy.effective(skin, reduceTransparency: reduceTransparency) == .glass
    }
}

// MARK: - Surfaces (tag, glance, icon disc)

/// The surface of a non-button chrome role.
struct PofuChromeSurface: ViewModifier {
    let role: PofuChromeRole

    @Environment(\.pofuSkin) private var skin
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ViewBuilder
    func body(content: Content) -> some View {
        if role == .iconButton, PofuKitArt.discClay.isPainted {
            // One round button (asset system v1 section 2.3): the clay disc
            // in either skin, never a glass circle.
            content.background { PofuClayDisc() }
        } else if role == .glance, PofuKitArt.cardLinen.isPainted {
            // The glance is a stat: the linen card, in either skin.
            content.background { PofuPaperSurface(kind: .linen) }
        } else if PofuSkinPolicy.effective(skin, reduceTransparency: reduceTransparency) == .glass {
            switch role {
            case .iconButton:
                content.glassEffect(.regular.interactive(), in: Circle())
            case .worldTag:
                content.glassEffect(.regular, in: Capsule(style: .continuous))
            case .glance:
                content
                    .background {
                        // The legibility plate (UI system v2 §3, L3): a soft
                        // cream halo so glass reads over a busy island lip.
                        Capsule(style: .continuous)
                            .fill(PofuColor.canvas.opacity(0.48))
                            .blur(radius: 14)
                            .padding(-12)
                            .allowsHitTesting(false)
                    }
                    .glassEffect(.regular, in: Capsule(style: .continuous))
            case .primaryAction, .secondaryAction:
                content
            }
        } else {
            switch role {
            case .iconButton:
                content.background {
                    PofuClayFace(
                        shape: Circle(),
                        top: PofuCraftedPalette.clayTop,
                        bottom: PofuCraftedPalette.clayBottom,
                        lip: PofuCraftedPalette.clayLip
                    )
                }
            case .worldTag:
                content.background { PaperTag() }
            case .glance:
                content.background { PaperStrip() }
            case .primaryAction, .secondaryAction:
                content
            }
        }
    }
}

/// The one round button's face: the painted clay disc, day or night
/// (`pofuNight`), under a duo glyph. Increase Contrast gets a flat disc
/// with a solid edge; without the painted disc, the code-drawn clay.
public struct PofuClayDisc: View {
    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    public init() {}

    public var body: some View {
        let resolver = PofuKitStyleResolver(night: night, scheme: scheme, contrast: contrast)
        let palette = resolver.palette
        if resolver.isHighContrast {
            Circle()
                .fill(palette.cream)
                .overlay { Circle().strokeBorder(palette.onPaper, lineWidth: 2) }
        } else {
            PofuKitFace(resolver.isNight ? .discClayNight : .discClay) {
                PofuClayFace(
                    shape: Circle(),
                    top: PofuCraftedPalette.clayTop,
                    bottom: PofuCraftedPalette.clayBottom,
                    lip: PofuCraftedPalette.clayLip
                )
            }
            .shadow(color: palette.edge.opacity(palette.isNight ? 0.45 : 0.16), radius: 5, y: 3)
        }
    }
}

/// A cream paper tag with a punched hole at its leading end.
private struct PaperTag: View {
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
        shape
            .fill(PofuCraftedPalette.paper)
            .overlay { shape.strokeBorder(PofuCraftedPalette.paperEdge, lineWidth: 1) }
            .overlay(alignment: .leading) {
                Circle()
                    .fill(PofuCraftedPalette.paperEdge)
                    .frame(width: 5, height: 5)
                    .padding(.leading, 6)
            }
            .shadow(color: PofuColor.shadow.opacity(0.15), radius: 2, y: 1)
    }
}

/// A cream paper strip with a stitched inset edge.
private struct PaperStrip: View {
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        shape
            .fill(PofuCraftedPalette.paper)
            .overlay { shape.strokeBorder(PofuCraftedPalette.paperEdge, lineWidth: 1) }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(PofuCraftedPalette.stitch.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .padding(4)
            }
            .shadow(color: PofuColor.shadow.opacity(0.18), radius: 4, y: 2)
    }
}

extension View {
    /// The action over the world: `.glassProminent` or a honey clay
    /// capsule for the primary, `.glass` or cream clay for the secondary.
    public func pofuActionStyle(_ weight: PofuActionWeight = .primary) -> some View {
        modifier(PofuActionStyleModifier(weight: weight))
    }

    /// The surface of a world tag or the glance, per the skin.
    public func pofuChrome(_ role: PofuChromeRole) -> some View {
        modifier(PofuChromeSurface(role: role))
    }
}
#endif
