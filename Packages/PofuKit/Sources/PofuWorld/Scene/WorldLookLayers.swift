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
    /// How much of the harbor is on screen, 0...1 (its art fades as the camera leaves it): the harbor's
    /// lit overlays follow it.
    var harborFade = 0.0
    /// The graphics spike's normal lighting does the practicals' pools and
    /// the characters' rims instead.
    var relit = false
    /// A visitor sleeps in the guest room tonight (H4).
    var guestNight = false
    /// The frame policy's say on shafts, particles and flicker
    /// (`WorldPower.directive`); nil draws everything the light asks for.
    var directive: FrameDirective?

    /// The scene's time for sway and particles: quantised to the policy's
    /// 30 Hz when a policy drives the scene.
    private var ambient: Double {
        directive == nil ? time : FramePolicy.ambientTime(time)
    }

    var body: some View {
        // The field, outside the draw: it changes a few times an evening.
        // Its ground pools are the scene's (`GroundPoolLayer`), under every
        // object and character.
        let field = LightField.make(world: world, light: light, guestNight: guestNight)
        return Canvas(rendersAsynchronously: false) { context, size in
            var glow = context
            glow.blendMode = .plusLighter
            var paint = context
            drawLitOverlays(in: &paint)
            drawSunRims(in: &glow)
            drawGlints(in: &glow)
            if directive?.shafts ?? true {
                drawShafts(in: &glow, size: size)
            }
            drawSunBloom(in: &glow, size: size)
            if !relit {
                drawPools(in: &glow)
                drawRims(field: field, glow: &glow)
            }
            drawEmitters(in: &glow)
            drawFieldHalos(field, in: &glow)
            if directive?.particles ?? true {
                drawParticles(glow: &glow, paint: paint)
            }
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
        let sway = sin(ambient * 0.21) * 0.012
        layer.translateBy(x: sun.x, y: sun.y)
        layer.rotate(by: .radians(sway))
        layer.translateBy(x: -sun.x, y: -sun.y)
        layer.opacity = min(max(light.shafts, 0), 1) * (0.85 + 0.15 * sin(ambient * 0.37))
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
            // A wide painted halo and a tight core: bloom, not a lamp shade.
            drawHalo(&context, at: p, radius: max(emitter.radius * 3.2 * s, 2), color: color(emitter.color, 0.30 * min(k, 1.4)))
            let r = max(emitter.radius * s, 2)
            context.fill(
                Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)),
                with: .radialGradient(
                    Gradient(colors: [color(emitter.color, 0.75 * min(k, 1.4)), color(emitter.color, 0)]),
                    center: p, startRadius: 0, endRadius: r
                )
            )
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

    /// The lit edits (tea-stall-1-lit, workshop-1-lit, ...), one per row of
    /// the lit-source table, painted over the graded art at night in their
    /// own colour.
    private func drawLitOverlays(in context: inout GraphicsContext) {
        guard litOverlays else { return }
        let k = IslandLayout.litOverlayStrength(in: light)
        guard k > 0.01 else { return }
        for row in LitSources.rows {
            // Another island's overlay sits at depth 0 like its art and fades with it.
            let home = row.island == .home
            let fade = home ? 1 : harborFade
            guard fade > 0.01, let lit = row.overlayAnchor(world: world, guestNight: guestNight),
                  let image = sprite(lit.art, at: lit.anchor, depth: home ? IslandLayout.depth(ofY: lit.anchor.y) : 0) else { continue }
            var layer = context
            layer.opacity = k * fade
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

    /// The promoted `glow-warm-halo` (a soft round bloom, white on alpha),
    /// tinted and added: `radius` is where the bloom has faded to nothing.
    private func drawHalo(_ context: inout GraphicsContext, at p: CGPoint, radius: Double, color: Color) {
        var art = context.resolve(Image("glow-warm-halo", bundle: .module))
        art.shading = .color(color)
        let half = radius * LookTuning.warmHaloArtScale
        context.draw(art, in: CGRect(x: p.x - half, y: p.y - half, width: 2 * half, height: 2 * half))
    }

    /// A painted halo on each field source the emitters do not already
    /// draw (the lantern, path lamps, other windows, the pond), with the
    /// lantern's flicker in the Ambient state only.
    private func drawFieldHalos(_ field: LightField, in context: inout GraphicsContext) {
        let s = pose.scale
        let flicker = directive?.flicker ?? !ProcessInfo.processInfo.isLowPowerModeEnabled
        for source in field.sources where source.id != "ember" && source.id != "window-pofu" {
            let depth = IslandLayout.depth(ofY: source.point.y)
            var p = screen(source.point, depth: depth)
            p.y -= source.height * s * 0.6
            var k = min(source.strength, 1.4)
            if flicker, source.kind == .lantern {
                k *= 0.97 + 0.03 * sin(ambient * 9.1)
            }
            let radius = source.kind == .window || source.kind == .guestRoom ? 5.0 : 8.0
            // The painted halo round the lamp, then its tight core.
            drawHalo(&context, at: p, radius: max(radius * 3 * s, 2), color: color(source.colour, 0.22 * k))
            let r = max(radius * s, 2)
            context.fill(
                Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)),
                with: .radialGradient(
                    Gradient(colors: [color(source.colour, 0.6 * k), color(source.colour, 0)]),
                    center: p, startRadius: 0, endRadius: r
                )
            )
        }
    }

    /// The light on Pofu and the residents: a broad key from the dominant
    /// source's side (or the sun's rim by day), a bounce of the pool's
    /// colour on the lower third and a thin cool moon rim with the
    /// readability floor. Each is masked by the sprite's alpha, inside this
    /// one Canvas. The shadows are the shadow layer's (`ShadowBake`).
    private func drawRims(field: LightField, glow context: inout GraphicsContext) {
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
            let sample = field.sample(subject.feet)
            let r = mask.1
            let centre = CGPoint(x: r.midX, y: r.midY)
            let reach = Double(max(r.width, r.height)) / 2

            // The key: from the sun's side, or from the source when it
            // outshines the sun's rim.
            var dir = (x: -light.cell.key.from.x, y: -light.cell.key.from.y)
            var tint = light.cell.rim.colour
            var strength = light.cell.rim.intensity * calm
            let keyed = sample.strength * LookTuning.keyGain
            if keyed > strength {
                strength = keyed
                tint = sample.colour
                dir = (x: sample.directionX, y: sample.directionY)
            }
            if strength > 0.02 {
                let n = max(hypot(dir.x, dir.y), 1e-6)
                let ux = dir.x / n, uy = dir.y / n
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

            // The bounce: the pool's colour on the lower third.
            if sample.strength > 0.05 {
                let bounce = min(sample.strength * LookTuning.bounceGain, 0.45)
                shine(&context, on: mask, with: .linearGradient(
                    Gradient(stops: [
                        .init(color: color(sample.colour, bounce), location: 0),
                        .init(color: color(sample.colour, 0), location: 1),
                    ]),
                    startPoint: CGPoint(x: centre.x, y: r.maxY),
                    endPoint: CGPoint(x: centre.x, y: r.maxY - r.height / 3)
                ))
            }

            // The thin cool moon rim, with the readability floor: nobody is
            // ever a silhouette between sources.
            let moon = sample.moonRim * 0.5
            if moon > 0.01 || sample.ambient > 0.01 {
                let k = light.cell.key.from
                let n = max(hypot(k.x, k.y), 1e-6)
                let ux = -k.x / n, uy = -k.y / n
                let lift = sample.ambient * LookTuning.floorGain
                let moonColour = field.moonColour
                shine(&context, on: mask, with: .linearGradient(
                    Gradient(stops: [
                        .init(color: color(moonColour, lift + moon), location: 0),
                        .init(color: color(moonColour, lift + moon * 0.2), location: 0.22),
                        .init(color: color(moonColour, lift), location: 1),
                    ]),
                    startPoint: CGPoint(x: centre.x + ux * reach, y: centre.y + uy * reach),
                    endPoint: CGPoint(x: centre.x - ux * reach, y: centre.y - uy * reach)
                ))
            }
        }
    }

    // MARK: The sun on objects (visual round 2)

    /// The home stations that are built, with the anchor and art they draw
    /// at: the shared walk of the sun treatment below.
    private var builtStations: [(id: StationID, art: String, anchor: WorldPoint)] {
        world.stations.compactMap { status in
            guard status.island == .home, status.level > 0,
                  let slot = IslandLayout.stationAnchors[status.id],
                  let art = IslandLayout.stationArt(status.id, level: status.level)?.name else { return nil }
            return (status.id, art, IslandFootprint.clamped(slot, footprint: IslandFootprint.footprint(of: art)))
        }
    }

    /// How much sun there is: full by day, a little warmer and lower at
    /// golden hour and dawn, none at night.
    private var sunK: Double {
        min(light.day + 1.1 * light.golden, 1.1) * (1 - 0.5 * light.unwell)
    }

    /// A warm highlight on the sun's side of every built station, in the
    /// key's colour, masked by the station's alpha (day, dawn and golden
    /// hour; night has the practicals instead).
    private func drawSunRims(in context: inout GraphicsContext) {
        let k = sunK
        guard k > 0.05, pose.scale > 0.3 else { return }
        let key = light.cell.key
        let strength = min(0.36 * key.intensity * k, 0.42)
        let n = max(hypot(key.from.x, key.from.y), 1e-6)
        let ux = key.from.x / n, uy = key.from.y / n
        for station in builtStations {
            let depth = IslandLayout.depth(ofY: station.anchor.y)
            guard let mask = sprite(station.art, at: station.anchor, depth: depth) else { continue }
            let r = mask.1
            let centre = CGPoint(x: r.midX, y: r.midY)
            let reach = Double(max(r.width, r.height)) / 2
            let start = CGPoint(x: centre.x + ux * reach, y: centre.y + uy * reach)
            let end = CGPoint(x: centre.x - ux * reach * 0.2, y: centre.y - uy * reach * 0.2)
            shine(&context, on: mask, with: .linearGradient(
                Gradient(stops: [
                    .init(color: color(key.colour, strength), location: 0),
                    .init(color: color(key.colour, strength * 0.4), location: 0.25),
                    .init(color: color(key.colour, 0), location: 0.62),
                ]),
                startPoint: start, endPoint: end
            ))
        }
    }

    /// Where the glints sit on a station's art, as fractions of its box.
    private static let glintSpots: [StationID: [(x: Double, y: Double)]] = [
        .pond: [(0.22, 0.52), (0.38, 0.42), (0.55, 0.56), (0.70, 0.45), (0.47, 0.64), (0.80, 0.58)],
        .garden: [(0.30, 0.34), (0.50, 0.22), (0.68, 0.30), (0.42, 0.46), (0.78, 0.42)],
    ]

    /// Small specular glints on the pond and the sunflower heads: a dim
    /// base so the settled frame already shimmers, and a brief flash that
    /// moves only while the scene's time does (frozen when settled, in
    /// Low Power Mode and under Reduce Motion). Time is quantised to 30 Hz.
    private func drawGlints(in context: inout GraphicsContext) {
        let k = min(light.day + light.golden * 0.85, 1) * (1 - 0.6 * light.unwell)
        guard k > 0.05, pose.scale > 0.3 else { return }
        let s = pose.scale
        let live = !ProcessInfo.processInfo.isLowPowerModeEnabled
        let t = live ? (time * 30).rounded(.down) / 30 : 0
        let tint = GradeRGB(1, 0.97 - 0.1 * light.golden, 0.86 - 0.25 * light.golden)
        for station in builtStations {
            guard let spots = Self.glintSpots[station.id],
                  let box = WorldArt.sprite(WorldArt.key(station.art, art: art))?.sharp else { continue }
            let depth = IslandLayout.depth(ofY: station.anchor.y)
            for (i, spot) in spots.enumerated() {
                let phase = Double(i) * 1.7 + (station.id == .pond ? 0.4 : 2.1)
                let flash = pow(max(0, sin(t * 1.15 + phase * 2.3)), 8)
                let a = (0.3 + 0.7 * flash) * k
                let p = screen(
                    WorldPoint(x: station.anchor.x + box.minX + box.width * spot.x, y: station.anchor.y + box.minY + box.height * spot.y),
                    depth: depth
                )
                let r = (1.2 + 2.0 * flash) * max(s * 0.55, 0.8)
                dot(&context, p, r: r * 2.2, color: color(tint, 0.55 * a))
                // Two thin crossing strokes make it a glint, not a dot.
                let arm = (3.5 + 7 * flash) * max(s * 0.5, 0.8)
                var cross = Path()
                cross.move(to: CGPoint(x: p.x - arm, y: p.y))
                cross.addLine(to: CGPoint(x: p.x + arm, y: p.y))
                cross.move(to: CGPoint(x: p.x, y: p.y - arm * 0.8))
                cross.addLine(to: CGPoint(x: p.x, y: p.y + arm * 0.8))
                context.stroke(cross, with: .color(color(tint, 0.7 * a)), lineWidth: 0.8)
            }
        }
    }

    private func drawParticles(glow context: inout GraphicsContext, paint: GraphicsContext) {
        let s = pose.scale
        if light.pollen > 0.02 {
            let tint = GradeRGB(1, 0.97, 0.84)
            for i in 0..<28 {
                let (x0, y0, ph) = seed(i, salt: 1)
                let x = -200 + 400 * x0 + sin(ambient * 0.31 + ph * 6) * 7
                let rise = (ambient * 3.2 + ph * 70).truncatingRemainder(dividingBy: 70)
                let y = -150 + 190 * y0 - rise
                let fade = sin(rise / 70 * .pi)
                let p = screen(WorldPoint(x: x, y: y))
                let r = (0.9 + 1.3 * x0.truncatingRemainder(dividingBy: 0.5) * 2) * max(s * 0.55, 0.8)
                dot(&context, p, r: r * 2.4, color: color(tint, 0.55 * light.pollen * fade))
            }
        }
        if light.fireflies > 0.02 {
            // The promoted firefly sheet: four frames of one bug, the belly
            // dim, warming, bright, dim. The count and the blink are the
            // old dots' (battery gating is the caller's: `directive.particles`).
            let tint = GradeRGB(0.92, 1, 0.55)
            for i in 0..<LookTuning.fireflyCount {
                let (x0, y0, ph) = seed(i, salt: 7)
                let x = -190 + 380 * x0 + sin(ambient * 0.5 + ph * 5) * 10
                let y = -120 + 170 * y0 + cos(ambient * 0.43 + ph * 3) * 7
                let blink = max(0, sin(ambient * 1.6 + ph * 9)) * 0.75 + 0.25
                let p = screen(WorldPoint(x: x, y: y))
                let faces: CGFloat = cos(ambient * 0.5 + ph * 5) < 0 ? -1 : 1
                // The halo is the bug's glow, brightest with the belly.
                drawHalo(&context, at: p, radius: max(LookTuning.fireflyHaloRadius * s, 4), color: color(tint, 0.5 * light.fireflies * blink))
                let frame = LookTuning.fireflyFrame(blink: blink)
                let width = max(LookTuning.fireflyWidth * s, 5)
                let height = width * 0.92
                let rect = CGRect(x: p.x - width / 2, y: p.y - height / 2, width: width, height: height)
                var bug = paint
                bug.opacity = min(light.fireflies, 1) * (0.55 + 0.45 * blink)
                bug.translateBy(x: p.x, y: p.y)
                bug.scaleBy(x: faces, y: 1)
                bug.translateBy(x: -p.x, y: -p.y)
                bug.draw(Image("firefly-\(frame + 1)", bundle: .module), in: rect)
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

// MARK: - The light map, baked

/// The ground pools of every lit source: the baked light map as one image
/// in world space, on the lawn between the shadow layer and the objects, so
/// a pool never washes over a character or a station (they take the light
/// through their rims and bounce). The map's alpha is the pool's own
/// strength, capped by `LookTuning.poolArtOpacity`, so the lawn under it
/// never clips.
struct GroundPoolLayer: View {
    let field: LightField
    /// Where a world point lands on the canvas (the plate's depth).
    let place: (WorldPoint) -> CGPoint

    var body: some View {
        if let image = LightMapCache.image(for: field) {
            let bounds = LightField.mapBounds
            let width = bounds.maxX - bounds.minX, height = bounds.maxY - bounds.minY
            let origin = place(WorldPoint(x: bounds.minX, y: bounds.minY))
            image
                .resizable()
                .interpolation(.high)
                .frame(width: width, height: height)
                .position(x: origin.x + width / 2, y: origin.y + height / 2)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// The pools of every lit source, painted into one low-resolution map
/// (512 x 256 over `LightField.mapBounds`) and kept until the lit set or a
/// strength bucket changes, a few times an evening. Each frame draws it as
/// one quad.
@MainActor
private enum LightMapCache {
    private static var key: LightField.BakeKey?
    private static var cached: Image?

    static func image(for field: LightField) -> Image? {
        let wanted = field.bakeKey
        if key == wanted { return cached }
        key = wanted
        guard !wanted.entries.isEmpty else {
            cached = nil
            return nil
        }
        let renderer = ImageRenderer(content: PoolMapArt(field: field))
        renderer.scale = 1
        renderer.isOpaque = false
        cached = renderer.uiImage.map { Image(uiImage: $0) }
        return cached
    }
}

/// Every source's pool on black-transparent, in map pixels. The pools are
/// the promoted `glow-ground-pool`, `glow-pond-shimmer` and
/// `glow-window-spill` art, tinted and added.
private struct PoolMapArt: View {
    let field: LightField

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            let bounds = LightField.mapBounds
            let k = size.width / (bounds.maxX - bounds.minX)
            func map(_ p: WorldPoint) -> CGPoint {
                CGPoint(x: (p.x - bounds.minX) * k, y: (p.y - bounds.minY) * k)
            }
            func tint(_ c: GradeRGB, _ opacity: Double) -> Color {
                Color(red: c.r, green: c.g, blue: c.b).opacity(min(max(opacity, 0), 1))
            }
            var layer = context
            layer.blendMode = .plusLighter
            for source in field.sources {
                let strength = min(source.strength, 1.4)
                switch source.shape {
                case .round:
                    // The promoted glow-ground-pool art (a wide flat ellipse
                    // filling 80% of its width, white on alpha), tinted by
                    // the source and added.
                    let c = map(WorldPoint(x: source.point.x, y: source.point.y + 2))
                    let width = source.reach * k * 2
                    let height = width * 0.5
                    var art = layer.resolve(Image("glow-ground-pool", bundle: .module))
                    art.shading = .color(tint(source.colour, LookTuning.poolArtOpacity * strength))
                    layer.draw(art, in: CGRect(x: c.x - width / 2, y: c.y - height / 2, width: width, height: height))
                case .pondEllipse:
                    // The promoted glow-pond-shimmer art: soft bands of
                    // light lying on the water, tinted cool and added.
                    let c = map(WorldPoint(x: source.point.x, y: source.point.y + 2))
                    let width = source.reach * k * 2 * 1.15
                    let height = width * 0.5
                    var art = layer.resolve(Image("glow-pond-shimmer", bundle: .module))
                    art.shading = .color(tint(source.colour, LookTuning.pondShimmerOpacity * strength))
                    layer.draw(art, in: CGRect(x: c.x - width / 2, y: c.y - height / 2, width: width, height: height))
                case .windowSpill:
                    // The promoted glow-window-spill art: a soft trapezoid
                    // of light falling from the window onto the grass, its
                    // narrow top edge on the window's sill (the art is
                    // square; its light starts 7% down).
                    let top = map(WorldPoint(x: source.point.x, y: source.point.y + 4))
                    let size = source.reach * k * LookTuning.windowSpillArtScale
                    var art = layer.resolve(Image("glow-window-spill", bundle: .module))
                    art.shading = .color(tint(source.colour, LookTuning.windowSpillOpacity * strength))
                    layer.draw(art, in: CGRect(x: top.x - size / 2, y: top.y - size * 0.07, width: size, height: size))
                }
            }
        }
        .frame(width: CGFloat(LightField.mapWidth), height: CGFloat(LightField.mapHeight))
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
