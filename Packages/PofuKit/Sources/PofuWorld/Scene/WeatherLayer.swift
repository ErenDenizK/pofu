#if os(iOS)
import Observation
import PofuDesignSystem
import SwiftUI
import UIKit

// Weather and the screen haze, drawn (sky and weather v1 section 2.2, 2.2b).
// The light change lives in the colour script and `WorldLight.withAtmosphere`;
// this file draws what the light cannot: falling rain, splash ticks, puddle
// glints, the rainbow and the haze that rolls in from the harbor side. All
// of it rides the 30 Hz ambient tier; a settled frame shows the frozen state
// at 0 Hz. Rain and splashes (the particles) are off in Low Power Mode and
// under Reduce Motion; the light change stays.

// MARK: - The parting

/// The seam between a resisted reach and the haze: the reach handler calls
/// `part()`, and the haze opens a little with a soft shaft of light, then
/// closes again (`ScreenHaze.parting`). Hand one to the scene with
/// `.environment(\.screenHazeClearing, clearing)`.
@MainActor @Observable
public final class ScreenHazeClearing {
    public private(set) var partedAt: Date?

    public init(partedAt: Date? = nil) {
        self.partedAt = partedAt
    }

    /// A reach was resisted: part the haze now.
    public func part(at date: Date = Date()) {
        partedAt = date
    }

    /// How open the parting is at `date`, 0...1.
    public func parting(at date: Date) -> Double {
        ScreenHaze.parting(secondsSince: partedAt.map { date.timeIntervalSince($0) })
    }

    /// The parting as the grade sees it: open for the rise and the hold,
    /// closed after (the grade's own animation does the easing).
    public func partingTarget(at date: Date) -> Double {
        guard let partedAt else { return 0 }
        let s = date.timeIntervalSince(partedAt)
        return s >= 0 && s < ScreenHaze.partingRise + ScreenHaze.partingHold ? 1 : 0
    }
}

extension EnvironmentValues {
    /// Where a resisted reach parts the screen haze; `nil` when nothing is
    /// wired (previews, screenshots).
    @Entry public var screenHazeClearing: ScreenHazeClearing? = nil
}

// MARK: - Shared

/// Where the world's points land on the screen (the camera transform).
private struct WeatherProjection {
    let pose: CameraPose
    let offset: CGSize
    let size: CGSize

    func point(_ x: Double, _ y: Double) -> CGPoint {
        CGPoint(
            x: size.width / 2 + CGFloat((x - pose.lookX) * pose.scale) + offset.width,
            y: CGFloat(pose.anchorY + (y - pose.lookY) * pose.scale) + offset.height
        )
    }

    var scale: CGFloat { CGFloat(pose.scale) }
}

private struct WeatherMotion {
    let still: Bool
    let paused: Bool
    let reduceMotion: Bool

    /// Rain streaks and splashes are particles: off in Low Power Mode and
    /// under Reduce Motion.
    var particlesOn: Bool {
        !reduceMotion && !ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}

/// The code-drawn images, cached; the painted art replaces them by name
/// when it lands (`world-rain-tile`, `world-puddle-glint`, `world-rainbow-arc`).
@MainActor
enum WeatherArt {
    static let rainTileName = "world-rain-tile"
    static let puddleGlintName = "world-puddle-glint"
    static let rainbowArcName = "world-rainbow-arc"

    private static var cache: [String: UIImage] = [:]

    static func rainTile() -> UIImage {
        cached(rainTileName) { drawnRainTile() }
    }

    static func rainbowArc() -> UIImage? {
        UIImage(named: rainbowArcName, in: .module, compatibleWith: nil)
    }

    static func puddleGlint() -> UIImage? {
        UIImage(named: puddleGlintName, in: .module, compatibleWith: nil)
    }

    private static func cached(_ name: String, draw: () -> UIImage) -> UIImage {
        if let hit = cache[name] { return hit }
        let image = UIImage(named: name, in: .module, compatibleWith: nil) ?? draw()
        cache[name] = image
        return image
    }

    nonisolated static let tileSize: CGFloat = 256

