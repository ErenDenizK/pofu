#if os(iOS)
import PofuCore
import SwiftUI

// The world's look, drawn (look-dev A, B): the runtime grade and the
// painted HD-2D lite layers. Every layer
// here is either a Metal pass over the world layer or a cheap gradient
// layer; all of them render only when the scene's timeline does, so a
// settled world is a cached frame and costs nothing.

extension EnvironmentValues {
    /// The world scene's look flags; on by default, in the world only.
    @Entry public var worldLook: WorldLook = .standard
}

// MARK: - Shaders

/// Access to PofuWorld's Metal shaders (`WorldShaders.metal`). Like
/// `CompanionShaders`, the compiled library exists only in Xcode builds;
/// without it the grade is skipped.
enum WorldShaders {
    static let isAvailable: Bool =
        Bundle.module.url(forResource: "default", withExtension: "metallib") != nil

    static var library: ShaderLibrary { .bundle(.module) }

    static func grade(_ g: WorldGrade, size: CGSize) -> Shader {
        Shader(function: ShaderFunction(library: library, name: "pofuWorldGrade"), arguments: [
            .float2(g.black, g.white),
            .float3(g.lift.r, g.lift.g, g.lift.b),
            .float3(g.gamma.r, g.gamma.g, g.gamma.b),
            .float3(g.gain.r, g.gain.g, g.gain.b),
            .float4(g.contrast, g.pivot, g.saturation, g.vignette),
            .float2(size.width, size.height),
        ])
    }
}

// MARK: - The grade, interpolated over time

/// A grade as a flat vector, so SwiftUI can animate between grades.
struct GradeVector: VectorArithmetic {
    var values: [Double]

    init(_ values: [Double]) {
        self.values = values
    }

    init(_ g: WorldGrade) {
        values = [
            g.lift.r, g.lift.g, g.lift.b, g.gamma.r, g.gamma.g, g.gamma.b,
            g.gain.r, g.gain.g, g.gain.b, g.contrast, g.pivot, g.saturation, g.vignette,
            g.black, g.white,
        ]
    }

    var grade: WorldGrade {
        guard values.count == 15 else { return .neutral }
        let v = values
        return WorldGrade(
            black: v[13],
            white: v[14],
            lift: GradeRGB(v[0], v[1], v[2]),
            gamma: GradeRGB(v[3], v[4], v[5]),
            gain: GradeRGB(v[6], v[7], v[8]),
            contrast: v[9],
            pivot: v[10],
            saturation: v[11],
            vignette: v[12]
        )
    }

    static var zero: GradeVector { GradeVector([]) }

    private static func combine(_ a: GradeVector, _ b: GradeVector, _ op: (Double, Double) -> Double) -> GradeVector {
        let n = max(a.values.count, b.values.count)
        return GradeVector((0..<n).map { i in
            op(i < a.values.count ? a.values[i] : 0, i < b.values.count ? b.values[i] : 0)
        })
    }

    static func + (a: GradeVector, b: GradeVector) -> GradeVector { combine(a, b, +) }
    static func - (a: GradeVector, b: GradeVector) -> GradeVector { combine(a, b, -) }

    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
    }

    var magnitudeSquared: Double {
        values.reduce(0) { $0 + $1 * $1 }
    }
}

/// Applies a grade to the world layer; animatable, so a change of hour or
/// of Pofu's state eases over a few seconds instead of cutting.
struct GradeEffect: ViewModifier, Animatable {
    var vector: GradeVector
    var isEnabled: Bool

    init(grade: WorldGrade, isEnabled: Bool) {
        vector = GradeVector(grade)
        self.isEnabled = isEnabled
    }

    // Stored Sendable properties of a value type are readable off the
    // main actor (SE-0434), so the animation system may interpolate here.
    nonisolated var animatableData: GradeVector {
        get { vector }
        set { vector = newValue }
    }

    func body(content: Content) -> some View {
        let grade = vector.grade
        let enabled = isEnabled && WorldShaders.isAvailable && !grade.isNeutral
        content.visualEffect { view, proxy in
            view.colorEffect(WorldShaders.grade(grade, size: proxy.size), isEnabled: enabled)
        }
    }
}

// MARK: - Painted HD-2D lite

