#if os(iOS)
import PofuCore
import PofuDesignSystem
import SwiftUI

/// The build moment's dust puffs and sparkles, around a station's footprint
/// on the world canvas (interaction spec §2.4). Positions come from
/// `BuildMoment`; nothing here keeps time.
struct BuildParticles: View {
    let moment: BuildMoment
    let time: Double
    /// The footprint on the canvas.
    let point: CGPoint

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(moment.puffs(at: time).enumerated()), id: \.offset) { item in
                let puff = item.element
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.95), Color(red: 0.98, green: 0.94, blue: 0.86).opacity(0.7), Color.white.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 15
                        )
                    )
                    .frame(width: 30, height: 30)
                    .scaleEffect(CGFloat(puff.scale))
                    .opacity(puff.opacity)
                    .position(x: point.x + CGFloat(puff.x), y: point.y + CGFloat(puff.y))
            }
            ForEach(Array(moment.sparkles(at: time).enumerated()), id: \.offset) { item in
                let sparkle = item.element
                SparkleShape()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, PofuPrimitive.honey300.rgb.color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 14, height: 14)
                    .shadow(color: PofuPrimitive.honey400.rgb.color.opacity(0.7), radius: 2.5)
                    .scaleEffect(CGFloat(sparkle.scale))
                    .rotationEffect(.degrees(sparkle.rotation))
                    .opacity(sparkle.opacity)
                    .position(x: point.x + CGFloat(sparkle.x), y: point.y + CGFloat(sparkle.y))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A four-pointed sparkle.
struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let waist = r * 0.28
        var path = Path()
        path.move(to: CGPoint(x: c.x, y: c.y - r))
        path.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: CGPoint(x: c.x + waist, y: c.y - waist))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: CGPoint(x: c.x + waist, y: c.y + waist))
        path.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: CGPoint(x: c.x - waist, y: c.y + waist))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: CGPoint(x: c.x - waist, y: c.y - waist))
        path.closeSubpath()
        return path
    }
}

/// A station's level, where its art is a stand-in shared by every level
/// (the build's swap still flips it inside the squash): a small cream disc
/// with the numeral, on the vignette's upper right.
struct LevelBadge: View {
    let level: Int

    var body: some View {
        Text(verbatim: "\(level)")
            .font(.system(size: 7.5, weight: .heavy, design: .rounded).monospacedDigit())
            .foregroundStyle(PofuPrimitive.ink700.rgb.color)
            .frame(width: 12, height: 12)
            .background(Circle().fill(PofuPrimitive.cream50.rgb.color))
            .overlay(Circle().strokeBorder(PofuPrimitive.honey400.rgb.color, lineWidth: 1))
            .shadow(color: Color.shadowInk.opacity(0.25), radius: 1, y: 0.5)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// "Seviye n!": the build's one exclamation (§6.3), crisp in screen space
/// above the station.
struct BuildTag: View {
    let level: Int
    /// The seeds the level took, said under the exclamation.
    var cost: Int?

    var body: some View {
        VStack(spacing: 0) {
            Text(WorldStrings.levelUp(level))
                .font(PofuFont.headline)
            if let cost {
                HStack(spacing: 4) {
                    SeedIcon(size: 12)
                    Text(verbatim: WorldStrings.buildSpent(cost))
                        .font(PofuFont.footnote.weight(.semibold).monospacedDigit())
                }
                .opacity(0.82)
            }
        }
        .foregroundStyle(Color.paperInk)
        .padding(.horizontal, PofuSpacing.m + 4)
        .padding(.vertical, cost == nil ? 0 : 5)
        .frame(minHeight: 36)
        // Celebration is painted, system UI is glass (look-dev C).
        .paintedPaper(cornerSeed: 5)
        .fixedSize()
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: cost.map { WorldStrings.levelUp(level) + " " + WorldStrings.buildSpent($0) } ?? WorldStrings.levelUp(level)))
        .accessibilityAddTraits(.updatesFrequently)
    }
}
// MARK: - The level-up ceremony of light

/// Warm light of the ceremony: the lit sources' flare and the burst.
private let ceremonyWarm = (r: 1.0, g: 0.80, b: 0.48)