    /// Thin soft streaks that wrap top to bottom, so the tile scrolls
    /// without a seam.
    static func drawnRainTile() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let size = CGSize(width: tileSize, height: tileSize)
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let cg = renderer.cgContext
            cg.setLineCap(.round)
            var g = CloudShape.Generator(state: 0x5A1B)
            for _ in 0 ..< 26 {
                let x = CGFloat(g.next()) * size.width
                let y = CGFloat(g.next()) * size.height
                let length = 16 + CGFloat(g.next()) * 26
                let alpha = 0.22 + 0.38 * g.next()
                cg.setStrokeColor(UIColor(red: 0.90, green: 0.95, blue: 1.0, alpha: CGFloat(alpha)).cgColor)
                cg.setLineWidth(1.0 + CGFloat(g.next()) * 0.7)
                for wrap in [CGFloat(0), -size.height] {
                    cg.move(to: CGPoint(x: x, y: y + wrap))
                    cg.addLine(to: CGPoint(x: x, y: y + wrap + length))
                }
                cg.strokePath()
            }
        }
    }
}

// MARK: - Rain (in front of the island)

/// Rain, splash ticks and puddle glints: two tiled streak layers at two
/// angles and speeds, up to 12 splash ticks and 3 to 6 puddle glints on the
/// plate's flat ground.
struct WeatherRain: View {
    let atmosphere: Atmosphere
    let pose: CameraPose
    let offset: CGSize
    let size: CGSize
    /// The sky's horizon (graded): the puddles reflect it.
    let horizon: PofuRGB

    @Environment(\.worldStillFrame) private var still
    @Environment(\.worldAmbientPaused) private var ambientPaused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct StreakLayer {
        let angle: Double
        let speed: Double
        let scale: CGFloat
        let opacity: Double
    }

    private static let layers = [
        StreakLayer(angle: 9, speed: 560, scale: 1.0, opacity: 0.85),
        StreakLayer(angle: 17, speed: 330, scale: 0.7, opacity: 0.6),
    ]

    /// The puddles' places on the lawn (world units around its centre), clear
    /// of Pofu's spot; the first three show in the rainbow hour.
    static let puddles: [(x: Double, y: Double, rx: Double, ry: Double)] = [
        (-150, 12, 34, 7), (96, 30, 30, 6), (-70, 34, 26, 5),
        (170, 8, 24, 5), (-205, 28, 22, 4.5), (40, -8, 22, 4.5),
    ]

    /// Up to twelve splash ticks, on the lawn's front half.
    static let splashes: [(x: Double, y: Double, phase: Double)] = (0 ..< 12).map { i in
        let t = Double(i)
        return (
            x: -215 + (t * 37.3).truncatingRemainder(dividingBy: 430),
            y: -22 + (t * 17.9).truncatingRemainder(dividingBy: 62),
            phase: (t * 0.381).truncatingRemainder(dividingBy: 1)
        )
    }

