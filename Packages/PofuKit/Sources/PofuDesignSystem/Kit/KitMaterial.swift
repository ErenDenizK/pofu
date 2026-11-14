#if canImport(SwiftUI)
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// The component kit v3 (UI v3 section 5, ADR-0020): painted surfaces,
// native behaviour. Every material here is drawn in code first (gradients,
// an inner shadow, a cached grain tile, never a per-frame blur) and has one
// asset-name hook (`PofuKitArt`): when Codex's batch-61 art lands in the
// package resources, the same view draws the painted 3-slice or 9-slice
// instead, with no API change.

/// The kit's palette, day and night. Warm only: no grey, no system tint.
public struct PofuKitPalette: Sendable {
    public var ink: Color
    public var inkSoft: Color
    public var honeyTop: Color
    public var honey: Color
    public var honeyBottom: Color
    public var creamTop: Color
    public var cream: Color
    public var creamBottom: Color
    public var woodTop: Color
    public var woodBottom: Color
    public var paperTop: Color
    public var paperBottom: Color
    public var linen: Color
    public var felt: Color
    public var feltSelected: Color
    public var stitch: Color
    public var edge: Color
    public var glow: Color
    public var focus: Color
    /// Text on paper, felt and linen.
    public var onPaper: Color
    public var isNight: Bool

    public static func rgb(_ hex: UInt32) -> Color {
        Color(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, opacity: 1)
    }

    /// Cocoa ink on honey wood, cream paper: the day set.
    public static let day = PofuKitPalette(
        ink: rgb(0x4A3326), inkSoft: rgb(0x7A6150),
        honeyTop: rgb(0xFBD679), honey: rgb(0xF6C453), honeyBottom: rgb(0xE8AE3A),
        creamTop: rgb(0xFFFAF2), cream: rgb(0xFFF6EC), creamBottom: rgb(0xF4E4CC),
        woodTop: rgb(0xDCC6A3), woodBottom: rgb(0xC8AC84),
        paperTop: rgb(0xFFF8EE), paperBottom: rgb(0xFBEBD6),
        linen: rgb(0xF3E6D2), felt: rgb(0xEBD9BE), feltSelected: rgb(0xF6C453),
        stitch: rgb(0xB89A78), edge: rgb(0x4A3326), glow: rgb(0xFFE7A8), focus: rgb(0x4A3326),
        onPaper: rgb(0x4A3326), isNight: false
    )

    /// Amber on deep ink, lamplit paper: the night set. A light, not a
    /// theme: world screens use it at night whatever the system says.
    public static let night = PofuKitPalette(
        ink: rgb(0x2A1E14), inkSoft: rgb(0xD9C3A0),
        honeyTop: rgb(0xF2BC5E), honey: rgb(0xE9A93B), honeyBottom: rgb(0xCC8F2A),
        creamTop: rgb(0x5E4A38), cream: rgb(0x54422F), creamBottom: rgb(0x46362A),
        woodTop: rgb(0x7A634C), woodBottom: rgb(0x5E4A38),
        paperTop: rgb(0x4A3A2C), paperBottom: rgb(0x3A2D22),
        linen: rgb(0x33271D), felt: rgb(0x54422F), feltSelected: rgb(0xE9A93B),
        stitch: rgb(0xA58B6B), edge: rgb(0x1A120B), glow: rgb(0xFFC76A), focus: rgb(0xF6C453),
        onPaper: rgb(0xF6E7D2), isNight: true
    )
}

private struct PofuNightKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

extension EnvironmentValues {
    /// Whether the kit draws its night set. `nil` follows the system
    /// appearance; world screens set it from the scene's light.
    public var pofuNight: Bool? {
        get { self[PofuNightKey.self] }
        set { self[PofuNightKey.self] = newValue }
    }
}

private struct PofuForcePressedKey: EnvironmentKey { static let defaultValue = false }
private struct PofuForceFocusedKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
    /// Draws plaques pressed, for the kit sheet and previews.
    public var pofuForcePressed: Bool {
        get { self[PofuForcePressedKey.self] }
        set { self[PofuForcePressedKey.self] = newValue }
    }

    /// Draws plaques focused, for the kit sheet and previews.
    public var pofuForceFocused: Bool {
        get { self[PofuForceFocusedKey.self] }
        set { self[PofuForceFocusedKey.self] = newValue }
    }
}

extension View {
    /// Draws the kit's night set (`true`) or day set (`false`) below.
    public func pofuNight(_ isNight: Bool?) -> some View {
        environment(\.pofuNight, isNight)
    }
}

/// Resolves the palette from the environment.
struct PofuKitStyleResolver {
    let night: Bool?
    let scheme: ColorScheme
    let contrast: ColorSchemeContrast

    var isNight: Bool { night ?? (scheme == .dark) }
    var palette: PofuKitPalette { isNight ? .night : .day }
    var isHighContrast: Bool { contrast == .increased }
}

#if canImport(UIKit)
/// The grain: one small noise tile, built once, tiled at low opacity over
/// paper and wood. Never regenerated and never blurred per frame.
@MainActor
enum PofuGrain {
    private static var cached: UIImage?