/// The station's lit sources flaring one after another, and the warm burst
/// that blooms from the building and covers the shadow bake's rebuild
/// (light and shadow v2, section 5). Drawn additively in one Canvas around
/// the station's footprint; the burst reuses `glow-ground-pool`. Positions
/// and strengths come from `BuildMoment`; nothing here keeps time.
struct LevelUpBloom: View {
    let moment: BuildMoment
    let time: Double
    /// The footprint on the canvas.
    let point: CGPoint

    var body: some View {
        let anchor = Self.anchor(of: moment.station, level: moment.toLevel)
        let lamps = BuildMoment.litPoints(station: moment.station, level: moment.toLevel)
        let burst = moment.burst(at: time)
        let flares = lamps.indices.map { moment.lampFlare(index: $0, at: time) }
        if burst != nil || flares.contains(where: { $0 > 0.001 }) {
            let room = CGSize(width: 480, height: 360)
            Canvas(rendersAsynchronously: false) { context, size in
                let centre = CGPoint(x: size.width / 2, y: size.height / 2)
                var glow = context
                glow.blendMode = .plusLighter
                if let burst {
                    let tint = Color(red: ceremonyWarm.r, green: ceremonyWarm.g, blue: ceremonyWarm.b)
                    // The pool on the ground, the existing glow art.
                    var pool = glow.resolve(Image("glow-ground-pool", bundle: .module))
                    pool.shading = .color(tint.opacity(burst.opacity))
                    let w = burst.radius * 2.6, h = w * 0.5
                    glow.draw(pool, in: CGRect(x: centre.x - w / 2, y: centre.y - h / 2 + 2, width: w, height: h))
                    // The bloom around the building.
                    let c = CGPoint(x: centre.x, y: centre.y - 24)
                    glow.fill(
                        Path(ellipseIn: CGRect(x: c.x - burst.radius, y: c.y - burst.radius, width: burst.radius * 2, height: burst.radius * 2)),
                        with: .radialGradient(
                            Gradient(colors: [tint.opacity(burst.opacity * 0.9), tint.opacity(burst.opacity * 0.3), tint.opacity(0)]),
                            center: c, startRadius: 0, endRadius: burst.radius
                        )
                    )
                }
                for (i, lamp) in lamps.enumerated() where flares[i] > 0.001 {
                    let k = flares[i]
                    let p = CGPoint(x: centre.x + CGFloat(lamp.x - anchor.x), y: centre.y + CGFloat(lamp.y - anchor.y))
                    // A wide halo and a tight core, as the emitters draw them.
                    for (radius, opacity) in [(34.0 * (0.7 + 0.5 * k), 0.45), (11.0 * (0.8 + 0.4 * k), 0.95)] {
                        let tint = Color(red: ceremonyWarm.r, green: ceremonyWarm.g, blue: ceremonyWarm.b)
                        glow.fill(
                            Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)),
                            with: .radialGradient(
                                Gradient(colors: [tint.opacity(opacity * k), tint.opacity(0)]),
                                center: p, startRadius: 0, endRadius: radius
                            )
                        )
                    }
                }
            }
            .frame(width: room.width, height: room.height)
            .position(x: point.x, y: point.y)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    /// The station's (footprint-clamped) anchor at `level`, in world units.
    static func anchor(of station: StationID, level: Int) -> WorldPoint {
        guard let slot = IslandLayout.stationAnchors[station] else { return .zero }
        let art = IslandLayout.stationArt(station, level: level)?.name ?? ""
        return IslandFootprint.clamped(slot, footprint: IslandFootprint.footprint(of: art))
    }
}

/// The ground pad under the building, brighter for 1.2 s: the existing pool
/// art added over the grass in the ground layer, under every object.
struct LevelUpPad: View {
    let moment: BuildMoment
    let time: Double
    /// Where a world point lands on the canvas (the plate's depth).
    let place: (WorldPoint) -> CGPoint

