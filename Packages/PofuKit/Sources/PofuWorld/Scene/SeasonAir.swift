import Foundation
import PofuCore

// The season's air (island calendar v1, C2): leaves in autumn, snow when it
// snows, fireflies kept to the warm half of the year, a hair of tint, all of
// it calm. The pure half lives here, so every platform tests it: how many
// of each, where each one is at a time, what the light does, and when the
// particles run at all. The drawn half (`SeasonAirLayer`) is below, iOS only.

public enum SeasonAir {
    /// What the air draws now.
    public struct Plan: Hashable, Sendable {
        public var leaves: Int
        public var flakes: Int

        public init(leaves: Int = 0, flakes: Int = 0) {
            self.leaves = max(0, leaves)
            self.flakes = max(0, flakes)
        }

        public static let none = Plan()

        public var isEmpty: Bool { leaves == 0 && flakes == 0 }
    }

    /// Leaves on a clear autumn day, flakes in a snowfall: counts for the
    /// device's 402 pt width (batch 25's frames show about a dozen of each
    /// on a screen, sparse and small). Halve these first if the particles
    /// ever cost frames.
    public static let leafCount = 9
    public static let flakeCount = 36

    /// The air for a season under a weather. Snow falls wherever the sky
    /// says it does (the island's winter rolls it; a special day may too);
    /// leaves belong to autumn and keep out of the rain and the snow.
    public static func plan(season: Season?, weather: Weather) -> Plan {
        if weather.isSnowing { return Plan(flakes: flakeCount) }
        guard season == .autumn else { return .none }
        switch weather {
        case .lightRain: return Plan(leaves: 3)
        case .mist: return Plan(leaves: 5)
        default: return Plan(leaves: leafCount)
        }
    }

    /// Fireflies stay: spring keeps the ones it ships with (so every spring
    /// frame stays as it was), summer has them, autumn and winter nights
    /// are dark and still.
    public static func fireflies(_ season: Season?) -> Double {
        switch season {
        case nil, .spring?, .summer?: 1
        case .autumn?, .winter?: 0
        }
    }

    /// The fireflies over a painted island: summer nights only. The painted
    /// Home has never drawn any (the sprite island's are `HD2DLayer`'s), so
    /// spring, which ships without them, stays as it is.
    public static func paintedFireflies(_ season: Season?) -> Double {
        season == .summer ? 1 : 0
    }

    /// Fireflies over the painted island: enough to be found, few enough to
    /// stay calm (the sprite island has `LookTuning.fireflyCount`, 18).
    public static let fireflyCount = 12

    /// Pollen is spring's and summer's; the leaves and the snow take its place.
    public static func pollen(_ season: Season?) -> Double {
        switch season {
        case nil, .spring?, .summer?: 1
        case .autumn?, .winter?: 0
        }
    }

    /// The season's light, a gain on the grade: a little warmer in autumn,
    /// a little cooler in winter. A few per cent: felt, never a filter.
    public static func tint(_ season: Season?) -> GradeRGB {
        switch season {
        case .autumn?: GradeRGB(1.025, 1.0, 0.965)
        case .winter?: GradeRGB(0.975, 0.995, 1.03)
        default: .one
        }
    }

    // MARK: The off switches (the same as rain's)

    /// Particles are drawn at all: not under Reduce Motion, not in Low Power Mode.
    public static func draws(reduceMotion: Bool, lowPower: Bool) -> Bool {
        !reduceMotion && !lowPower
    }

    /// They move: the ambient tier is running (`FramePolicy`: `ambientPaused`
    /// is the frame policy's pause), the frame is not settled, and neither
    /// Reduce Motion nor Low Power asks for stillness.
    public static func moves(still: Bool, ambientPaused: Bool, reduceMotion: Bool, lowPower: Bool) -> Bool {
        !(still || ambientPaused || reduceMotion || lowPower)
    }

    // MARK: Where each one is

    /// One flake: a position in points inside a `width` by `height` screen, a
    /// radius and an opacity.
    public struct Flake: Hashable, Sendable {
        public var x: Double
        public var y: Double
        public var radius: Double
        public var opacity: Double
    }

    /// One leaf: its centre, length, turn, how far it has tipped (1 flat,
    /// less edge-on), opacity and which of the three colours.
    public struct Leaf: Hashable, Sendable {
        public var x: Double
        public var y: Double
        public var length: Double
        public var angle: Double
        public var tip: Double
        public var opacity: Double
        public var variant: Int
    }

