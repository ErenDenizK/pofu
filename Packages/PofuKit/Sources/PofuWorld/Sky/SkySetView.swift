#if os(iOS)
import SwiftUI
import UIKit

/// A sky set (ADR-0025) drawn at the camera's projection, back to front behind nothing but itself: the
/// plate's whole picture, split into layers that move. At rest (time zero) it equals the painting; the
/// island layer, and with it the characters, never moves with the sky.
///
/// Motion is `SkyMotion`'s: far, mid and sea clouds drift and breathe, the isles bob, the whale
/// glides and wraps off screen, the painted stars brighten in beats (night); the isles and the whale carry
/// painted detail that moves on its own (`SkySet.Detail`: a waterfall's water flows down with a breathing
/// mist, a canopy sways, a lamp flickers), each amount rising from zero so time zero is the painting.
/// Battery: one
/// `TimelineView` drawing one `Canvas` at 30 Hz that is paused in the background and not drawn at all while the plate is
/// faded out (toward the Map); under Reduce Motion, Low Power Mode and still frames (screenshots) there
/// is no timeline and every layer stays at time zero, so a settled frame is cached and costs nothing.
struct SkySetLayers: View {
    let sky: SkySet
    let plate: HomePlate
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize
    /// When this painting appeared: the motion's time zero (a crossfade's incoming sky starts at the
    /// painting).
    let start: Date
    /// Whether the island layer (and with it the cloud bank cut with the island) is drawn. A painted sky
    /// behind another island (`PaintedSky`) leaves it out: the sea, the clouds and the isles remain.
    var drawsIsland = true