    var body: some View {
        let glow = moment.padGlow(at: time)
        if glow > 0.001, let art = IslandLayout.stationArt(moment.station, level: moment.toLevel)?.name {
            let anchor = LevelUpBloom.anchor(of: moment.station, level: moment.toLevel)
            let pad = ShadowCasters.padBox(of: IslandFootprint.footprint(of: art))
            let width = max((pad.maxX - pad.minX) * 1.6, 60), height = max(width * 0.45, 28)
            let centre = place(WorldPoint(x: anchor.x + (pad.minX + pad.maxX) / 2, y: anchor.y + (pad.minY + pad.maxY) / 2))
            Canvas(rendersAsynchronously: false) { context, size in
                var glow2 = context
                glow2.blendMode = .plusLighter
                var image = glow2.resolve(Image("glow-ground-pool", bundle: .module))
                image.shading = .color(Color(red: ceremonyWarm.r, green: ceremonyWarm.g, blue: ceremonyWarm.b).opacity(0.7 * glow))
                glow2.draw(image, in: CGRect(origin: .zero, size: size))
            }
            .frame(width: width, height: height)
            .position(x: centre.x, y: centre.y)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

// MARK: - Cloud shadows

/// The cloud shadows, in the ground layer next to the baked shadow layer:
/// one pre-rendered tile (no blur per frame) translated across the island.
/// Two copies cover the window at any drift.
struct CloudShadowLayer: View {
    let frame: CloudShadows.Frame
    /// Where a world point lands on the canvas (the plate's depth).
    let place: (WorldPoint) -> CGPoint

    var body: some View {
        if let tile = CloudTileCache.image {
            let window = CloudShadows.window
            let width = window.maxX - window.minX, height = window.maxY - window.minY
            let origin = place(WorldPoint(x: window.minX, y: window.minY))
            let tint = Color(red: frame.tint.r, green: frame.tint.g, blue: frame.tint.b)
            Canvas(rendersAsynchronously: false) { context, _ in
                var image = context.resolve(tile)
                image.shading = .color(tint)
                context.opacity = frame.opacity
                let w = CloudShadows.tileWidth, h = CloudShadows.tileHeight
                for x in [frame.shift, frame.shift - w] {
                    context.draw(image, in: CGRect(x: x, y: 0, width: w, height: h))
                }
            }
            .frame(width: width, height: height)
            .position(x: origin.x + width / 2, y: origin.y + height / 2)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Where the clouds hold while they do not drift, so a settled frame shows
/// them where the last Ambient frame left them.
@MainActor
enum CloudHold {
    private static var shift = 0.0

    static func frame(
        shadow: SunShadow,
        directive: FrameDirective,
        conditions: FrameConditions,
        ambientTime: Double
    ) -> CloudShadows.Frame? {
        let frame = CloudShadows.frame(
            shadow: shadow,
            directive: directive,
            lowPower: conditions.lowPower,
            reduceMotion: conditions.reduceMotion,
            ambientTime: ambientTime,
            held: shift
        )
        if let frame, CloudShadows.drifts(under: directive) { shift = frame.shift }
        return frame
    }
}

/// The tile, rendered once: soft white ellipses on clear (radial gradients,
/// so no blur filter), tinted at draw time.
@MainActor
private enum CloudTileCache {
    static let image: Image? = {
        let renderer = ImageRenderer(content: CloudTileArt())
        renderer.scale = 0.5
        renderer.isOpaque = false
        return renderer.uiImage.map { Image(uiImage: $0) }
    }()
}

private struct CloudTileArt: View {
    var body: some View {
        Canvas(rendersAsynchronously: false) { context, _ in
            for shape in CloudShadows.shapes {
                var layer = context
                layer.translateBy(x: shape.x, y: shape.y)
                layer.scaleBy(x: shape.radiusX, y: shape.radiusY)
                layer.fill(
                    Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: Color.white.opacity(shape.weight), location: 0),
                            .init(color: Color.white.opacity(shape.weight * 0.55), location: 0.45),
                            .init(color: Color.white.opacity(0), location: 1),
                        ]),
                        center: .zero, startRadius: 0, endRadius: 1
                    )
                )
            }
        }
        .frame(width: CloudShadows.tileWidth, height: CloudShadows.tileHeight)
    }
}
#endif
