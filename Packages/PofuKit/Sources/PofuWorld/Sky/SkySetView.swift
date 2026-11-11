#if os(iOS)
import SwiftUI
import UIKit

/// A sky set (ADR-0025) drawn at the camera's projection, back to front behind nothing but itself: the
/// plate's whole picture, split into layers that move. At rest (time zero) it equals the painting; the
/// island layer, and with it the characters, never moves with the sky.
///
/// Motion is `SkyMotion`'s: far, mid and sea clouds drift and breathe, the isles bob, the whale
/// glides and wraps off screen, the painted stars brighten in beats (night). Battery: one
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
            for layer in sky.layers {
                draw(layer, in: &context, time: time, scale: scale)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    /// The layer's place on screen in points (before the peek's offset): its master box through the
    /// plate's placement and the camera.
    private func rect(of layer: SkySet.Layer) -> CGRect {
        let box = plate.worldBox(
            master: PlateRect(minX: layer.pos.x, minY: layer.pos.y, maxX: layer.pos.x + layer.size.x, maxY: layer.pos.y + layer.size.y),
            of: sky
        )
        let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: Double(size.width))
        return CGRect(x: a.x, y: a.y, width: box.width * pose.scale, height: box.height * pose.scale)
    }

    private func draw(_ layer: SkySet.Layer, in context: inout GraphicsContext, time: Double, scale: Double) {
        let r = rect(of: layer)
        let dy = SkyMotion.bob(layer.bob, time: time, scale: scale)
        switch layer.role {
        case .sky, .island, .sprite:
            piece(layer.asset, r, dx: 0, dy: dy, in: &context)
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
            // Three copies cover the screen at any shift; each overlaps the next by a point, so no
            // hairline shows where two meet at a fractional position.
            for n in [-1.0, 0.0, 1.0] {
                piece(layer.asset, r, dx: shift + n * r.width, dy: dy, overlap: 1, in: &context)
            }
        case .whale:
            let left = SkyMotion.glideLeft(
                restLeft: r.minX, width: r.width, speed: layer.drift, time: time, screenWidth: Double(size.width), scale: scale
            )
            piece(layer.asset, r, dx: left - r.minX, dy: dy, in: &context)
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
