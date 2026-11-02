#if os(iOS)
import PofuDesignSystem
import SwiftUI

extension EnvironmentValues {
    /// Still-frame rendering, for screenshots: the sky's clouds stop at
    /// their time-zero places, so every run draws the same frame.
    @Entry public var worldStillFrame: Bool = false
    /// The world is settled under the look (look-dev B): the drift holds
    /// where it is, so the settled frame is cached and costs nothing.
    @Entry var worldAmbientPaused: Bool = false
}

/// The sky behind the islands (design language §12; boundary doc §6.3's
/// calm bands): a gradient and a sun or moon glow that follow the
/// snapshot's clock, faint stars at night, and two layers of clouds that
/// drift slowly at different speeds (parallax: the far layer moves least).
///
/// Cheap enough to idle under the 60 fps world: the clouds are drawn once
/// per palette (equatable canvases) and only their offsets change, on a
/// 30 Hz timeline (a cloud moves at most 5 pt a second, a sixth of a point
/// a frame). Reduce Motion, Low Power Mode and still frames stop the drift.
struct LivingSky: View {
    let palette: SkyPalette
    /// The peek's screen offset; the sky moves 0.3× and 0.6× of it.
    let offset: CGSize

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
                if palette.stars > 0.01 {
                    StarField(width: Double(size.width), height: Double(size.height))
                        .equatable()
                        .opacity(palette.stars * 0.85)
                }
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { context in
                    let time = still ? 0 : context.date.timeIntervalSinceReferenceDate
                    ZStack(alignment: .topLeading) {
                        cloudLayer(SkyCloud.far, time: time, size: size, parallax: 0.3)
                        cloudLayer(SkyCloud.near, time: time, size: size, parallax: 0.6)
                    }
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

    private func cloudLayer(_ clouds: [SkyCloud], time: Double, size: CGSize, parallax: Double) -> some View {
        ForEach(clouds, id: \.seed) { cloud in
            let width = Double(size.width)
            let x = SkyModel.cloudX(time: time, speed: cloud.speed, phase: cloud.phase * width, width: cloud.width, span: width)
            CloudPuff(seed: cloud.seed, width: cloud.width, light: palette.cloudLight, shade: palette.cloudShade)
                .equatable()
                .opacity(cloud.opacity * palette.cloudOpacity)
                .offset(
                    x: CGFloat(x) + offset.width * CGFloat(parallax),
                    y: CGFloat(cloud.top) * size.height + offset.height * CGFloat(parallax)
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

/// One cloud: soft lobes, a shaded underside and a lit top, drawn once.
struct CloudPuff: View, Equatable {
    let seed: Int
    let width: Double
    let light: PofuRGB
    let shade: PofuRGB

    var body: some View {
        Canvas { context, size in
            let w = Double(size.width)
            let lobes = CloudShape.lobes(seed: seed)
            for lobe in lobes {
                let r = lobe.r * w
                let c = CGPoint(x: lobe.x * w, y: lobe.y * w + r * 0.18)
                context.fill(circle(c, r), with: soft(shade.color, at: c, radius: r, core: 0.75))
            }
            for lobe in lobes {
                let r = lobe.r * w * 0.95
                let c = CGPoint(x: lobe.x * w, y: lobe.y * w - r * 0.05)
                context.fill(circle(c, r), with: soft(light.color, at: c, radius: r, core: 1))
            }
        }
        .frame(width: CGFloat(width), height: CGFloat(width * 0.62))
    }

    private func circle(_ c: CGPoint, _ r: Double) -> Path {
        Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
    }

    private func soft(_ color: Color, at c: CGPoint, radius r: Double, core: Double) -> GraphicsContext.Shading {
        .radialGradient(
            Gradient(stops: [
                .init(color: color.opacity(core), location: 0),
                .init(color: color.opacity(core * 0.92), location: 0.62),
                .init(color: color.opacity(0), location: 1),
            ]),
            center: c,
            startRadius: 0,
            endRadius: r
        )
    }
}

/// The cloud sea below the islands (home directions: "sky above, cloud sea
/// below"): a bank of big lobes along the bottom band, drifting slowly and
/// moving 1.25× with the peek (interaction spec §1.5). It keeps the bottom
/// band calm under the Today card and the action.
struct CloudSea: View {
    let palette: SkyPalette
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
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: still || ambientPaused || reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled)) { context in
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
                                .init(color: palette.cloudLight.color.opacity(0), location: 0),
                                .init(color: palette.cloudLight.color.opacity(0.97), location: 0.3),
                                .init(color: palette.cloudLight.color.opacity(0.97), location: 0.75),
                                .init(color: palette.cloudShade.color.opacity(0.6), location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: size.width + 120, height: CGFloat(rise) + 90)
                        .offset(x: -60, y: CGFloat(-Self.height * 0.35) + offset.height * 0.35)
                    }
                    strip(copies: copies)
                        .offset(x: CGFloat(-drift) + offset.width * 1.25, y: offset.height * 0.4)
                }
                .frame(width: size.width, height: size.height, alignment: .bottomLeading)
            }
        }
        .ignoresSafeArea()
        .opacity(palette.cloudOpacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func strip(copies: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<copies, id: \.self) { _ in
                SeaStrip(light: palette.cloudLight, shade: palette.cloudShade)
                    .equatable()
            }
        }
        .frame(height: CGFloat(Self.height))
    }

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

/// A few fixed stars in the upper sky, for night.
private struct StarField: View, Equatable {
    let width: Double
    let height: Double

    var body: some View {
        Canvas { context, _ in
            var g = CloudShape.Generator(state: 977)
            for _ in 0..<38 {
                let x = g.next() * width
                let y = g.next() * height * 0.42
                let r = 0.6 + g.next() * 1.1
                context.fill(
                    Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)),
                    with: .color(Color.white.opacity(0.45 + 0.5 * g.next()))
                )
            }
        }
        .frame(width: CGFloat(width), height: CGFloat(height))
    }
}
#endif
