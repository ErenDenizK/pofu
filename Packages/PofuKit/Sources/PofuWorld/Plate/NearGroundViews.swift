#if os(iOS)
import CoreGraphics
import PofuCore
import SwiftUI

/// The near camera's ground (mainflow plan row 3a), drawn inside the island's picture so the thin lens
/// blurs it with the rest: a lawn detail tile in soft light over the plate (it takes the plate's own colour
/// in day, golden, night and autumn), clipped to the lawn by a mask, fading out above and below Pofu's row;
/// the dressing (tufts, pebbles, clover, daisies, the tea stool) on its contact shadows; and the soft
/// foreground strip over the front lip, which covers the whole earth face. Nothing draws below
/// `fadeIn`'s first scale, so mid, the Map and a flight keep the plate as painted.
struct NearGround: View {
    let plate: HomePlate
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize

    /// Plate pixels to screen points under this pose.
    private struct Frame {
        var ox: Double
        var oy: Double
        var ppp: Double

        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: ox + x * ppp, y: oy + y * ppp)
        }

        func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> CGRect {
            CGRect(x: ox + x0 * ppp, y: oy + y0 * ppp, width: (x1 - x0) * ppp, height: (y1 - y0) * ppp)
        }
    }

    private var frame: Frame {
        let zero = pose.project(plate.world(PlatePoint(x: 0, y: 0)), width: Double(size.width))
        return Frame(ox: zero.x + Double(offset.width), oy: zero.y + Double(offset.height), ppp: plate.unitsPerPixel * pose.scale)
    }

    var body: some View {
        if let near = plate.plate.near {
            let f = frame
            ZStack(alignment: .topLeading) {
                if let patch = near.patch {
                    let share = nearGroundShare(scale: pose.scale, fadeIn: patch.fadeIn)
                    if share > 0.001 {
                        detail(patch, frame: f, share: share)
                        dressing(near.dressing, frame: f, share: share)
                    }
                }
                if let strip = near.foreground {
                    let share = nearGroundShare(scale: pose.scale, fadeIn: strip.fadeIn)
                    if share > 0.001 {
                        foreground(strip, frame: f, share: share)
                    }
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    // MARK: The lawn

    private func detail(_ patch: PlateNear.Patch, frame f: Frame, share: Double) -> some View {
        let strength = plate.light == "night" ? patch.night : 1
        return Canvas { ctx, canvas in
            let tile = ctx.resolve(Image(patch.detail, bundle: .module))
            let side = patch.tile * f.ppp
            guard side > 1 else { return }
            let i0 = Int(((0 - f.ox) / side).rounded(.down)), i1 = Int(((Double(canvas.width) - f.ox) / side).rounded(.up))
            let j0 = Int(((0 - f.oy) / side).rounded(.down)), j1 = Int(((Double(canvas.height) - f.oy) / side).rounded(.up))
            guard i1 - i0 < 40, j1 - j0 < 40 else { return }
            for j in j0..<j1 {
                for i in i0..<i1 {
                    // A hair of overlap, so a fractional edge never shows the plate between two tiles.
                    ctx.draw(tile, in: CGRect(x: f.ox + Double(i) * side - 0.5, y: f.oy + Double(j) * side - 0.5, width: side + 1, height: side + 1))
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .mask { lawnMask(patch, frame: f) }
        .blendMode(.softLight)
        .opacity(share * strength)
    }

    /// The lawn's alpha: the mask's own, times the depth band (full at Pofu's row, gone above and below),
    /// minus every object of the state (the wheel, the mailbox, a built station).
    private func lawnMask(_ patch: PlateNear.Patch, frame f: Frame) -> some View {
        Canvas { ctx, _ in
            guard patch.maskBox.count == 4, patch.rows.count == 4 else { return }
            let box = f.rect(patch.maskBox[0], patch.maskBox[1], patch.maskBox[2], patch.maskBox[3])
            let y0 = f.oy + patch.rows[0] * f.ppp, y3 = f.oy + patch.rows[3] * f.ppp
            guard y3 > y0 else { return }
            let stops: [Gradient.Stop] = [
                .init(color: .black.opacity(0), location: 0),
                .init(color: .black, location: (patch.rows[1] - patch.rows[0]) / (patch.rows[3] - patch.rows[0])),
                .init(color: .black, location: (patch.rows[2] - patch.rows[0]) / (patch.rows[3] - patch.rows[0])),
                .init(color: .black.opacity(0), location: 1),
            ]
            ctx.fill(Path(box), with: .linearGradient(Gradient(stops: stops), startPoint: CGPoint(x: 0, y: y0), endPoint: CGPoint(x: 0, y: y3)))
            ctx.blendMode = .destinationIn
            ctx.draw(ctx.resolve(Image("\(patch.mask)-\(plate.stage)", bundle: .module)), in: box)
            ctx.blendMode = .destinationOut
            for object in plate.objects where object.polygon.count >= 3 {
                var path = Path()
                path.move(to: f.point(object.polygon[0].x, object.polygon[0].y))
                for p in object.polygon.dropFirst() { path.addLine(to: f.point(p.x, p.y)) }
                path.closeSubpath()
                ctx.fill(path, with: .color(.black))
            }
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: The dressing

    private func dressing(_ pieces: [PlateNear.Dressing], frame f: Frame, share: Double) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(pieces.enumerated()), id: \.offset) { _, d in
                if d.at.count == 2, d.stages?.contains(plate.stage) ?? true {
                    piece(d, frame: f)
                }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .opacity(share)
    }

    /// One piece, in the plate's light (Pofu's own grade at its foot), on a contact shadow in the lawn's shadow hue.
    private func piece(_ d: PlateNear.Dressing, frame f: Frame) -> some View {
        let foot = f.point(d.at[0], d.at[1])
        let w = d.width * f.ppp, h = d.height * f.ppp
        let u = plate.unitsPerPixel
        let light = plate.characterLight(at: plate.world(PlatePoint(x: d.at[0], y: d.at[1])), width: d.width * u, height: d.height * u, id: "near")
        return ZStack(alignment: .topLeading) {
            ContactPad(width: w, light: light, strength: d.shadow, near: 1)
                .position(x: foot.x, y: foot.y)
            Image(d.art, bundle: .module)
                .resizable()
                .interpolation(.high)
                .frame(width: w, height: h)
                .saturation(light.saturation)
                .colorMultiply(Color(red: light.paint.red, green: light.paint.green, blue: light.paint.blue))
                .position(x: foot.x, y: foot.y - h / 2)
        }
    }

    // MARK: The foreground

    private func foreground(_ strip: PlateNear.Foreground, frame f: Frame, share: Double) -> some View {
        let u = plate.unitsPerPixel
        let light = plate.characterLight(at: plate.world(PlatePoint(x: strip.x + strip.width * Double(strip.count) / 2, y: strip.top + strip.height / 2)), width: strip.width * u, height: strip.height * u, id: "near")
        return ZStack(alignment: .topLeading) {
            ForEach(0..<max(strip.count, 0), id: \.self) { i in
                let centre = f.point(strip.x + (Double(i) + 0.5) * strip.width, strip.top + strip.height / 2)
                Image(strip.art, bundle: .module)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: strip.width * f.ppp, height: strip.height * f.ppp)
                    // Each copy mirrors its neighbour, so their edges meet in the same pixels.
                    .scaleEffect(x: i % 2 == 0 ? 1 : -1, y: 1)
                    .saturation(light.saturation)
                    .colorMultiply(Color(red: light.paint.red, green: light.paint.green, blue: light.paint.blue))
                    .position(x: centre.x, y: centre.y)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .opacity(share)
    }
}
#endif