    /// One firefly in the world's units (where `HD2DLayer`'s fly), its blink
    /// 0.25...1 and the way it faces.
    public struct Firefly: Hashable, Sendable {
        public var x: Double
        public var y: Double
        public var blink: Double
        public var faces: Double
    }

    public static func firefly(_ i: Int, time: Double) -> Firefly {
        let phase = unit(i, 31)
        let x = -190 + 380 * unit(i, 32) + sin(time * 0.5 + phase * 5) * 10
        let y = -120 + 170 * unit(i, 33) + cos(time * 0.43 + phase * 3) * 7
        let blink = max(0, sin(time * 1.6 + phase * 9)) * 0.75 + 0.25
        return Firefly(x: x, y: y, blink: blink, faces: cos(time * 0.5 + phase * 5) < 0 ? -1 : 1)
    }

    /// How far above and below the screen a particle lives, so it never
    /// pops in or out.
    static let margin = 24.0

    static func unit(_ i: Int, _ salt: UInt64) -> Double {
        var g = SplitMix64(seed: UInt64(truncatingIfNeeded: i) &* 0x9E37_79B9_7F4A_7C15 &+ salt &* 0xD1B5_4A32_D192_ED03)
        return Double(g.next() >> 11) / 9_007_199_254_740_992.0
    }

    /// A low-discrepancy spread (the R2 sequence): even, never a grid.
    static func spread(_ i: Int) -> (Double, Double) {
        func frac(_ v: Double) -> Double { v - v.rounded(.down) }
        let n = Double(i + 1)
        return (frac(0.5 + n * 0.754_877_666_2), frac(0.5 + n * 0.569_840_291_0))
    }

    /// The edge ramp: 0 off the screen, 1 a little inside it.
    static func ramp(_ y: Double, height: Double) -> Double {
        let edge = max(height * 0.05, 1)
        let t = min(max(min(y + margin, height + margin - y) / (edge + margin), 0), 1)
        return t * t * (3 - 2 * t)
    }

    public static func flake(_ i: Int, time: Double, width: Double, height: Double) -> Flake {
        let (sx, sy) = spread(i)
        let jx = (unit(i, 1) - 0.5) * 0.08
        let jy = (unit(i, 2) - 0.5) * 0.08
        let size = unit(i, 3)
        let radius = 1.3 + 2.1 * size * size
        // Near (big) flakes fall a little faster than far (small) ones.
        let speed = 11 + 7 * radius
        let span = height + 2 * margin
        let fall = (sy + jy) * span + speed * time
        let y = fall.truncatingRemainder(dividingBy: span) - margin
        let sway = (5 + 9 * unit(i, 4)) * sin(time * (0.25 + 0.3 * unit(i, 5)) + 6.28 * unit(i, 6))
        let x = (sx + jx) * width + sway
        // Big flakes are the soft, near ones: fainter.
        let opacity = (0.9 - 0.35 * size) * ramp(y, height: height)
        return Flake(x: x, y: y, radius: radius, opacity: max(opacity, 0))
    }

    public static func leaf(_ i: Int, time: Double, width: Double, height: Double) -> Leaf {
        let (sx, sy) = spread(i + 11)
        let jx = (unit(i, 11) - 0.5) * 0.1
        let jy = (unit(i, 12) - 0.5) * 0.1
        let speed = 9 + 7 * unit(i, 13)
        let span = height + 2 * margin
        let fall = (sy + jy) * span + speed * time
        let y = fall.truncatingRemainder(dividingBy: span) - margin
        let swayAmp = 16 + 16 * unit(i, 14)
        let phase = 6.28 * unit(i, 16)
        let x = (sx + jx) * width + swayAmp * sin(time * (0.35 + 0.3 * unit(i, 15)) + phase)
        let angle = 0.9 * sin(time * (0.4 + 0.3 * unit(i, 17)) + phase) + 6.28 * unit(i, 18)
        let tip = 0.55 + 0.45 * abs(cos(time * (0.5 + 0.4 * unit(i, 19)) + phase))
        return Leaf(
            x: x, y: y, length: 10 + 4 * unit(i, 20), angle: angle, tip: tip,
            opacity: max(0.8 * ramp(y, height: height), 0), variant: Int(unit(i, 21) * 3) % 3
        )
    }
}

