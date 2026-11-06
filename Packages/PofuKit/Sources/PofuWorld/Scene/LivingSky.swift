#if os(iOS)
import PofuDesignSystem
import SwiftUI

extension EnvironmentValues {
    /// Still-frame rendering, for screenshots: the sky's clouds stop at
    /// their time-zero places, so every run draws the same frame.
    @Entry public var worldStillFrame: Bool = false
    /// Screenshots: pins the residents' loop to a day and a time into a visit.
    @Entry public var worldResidentPin: ResidentLife.Pin?
    /// The world is settled under the look (look-dev B): the drift holds
    /// where it is, so the settled frame is cached and costs nothing.
    @Entry var worldAmbientPaused: Bool = false
}

/// The sky behind the islands (design language §12; boundary doc §6.3's
/// calm bands): a gradient and a sun or moon glow that follow the
/// snapshot's clock, stars that twinkle at night, and three layers of
/// painted clouds that drift slowly at different speeds (parallax 1x, 1.8x
/// and 3x: the far layer moves least; sky and weather v1 §2.1).
///
/// Cheap enough to idle under the 60 fps world: the clouds are tinted once
/// per palette (equatable, rasterised once) and only their offsets change,
/// on a 30 Hz timeline (a cloud moves under 3 pt a second, a tenth of a
/// point a frame). Reduce Motion, Low Power Mode and still frames stop the
/// drift and the twinkle, so the settled frame is cached at 0 Hz.
struct LivingSky: View {
    /// Already graded (`SkyPalette.graded(by:)`): the sky takes no shader
    /// pass of its own (look round 3).
    let palette: SkyPalette
    /// The peek's screen offset; the sky moves 0.3× and 0.6× of it.
    let offset: CGSize
    /// The far isles and painted clouds (look round 3).
    var far: FarSky.Look?

    @Environment(\.worldStillFrame) private var still
    @Environment(\.worldAmbientPaused) private var ambientPaused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [palette.zenith.color, palette.horizon.color],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.75)
                )
                SunGlow(palette: palette, size: size)
                    .offset(x: offset.width * 0.15, y: offset.height * 0.15)
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { context in
                    let time = still ? 0 : FramePolicy.ambientTime(context.date.timeIntervalSinceReferenceDate)
                    ZStack(alignment: .topLeading) {
                        if palette.stars > 0.01 {
                            StarField(width: Double(size.width), height: Double(size.height), time: time)
                                .opacity(palette.stars * 0.9)
                        }
                        ForEach(SkyCloudLayer.allCases, id: \.rawValue) { layer in
                            cloudLayer(layer, time: time, size: size)
                        }
                    }
                }
                if let far {
                    // The depth fog's colour is the sky's own horizon.
                    FarSky(look: far.withHorizon(palette.horizon), offset: offset, size: size)
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var isPaused: Bool {
        still || ambientPaused || reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    private func cloudLayer(_ layer: SkyCloudLayer, time: Double, size: CGSize) -> some View {
        let tint = CloudTint(palette: palette, layer: layer).quantised()
        let width = Double(size.width)
        return ForEach(layer.clouds, id: \.seed) { cloud in
            let x = SkyModel.cloudX(time: time, speed: cloud.speed, phase: cloud.phase * width, width: cloud.width, span: width)
            PaintedCloud(art: cloud.art, mirrored: cloud.mirrored, width: cloud.width, tint: tint)
                .equatable()
                .opacity(cloud.opacity * palette.cloudOpacity)
                .offset(
                    x: CGFloat(x) + offset.width * CGFloat(layer.parallax),
                    y: CGFloat(cloud.top) * size.height + offset.height * CGFloat(layer.parallax)
                )
        }
    }
}

/// The sun's (or the moon's) glow: a wide soft halo and, at night, a small
/// moon.
private struct SunGlow: View {
    let palette: SkyPalette
    let size: CGSize

    var body: some View {
        let center = UnitPoint(x: palette.sun.x, y: palette.sun.y)
        ZStack {
            RadialGradient(
                colors: [palette.glow.color.opacity(palette.glowStrength), palette.glow.color.opacity(palette.glowStrength * 0.35), palette.glow.color.opacity(0)],
                center: center,
                startRadius: 0,
                endRadius: size.width * 0.85
            )
            if palette.stars > 0.5 {
                // The moon's halo: a wide, faint ring of cool light.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.82, green: 0.86, blue: 1).opacity(0.30), Color(red: 0.74, green: 0.80, blue: 0.98).opacity(0.10), Color(red: 0.7, green: 0.76, blue: 0.96).opacity(0)],
                            center: .center,
                            startRadius: 6,
                            endRadius: LookTuning.moonHaloRadius * size.width
                        )
                    )
                    .frame(width: LookTuning.moonHaloRadius * size.width * 2, height: LookTuning.moonHaloRadius * size.width * 2)
                    .opacity((palette.stars - 0.5) * 2)
                    .position(x: size.width * palette.sun.x, y: size.height * palette.sun.y)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 1, green: 0.98, blue: 0.92), Color(red: 0.96, green: 0.93, blue: 0.86).opacity(0.9), Color.white.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 17
                        )
                    )
                    .frame(width: 34, height: 34)
                    .opacity((palette.stars - 0.5) * 2)
                    .position(x: size.width * palette.sun.x, y: size.height * palette.sun.y)
            }
        }
    }
}