/// Bloom on the emissive points, soft light shafts from the sun at golden
/// hour, ambient particles (pollen by day, fireflies at night) and, from
/// look round 3, the colour script's light on things: the practicals' warm
/// pools on what stands near them (the ember on the çaydanlık) and a soft
/// rim on Pofu and the residents from the key or the nearest practical.
/// Drawn additively over the graded world in one Canvas; the pools and rims
/// are masked by the receiving sprite's alpha.
struct HD2DLayer: View {
    let world: WorldSnapshot
    let light: WorldLight
    let pose: CameraPose
    let offset: CGSize
    let size: CGSize
    /// Seconds; frozen while the scene is settled.
    let time: Double
    /// The camera's motion and the lens focus, so the glows ride with
    /// their objects during depth in motion.
    var motion: CameraMotion = .still
    var focus: Double = 0
    /// The peek and device tilt, so the light lands where the canvas drew.
    var tilt: (x: Double, y: Double) = (0, 0)
    /// The art set, so a mask is the sprite that was drawn.
    var art: WorldLook.ArtSet = .lockLight
    /// The painted night overlays of practical lights.
    var litOverlays = true
    /// The graphics spike's normal lighting does the practicals' pools and
    /// the characters' rims instead.
    var relit = false

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            var glow = context
            glow.blendMode = .plusLighter
            var paint = context
            drawLitOverlays(in: &paint)
            drawShafts(in: &glow, size: size)
            drawSunBloom(in: &glow, size: size)
            if !relit {
                drawPools(in: &glow)
                drawRims(in: &glow)
            }
            drawEmitters(in: &glow)
            drawParticles(in: &glow)
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func screen(_ p: WorldPoint) -> CGPoint {
        let s = pose.project(p, width: Double(size.width))
        return CGPoint(x: s.x + Double(offset.width), y: s.y + Double(offset.height))
    }

    private func color(_ c: GradeRGB, _ opacity: Double) -> Color {
        Color(red: c.r, green: c.g, blue: c.b).opacity(min(max(opacity, 0), 1))
    }

    /// The beams are blurred once (see `ShaftImageCache`); each frame only
    /// sways and fades that image.
    private func drawShafts(in context: inout GraphicsContext, size: CGSize) {
        guard light.shafts > 0.02, let image = shaftImage else { return }
        let sun = CGPoint(x: light.sunX * size.width, y: light.sunY * size.height)
        var layer = context
        let sway = sin(time * 0.21) * 0.012
        layer.translateBy(x: sun.x, y: sun.y)
        layer.rotate(by: .radians(sway))
        layer.translateBy(x: -sun.x, y: -sun.y)
        layer.opacity = min(max(light.shafts, 0), 1) * (0.85 + 0.15 * sin(time * 0.37))
        layer.draw(image, in: CGRect(origin: .zero, size: size))
    }

    /// The pre-rendered beams, or nil when the shafts are off.
    private var shaftImage: Image? {
        guard light.shafts > 0.02 else { return nil }
        return ShaftImageCache.image(size: size, sunX: light.sunX, sunY: light.sunY)
    }

    private func drawSunBloom(in context: inout GraphicsContext, size: CGSize) {
        let sun = CGPoint(x: light.sunX * size.width, y: light.sunY * size.height)
        let tint = GradeRGB(1, 0.93 - 0.12 * light.golden, 0.80 - 0.3 * light.golden + 0.2 * light.night)
        let r = size.width * (0.42 - 0.18 * light.night)
        let strength = 0.20 * light.bloom * (1 - 0.6 * light.night)
        context.fill(
            Path(ellipseIn: CGRect(x: sun.x - r, y: sun.y - r, width: 2 * r, height: 2 * r)),
            with: .radialGradient(
                Gradient(colors: [color(tint, strength), color(tint, 0)]),
                center: sun, startRadius: 0, endRadius: r
            )
        )
    }