    private var isPaused: Bool {
        still || ambientPaused || reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    var body: some View {
        let motion = WeatherMotion(still: still, paused: isPaused, reduceMotion: reduceMotion)
        let raining = atmosphere.conditions.weather.isRaining
        let wet = atmosphere.conditions.wet
        let tile = Image(uiImage: WeatherArt.rainTile())
        let projection = WeatherProjection(pose: pose, offset: offset, size: size)
        let reflection = horizon.mixed(with: PofuRGB(red: 1, green: 1, blue: 1), amount: 0.35)
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { context in
            let time = still ? 0 : FramePolicy.ambientTime(context.date.timeIntervalSinceReferenceDate)
            Canvas { gc, canvas in
                if wet {
                    drawPuddles(&gc, projection: projection, time: time, reflection: reflection, count: raining ? 6 : 4)
                }
                guard raining, motion.particlesOn else { return }
                drawSplashes(&gc, projection: projection, time: time)
                let resolved = gc.resolve(tile)
                for layer in Self.layers {
                    drawStreaks(gc, resolved, layer: layer, time: time, canvas: canvas)
                }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .opacity(raining || wet ? 1 : 0)
        .animation(still ? nil : .easeInOut(duration: 8), value: raining)
        .animation(still ? nil : .easeInOut(duration: 8), value: wet)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawStreaks(_ base: GraphicsContext, _ tile: GraphicsContext.ResolvedImage, layer: StreakLayer, time: Double, canvas: CGSize) {
        var gc = base
        gc.opacity = layer.opacity
        gc.translateBy(x: canvas.width / 2, y: canvas.height / 2)
        gc.rotate(by: .degrees(layer.angle))
        let edge = WeatherArt.tileSize * layer.scale
        let phase = CGFloat((time * layer.speed).truncatingRemainder(dividingBy: Double(edge)))
        let span = hypot(canvas.width, canvas.height)
        let count = Int((span / edge).rounded(.up)) / 2 + 2
        for ix in -count ... count {
            for iy in -count ... count {
                let rect = CGRect(x: CGFloat(ix) * edge, y: CGFloat(iy) * edge + phase, width: edge, height: edge)
                gc.draw(tile, in: rect)
            }
        }
    }

    private func drawSplashes(_ gc: inout GraphicsContext, projection: WeatherProjection, time: Double) {
        for splash in Self.splashes {
            let t = (time / 0.9 + splash.phase).truncatingRemainder(dividingBy: 1)
            let centre = projection.point(splash.x, splash.y)
            let radius = (2.5 + 7.5 * t) * projection.scale
            let rect = CGRect(x: centre.x - radius, y: centre.y - radius * 0.38, width: radius * 2, height: radius * 0.76)
            gc.stroke(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.5 * (1 - t))), lineWidth: 1.1)
        }
    }

    private func drawPuddles(_ gc: inout GraphicsContext, projection: WeatherProjection, time: Double, reflection: PofuRGB, count: Int) {
        let colour = reflection.color
        let glintArt = WeatherArt.puddleGlint().map { gc.resolve(Image(uiImage: $0)) }
        for (i, puddle) in Self.puddles.prefix(count).enumerated() {
            let centre = projection.point(puddle.x, puddle.y)
            let rx = puddle.rx * Double(projection.scale)
            let ry = puddle.ry * Double(projection.scale)
            let rect = CGRect(x: centre.x - rx, y: centre.y - ry, width: rx * 2, height: ry * 2)
            let shimmer = 0.5 + 0.12 * sin(time * 1.3 + Double(i) * 1.9)
            gc.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    Gradient(colors: [colour.opacity(shimmer), colour.opacity(shimmer * 0.5), colour.opacity(0)]),
                    center: centre, startRadius: 0, endRadius: CGFloat(rx)
                )
            )
            if let glintArt {
                // The painted glint (batch 44): light on alpha, added over the puddle.
                var lit = gc
                lit.blendMode = .plusLighter
                lit.opacity = min(1, shimmer + 0.25)
                lit.draw(glintArt, in: rect.insetBy(dx: -rx * 0.2, dy: -ry * 0.35))
                continue
            }
            // The bright wet glint on the puddle's far edge.
            let glint = CGRect(x: centre.x - rx * 0.38, y: centre.y - ry * 0.45, width: rx * 0.76, height: ry * 0.34)
            gc.fill(Path(ellipseIn: glint), with: .color(Color.white.opacity(0.45 * shimmer + 0.15)))
        }
    }
}

// MARK: - The rainbow (behind the island)

/// The rainbow: one soft pastel arc behind the island, fading in over six
/// seconds, only within an hour after rain ends, by day.
struct WeatherRainbow: View {
    let atmosphere: Atmosphere
    let size: CGSize
    /// Where the cloud-sea line sits, in points from the top.
    let seaLine: Double
    let offset: CGSize

    @Environment(\.worldStillFrame) private var still
    @State private var shown = false

    private static let bands: [(r: Double, g: Double, b: Double)] = [
        (1.00, 0.72, 0.74), (1.00, 0.84, 0.70), (1.00, 0.96, 0.74),
        (0.78, 0.94, 0.76), (0.74, 0.88, 1.00), (0.84, 0.78, 0.98),
    ]

