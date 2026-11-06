#if os(iOS)
import PofuDesignSystem
import SwiftUI

/// The far sky (look round 3): batch 04's far isles and painted clouds,
/// composed per framing (`FarSkyLayout`) so the band the island cannot fill
/// has depth instead of dead sky. Atmospheric perspective is the depth fog
/// (`FogModel`, sky and weather v1 §2.3): the farther an element, the more
/// it is mixed toward the current horizon colour (never grey) and the lower
/// its opacity, so it sits in the haze. It is tinted on the CPU like the
/// rest of the sky; there is no shader pass.
struct FarSky: View {
    /// What the far sky needs from the scene.
    struct Look: Hashable {
        /// Koke on the horizon, seen from the harbor; `lit` once it is
        /// healed (the gift's faint light).
        struct Koke: Hashable {
            var lit: Bool
        }

        /// The rail position.
        var z: Double
        /// The fog's colour (the sky's horizon, through its grade) and the
        /// mist (0 in clear weather; SW-2 sets it).
        var fog: PofuRGB
        var mist: Double
        /// White through the sky's grade: the hour's light on the far art.
        var light: PofuRGB
        var koke: Koke?

        /// This look with the fog taken from `horizon`, the sky's own.
        func withHorizon(_ horizon: PofuRGB) -> Look {
            var copy = self
            copy.fog = horizon
            return copy
        }

        init(z: Double, cell: ColourCell, grade: WorldGrade, koke: Koke? = nil, mist: Double = 0) {
            self.z = z
            self.koke = koke
            self.mist = mist
            let g = grade.sky
            // Until `LivingSky` swaps in the palette's own horizon, the cell's.
            fog = g.apply(cell.sky.horizon)
            light = g.apply(PofuRGB(red: 1, green: 1, blue: 1))
        }
    }

    let look: Look
    let offset: CGSize
    let size: CGSize

    var body: some View {
        let k = Double(size.width) / CameraRail.referenceWidth
        ZStack(alignment: .topLeading) {
            ForEach(FarSkyLayout.elements) { element in
                let p = element.placement(z: look.z)
                if p.opacity > 0.01, let box = WorldArt.sprite(element.art)?.sharp {
                    let w = p.width * k
                    let h = w * box.height / box.width
                    // Farther elements take more of the fog and follow the
                    // peek less (they are nearly at infinity). The fog is a
                    // true mix toward the horizon colour, drawn as a mask of
                    // the art over it, so the far isles take the sky's hue.
                    let haze = FogModel.amount(distance: element.distance, mist: look.mist)
                    let name = WorldArt.assetName(element.art, variant: .sharp)
                    let parallax = 0.12 + 0.2 * (1 - element.distance)
                    Image(name, bundle: .module)
                        .resizable()
                        .frame(width: CGFloat(w), height: CGFloat(h))
                        .colorMultiply(look.light.color)
                        .overlay {
                            FogModel.colour(horizon: look.fog).color
                                .opacity(haze)
                                .mask { Image(name, bundle: .module).resizable() }
                        }
                        .opacity(p.opacity * (1 - 0.45 * haze))
                        .position(
                            x: CGFloat(p.x) * size.width + offset.width * CGFloat(parallax),
                            y: CGFloat(p.y) * size.height + offset.height * CGFloat(parallax)
                        )
                }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .overlay { KokeFarHump(look: look, offset: offset, size: size) }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
