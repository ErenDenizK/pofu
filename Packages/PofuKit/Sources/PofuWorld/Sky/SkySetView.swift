#if os(iOS)
import SwiftUI
import UIKit

/// A sky set (ADR-0025) drawn at the camera's projection, back to front behind nothing but itself: the
/// plate's whole picture, split into layers that move. At rest (time zero) it equals the painting; the
/// island layer, and with it the characters, never moves with the sky.
///
/// Motion is `SkyMotion`'s: far, mid and sea clouds drift and breathe, the isles bob, the whale
/// glides and wraps off screen, the painted stars brighten in beats (night). Battery: one
/// `TimelineView` at 30 Hz that is paused in the background and not drawn at all while the plate is
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
            layers(time: 0)
        } else {
            TimelineView(.animation(minimumInterval: SkyMotion.frameInterval, paused: scenePhase != .active)) { context in
                layers(time: max(context.date.timeIntervalSince(start), 0))
            }
        }
    }

    private func layers(time: Double) -> some View {
        let scale = SkyMotion.scale(width: Double(size.width), referenceWidth: sky.referenceWidth)
        return ZStack(alignment: .topLeading) {
            ForEach(sky.layers) { layer in
                layerView(layer, time: time, scale: scale)
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

    @ViewBuilder
    private func layerView(_ layer: SkySet.Layer, time: Double, scale: Double) -> some View {
        let r = rect(of: layer)
        let dy = SkyMotion.bob(layer.bob, time: time, scale: scale)
        switch layer.role {
        case .sky, .island, .sprite:
            piece(layer.asset, r, dx: 0, dy: dy)
        case .stars:
            let light = SkyMotion.twinkle(layer.twinkle, time: time)
            if light > 0.004 {
                // The star's own pixels, added over the sky: the painted star brightens, nothing new is drawn.
                piece(layer.asset, r, dx: 0, dy: 0)
                    .blendMode(.plusLighter)
                    .opacity(light)
            }
        case .tile:
            let shift = SkyMotion.drift(rate: layer.drift, time: time, tileWidth: r.width, scale: scale)
            // Three copies cover the screen at any shift; each overlaps the next by a point, so no
            // hairline shows where two meet at a fractional position.
            ForEach([-1.0, 0.0, 1.0], id: \.self) { n in
                piece(layer.asset, r, dx: shift + n * r.width, dy: dy, overlap: 1)
            }
        case .whale:
            let left = SkyMotion.glideLeft(
                restLeft: r.minX, width: r.width, speed: layer.drift, time: time, screenWidth: Double(size.width), scale: scale
            )
            piece(layer.asset, r, dx: left - r.minX, dy: dy)
        }
    }

    private func piece(_ name: String, _ r: CGRect, dx: Double, dy: Double, overlap: Double = 0) -> some View {
        Image(name, bundle: .module)
            .resizable()
            .interpolation(.high)
            .frame(width: r.width + overlap, height: r.height)
            .position(x: r.minX + dx + (r.width + overlap) / 2 + offset.width, y: r.minY + dy + r.height / 2 + offset.height)
    }
}
#endif
