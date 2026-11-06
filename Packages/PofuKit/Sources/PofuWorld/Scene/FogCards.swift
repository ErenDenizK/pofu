#if os(iOS)
import PofuDesignSystem
import SwiftUI
import UIKit

/// The fog card images: soft white shapes, drawn once and cached (never
/// blurred per frame), tinted by the view. When the painted cards of
/// `batch-44-weather-fx` land as `world-fog-card-1...3`, they replace the
/// code ones by name (`FogCardLayout.artName`).
@MainActor
enum FogCardImage {
    private static var cache: [Int: UIImage] = [:]

    /// The painted card if the catalog has it, else the code-drawn one.
    static func image(_ art: Int) -> UIImage {
        if let hit = cache[art] { return hit }
        let image = UIImage(named: FogCardLayout.artName(art), in: .module, compatibleWith: nil) ?? drawn(seed: art)
        cache[art] = image
        return image
    }

    static let size = CGSize(width: 512, height: 160)

    /// Overlapping soft ellipses, densest in the middle and gone at the
    /// edges: a low bank of fog.
    static func drawn(seed: Int) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let size = Self.size
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let cg = renderer.cgContext
            var g = CloudShape.Generator(state: UInt64(truncatingIfNeeded: seed &* 31 &+ 5))
            let colours = [
                UIColor.white.withAlphaComponent(0.55).cgColor,
                UIColor.white.withAlphaComponent(0.28).cgColor,
                UIColor.white.withAlphaComponent(0).cgColor,
            ] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colours, locations: [0, 0.5, 1]) else { return }
            let count = 11
            for i in 0..<count {
                let rx = 70 + 60 * g.next()
                let ry = rx * (0.26 + 0.1 * g.next())
                let t = (Double(i) + 0.5 + 0.4 * (g.next() - 0.5)) / Double(count)
                let cx = min(max(rx + (size.width - 2 * rx) * t, rx), size.width - rx)
                let cy = size.height / 2 + (g.next() - 0.5) * 26
                cg.saveGState()
                cg.translateBy(x: cx, y: cy)
                cg.scaleBy(x: 1, y: ry / rx)
                cg.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: rx, options: [])
                cg.restoreGState()
            }
        }
    }
}

/// Height fog (sky and weather v1 §2.3): two to four soft cards, densest at
/// the cloud-sea line, drifting at 1x, 2x and 3.5x speed. `.behind` cards
/// sit behind the island, the `.front` one across its base, so the foot
/// dissolves and the top stays clear. Opacity is low in clear weather;
/// `mist` (0...1) is SW-2's to raise. Drifts on the 30 Hz ambient tier and
/// holds when the world settles, like the sky.
struct FogCards: View {
    let layer: FogCardLayout.Layer
    /// The sky's horizon, through its grade: the fog's colour.
    let horizon: PofuRGB
    var mist: Double = 0
    let offset: CGSize
    let size: CGSize
    /// Where the cloud-sea line sits, in points from the top.
    let seaLine: Double

    @Environment(\.worldStillFrame) private var still
    @Environment(\.worldAmbientPaused) private var ambientPaused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isPaused: Bool {
        still || ambientPaused || reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    var body: some View {
        let cards = FogCardLayout.cards.filter { $0.layer == layer }
        let colour = FogModel.colour(horizon: horizon).color
        let peak = FogModel.cardOpacity(mist: mist)
        let screen = Double(size.width)
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { context in
            let time = still ? 0 : FramePolicy.ambientTime(context.date.timeIntervalSinceReferenceDate)
            ZStack(alignment: .topLeading) {
                ForEach(cards) { card in
                    let w = card.width * screen
                    let h = w * Double(FogCardImage.size.height / FogCardImage.size.width)
                    Image(uiImage: FogCardImage.image(card.art))
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: CGFloat(w), height: CGFloat(h))
                        .foregroundStyle(colour)
                        .opacity(peak * card.strength)
                        .offset(
                            x: CGFloat(FogCardLayout.x(of: card, time: time, screenWidth: screen)) + offset.width * CGFloat(card.parallax),
                            y: CGFloat(seaLine + card.yOffset - h / 2) + offset.height * CGFloat(card.parallax * 0.4)
                        )
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