    static var tile: UIImage {
        if let cached { return cached }
        let side = 96
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { context in
            for y in 0..<side {
                for x in 0..<side {
                    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                    let value = CGFloat((state >> 33) & 0xFF) / 255
                    UIColor(white: value > 0.5 ? 1 : 0, alpha: abs(value - 0.5) * 0.5).setFill()
                    context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        cached = image
        return image
    }
}

extension PofuKitArt {
    @MainActor private static let cache = NSCache<NSString, UIImage>()

    /// The painted art, decoded once; `nil` until batch-61 lands.
    @MainActor
    var image: UIImage? {
        let key = rawValue as NSString
        if let hit = Self.cache.object(forKey: key) { return hit }
        guard let url = Bundle.module.url(forResource: rawValue, withExtension: "png"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data, scale: 3)
        else { return nil }
        Self.cache.setObject(image, forKey: key)
        return image
    }

    /// The face to draw: this one, or its stand-in while it is unpainted.
    @MainActor
    var painted: (art: PofuKitArt, image: UIImage)? {
        if let image { return (self, image) }
        if let standIn, let image = standIn.image { return (standIn, image) }
        return nil
    }

    /// Whether a painted face (its own or its stand-in) is in the bundle.
    @MainActor
    public var isPainted: Bool { painted != nil }
}

/// A painted face stretched by its slicing.
struct PofuKitSlices: View {
    let image: UIImage
    let slicing: PofuKitSlicing

    var body: some View {
        switch slicing {
        case let .nine(top, leading, bottom, trailing):
            Image(uiImage: image)
                .resizable(
                    capInsets: EdgeInsets(top: CGFloat(top), leading: CGFloat(leading), bottom: CGFloat(bottom), trailing: CGFloat(trailing)),
                    resizingMode: .stretch
                )
        case let .ends(leading, trailing):
            GeometryReader { proxy in
                let height = max(proxy.size.height, 1)
                if let cg = image.cgImage {
                    // Drawn at the frame's height, so the ends keep their shape
                    // and only the flat middle stretches. A frame narrower than
                    // both ends shares it between them.
                    let ends = CGFloat(leading + trailing) * height
                    let fit: CGFloat = ends > proxy.size.width ? proxy.size.width / ends : 1
                    Image(uiImage: UIImage(cgImage: cg, scale: CGFloat(cg.height) / height, orientation: .up))
                        .resizable(
                            capInsets: EdgeInsets(top: 0, leading: CGFloat(leading) * height * fit, bottom: 0, trailing: CGFloat(trailing) * height * fit),
                            resizingMode: .stretch
                        )
                }
            }
        case .whole:
            Image(uiImage: image).resizable()
        case .halfHeight:
            let half = image.size.height / 2
            Image(uiImage: image)
                .resizable(capInsets: EdgeInsets(top: half, leading: half, bottom: half, trailing: half), resizingMode: .stretch)
        }
    }
}
#else
extension PofuKitArt {
    /// No painted faces without UIKit.
    public var isPainted: Bool { false }
}
#endif

/// Grain over a shape: the cached noise tile, tiled, very low opacity.
struct PofuGrainOverlay: View {
    var opacity: Double = 0.07

    var body: some View {
        #if canImport(UIKit)
        Image(uiImage: PofuGrain.tile)
            .resizable(resizingMode: .tile)
            .opacity(opacity)
            .blendMode(.overlay)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        #else
        Color.clear
        #endif
    }
}

/// A painted face: the baked image, sliced by its `PofuKitArt.slicing`
/// (or by explicit `caps`), when it exists; the code-drawn `fallback`
/// otherwise.
struct PofuKitFace<Fallback: View>: View {
    let art: PofuKitArt
    let caps: EdgeInsets?
    let fallback: Fallback

    /// Painted faces are drawn in the crafted skin only; the glass skin
    /// draws the code-drawn fallback it drew before the faces were baked.
    @Environment(\.pofuPaintedChrome) private var paintsChrome

    init(_ art: PofuKitArt, caps: EdgeInsets? = nil, @ViewBuilder fallback: () -> Fallback) {
        self.art = art
        self.caps = caps
        self.fallback = fallback()
    }

    var body: some View {
        #if canImport(UIKit)
        if paintsChrome, let painted = art.painted {
            if let caps {
                Image(uiImage: painted.image).resizable(capInsets: caps, resizingMode: .stretch)
            } else {
                PofuKitSlices(image: painted.image, slicing: painted.art.slicing)
            }
        } else {
            fallback
        }
        #else
        fallback
        #endif
    }
}

extension InsettableShape {
    /// An inner shadow: a soft rim pushed down, clipped to the shape.
    func pofuInnerShadow(_ color: Color, width: CGFloat = 4, blur: CGFloat = 2.5, y: CGFloat = 2) -> some View {
        strokeBorder(color, lineWidth: width)
            .blur(radius: blur)
            .offset(y: y)
            .clipShape(self)
            .allowsHitTesting(false)
    }
}
#endif