    var body: some View {
        let on = atmosphere.conditions.rainbow
        let visible = on && (shown || still)
        Group {
            if let art = WeatherArt.rainbowArc() {
                Image(uiImage: art).resizable().scaledToFit().frame(width: size.width * 1.05)
                    .position(x: size.width * 0.58, y: CGFloat(seaLine) - size.width * 0.26)
            } else {
                Canvas { gc, canvas in
                    let outer = canvas.width * 1.0
                    // The crest sits in the sky above the island's top.
                    let centre = CGPoint(x: canvas.width * 0.58, y: canvas.height * 0.115 + outer)
                    let width = canvas.width * 0.036
                    for (i, band) in Self.bands.enumerated() {
                        let radius = outer - CGFloat(i) * width
                        var path = Path()
                        path.addArc(center: centre, radius: radius, startAngle: .degrees(190), endAngle: .degrees(350), clockwise: false)
                        gc.stroke(
                            path,
                            with: .color(Color(red: band.r, green: band.g, blue: band.b).opacity(0.5)),
                            style: StrokeStyle(lineWidth: width + 1, lineCap: .round)
                        )
                    }
                }
                .blur(radius: 5)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .offset(x: offset.width * 0.5, y: offset.height * 0.2)
        .opacity(visible ? 0.8 : 0)
        .animation(still ? nil : .easeInOut(duration: 6), value: visible)
        .onAppear { shown = true }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - The screen haze (over the island)

/// The player's sky (section 2.2b): a cool lilac-grey haze that rolls in
/// from the harbor side (the left) and sits over home at any hour. Distinct
/// from weather mist, which is pale peach and lies on the sea at dawn. Value
/// contrast is kept: the veil is thin and thickest at the edge, never a
/// full-screen wash. A resisted reach parts it a little with a soft shaft.
struct ScreenHazeLayer: View {
    /// The haze before any parting, 0...1.
    let haze: Double
    let sunX: Double
    let offset: CGSize
    let size: CGSize
    let seaLine: Double

    @Environment(\.worldStillFrame) private var still
    @Environment(\.worldAmbientPaused) private var ambientPaused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.screenHazeClearing) private var clearing

    private var isPaused: Bool {
        still || ambientPaused || reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    var body: some View {
        let lilac = ScreenHaze.colour.color
        let screen = Double(size.width)
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { context in
            let time = still ? 0 : FramePolicy.ambientTime(context.date.timeIntervalSinceReferenceDate)
            let parting = clearing?.parting(at: context.date) ?? 0
            let amount = ScreenHaze.parted(haze, parting: parting)
            ZStack(alignment: .topLeading) {
                // The harbor side is thickest; the right stays nearly clear.
                LinearGradient(
                    stops: [
                        .init(color: lilac.opacity(0.46 * amount), location: 0),
                        .init(color: lilac.opacity(0.24 * amount), location: 0.5),
                        .init(color: lilac.opacity(0.10 * amount), location: 1),
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
                // Two banks roll in from the left and drift slowly.
                ForEach(0 ..< 2, id: \.self) { i in
                    let w = screen * (i == 0 ? 1.25 : 1.0)
                    let h = w * Double(FogCardImage.size.height / FogCardImage.size.width)
                    let drift = 14 * sin(time * 0.12 + Double(i) * 2.1)
                    Image(uiImage: FogCardImage.image(i + 1))
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: CGFloat(w), height: CGFloat(h))
                        .foregroundStyle(lilac)
                        .opacity(0.62 * amount)
                        .offset(
                            x: CGFloat(-0.42 * w + drift) + offset.width * 0.6,
                            y: CGFloat(seaLine - (i == 0 ? 120 : 20) - h / 2)
                        )
                }
                // The part: a soft shaft of light through the haze.
                if parting > 0.01 {
                    ShaftShape(topX: size.width * CGFloat(0.25 + 0.5 * sunX), width: size.width * 0.34, slant: size.width * 0.22)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1, green: 0.93, blue: 0.78).opacity(0.22 * parting), Color(red: 1, green: 0.93, blue: 0.78).opacity(0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(height: CGFloat(seaLine))
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .opacity(haze > 0.001 ? 1 : 0)
        .animation(still ? nil : .easeInOut(duration: 8), value: haze)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A slanted beam: narrow at the top, wide and shifted at the bottom.
private struct ShaftShape: Shape {
    let topX: CGFloat
    let width: CGFloat
    let slant: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: topX - width * 0.12, y: 0))
        path.addLine(to: CGPoint(x: topX + width * 0.12, y: 0))
        path.addLine(to: CGPoint(x: topX + width * 0.6 - slant, y: rect.maxY))
        path.addLine(to: CGPoint(x: topX - width * 0.6 - slant, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
#endif
