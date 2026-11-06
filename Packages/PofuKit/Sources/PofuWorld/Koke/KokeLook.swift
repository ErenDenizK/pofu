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
    /// How much of the cool grade is mixed in, 0 to 1.
    public var coolAmount: Double { LookTuning.kokeCoolShade[stage] }
    public var isActive: Bool { fog > 0 }

    /// The multiply tint of the cooler shade grade, white when there is none.
    public var coolTint: PofuRGB {
        PofuRGB(red: 1, green: 1, blue: 1).mixed(with: Self.coolShade, amount: coolAmount)
    }

    /// The cool shade: blue-violet and teal, where the colour lives at
    /// stage 0.
    public static let coolShade = PofuRGB(red: 0.80, green: 0.88, blue: 1.0)
    /// The shaft's warm hue.
    public static let shaftColour = PofuRGB(hex: 0xFFD98F)
    /// The sprout on the crown, in world units from the island's centre (from
    /// the painted plate: the green shoot on Koke's head).
    public static let sprout = WorldPoint(x: -0.5, y: -64.4)
    /// The shaft leans in from the upper left, this many degrees off vertical.
    public static let shaftAngle = 20.0
}

#if os(iOS)
import SwiftUI

extension EnvironmentValues {
    /// The sky's horizon colour through its grade: the depth fog's colour
    /// for everything drawn in the world canvas (set by the scene).
    @Entry var worldHorizon: PofuRGB = PofuRGB(hex: 0xDCEAF4)
}

/// The shaft and the foot's fog card over Koke's plate: the shaft a
/// soft-edged gradient wedge (a fade along its length, a fade across it, no
/// blur), the card the shared code fog card.
struct KokeStageLight: View {
    let look: KokeStageLook
    let horizon: PofuRGB
    /// The island's centre in the host canvas, and its width.
    let origin: CGPoint

    var body: some View {
        ZStack {
            // The fog card across the foot.
            Image(uiImage: FogCardImage.image(1))
                .renderingMode(.template)
                .resizable()
                .frame(width: 330, height: 103)
                .foregroundStyle(FogModel.colour(horizon: horizon).color)
                .opacity(look.cardOpacity)
                .position(x: origin.x + 6, y: origin.y + 50)
            shaft
        }
        .allowsHitTesting(false)
    }

    /// One warm wedge from the upper left, landing on the sprout, with a
    /// small pool of the same warmth where it lands.
    private var shaft: some View {
        let sprout = CGPoint(x: origin.x + KokeStageLook.sprout.x, y: origin.y + KokeStageLook.sprout.y)
        let warm = KokeStageLook.shaftColour.color
        let length = 190.0
        return ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: warm.opacity(0), location: 0),
                            .init(color: warm.opacity(look.shaftAlpha * 0.7), location: 0.55),
                            .init(color: warm.opacity(look.shaftAlpha), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white, location: 0.35),
                            .init(color: .white, location: 0.65),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .frame(width: 58, height: length)
                .rotationEffect(.degrees(-KokeStageLook.shaftAngle), anchor: .bottom)
                .position(x: sprout.x, y: sprout.y + 10 - length / 2)
                .blendMode(.plusLighter)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [warm.opacity(look.shaftAlpha * 2.2), warm.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .frame(width: 40, height: 40)
                .position(x: sprout.x, y: sprout.y + 2)
                .blendMode(.plusLighter)
        }
    }
}

/// The cooler shade grade as a multiply tint, only while it applies.
struct KokeCoolShade: ViewModifier {
    let look: KokeStageLook

    func body(content: Content) -> some View {
        if look.isActive {
            content.colorMultiply(look.coolTint.color)
        } else {
            content
        }
    }
}
#endif