/// One painted cloud, tinted (sky and weather v1 §2.1): the lit side takes
/// the cell's cloud light, a gradient of the shade colour (the zenith
/// darkened, the horizon glow at dusk) takes the underside, both through the
/// painting's own silhouette. Rasterised once per tint, so a drifting cloud
/// only moves a texture.
struct PaintedCloud: View, Equatable {
    let art: String
    let mirrored: Bool
    let width: Double
    let tint: CloudTint

    var body: some View {
        if let box = WorldArt.sprite(art)?.sharp {
            let name = WorldArt.assetName(art, variant: .sharp)
            ZStack {
                Image(name, bundle: .module)
                    .resizable()
                    .colorMultiply(tint.lit.color)
                LinearGradient(
                    stops: [
                        .init(color: tint.shade.color.opacity(0), location: 0.3),
                        .init(color: tint.shade.color.opacity(0.75), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask { Image(name, bundle: .module).resizable() }
            }
            .frame(width: CGFloat(width), height: CGFloat(width * box.height / box.width))
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            .drawingGroup()
        }
    }
}

/// The cloud sea below the islands (home directions: "sky above, cloud sea
/// below"): a bank of big lobes along the bottom band, drifting slowly and
/// moving 1.25× with the peek (interaction spec §1.5). It keeps the bottom
/// band calm under the Today card and the action.
struct CloudSea: View {
    /// The sea's colours for the hour, pre-graded (look round 3): outside
    /// the world's grade, so the night sea is lifted indigo, never the
    /// black void the levels made of it.
    struct Colours: Hashable {
        var light: PofuRGB
        var shade: PofuRGB
        var opacity: Double

        /// The colour script's sea for `cell` through the sky's grade
        /// (without input levels), overcast when Pofu is unwell.
        init(cell: ColourCell, grade: WorldGrade, unwell: Double) {
            let g = grade.sky
            light = g.apply(cell.sea.light).overcast(ColourScript.unwell, amount: unwell)
            shade = g.apply(cell.sea.shade).overcast(ColourScript.unwell, amount: unwell)
            opacity = cell.sea.opacity
        }
    }

    let colours: Colours
    let offset: CGSize
    /// How far the sea rises above its Home height, in points: at the
    /// Island framing it climbs to meet the island's roots, so the band
    /// under the island is cloud, not empty sky.
    var rise: Double = 0

    @Environment(\.worldStillFrame) private var still
    @Environment(\.worldAmbientPaused) private var ambientPaused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let height = 190.0
    static let period = 640.0
    static let speed = 3.0

    /// The rise for a camera pose (look round 4): up to the island's roots,
    /// so the band under the island is always the sea, never dead sky;
    /// capped by the rail's rise (none at Home, a little on the Map).
    static func rise(z: Double, pose: CameraPose, height: Double) -> Double {
        let roots = pose.anchorY + (IslandFraming.islandBox.maxY - 30 - pose.lookY) * pose.scale
        let reach = height - Self.height - roots
        return min(max(reach, 0), rise(z: z))
    }

    /// The rise along the camera rail: none at Home (the Today card sits
    /// there), most at the Island, a little on the Map.
    static func rise(z: Double) -> Double {
        let island = 200.0
        let map = 60.0
        if z >= 2 { return 0 }
        if z >= 1 { return island * (2 - z) }
        return map + (island - map) * max(z, 0)
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: still || ambientPaused || reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled)) { context in
                let time = still ? 0 : context.date.timeIntervalSinceReferenceDate
                let drift = (time * Self.speed).truncatingRemainder(dividingBy: Self.period)
                let backDrift = (time * Self.speed * 0.6 + Self.period / 2).truncatingRemainder(dividingBy: Self.period)
                let copies = Self.copies(for: Double(size.width))
                ZStack(alignment: .bottomLeading) {
                    if rise > 1 {
                        // A back row of lobes at the risen top, and the
                        // bank filling down to the front row.
                        strip(copies: copies)
                            .offset(x: CGFloat(-backDrift) + offset.width * 1.1, y: CGFloat(-rise) + offset.height * 0.3)
                        // The bank between the rows: it fades in under the
                        // back row's lobes, so no edge shows, and stays
                        // light until the front row.
                        LinearGradient(
                            stops: [
                                .init(color: colours.light.color.opacity(0), location: 0),
                                .init(color: colours.light.color.opacity(0.97), location: 0.3),
                                .init(color: colours.light.color.opacity(0.97), location: 0.75),
                                .init(color: colours.shade.color.opacity(0.6), location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: size.width + 120, height: CGFloat(rise) + 90)
                        .offset(x: -60, y: CGFloat(-Self.height * 0.35) + offset.height * 0.35)
                        // Painted rows down the risen sea (look round 3):
                        // smaller and slower toward the back, so the band
                        // under the island reads as a sea of clouds in
                        // depth, not a flat bank.
                        paintedRow(width: Double(size.width), time: time, scale: 0.62, speed: 0.6, phase: 0.3, fades: true)
                            .offset(x: offset.width * 1.05, y: CGFloat(-rise - 40) + offset.height * 0.32)
                        paintedRow(width: Double(size.width), time: time, scale: 0.8, speed: 0.9, phase: 0.65, fades: true)
                            .offset(x: offset.width * 1.2, y: CGFloat(-rise * 0.5) + offset.height * 0.38)
                    }
                    strip(copies: copies)
                        .offset(x: CGFloat(-drift) + offset.width * 1.25, y: offset.height * 0.4)
                    // The painted front row (batch 04's cloud-sea master),
                    // mirrored every other copy so it tiles.
                    paintedRow(width: Double(size.width), time: time)
                        .offset(x: offset.width * 1.4, y: offset.height * 0.45 + 18)
                }
                .frame(width: size.width, height: size.height, alignment: .bottomLeading)
            }
        }
        .ignoresSafeArea()
        .opacity(colours.opacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func strip(copies: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<copies, id: \.self) { _ in
                SeaStrip(light: colours.light, shade: colours.shade)
                    .equatable()
            }
        }
        .frame(height: CGFloat(Self.height))
    }

    /// The painted cloud-sea row: the master tinted by the hour's sea light,
    /// drifting a little faster than the procedural bank behind it.
    @ViewBuilder
    /// `fades`: the row's bottom melts into the row in front of it (the
    /// master's bottom edge is a hard cut).
    private func paintedRow(width: Double, time: Double, scale: Double = 1, speed: Double = 1.3, phase: Double = 0, fades: Bool = false) -> some View {
        if let box = WorldArt.sprite("cloud-sea")?.sharp {
            let w = Self.paintedWidth * scale
            let h = w * box.height / box.width
            let period = 2 * w
            let drift = (time * Self.speed * speed + phase * period).truncatingRemainder(dividingBy: period)
            let copies = Int(((width + 120) / period).rounded(.up)) + 1
            HStack(spacing: 0) {
                ForEach(0..<copies, id: \.self) { _ in
                    Image(WorldArt.assetName("cloud-sea", variant: .sharp), bundle: .module)
                        .resizable()
                        .frame(width: CGFloat(w), height: CGFloat(h))
                    Image(WorldArt.assetName("cloud-sea", variant: .sharp), bundle: .module)
                        .resizable()
                        .frame(width: CGFloat(w), height: CGFloat(h))
                        .scaleEffect(x: -1, y: 1)
                }
            }
            .colorMultiply(colours.light.color)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: fades ? 0.45 : 1),
                        .init(color: .white.opacity(fades ? 0 : 1), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .offset(x: CGFloat(-drift - 40))
            .allowsHitTesting(false)
        }
    }

    /// The painted row's width per copy, in points.
    static let paintedWidth = 520.0

    /// Enough strip copies to cover the width plus one period of drift and
    /// the peek.
    static func copies(for width: Double) -> Int {
        Int(((width + 80) / period).rounded(.up)) + 1
    }
}

/// One period of the cloud sea, drawn once.
private struct SeaStrip: View, Equatable {
    let light: PofuRGB
    let shade: PofuRGB

    var body: some View {
        Canvas { context, size in
            let h = Double(size.height)
            let lobes = CloudShape.seaLobes(period: CloudSea.period)
            // A solid bank under the lobes, so the band is calm.
            context.fill(
                Path(CGRect(x: 0, y: h - 70, width: Double(size.width), height: 70)),
                with: .linearGradient(
                    Gradient(colors: [light.color.opacity(0.9), shade.color.opacity(0.95)]),
                    startPoint: CGPoint(x: 0, y: h - 70),
                    endPoint: CGPoint(x: 0, y: h)
                )
            )
            for pass in 0..<2 {
                for lobe in lobes {
                    // Wrap the lobes that cross the strip's ends.
                    for shift in [-CloudSea.period, 0, CloudSea.period] {
                        let r = pass == 0 ? lobe.r : lobe.r * 0.94
                        let c = CGPoint(x: lobe.x + shift, y: h - lobe.y + (pass == 0 ? r * 0.2 : -r * 0.04))
                        guard c.x + r > 0, c.x - r < Double(size.width) else { continue }
                        let color = pass == 0 ? shade.color : light.color
                        context.fill(
                            Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                            with: .radialGradient(
                                Gradient(stops: [
                                    .init(color: color.opacity(pass == 0 ? 0.8 : 1), location: 0),
                                    .init(color: color.opacity(pass == 0 ? 0.7 : 0.96), location: 0.66),
                                    .init(color: color.opacity(0), location: 1),
                                ]),
                                center: c,
                                startRadius: 0,
                                endRadius: r
                            )
                        )
                    }
                }
            }
        }
        .frame(width: CGFloat(CloudSea.period), height: CGFloat(CloudSea.height))
    }
}

/// The stars of the night sky: 36 fixed ones, each twinkling at its own
/// 0.1 to 0.3 Hz (`SkyModel.twinkle`). Redrawn only while the ambient
/// timeline runs; settled, the last frame holds.
private struct StarField: View {
    let width: Double
    let height: Double
    let time: Double

    var body: some View {
        Canvas { context, _ in
            for star in SkyModel.stars {
                let x = star.x * width
                let y = star.y * height
                let r = star.radius
                context.fill(
                    Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)),
                    with: .color(Color.white.opacity(SkyModel.twinkle(star, time: time)))
                )
            }
        }
        .frame(width: CGFloat(width), height: CGFloat(height))
    }
}

/// One vignette over the whole world (look round 3): the grade's vignette
/// as a dark elliptical gradient instead of a term in every shader pass,
/// the same curve as `pofuWorldGrade`'s (gentle in the middle third).
struct VignetteOverlay: View {
    let strength: Double

    var body: some View {
        let w = min(max(strength, 0), 1)
        // v = 1 − w · ((d − 0.3) / 0.7)^1.6, d = the elliptical radius over
        // 1.345; a black overlay at opacity 1 − v multiplies by v.
        let stops: [Gradient.Stop] = stride(from: 0.3, through: 1.0, by: 0.1).map { d in
            .init(color: Color.black.opacity(w * pow((d - 0.3) / 0.7, 1.6)), location: d)
        }
        EllipticalGradient(stops: stops, center: .center, startRadiusFraction: 0, endRadiusFraction: 0.6725)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
#endif