    @Environment(\.worldStillFrame) private var still
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var isStatic: Bool {
        still || reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    var body: some View {
        if isStatic {
            canvas(time: 0)
        } else {
            TimelineView(.animation(minimumInterval: SkyMotion.frameInterval, paused: scenePhase != .active)) { context in
                canvas(time: max(context.date.timeIntervalSince(start), 0))
            }
        }
    }

    /// One `Canvas` draws every layer at its exact fractional place: SwiftUI's image views would snap each
    /// layer's frame to the pixel grid on its own, shifting the island layer a fraction of a pixel against
    /// the layers behind it (and against the painting it was cut from).
    private func canvas(time: Double) -> some View {
        let scale = SkyMotion.scale(width: Double(size.width), referenceWidth: sky.referenceWidth)
        return Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: false) { context, _ in
            for layer in sky.layers where drawsIsland || layer.role != .island {
                if let window = layer.window {
                    // A band of the layer (the Map's sky, `PaintedSky.mapSet`): drawn through a mask that
                    // fades in and out across the band's rows.
                    var band = context
                    let r = rect(of: layer)
                    let dy = SkyMotion.bob(layer.bob, time: time, scale: scale) + offset.height
                    band.clipToLayer { mask in
                        Self.fill(window, in: r.offsetBy(dx: 0, dy: dy), width: size.width, into: &mask)
                    }
                    draw(layer, in: &band, time: time, scale: scale)
                } else {
                    draw(layer, in: &context, time: time, scale: scale)
                }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    /// The window's band across the screen, opaque where the band shows and fading at its edges.
    private static func fill(_ window: SkySet.Window, in r: CGRect, width: CGFloat, into mask: inout GraphicsContext) {
        let top = r.minY + window.top * r.height, bottom = r.minY + window.bottom * r.height
        guard bottom > top else { return }
        let h = bottom - top
        let a = min(max(window.topFade * r.height / h, 0), 1), b = min(max(window.bottomFade * r.height / h, 0), 1)
        let stops: [Gradient.Stop] = [
            .init(color: .black.opacity(a > 0 ? 0 : 1), location: 0),
            .init(color: .black, location: min(a, 1 - b)),
            .init(color: .black, location: max(1 - b, a)),
            .init(color: .black.opacity(b > 0 ? 0 : 1), location: 1),
        ]
        mask.fill(
            Path(CGRect(x: 0, y: top, width: width, height: h)),
            with: .linearGradient(Gradient(stops: stops), startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: bottom))
        )
    }

    /// The layer's place on screen in points (before the peek's offset): its master box through the
    /// plate's placement and the camera.
    private func rect(of layer: SkySet.Layer) -> CGRect {
        rect(pos: layer.pos, size: layer.size)
    }

    private func rect(pos: PlatePoint, size extent: PlatePoint) -> CGRect {
        let box = plate.worldBox(
            master: PlateRect(minX: pos.x, minY: pos.y, maxX: pos.x + extent.x, maxY: pos.y + extent.y),
            of: sky
        )
        let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: Double(size.width))
        return CGRect(x: a.x, y: a.y, width: box.width * pose.scale, height: box.height * pose.scale)
    }

    private func draw(_ layer: SkySet.Layer, in context: inout GraphicsContext, time: Double, scale: Double) {
        let r = rect(of: layer)
        let dy = SkyMotion.bob(layer.bob, time: time, scale: scale)
        switch layer.role {
        case .sky, .island:
            piece(layer.asset, r, dx: 0, dy: dy, in: &context)
        case .sprite:
            piece(layer.asset, r, dx: 0, dy: dy, in: &context)
            drawDetails(of: layer, dx: 0, dy: dy, in: &context, time: time, scale: scale)
        case .stars:
            let light = SkyMotion.twinkle(layer.twinkle, time: time)
            if light > 0.004 {
                // The star's own pixels, added over the sky: the painted star brightens, nothing new is drawn.
                var added = context
                added.blendMode = .plusLighter
                added.opacity = light
                piece(layer.asset, r, dx: 0, dy: 0, in: &added)
            }
        case .tile:
            let shift = SkyMotion.drift(rate: layer.drift, time: time, tileWidth: r.width, scale: scale)
            // As many copies as cover the screen at any shift (three for a tile the master's width, more
            // for the Map's smaller rows of cloud sea); each overlaps the next by a point, so no hairline
            // shows where two meet at a fractional position.
            for n in SkyMotion.copies(left: r.minX + shift + offset.width, width: r.width, screen: Double(size.width)) {
                piece(layer.asset, r, dx: shift + Double(n) * r.width, dy: dy, overlap: 1, in: &context)
            }
        case .whale:
            let left = SkyMotion.glideLeft(
                restLeft: r.minX, width: r.width, speed: layer.drift, time: time, screenWidth: Double(size.width), scale: scale
            )
            piece(layer.asset, r, dx: left - r.minX, dy: dy, in: &context)
            drawDetails(of: layer, dx: left - r.minX, dy: dy, in: &context, time: time, scale: scale)
        }
    }

    // MARK: Painted detail

    private func drawDetails(of layer: SkySet.Layer, dx: Double, dy: Double, in context: inout GraphicsContext, time: Double, scale: Double) {
        for detail in layer.details {
            let r = rect(pos: detail.pos, size: detail.size).offsetBy(dx: dx + offset.width, dy: dy + offset.height)
            switch detail.kind {
            case .fall: drawFall(detail, in: r, context: &context, time: time, scale: scale)
            case .sway: drawSway(detail, in: r, context: &context, time: time, scale: scale)
            case .glow: drawGlow(detail, in: r, context: &context, time: time)
            }
        }
    }

    private func image(_ name: String?, in context: inout GraphicsContext) -> GraphicsContext.ResolvedImage? {
        guard let name else { return nil }
        return context.resolve(Image(name, bundle: .module).interpolation(.high))
    }

    /// A waterfall: a veil of lighter and darker streaks (the painted fall's own detail) scrolls down inside
    /// the fall's mask, then a faint mist breathes at its foot. Nothing is drawn at time zero.
    private func drawFall(_ d: SkySet.Detail, in r: CGRect, context: inout GraphicsContext, time: Double, scale: Double) {
        let e = SkyMotion.ease(time: time, ramp: d.ramp)
        let opacity = d.strength * e
        if opacity > 0.002, let mask = image(d.mask, in: &context), let flow = image(d.flow, in: &context) {
            let tile = rect(pos: d.pos, size: PlatePoint(x: d.size.x, y: d.flowHeight)).height
            let shift = SkyMotion.flowOffset(speed: d.speed, time: time, period: tile, scale: scale)
            var veil = context
            veil.clipToLayer { layer in
                layer.draw(mask, in: r)
            }
            veil.opacity = opacity
            // Two tiles abut at the scrolled seam; the veil is alpha-only streaks, so the join does not show.
            for n in [-1.0, 0.0] {
                veil.draw(flow, in: CGRect(x: r.minX, y: r.minY + shift + n * tile, width: r.width, height: tile))
            }
        }
        if let mist = d.mist {
            let level = SkyMotion.mist(mist, time: time, ease: e)
            if level > 0.002, mist.color.count == 3 {
                let home = rect(pos: d.pos, size: d.size)
                let c = rect(pos: mist.centre, size: PlatePoint(x: 0, y: 0)).origin
                let rx = rect(pos: mist.centre, size: PlatePoint(x: mist.radius.x, y: 0)).width
                let ry = rect(pos: mist.centre, size: PlatePoint(x: 0, y: mist.radius.y)).height
                var puff = context
                puff.opacity = level
                puff.translateBy(x: c.x + r.minX - home.minX, y: c.y + r.minY - home.minY)
                puff.scaleBy(x: 1, y: ry / max(rx, 0.001))
                let colour = Color(red: mist.color[0], green: mist.color[1], blue: mist.color[2])
                puff.fill(
                    Path(ellipseIn: CGRect(x: -rx, y: -rx, width: 2 * rx, height: 2 * rx)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: colour, location: 0),
                            .init(color: colour.opacity(0.45), location: 0.5),
                            .init(color: colour.opacity(0), location: 1),
                        ]),
                        center: .zero, startRadius: 0, endRadius: rx
                    )
                )
            }
        }
    }

    /// A canopy: its own pixels, sheared about the region's foot (the top moves most), seen only through the
    /// feathered mask of its inside, so its silhouette stays where the painter put it.
    private func drawSway(_ d: SkySet.Detail, in r: CGRect, context: inout GraphicsContext, time: Double, scale: Double) {
        let top = SkyMotion.sway(d, time: time, scale: scale)
        guard abs(top) > 0.01, r.height > 0, let mask = image(d.mask, in: &context), let crop = image(d.crop, in: &context) else { return }
        var moved = context
        moved.clipToLayer { layer in
            layer.draw(mask, in: r)
        }
        moved.translateBy(x: 0, y: r.maxY)
        moved.concatenate(CGAffineTransform(a: 1, b: 0, c: -top / r.height, d: 1, tx: 0, ty: 0))
        moved.draw(crop, in: r.offsetBy(dx: 0, dy: -r.maxY))
    }

    /// A lantern or window: its lit pixels added over themselves (a brighter beat) or a little black under
    /// their mask (a dimmer one), a few per cent either way.
    private func drawGlow(_ d: SkySet.Detail, in r: CGRect, context: inout GraphicsContext, time: Double) {
        let v = SkyMotion.flicker(d, time: time)
        guard abs(v) > 0.002, let lit = image(d.asset, in: &context) else { return }
        if v > 0 {
            var added = context
            added.blendMode = .plusLighter
            added.opacity = v
            added.draw(lit, in: r)
        } else {
            var dimmed = context
            dimmed.clipToLayer { layer in
                layer.draw(lit, in: r)
            }
            dimmed.opacity = -v
            dimmed.fill(Path(r), with: .color(.black))
        }
    }

    private func piece(_ name: String, _ r: CGRect, dx: Double, dy: Double, overlap: Double = 0, in context: inout GraphicsContext) {
        let image = context.resolve(Image(name, bundle: .module).interpolation(.high))
        let target = CGRect(
            x: r.minX + dx + offset.width, y: r.minY + dy + offset.height, width: r.width + overlap, height: r.height
        )
        context.draw(image, in: target)
    }
}
#endif
