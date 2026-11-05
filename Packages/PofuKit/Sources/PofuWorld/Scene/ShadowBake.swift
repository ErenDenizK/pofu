#if os(iOS)
import CoreGraphics
import PofuCore
import SwiftUI
import UIKit

/// The sun-shadow layer (light and shadow v2, §3): every static caster's
/// shadow and ambient pad in ONE offscreen image in world coordinates,
/// drawn between the island plate and the objects, so a building never
/// darkens the one behind it and panning or zooming costs one image draw.
///
/// Each caster's baked silhouette (`tools/assets/shadows.py`, 1/4 size and
/// pre-blurred, no blur at runtime) is flattened and sheared along the sun's
/// ground direction from the caster's feet: a point `h` units above the feet
/// lands `direction · length · h` away. The image is rebuilt only when its
/// key changes: the sun bucket (3° and 0.1 steps, the time band) or the
/// layout (a build, a level, the island level).
enum ShadowBake {
    struct Key: Hashable {
        var sun: SunShadow.Key
        var layout: ShadowCasters.Signature
    }

    struct Baked {
        var image: UIImage
        /// The image's place in world units.
        var rect: CGRect
    }

    /// The imageset of a caster's silhouette.
    static func silhouetteName(_ art: String) -> String {
        art.hasPrefix("ui-") ? "\(art)-shadow" : "world-\(art)-shadow"
    }

    // MARK: Rendering

    /// The lawn's world rectangle and clip polygon: the walkable polygon
    /// grown a little (`ShadowTuning.clipGrow*`), so shadows may cross the
    /// lip but never reach the sky.
    private static func lawn() -> (rect: CGRect, clip: [CGPoint])? {
        guard let polygon = IslandFootprint.walkable, let b = polygon.bounds else { return nil }
        let gx = ShadowTuning.clipGrowX, gy = ShadowTuning.clipGrowY
        let clip = polygon.points.map { p in
            CGPoint(x: b.midX + (p.x - b.midX) * gx, y: b.midY + (p.y - b.midY) * gy)
        }
        let rect = CGRect(
            x: b.midX - b.width / 2 * gx - 2,
            y: b.midY - b.height / 2 * gy - 2,
            width: b.width * gx + 4,
            height: b.height * gy + 4
        )
        return (rect, clip)
    }

    static func render(sun: SunShadow, casters: [ShadowCaster]) -> Baked? {
        guard let lawn = lawn() else { return nil }
        let scale = ShadowTuning.bakeScale
        let size = CGSize(width: ceil(lawn.rect.width * scale), height: ceil(lawn.rect.height * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        format.preferredRange = .standard
        let tint = UIColor(red: sun.tint.r, green: sun.tint.g, blue: sun.tint.b, alpha: 1)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext
            cg.scaleBy(x: scale, y: scale)
            cg.translateBy(x: -lawn.rect.minX, y: -lawn.rect.minY)
            cg.addLines(between: lawn.clip)
            cg.closePath()
            cg.clip()
            // Pads first, so a cast shadow lies over its own pad.
            for caster in casters where !caster.pad.isEmpty {
                let pad = caster.pad
                softEllipse(
                    in: cg,
                    centre: CGPoint(x: caster.anchor.x + pad.midX, y: caster.anchor.y + pad.midY),
                    radii: CGSize(width: pad.width / 2, height: pad.height / 2),
                    rotation: 0,
                    colour: tint,
                    alpha: sun.padOpacity
                )
            }
            for caster in casters {
                switch caster.cast {
                case .silhouette(let art, let explicitBox):
                    silhouette(art: art, box: explicitBox, anchor: caster.anchor, sun: sun, tint: tint, in: cg)
                case .blob(let width, let height):
                    blob(width: width, height: height, anchor: caster.anchor, sun: sun, tint: tint, in: cg)
                case .none:
                    break
                }
            }
        }
        return Baked(image: image, rect: lawn.rect)
    }

    /// A caster's silhouette flattened and sheared from its feet. Softer
    /// light draws it three times, a little apart across the direction.
    private static func silhouette(art: String, box explicitBox: WorldBox?, anchor: WorldPoint, sun: SunShadow, tint: UIColor, in cg: CGContext) {
        guard let box = explicitBox ?? WorldArt.sprite(art)?.sharp,
              let image = UIImage(named: silhouetteName(art), in: .module, compatibleWith: nil) else { return }
        let length = sun.length
        let rect = CGRect(x: box.minX, y: box.minY, width: box.width, height: box.height)
        // A point (x, y) up from the feet (y < 0) lands at
        // (x - d.x · L · y, -d.y · L · y).
        let shear = CGAffineTransform(a: 1, b: 0, c: -sun.direction.x * length, d: -sun.direction.y * length, tx: 0, ty: 0)
        let spread = sun.softness * 2.5
        let taps: [(offset: Double, alpha: Double)] = sun.softness > 0.5 ? [(-spread, 0.3), (0, 0.4), (spread, 0.3)] : [(0, 1)]
        cg.saveGState()
        cg.setAlpha(sun.opacity)
        cg.beginTransparencyLayer(in: cg.boundingBoxOfClipPath, auxiliaryInfo: nil)
        // The group's alpha is applied once, when the layer is composited.
        cg.setAlpha(1)
        for tap in taps {
            cg.saveGState()
            cg.translateBy(x: anchor.x + tap.offset, y: anchor.y)
            cg.concatenate(shear)
            image.draw(in: rect, blendMode: .normal, alpha: tap.alpha)
            cg.restoreGState()
        }
        // The silhouette is black; the layer takes the shadow's hue.
        cg.setBlendMode(.sourceIn)
        cg.setFillColor(tint.cgColor)
        cg.fill(cg.boundingBoxOfClipPath)
        cg.endTransparencyLayer()
        cg.restoreGState()
    }

    /// A soft elongated blob from the feet along the direction: Pofu, who is
    /// the live companion view and has no silhouette.
    private static func blob(width: Double, height: Double, anchor: WorldPoint, sun: SunShadow, tint: UIColor, in cg: CGContext) {
        let reach = (sun.direction.x * sun.direction.x + sun.direction.y * sun.direction.y).squareRoot() * sun.length * height
        let angle = atan2(sun.direction.y, sun.direction.x)
        let half = max(reach / 2, width * 0.3)
        // The ellipse starts a little behind the feet and runs along the direction.
        let centre = CGPoint(
            x: anchor.x + cos(angle) * (reach / 2 - width * 0.1),
            y: anchor.y + sin(angle) * (reach / 2 - width * 0.1)
        )
        softEllipse(in: cg, centre: centre, radii: CGSize(width: half + width * 0.2, height: width * 0.3), rotation: angle, colour: tint, alpha: sun.opacity * 0.9)
    }

    /// An ellipse filled with a soft radial falloff: a firmer core and a
    /// feathered edge.
    private static func softEllipse(in cg: CGContext, centre: CGPoint, radii: CGSize, rotation: Double, colour: UIColor, alpha: Double) {
        let space = CGColorSpaceCreateDeviceRGB()
        let base = colour.withAlphaComponent(alpha)
        let colours = [base.cgColor, base.withAlphaComponent(alpha * 0.6).cgColor, base.withAlphaComponent(0).cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: space, colors: colours, locations: [0, 0.55, 1]) else { return }
        cg.saveGState()
        cg.translateBy(x: centre.x, y: centre.y)
        cg.rotate(by: rotation)
        cg.scaleBy(x: max(radii.width, 0.5), y: max(radii.height, 0.5))
        cg.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 1, options: [])
        cg.restoreGState()
    }
}