    private func drawEmitters(in context: inout GraphicsContext) {
        let s = pose.scale
        for emitter in IslandLayout.emitters {
            if let station = emitter.station,
               (world.stations.first(where: { $0.id == station })?.level ?? 0) == 0 { continue }
            let k = emitter.strength(in: light)
            guard k > 0.02 else { continue }
            let m = DepthMotion.shift(
                point: emitter.point,
                depth: IslandLayout.depth(ofY: emitter.point.y),
                focus: focus,
                look: WorldPoint(x: pose.lookX, y: pose.lookY),
                motion: motion
            )
            let p = screen(WorldPoint(x: emitter.point.x + m.x, y: emitter.point.y + m.y))
            // A wide halo and a tight core: bloom, not a lamp shade.
            for (radius, opacity) in [(emitter.radius * 3.2, 0.30), (emitter.radius, 0.75)] {
                let r = max(radius * s, 2)
                context.fill(
                    Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)),
                    with: .radialGradient(
                        Gradient(colors: [color(emitter.color, opacity * min(k, 1.4)), color(emitter.color, 0)]),
                        center: p, startRadius: 0, endRadius: r
                    )
                )
            }
        }
    }

    // MARK: Light on things

    /// Where a world point at `depth` lands on screen, with the canvas's
    /// parallax (peek, tilt, depth in motion).
    private func screen(_ p: WorldPoint, depth: Double) -> CGPoint {
        let s = max(pose.scale, 0.01)
        let m = DepthMotion.shift(point: p, depth: depth, focus: focus, look: WorldPoint(x: pose.lookX, y: pose.lookY), motion: motion)
        let px = (depth - focus) * tilt.x * 0.12 / s
        let py = (depth - focus) * tilt.y * 0.06 / s
        return screen(WorldPoint(x: p.x + px + m.x, y: p.y + py + m.y))
    }

    /// A sprite's sharp image and its rect on screen, anchored at `anchor`.
    private func sprite(_ name: String, variant: DepthVariant = .sharp, at anchor: WorldPoint, depth: Double) -> (Image, CGRect)? {
        let key = WorldArt.key(name, art: art)
        guard let sprite = WorldArt.sprite(key), let box = sprite.box(for: variant) else { return nil }
        let a = screen(anchor, depth: depth)
        let s = pose.scale
        let rect = CGRect(x: a.x + box.minX * s, y: a.y + box.minY * s, width: box.width * s, height: box.height * s)
        return (Image(WorldArt.assetName(key, variant: variant), bundle: .module), rect)
    }

    /// Light falling on a sprite: `shading` filled over its rect, masked by
    /// its alpha.
    private func shine(_ context: inout GraphicsContext, on mask: (Image, CGRect), with shading: GraphicsContext.Shading) {
        context.drawLayer { layer in
            layer.clipToLayer { m in
                m.draw(mask.0, in: mask.1)
            }
            layer.fill(Path(mask.1), with: shading)
        }
    }

    /// The lit edits' flames (tea-stall-1-lit), painted over the graded station
    /// at night in their own colour.
    private func drawLitOverlays(in context: inout GraphicsContext) {
        guard litOverlays else { return }
        let k = IslandLayout.litOverlayStrength(in: light)
        guard k > 0.01 else { return }
        for status in world.stations where status.island == .home && status.level > 0 {
            guard let overlay = IslandLayout.litOverlay(status.id, level: status.level),
                  let slot = IslandLayout.stationAnchors[status.id],
                  let art = IslandLayout.stationArt(status.id, level: status.level)?.name else { continue }
            let anchor = IslandFootprint.clamped(slot, footprint: IslandFootprint.footprint(of: art))
            guard let image = sprite(overlay, at: anchor, depth: IslandLayout.depth(ofY: anchor.y)) else { continue }
            var layer = context
            layer.opacity = k
            layer.draw(image.0, in: image.1)
        }
    }

    /// The practicals' warm pools: the ember lights the çaydanlık and the
    /// stall around it, so the copper reads warm because the fire lights it
    /// (the colour script), not because it was repainted.
    private func drawPools(in context: inout GraphicsContext) {
        let s = pose.scale
        for emitter in IslandLayout.emitters {
            guard let station = emitter.station,
                  let level = world.stations.first(where: { $0.id == station })?.level, level > 0,
                  let slot = IslandLayout.stationAnchors[station],
                  let art = IslandLayout.stationArt(station, level: level)?.name else { continue }
            let k = min(emitter.strength(in: light), 1.2)
            guard k > 0.05 else { continue }
            let anchor = IslandFootprint.clamped(slot, footprint: IslandFootprint.footprint(of: art))
            let depth = IslandLayout.depth(ofY: anchor.y)
            guard let mask = sprite(art, at: anchor, depth: depth) else { continue }
            let c = screen(emitter.point, depth: IslandLayout.depth(ofY: emitter.point.y))
            let r = max(emitter.reach * s, 4)
            shine(&context, on: mask, with: .radialGradient(
                Gradient(stops: [
                    .init(color: color(emitter.color, 0.42 * k), location: 0),
                    .init(color: color(emitter.color, 0.16 * k), location: 0.45),
                    .init(color: color(emitter.color, 0), location: 1),
                ]),
                center: c, startRadius: 0, endRadius: r
            ))
        }
    }

    /// A soft rim on Pofu and the residents: from the nearest practical
    /// when it outshines the key (night, dusk), else from the key's side in
    /// the cell's rim colour.
    private func drawRims(in context: inout GraphicsContext) {
        guard pose.scale > 0.3 else { return }
        var subjects: [(name: String, variant: DepthVariant, feet: WorldPoint)] = [("pofu", .soft, IslandLayout.pofu)]
        for resident in IslandLayout.residents {
            guard (world.stations.first(where: { $0.id == resident.station })?.level ?? 0) > 0 else { continue }
            subjects.append((resident.art, .sharp, IslandFootprint.clamped(resident.feet, footprint: IslandFootprint.footprint(of: resident.art))))
        }
        let calm = 1 - 0.5 * light.unwell
        for subject in subjects {
            let depth = IslandLayout.depth(ofY: subject.feet.y)
            guard let mask = sprite(subject.name, variant: subject.variant, at: subject.feet, depth: depth) else { continue }
            // The key's rim, from the side the key comes from.
            var dir = (x: -light.cell.key.from.x, y: -light.cell.key.from.y)
            var tint = light.cell.rim.colour
            var strength = light.cell.rim.intensity * calm
            // A practical close enough outshines it.
            for emitter in IslandLayout.emitters {
                if let station = emitter.station, (world.stations.first(where: { $0.id == station })?.level ?? 0) == 0 { continue }
                let dx = emitter.point.x - subject.feet.x, dy = emitter.point.y - (subject.feet.y - 14)
                let d = hypot(dx, dy)
                let falloff = max(0, 1 - d / (emitter.reach * 1.6))
                let k = min(emitter.strength(in: light), 1.2) * falloff * 0.55
                if k > strength {
                    strength = k
                    tint = emitter.color
                    dir = (x: dx / max(d, 1e-6), y: dy / max(d, 1e-6))
                }
            }
            guard strength > 0.02 else { continue }
            let r = mask.1
            let centre = CGPoint(x: r.midX, y: r.midY)
            let n = hypot(dir.x, dir.y)
            let ux = dir.x / max(n, 1e-6), uy = dir.y / max(n, 1e-6)
            let reach = Double(max(r.width, r.height)) / 2
            let start = CGPoint(x: centre.x + ux * reach, y: centre.y + uy * reach)
            let end = CGPoint(x: centre.x - ux * reach * 0.1, y: centre.y - uy * reach * 0.1)
            shine(&context, on: mask, with: .linearGradient(
                Gradient(stops: [
                    .init(color: color(tint, min(strength, 0.7)), location: 0),
                    .init(color: color(tint, min(strength, 0.7) * 0.35), location: 0.3),
                    .init(color: color(tint, 0), location: 1),
                ]),
                startPoint: start, endPoint: end
            ))
        }
    }

    private func drawParticles(in context: inout GraphicsContext) {
        let s = pose.scale
        if light.pollen > 0.02 {
            let tint = GradeRGB(1, 0.97, 0.84)
            for i in 0..<28 {
                let (x0, y0, ph) = seed(i, salt: 1)
                let x = -200 + 400 * x0 + sin(time * 0.31 + ph * 6) * 7
                let rise = (time * 3.2 + ph * 70).truncatingRemainder(dividingBy: 70)
                let y = -150 + 190 * y0 - rise
                let fade = sin(rise / 70 * .pi)
                let p = screen(WorldPoint(x: x, y: y))
                let r = (0.9 + 1.3 * x0.truncatingRemainder(dividingBy: 0.5) * 2) * max(s * 0.55, 0.8)
                dot(&context, p, r: r * 2.4, color: color(tint, 0.55 * light.pollen * fade))
            }
        }
        if light.fireflies > 0.02 {
            let tint = GradeRGB(0.92, 1, 0.55)
            for i in 0..<18 {
                let (x0, y0, ph) = seed(i, salt: 7)
                let x = -190 + 380 * x0 + sin(time * 0.5 + ph * 5) * 10
                let y = -120 + 170 * y0 + cos(time * 0.43 + ph * 3) * 7
                let blink = max(0, sin(time * 1.6 + ph * 9)) * 0.75 + 0.25
                let p = screen(WorldPoint(x: x, y: y))
                let r = max(1.6 * s, 1.4)
                dot(&context, p, r: r * 5, color: color(tint, 0.35 * light.fireflies * blink))
                dot(&context, p, r: r * 1.3, color: color(tint, 0.95 * light.fireflies * blink))
            }
        }
    }

    private func dot(_ context: inout GraphicsContext, _ p: CGPoint, r: Double, color: Color) {
        context.fill(
            Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)),
            with: .radialGradient(Gradient(colors: [color, color.opacity(0)]), center: p, startRadius: 0, endRadius: r)
        )
    }

    /// A stable pseudo-random placement per particle.
    private func seed(_ i: Int, salt: Int) -> (Double, Double, Double) {
        func h(_ n: Double) -> Double {
            let v = sin(n) * 43758.5453
            return v - v.rounded(.down)
        }
        let n = Double(i * 31 + salt * 977)
        return (h(n * 12.9898), h(n * 78.233 + 1), h(n * 39.425 + 2))
    }
}