extension WorldLight {
    /// This light in the island's season: the fireflies and the pollen the
    /// season keeps, and its tint on the grade. Spring (and no season) is
    /// returned as it is, so the shipped island does not move.
    public func withSeason(_ season: Season?) -> WorldLight {
        guard let season, season != .spring else { return self }
        var copy = self
        copy.fireflies *= SeasonAir.fireflies(season)
        copy.pollen *= SeasonAir.pollen(season)
        copy.grade.gain = copy.grade.gain * SeasonAir.tint(season)
        return copy
    }
}

#if os(iOS)
import PofuDesignSystem
import SwiftUI
import UIKit

extension EnvironmentValues {
    /// A fixed time for the air (screenshots: one still frame of the
    /// moving layer at three moments); `nil` follows the ambient clock.
    @Entry public var seasonAirTime: Double? = nil
}

/// The code-drawn soft dot and leaves, cached.
@MainActor
enum SeasonAirArt {
    private static var cache: [String: UIImage] = [:]

    /// A soft round flake: bright in the middle, gone at the edge, no ring.
    static func flake() -> UIImage {
        if let hit = cache["flake"] { return hit }
        let side: CGFloat = 48
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { renderer in
            let colours = [
                UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor,
                UIColor(red: 1, green: 1, blue: 1, alpha: 0.7).cgColor,
                UIColor(red: 1, green: 1, blue: 1, alpha: 0.18).cgColor,
                UIColor(red: 1, green: 1, blue: 1, alpha: 0).cgColor,
            ]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colours as CFArray, locations: [0, 0.35, 0.7, 1]) else { return }
            let centre = CGPoint(x: side / 2, y: side / 2)
            renderer.cgContext.drawRadialGradient(gradient, startCenter: centre, startRadius: 0, endCenter: centre, endRadius: side / 2, options: [])
        }
        cache["flake"] = image
        return image
    }

    private static let leafColours: [UIColor] = [
        UIColor(red: 0.93, green: 0.55, blue: 0.26, alpha: 1),
        UIColor(red: 0.96, green: 0.74, blue: 0.30, alpha: 1),
        UIColor(red: 0.83, green: 0.40, blue: 0.31, alpha: 1),
    ]

    /// A pointed leaf lying along the x axis, edges feathered by a small
    /// glow of its own colour so it reads soft at a few points wide.
    static func leaf(_ variant: Int) -> UIImage {
        let name = "leaf-\(variant)"
        if let hit = cache[name] { return hit }
        let side: CGFloat = 64
        let colour = leafColours[variant % leafColours.count]
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { renderer in
            let cg = renderer.cgContext
            let body = CGMutablePath()
            body.move(to: CGPoint(x: 8, y: 32))
            body.addQuadCurve(to: CGPoint(x: 56, y: 32), control: CGPoint(x: 30, y: 8))
            body.addQuadCurve(to: CGPoint(x: 8, y: 32), control: CGPoint(x: 30, y: 56))
            cg.setShadow(offset: .zero, blur: 4, color: colour.withAlphaComponent(0.7).cgColor)
            cg.setFillColor(colour.cgColor)
            cg.addPath(body)
            cg.fillPath()
            cg.setShadow(offset: .zero, blur: 0, color: nil)
            cg.setStrokeColor(UIColor(red: 1, green: 0.95, blue: 0.8, alpha: 0.35).cgColor)
            cg.setLineWidth(1.5)
            cg.move(to: CGPoint(x: 12, y: 32))
            cg.addLine(to: CGPoint(x: 50, y: 32))
            cg.strokePath()
        }
        cache[name] = image
        return image
    }
}

/// The air over the island: flakes or leaves drifting down the whole
/// screen, in front of everything the way rain is. Rides the 30 Hz ambient
/// tier; frozen at 0 Hz when settled; not drawn under Reduce Motion or in
/// Low Power Mode (`SeasonAir.draws`).
struct SeasonAirLayer: View {
    let plan: SeasonAir.Plan
    /// How dark it is, 0...1: leaves dim at night.
    let night: Double
    let pose: CameraPose
    let offset: CGSize
    let size: CGSize
    /// The fireflies' strength, 0...1 (summer nights over a painted island).
    var fireflies: Double = 0

