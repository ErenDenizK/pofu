import Foundation
import PofuDesignSystem

/// Koke's stage 0 look (sky and weather v1 §2.4): the painted stages 0 to 2
/// were made under the old "pale and flat" rule and are not regenerated, so
/// code gives them the new one with what it has: depth fog, a fog card
/// across the foot, ONE warm light shaft landing on the sprout on the
/// crown, and a slightly cooler shade grade. Strongest at stage 0, fading
/// over stages 1 and 2, gone from stage 3. Pure, so the numbers are tested.
public struct KokeStageLook: Hashable, Sendable {
    public let stage: Int

    public init(stage: Int) {
        self.stage = min(max(stage, 0), LookTuning.kokeFogAmount.count - 1)
    }

    /// Depth fog on the island (the mid tier's order of size), toward the
    /// horizon colour.
    public var fog: Double { LookTuning.kokeFogAmount[stage] }
    /// The fog card across the island's foot.
    public var cardOpacity: Double { LookTuning.kokeCardOpacity[stage] }
    /// The one warm shaft's alpha: 0.08 to 0.18 while it shows.
    public var shaftAlpha: Double { LookTuning.kokeShaftAlpha[stage] }
    /// The shade grade's multiply strength at the island's foot (the lit
    /// rim takes a third of it).
    public var shadeAmount: Double { LookTuning.kokeShade[stage] }
    public var contrast: Double { LookTuning.kokeContrast[stage] }
    public var skyDeepen: Double { LookTuning.kokeSkyDeepen[stage] }
    public var isActive: Bool { fog > 0 }

    /// The shade: a deep blue-violet the mids and shadows are multiplied
    /// toward, where the colour lives at stage 0.
    public static let shadeColour = PofuRGB(hex: 0x4E4C7E)
    /// The shaft's warm hue.
    public static let shaftColour = PofuRGB(hex: 0xFFC98A)
    /// The shaft's width, 0.2 of the island's.
    public static var shaftWidth: Double { 0.2 * KokeLayout.plateSize.width }
    /// The sprout on the crown, in world units from the island's centre (from
    /// the painted plate: the green shoot on Koke's head).
    public static let sprout = WorldPoint(x: -0.5, y: -64.4)
    /// The shaft leans in from the upper left, this many degrees off vertical.
    public static let shaftAngle = 20.0

    /// The sky behind Koke: deeper by `skyDeepen` L* and pushed a little
    /// bluer, so the island's silhouette sits off it.
    public func sky(_ palette: SkyPalette) -> SkyPalette {
        guard skyDeepen > 0 else { return palette }
        let blue = PofuRGB(hex: 0x3A5A9A)
        func deepen(_ c: PofuRGB) -> PofuRGB {
            SkyModel.darkened(c.mixed(with: blue, amount: 0.04 * skyDeepen / 3), byLightness: skyDeepen)
        }
        var copy = palette
        copy.zenith = deepen(palette.zenith)
        copy.horizon = deepen(palette.horizon)
        return copy
    }
}

#if os(iOS)
import SwiftUI

extension EnvironmentValues {
    /// The sky's horizon colour through its grade: the depth fog's colour
    /// for everything drawn in the world canvas (set by the scene).
    @Entry var worldHorizon: PofuRGB = PofuRGB(hex: 0xDCEAF4)
}

/// The shaft and the foot's fog card over Koke's plate: the shaft a
/// narrow source-over wedge (a gaussian across, a fade along, ending on the
/// sprout), the card the shared code fog card, below the island's foot.
struct KokeStageLight: View {
    let look: KokeStageLook
    let horizon: PofuRGB
    /// The island's centre in the host canvas.
    let origin: CGPoint

    var body: some View {
        ZStack {
            // The fog card under the foot: the earth body stays readable.
            Image(uiImage: FogCardImage.image(1))
                .renderingMode(.template)
                .resizable()
                .frame(width: 300, height: 94)
                .foregroundStyle(FogModel.colour(horizon: horizon).color)
                .opacity(look.cardOpacity)
                .position(x: origin.x + 6, y: origin.y + 84)
            shaft
        }
        .allowsHitTesting(false)
    }

    /// One warm beam from the upper left that finds the sprout: no hard
    /// edge, a soft pool where it lands. Normal blend.
    private var shaft: some View {
        let sprout = CGPoint(x: origin.x + KokeStageLook.sprout.x, y: origin.y + KokeStageLook.sprout.y)
        let warm = KokeStageLook.shaftColour.color
        let length = 170.0
        let gaussian: [Gradient.Stop] = [
            .init(color: .clear, location: 0),
            .init(color: .white.opacity(0.08), location: 0.14),
            .init(color: .white.opacity(0.4), location: 0.3),
            .init(color: .white, location: 0.5),
            .init(color: .white.opacity(0.4), location: 0.7),
            .init(color: .white.opacity(0.08), location: 0.86),
            .init(color: .clear, location: 1),
        ]
        return ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: warm.opacity(0), location: 0),
                            .init(color: warm.opacity(look.shaftAlpha * 0.6), location: 0.55),
                            .init(color: warm.opacity(look.shaftAlpha), location: 0.9),
                            .init(color: warm.opacity(look.shaftAlpha * 0.5), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask { LinearGradient(stops: gaussian, startPoint: .leading, endPoint: .trailing) }
                .frame(width: CGFloat(KokeStageLook.shaftWidth), height: length)
                .rotationEffect(.degrees(-KokeStageLook.shaftAngle), anchor: .bottom)
                .position(x: sprout.x, y: sprout.y - length / 2)
            // The pool on the sprout: about three sprouts across.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [warm.opacity(0.25), warm.opacity(0.1), warm.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 24
                    )
                )
                .frame(width: 48, height: 48)
                .position(x: sprout.x, y: sprout.y + 2)
        }
    }
}

/// The shade grade on Koke's plate while stage 0 to 2 apply: contrast, then
/// a multiply toward a deep blue-violet that is light at the top (the lit
/// rim stays) and full toward the underside, masked to the plate.
struct KokeShadeGrade: ViewModifier {
    let look: KokeStageLook
    let plate: AnyView

    func body(content: Content) -> some View {
        if look.isActive {
            let shade = KokeStageLook.shadeColour.color
            content
                .contrast(look.contrast)
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: shade.opacity(look.shadeAmount * 0.3), location: 0.2),
                            .init(color: shade.opacity(look.shadeAmount), location: 0.6),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .blendMode(.multiply)
                    .mask { plate }
                }
        } else {
            content
        }
    }
}
#endif