// MARK: - Light shafts, rendered once

/// The sun's five beams at full strength, blurred, drawn into an image
/// once per size and sun position. The per-frame Canvas only rotates and
/// fades the image instead of blurring five paths every frame.
@MainActor
private enum ShaftImageCache {
    private struct Key: Equatable {
        var width: Double
        var height: Double
        var sunX: Double
        var sunY: Double
    }

    private static var key: Key?
    private static var cached: Image?

    static func image(size: CGSize, sunX: Double, sunY: Double) -> Image? {
        let wanted = Key(
            width: Double(size.width).rounded(),
            height: Double(size.height).rounded(),
            sunX: (sunX * 200).rounded() / 200,
            sunY: (sunY * 200).rounded() / 200
        )
        if key == wanted { return cached }
        let renderer = ImageRenderer(content: ShaftArt(size: size, sunX: wanted.sunX, sunY: wanted.sunY))
        // The beams are blurred, so half resolution is indistinguishable.
        renderer.scale = 0.5
        renderer.isOpaque = false
        let image = renderer.uiImage.map { Image(uiImage: $0) }
        key = wanted
        cached = image
        return image
    }
}

/// The five beams, unswayed and at full strength, blurred.
private struct ShaftArt: View {
    let size: CGSize
    let sunX: Double
    let sunY: Double

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, canvas in
            let sun = CGPoint(x: sunX * canvas.width, y: sunY * canvas.height)
            let target = CGPoint(x: canvas.width * 0.62, y: canvas.height * 0.78)
            let base = atan2(target.y - sun.y, target.x - sun.x)
            let length = hypot(canvas.width, canvas.height) * 1.1
            var layer = context
            layer.addFilter(.blur(radius: 14))
            let beams: [(angle: Double, width: Double, strength: Double)] = [
                (-0.30, 70, 0.8), (-0.13, 46, 1.0), (0.02, 96, 0.7), (0.17, 40, 0.9), (0.31, 64, 0.6),
            ]
            for beam in beams {
                let a = base + beam.angle * 0.55
                let dir = CGPoint(x: cos(a), y: sin(a))
                let normal = CGPoint(x: -dir.y, y: dir.x)
                let w0 = beam.width * 0.25, w1 = beam.width
                var path = Path()
                path.move(to: CGPoint(x: sun.x + normal.x * w0, y: sun.y + normal.y * w0))
                path.addLine(to: CGPoint(x: sun.x + dir.x * length + normal.x * w1, y: sun.y + dir.y * length + normal.y * w1))
                path.addLine(to: CGPoint(x: sun.x + dir.x * length - normal.x * w1, y: sun.y + dir.y * length - normal.y * w1))
                path.addLine(to: CGPoint(x: sun.x - normal.x * w0, y: sun.y - normal.y * w0))
                path.closeSubpath()
                let strength = 0.26 * beam.strength
                let end = CGPoint(x: sun.x + dir.x * length, y: sun.y + dir.y * length)
                layer.fill(path, with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Self.warm(strength * 0.4), location: 0),
                        .init(color: Self.warm(strength), location: 0.25),
                        .init(color: Self.warm(0), location: 0.9),
                    ]),
                    startPoint: sun,
                    endPoint: end
                ))
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private static func warm(_ opacity: Double) -> Color {
        Color(red: 1, green: 0.86, blue: 0.62).opacity(min(max(opacity, 0), 1))
    }
}
#endif