    @Environment(\.worldStillFrame) private var still
    @Environment(\.worldAmbientPaused) private var ambientPaused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.seasonAirTime) private var fixedTime
    /// The last plan that drew something, so the air fades out rather than vanishing.
    @State private var shown: SeasonAir.Plan = .none

    var body: some View {
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        let draws = SeasonAir.draws(reduceMotion: reduceMotion, lowPower: lowPower)
        let moves = SeasonAir.moves(still: still || fixedTime != nil, ambientPaused: ambientPaused, reduceMotion: reduceMotion, lowPower: lowPower)
        let drawn = plan.isEmpty ? shown : plan
        let flake = Image(uiImage: SeasonAirArt.flake())
        let leaves = (0 ..< 3).map { Image(uiImage: SeasonAirArt.leaf($0)) }
        let glow = fireflies > 0.02
        let scale = CGFloat(pose.scale)
        PofuTimeline(hz: PofuFrameRate.event, paused: !moves) { context in
            let time = fixedTime ?? (still ? 0 : FramePolicy.ambientTime(context.date.timeIntervalSinceReferenceDate))
            Canvas { gc, canvas in
                guard draws else { return }
                let width = Double(canvas.width)
                let height = Double(canvas.height)
                let parallax = Double(offset.width) * 0.3
                if drawn.flakes > 0 {
                    let dot = gc.resolve(flake)
                    for i in 0 ..< drawn.flakes {
                        let f = SeasonAir.flake(i, time: time, width: width, height: height)
                        guard f.opacity > 0.01 else { continue }
                        var layer = gc
                        layer.opacity = f.opacity
                        let r = CGFloat(f.radius * 1.6)
                        layer.draw(dot, in: CGRect(x: CGFloat(f.x + parallax) - r, y: CGFloat(f.y) - r, width: r * 2, height: r * 2))
                    }
                }
                if drawn.leaves > 0 {
                    let resolved = leaves.map { gc.resolve($0) }
                    let dim = 1 - 0.5 * night
                    for i in 0 ..< drawn.leaves {
                        let l = SeasonAir.leaf(i, time: time, width: width, height: height)
                        guard l.opacity > 0.01 else { continue }
                        var layer = gc
                        layer.opacity = l.opacity * dim
                        layer.translateBy(x: CGFloat(l.x + parallax), y: CGFloat(l.y))
                        layer.rotate(by: .radians(l.angle))
                        layer.scaleBy(x: 1, y: CGFloat(l.tip))
                        let side = CGFloat(l.length * 1.3)
                        layer.draw(resolved[l.variant], in: CGRect(x: -side / 2, y: -side / 2, width: side, height: side))
                    }
                }
                if glow {
                    let tint = Color(red: 0.92, green: 1, blue: 0.55)
                    let frames = (1 ... 4).map { gc.resolve(Image("firefly-\($0)", bundle: .module)) }
                    for i in 0 ..< SeasonAir.fireflyCount {
                        let f = SeasonAir.firefly(i, time: time)
                        let p = CGPoint(
                            x: canvas.width / 2 + CGFloat((f.x - pose.lookX) * pose.scale) + offset.width,
                            y: CGFloat(pose.anchorY + (f.y - pose.lookY) * pose.scale) + offset.height
                        )
                        let radius = max(CGFloat(LookTuning.fireflyHaloRadius) * scale, 4)
                        var halo = gc
                        halo.blendMode = .plusLighter
                        halo.fill(
                            Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)),
                            with: .radialGradient(
                                Gradient(colors: [tint.opacity(0.5 * fireflies * f.blink), tint.opacity(0)]),
                                center: p, startRadius: 0, endRadius: radius
                            )
                        )
                        let width = max(CGFloat(LookTuning.fireflyWidth) * scale, 5)
                        let height = width * 0.92
                        var bug = gc
                        bug.opacity = min(fireflies, 1) * (0.55 + 0.45 * f.blink)
                        bug.translateBy(x: p.x, y: p.y)
                        bug.scaleBy(x: CGFloat(f.faces), y: 1)
                        bug.translateBy(x: -p.x, y: -p.y)
                        bug.draw(frames[LookTuning.fireflyFrame(blink: f.blink)], in: CGRect(x: p.x - width / 2, y: p.y - height / 2, width: width, height: height))
                    }
                }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .opacity(plan.isEmpty && !glow ? 0 : 1)
        .animation(still ? nil : .easeInOut(duration: 8), value: plan.isEmpty)
        .onAppear { if !plan.isEmpty { shown = plan } }
        .onChange(of: plan) { _, new in if !new.isEmpty { shown = new } }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
