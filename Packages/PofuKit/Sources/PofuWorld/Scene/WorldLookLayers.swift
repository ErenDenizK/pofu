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
        ]
    }

    var grade: WorldGrade {
        guard values.count == 13 else { return .neutral }
        let v = values
        return WorldGrade(
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
/// hour, and ambient particles (pollen by day, fireflies at night), drawn
/// additively over the graded world in one Canvas.
struct HD2DLayer: View {
    let world: WorldSnapshot
    let light: WorldLight
    let pose: CameraPose
    let offset: CGSize
    let size: CGSize
    /// Seconds; frozen while the scene is settled.
    let time: Double

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            var glow = context
            glow.blendMode = .plusLighter
            drawShafts(in: &glow, size: size)
            drawSunBloom(in: &glow, size: size)
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

    private func drawShafts(in context: inout GraphicsContext, size: CGSize) {
        guard light.shafts > 0.02 else { return }
        let sun = CGPoint(x: light.sunX * size.width, y: light.sunY * size.height)
        let target = CGPoint(x: size.width * 0.62, y: size.height * 0.78)
        let base = atan2(target.y - sun.y, target.x - sun.x)
        let length = hypot(size.width, size.height) * 1.1
        var layer = context
        layer.addFilter(.blur(radius: 14))
        let beams: [(angle: Double, width: Double, strength: Double)] = [
            (-0.30, 70, 0.8), (-0.13, 46, 1.0), (0.02, 96, 0.7), (0.17, 40, 0.9), (0.31, 64, 0.6),
        ]
        let warm = GradeRGB(1, 0.86, 0.62)
        for (i, beam) in beams.enumerated() {
            let sway = sin(time * 0.21 + Double(i) * 1.7) * 0.012
            let a = base + beam.angle * 0.55 + sway
            let dir = CGPoint(x: cos(a), y: sin(a))
            let normal = CGPoint(x: -dir.y, y: dir.x)
            let w0 = beam.width * 0.25, w1 = beam.width
            var path = Path()
            path.move(to: CGPoint(x: sun.x + normal.x * w0, y: sun.y + normal.y * w0))
            path.addLine(to: CGPoint(x: sun.x + dir.x * length + normal.x * w1, y: sun.y + dir.y * length + normal.y * w1))
            path.addLine(to: CGPoint(x: sun.x + dir.x * length - normal.x * w1, y: sun.y + dir.y * length - normal.y * w1))
            path.addLine(to: CGPoint(x: sun.x - normal.x * w0, y: sun.y - normal.y * w0))
            path.closeSubpath()
            let strength = 0.26 * light.shafts * beam.strength * (0.85 + 0.15 * sin(time * 0.37 + Double(i)))
            layer.fill(path, with: .linearGradient(
                Gradient(stops: [
                    .init(color: color(warm, strength * 0.4), location: 0),
                    .init(color: color(warm, strength), location: 0.25),
                    .init(color: color(warm, 0), location: 0.9),
                ]),
                startPoint: sun,
                endPoint: CGPoint(x: sun.x + dir.x * length, y: sun.y + dir.y * length)
            ))
        }
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
            let p = screen(emitter.point)
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
#endif