/// The one cached bake: the frame asks every pass, a render happens only
/// when the key changed.
@MainActor
enum ShadowBakeCache {
    private static var cached: (key: ShadowBake.Key, baked: ShadowBake.Baked)?
    /// How many times the bake was rendered.
    private(set) static var rebuilds = 0

    /// The baked layer for the sun and the layout, rendering it only when
    /// either changed since the last call.
    static func baked(sun: SunShadow, layout: ShadowCasters.Signature) -> ShadowBake.Baked? {
        let key = ShadowBake.Key(sun: sun.key, layout: layout)
        if let cached, cached.key == key {
            return cached.baked
        }
        guard let baked = ShadowBake.render(sun: sun, casters: ShadowCasters.casters(for: layout)) else { return nil }
        cached = (key, baked)
        rebuilds += 1
        return baked
    }
}

// MARK: - The layer

/// The baked shadow, placed in world space like the plate.
struct SunShadowLayer: View {
    let sun: SunShadow
    let layout: ShadowCasters.Signature
    /// Where a world point lands on the canvas (the plate's depth).
    let place: (WorldPoint) -> CGPoint

    var body: some View {
        if let baked = ShadowBakeCache.baked(sun: sun, layout: layout) {
            let origin = place(WorldPoint(x: baked.rect.minX, y: baked.rect.minY))
            Image(uiImage: baked.image)
                .resizable()
                .interpolation(.high)
                .frame(width: baked.rect.width, height: baked.rect.height)
                .position(x: origin.x + baked.rect.width / 2, y: origin.y + baked.rect.height / 2)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Moving casters

/// A moving caster's own shadow (a critter, the visitor): its baked
/// silhouette flattened and sheared from its feet, one image draw. Nothing is
/// drawn until the art has a silhouette (`tools/assets/shadows.py`); the
/// code-drawn stand-ins keep their contact ellipses. A settled frame holds
/// it like everything else.
struct MovingShadow: View {
    let art: String
    /// The feet on the canvas.
    let feet: CGPoint
    let sun: SunShadow

    var body: some View {
        let name = ShadowBake.silhouetteName(art)
        if let box = WorldArt.sprite(art)?.sharp, UIImage(named: name, in: .module, compatibleWith: nil) != nil {
            let shear = CGAffineTransform(a: 1, b: 0, c: -sun.direction.x * sun.length, d: -sun.direction.y * sun.length, tx: 0, ty: 0)
            let colour = Color(red: sun.tint.r, green: sun.tint.g, blue: sun.tint.b)
            // Room for the longest shadow around the feet.
            let room = CGSize(width: 300, height: 160)
            let origin = CGPoint(x: room.width / 2, y: 40)
            Canvas { context, _ in
                var image = context.resolve(Image(name, bundle: .module))
                image.shading = .color(colour)
                context.opacity = sun.opacity
                context.translateBy(x: origin.x, y: origin.y)
                context.concatenate(shear)
                context.draw(image, in: CGRect(x: box.minX, y: box.minY, width: box.width, height: box.height))
            }
            .frame(width: room.width, height: room.height)
            .position(x: feet.x - origin.x + room.width / 2, y: feet.y - origin.y + room.height / 2)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
#endif
