#if os(iOS)
import Observation
import PofuCore
import PofuDesignSystem
import SwiftUI
import UIKit

/// Whether an imageset has been delivered: the code placeholders below draw
/// only until the art for their name exists.
enum KokeArt {
    static func has(_ name: String) -> Bool {
        UIImage(named: name, in: .module, compatibleWith: nil) != nil
    }
}

/// Koke's beat: the bubble, the light swell and the haptic, driven by taps
/// on Koke. Observable state is only what the views read; the game state
/// itself lives in `PofuCore` and arrives through `status`.
@MainActor
@Observable
public final class KokeBeatState {
    /// The bubble now, or `nil`.
    public private(set) var line: KokeLine?
    /// When the light swell began; `nil` before the first beat.
    public private(set) var swellStart: Date?
    /// Bumped by every beat that advances Koke, for the haptic.
    public private(set) var beats = 0

    /// Koke as the world last saw it; the scene sets it on every pass.
    @ObservationIgnored public var status = WonderStatus()
    @ObservationIgnored private var counter = 0
    @ObservationIgnored private var dismissTask: Task<Void, Never>?
    @ObservationIgnored private var landTask: Task<Void, Never>?
    @ObservationIgnored private var rumourSaid = false

    public init() {}

    /// Says a line for a few seconds.
    func say(_ kind: KokeLineKind) {
        show(kind)
        let id = counter
        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(KokeLayout.lineSeconds))
            guard !Task.isCancelled, let self, self.line?.id == id else { return }
            self.line = nil
        }
    }

    /// Shows a line and keeps it (screenshots and tests).
    public func show(_ kind: KokeLineKind) {
        counter += 1
        dismissTask?.cancel()
        line = KokeLine(id: counter, kind: kind)
    }

    /// Starts the light swell at `date` (screenshots hold a frame of it).
    public func swell(at date: Date) {
        swellStart = date
    }

    /// A tap on Koke: on a day it can advance, the next stage's line, the
    /// swell, the haptic and the game event; otherwise a snore and the line
    /// that says to come back after a quiet day.
    func tapped(in model: IslandSceneModel, now: Date = Date()) {
        if status.canAdvance {
            say(.stage(min(status.stage + 1, WonderIslands.healedStage)))
            swellStart = now
            beats += 1
            model.holdMoment(seconds: BuildMoment.Ceremony.burstLength + 0.3, from: now)
            PofuHaptics.shared.play(.growth)
            model.onVisitorEvent?(.tendedWonder(.koke))
        } else if status.stage >= WonderIslands.healedStage {
            say(.stage(WonderIslands.healedStage))
        } else {
            say(.rest)
        }
    }

    /// The camera landed on an island: Koke's first line at stage 0, or the
    /// harbor's rumour, once the flight is over.
    func landed(on island: IslandID, model: IslandSceneModel) {
        landTask?.cancel()
        landTask = Task { @MainActor [weak self, weak model] in
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled, let self, let model, model.island == island else { return }
            if island == .koke, self.status.isArrived, self.status.stage == 0 {
                self.say(.stage(0))
            } else if island == .harbor, self.status.phase == .rumoured, !self.rumourSaid {
                self.rumourSaid = true
                self.say(.rumour)
            }
        }
    }
}

// MARK: - The bubble

/// Koke's speech bubble, over the scene near the top of the island's band.
struct KokeBubbleOverlay: View {
    let state: KokeBeatState

    var body: some View {
        if let line = state.line {
            SpeechBubble {
                VStack(spacing: 2) {
                    if line.speaker != .koke {
                        Text(verbatim: WorldStrings.kokeSpeaker(line.speaker))
                            .font(PofuFont.caption)
                            .foregroundStyle(PofuColor.textSecondary)
                    }
                    Text(verbatim: WorldStrings.kokeLine(line.kind))
                }
            }
            .id(line.id)
            .transition(.scale(scale: 0.92, anchor: .bottom).combined(with: .opacity))
            .padding(.horizontal, PofuSpacing.screen)
            .padding(.top, 150)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(false)
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - The island

/// Koke's island on the world canvas: the plate at its stage, the carved
/// stone with its first warm light, Koke, and the beat's light swell. The
/// art swaps in by name (`world-koke-island-N`, `world-koke-<pose>`); until
/// then these are code placeholders. The world's grade supplies the colour
/// arc (saturation 0.4 to 1.0), so the palette here only moves a little.
struct KokeIsleView: View {
    let stage: Int
    /// Seconds since the beat began, while it runs.
    let swellAge: Double?
    let reduceMotion: Bool
    /// Where the island's centre lands on the canvas.
    let point: CGPoint
    /// Seconds for the stage 4 bounce, or `nil` for the rest pose (still
    /// frames, Reduce Motion, the Map).
    var bounceTime: Double?
    /// The sky's horizon colour: the depth fog's (sky and weather v1 §2.4).
    @Environment(\.worldHorizon) private var horizon

    private static let canvas = CGSize(width: 320, height: 200)
    /// The island's centre inside the canvas.
    private static let origin = CGPoint(x: 160, y: 100)

    var body: some View {
        let s = KokeLayout.clamped(stage)
        let g = KokeLayout.greenShare(stage: s)
        let look = KokeStageLook(stage: s)
        ZStack {
            // Stage 0 reads hushed, not pale: depth fog toward the horizon
            // colour over the plate (masked to it), a fog card across the
            // foot and one warm shaft on the sprout, under a cooler shade.
            plate(stage: s, green: g)
                .overlay {
                    if look.fog > 0.005 {
                        FogModel.colour(horizon: horizon).color
                            .opacity(look.fog)
                            .mask { plate(stage: s, green: g) }
                    }
                }
            if KokeLayout.hasBlossoms(stage: s) {
                Canvas { context, _ in Self.drawBlossoms(&context) }
            }
            Canvas { context, _ in Self.drawStone(&context, stage: s) }
            if let overlay = KokeLayout.overlay(stage: s) {
                // The plate's Koke is a stand-in here: draw the pose over it.
                let own = KokeArt.has(overlay.pose.art)
                let pose = own ? overlay.pose : (overlay.pose.fallback ?? overlay.pose)
                let lift = KokeLayout.bounce(stage: s, time: bounceTime)
                Self.art(
                    pose.art, key: String(pose.art.dropFirst("world-".count)), scale: own ? 1 : overlay.scale,
                    feet: CGPoint(x: Self.origin.x + KokeLayout.kokeFeet.x, y: Self.origin.y + KokeLayout.kokeFeet.y - lift),
                    fallbackWidth: 114
                )
            } else if !KokeArt.has(KokeLayout.plateArt(stage: s)) {
                Canvas { context, _ in Self.drawKoke(&context, stage: s, green: g) }
            }
            if look.isActive {
                KokeStageLight(look: look, horizon: horizon, origin: Self.origin)
            }
            Canvas { context, _ in
                if let swellAge, let swell = KokeLayout.swell(age: swellAge, reduceMotion: reduceMotion) {
                    Self.drawSwell(&context, radius: swell.radius, opacity: swell.opacity)
                }
            }
        }
        .modifier(KokeCoolShade(look: look))
        .frame(width: Self.canvas.width, height: Self.canvas.height)
        .position(x: point.x, y: point.y)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The plate at `stage`: its painting, or the code placeholder.
    @ViewBuilder
    private func plate(stage: Int, green: Double) -> some View {
        if KokeArt.has(KokeLayout.plateArt(stage: stage)) {
            Self.art(KokeLayout.plateArt(stage: stage), key: String(KokeLayout.plateArt(stage: stage).dropFirst("world-".count)), scale: 1, feet: Self.origin, fallbackWidth: KokeLayout.artWidth)
        } else {
            Canvas { context, _ in Self.drawPlate(&context, stage: stage, green: green) }
        }
    }

    /// A painted image placed by its baked box (world units around its
    /// anchor), scaled about the anchor.
    @ViewBuilder
    private static func art(_ name: String, key: String, scale: Double, feet: CGPoint, fallbackWidth: Double) -> some View {
        if let box = WorldArt.sprite(key)?.sharp {
            Image(name, bundle: .module)
                .resizable()
                .frame(width: box.width * scale, height: box.height * scale)
                .position(x: feet.x + box.midX * scale, y: feet.y + box.midY * scale)
        } else {
            Image(name, bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: fallbackWidth * scale)
                .position(x: feet.x, y: feet.y)
        }
    }

    // MARK: Drawing (canvas units are points, origin at the island's centre)

    private static func moss(_ g: Double, grey: (Double, Double, Double), green: (Double, Double, Double)) -> Color {
        Color(
            red: grey.0 + (green.0 - grey.0) * g,
            green: grey.1 + (green.1 - grey.1) * g,
            blue: grey.2 + (green.2 - grey.2) * g
        )
    }

    private static func at(_ x: Double, _ y: Double) -> CGPoint {
        CGPoint(x: origin.x + x, y: origin.y + y)
    }

    private static func drawPlate(_ context: inout GraphicsContext, stage: Int, green g: Double) {
        let earth = moss(g, grey: (0.50, 0.44, 0.40), green: (0.55, 0.41, 0.30))
        var under = Path()
        under.move(to: at(-122, -8))
        under.addQuadCurve(to: at(0, 72), control: at(-100, 66))
        under.addQuadCurve(to: at(122, -8), control: at(100, 66))
        under.closeSubpath()
        context.fill(under, with: .color(earth))
        // The lawn: a rim, then the top.
        let lawn = moss(g, grey: (0.63, 0.67, 0.60), green: (0.46, 0.73, 0.36))
        let rim = lawn.opacity(0.65)
        context.fill(Path(ellipseIn: CGRect(x: origin.x - 125, y: origin.y - 36, width: 250, height: 84)), with: .color(rim))
        context.fill(Path(ellipseIn: CGRect(x: origin.x - 125, y: origin.y - 46, width: 250, height: 84)), with: .color(lawn))
        // Green patches come back one after another.
        let patches: [(Double, Double, Double)] = [
            (-70, -6, 30), (40, -20, 26), (-20, 12, 34), (78, 6, 22), (-92, -22, 20), (8, -34, 24), (60, 24, 26), (-52, 28, 22),
        ]
        let shown = [0, 2, 4, 6, 8][min(max(stage, 0), 4)]
        let patch = Color(red: 0.40, green: 0.70, blue: 0.32).opacity(0.85)
        for (x, y, r) in patches.prefix(shown) {
            context.fill(Path(ellipseIn: CGRect(x: origin.x + x - r, y: origin.y + y - r * 0.5, width: r * 2, height: r)), with: .color(patch))
        }
        // The flowers: buds until they open.
        let spots: [(Double, Double)] = [
            (-96, -14), (-74, 18), (-44, -30), (-6, 24), (22, -26), (50, 16), (84, -10), (104, 8), (-30, 38), (70, 34),
        ]
        let open = KokeLayout.openFlowers(stage: stage)
        let petals: [Color] = [
            Color(red: 0.98, green: 0.72, blue: 0.78), Color(red: 0.99, green: 0.86, blue: 0.45), Color(red: 0.98, green: 0.80, blue: 0.62),
        ]
        for (index, spot) in spots.enumerated() {
            let p = at(spot.0, spot.1)
            if index < open {
                let color = petals[index % petals.count]
                for k in 0..<5 {
                    let a = Double(k) * .pi * 2 / 5
                    let c = CGPoint(x: p.x + cos(a) * 3.4, y: p.y + sin(a) * 2.4)
                    context.fill(Path(ellipseIn: CGRect(x: c.x - 2.6, y: c.y - 2.6, width: 5.2, height: 5.2)), with: .color(color))
                }
                context.fill(Path(ellipseIn: CGRect(x: p.x - 1.6, y: p.y - 1.6, width: 3.2, height: 3.2)), with: .color(Color(red: 0.95, green: 0.62, blue: 0.2)))
            } else {
                // A closed bud: a small grey-green drop on a stalk.
                var stalk = Path()
                stalk.move(to: p)
                stalk.addLine(to: CGPoint(x: p.x, y: p.y - 5))
                context.stroke(stalk, with: .color(Color(red: 0.42, green: 0.52, blue: 0.40)), lineWidth: 1.2)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 2, y: p.y - 10, width: 4, height: 6)), with: .color(Color(red: 0.55, green: 0.60, blue: 0.54)))
            }
        }
    }

    /// The stage 4 signature, until its plate is painted: open blossoms
    /// scattered on the lawn's front half, clear of Koke and the stone.
    private static func drawBlossoms(_ context: inout GraphicsContext) {
        let spots: [(Double, Double, Int)] = [
            (-96, 12, 0), (-74, 30, 1), (-52, 44, 2), (-22, 48, 0), (8, 44, 1), (30, 34, 2),
            (74, 38, 0), (92, 22, 1), (-104, -2, 2), (104, 4, 0), (-84, 40, 1), (60, 18, 2),
        ]
        let petals: [Color] = [
            Color(red: 0.98, green: 0.72, blue: 0.78), Color(red: 0.99, green: 0.86, blue: 0.45), Color(red: 0.98, green: 0.80, blue: 0.62),
        ]
        for (x, y, tone) in spots {
            let p = at(x, y)
            var stalk = Path()
            stalk.move(to: CGPoint(x: p.x, y: p.y + 4))
            stalk.addLine(to: p)
            context.stroke(stalk, with: .color(Color(red: 0.36, green: 0.58, blue: 0.30)), lineWidth: 1.2)
            for k in 0..<5 {
                let a = Double(k) * .pi * 2 / 5
                let c = CGPoint(x: p.x + cos(a) * 3.2, y: p.y - 1 + sin(a) * 2.3)
                context.fill(Path(ellipseIn: CGRect(x: c.x - 2.5, y: c.y - 2.5, width: 5, height: 5)), with: .color(petals[tone]))
            }
            context.fill(Path(ellipseIn: CGRect(x: p.x - 1.5, y: p.y - 2.5, width: 3, height: 3)), with: .color(Color(red: 0.95, green: 0.62, blue: 0.2)))
        }
    }

    private static func drawStone(_ context: inout GraphicsContext, stage: Int) {
        let base = at(KokeLayout.stoneOffset.x, KokeLayout.stoneOffset.y + 38)
        if KokeLayout.hasWarmLight(stage: stage) {
            // The first warm practical: a lamp at the stone, added to the light.
            var glow = context
            glow.blendMode = .plusLighter
            let c = CGPoint(x: base.x, y: base.y - 34)
            let r = 36.0
            let warm = Color(red: 1.0, green: 0.80, blue: 0.48)
            glow.fill(
                Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                with: .radialGradient(Gradient(colors: [warm.opacity(0.55), warm.opacity(0)]), center: c, startRadius: 0, endRadius: r)
            )
        }
        let stone = CGRect(x: base.x - 12, y: base.y - 34, width: 24, height: 34)
        context.fill(Path(roundedRect: stone, cornerRadius: 9), with: .color(Color(red: 0.62, green: 0.62, blue: 0.60)))
        // The carved lines Mochi reads.
        for k in 0..<3 {
            var line = Path()
            let y = stone.minY + 11 + Double(k) * 7
            line.move(to: CGPoint(x: stone.minX + 6, y: y))
            line.addLine(to: CGPoint(x: stone.maxX - 6 - Double(k) * 2, y: y))
            context.stroke(line, with: .color(Color(red: 0.40, green: 0.40, blue: 0.40)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        }
        if KokeLayout.hasWarmLight(stage: stage) {
            // The lamp's core at the stone's foot.
            let core = CGPoint(x: base.x + 16, y: base.y - 6)
            var glow = context
            glow.blendMode = .plusLighter
            glow.fill(
                Path(ellipseIn: CGRect(x: core.x - 7, y: core.y - 7, width: 14, height: 14)),
                with: .radialGradient(Gradient(colors: [Color(red: 1.0, green: 0.86, blue: 0.55), Color(red: 1.0, green: 0.8, blue: 0.4).opacity(0)]), center: core, startRadius: 0, endRadius: 7)
            )
        }
    }

    /// Koke: a mossy mound with a sleepy face, taller as it wakes.
    private static func drawKoke(_ context: inout GraphicsContext, stage: Int, green g: Double) {
        let feet = at(KokeLayout.kokeOffset.x, KokeLayout.kokeOffset.y + 40)
        let sizes: [(w: Double, h: Double)] = [(118, 54), (118, 56), (118, 62), (136, 74), (100, 96)]
        let size = sizes[min(max(stage, 0), 4)]
        let body = moss(g, grey: (0.50, 0.56, 0.47), green: (0.42, 0.62, 0.34))
        let shade = moss(g, grey: (0.40, 0.46, 0.38), green: (0.32, 0.50, 0.26))
        if stage >= 4 {
            for dx in [-20.0, 20.0] {
                context.fill(Path(ellipseIn: CGRect(x: feet.x + dx - 11, y: feet.y - 8, width: 22, height: 12)), with: .color(shade))
            }
        }
        let lift = stage >= 4 ? 6.0 : 0.0
        var mound = Path()
        mound.move(to: CGPoint(x: feet.x - size.w / 2, y: feet.y - lift))
        mound.addCurve(
            to: CGPoint(x: feet.x + size.w / 2, y: feet.y - lift),
            control1: CGPoint(x: feet.x - size.w * 0.5, y: feet.y - lift - size.h * 1.35),
            control2: CGPoint(x: feet.x + size.w * 0.5, y: feet.y - lift - size.h * 1.35)
        )
        mound.closeSubpath()
        context.fill(mound, with: .color(body))
        // Moss tufts on its back.
        for (x, y) in [(-0.28, 0.62), (0.05, 0.86), (0.30, 0.55), (-0.05, 0.40)] {
            let c = CGPoint(x: feet.x + size.w * x, y: feet.y - lift - size.h * y)
            context.fill(Path(ellipseIn: CGRect(x: c.x - 9, y: c.y - 5, width: 18, height: 10)), with: .color(shade.opacity(0.7)))
        }
        if stage == 3 {
            // The stretch: two small arms up.
            for dx in [-1.0, 1.0] {
                var arm = Path()
                arm.move(to: CGPoint(x: feet.x + dx * size.w * 0.42, y: feet.y - size.h * 0.35))
                arm.addQuadCurve(to: CGPoint(x: feet.x + dx * size.w * 0.62, y: feet.y - size.h * 0.95), control: CGPoint(x: feet.x + dx * size.w * 0.66, y: feet.y - size.h * 0.55))
                context.stroke(arm, with: .color(body), style: StrokeStyle(lineWidth: 9, lineCap: .round))
            }
        }
        // The face.
        let faceY = feet.y - lift - size.h * 0.34
        let ink = Color(red: 0.20, green: 0.24, blue: 0.20)
        func eyeShut(_ x: Double) {
            var arc = Path()
            arc.addArc(center: CGPoint(x: x, y: faceY - 2), radius: 6, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
            context.stroke(arc, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        func eyeOpen(_ x: Double) {
            context.fill(Path(ellipseIn: CGRect(x: x - 4.5, y: faceY - 6, width: 9, height: 11)), with: .color(ink))
            context.fill(Path(ellipseIn: CGRect(x: x - 1.5, y: faceY - 4, width: 3, height: 3)), with: .color(.white))
        }
        let left = feet.x - 17, right = feet.x + 17
        switch stage {
        case 0, 1:
            eyeShut(left)
            eyeShut(right)
        case 2:
            eyeOpen(left)
            eyeShut(right)
        case 3:
            eyeOpen(left)
            eyeOpen(right)
        default:
            eyeOpen(left)
            eyeOpen(right)
            var smile = Path()
            smile.addArc(center: CGPoint(x: feet.x, y: faceY + 6), radius: 7, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
            context.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        if stage <= 1 {
            // Snoring.
            for (k, fontSize) in [(0, 13.0), (1, 10.0)] {
                let p = CGPoint(x: feet.x + 44 + Double(k) * 12, y: feet.y - 62 - Double(k) * 16)
                context.draw(Text("z").font(.system(size: fontSize, weight: .bold, design: .rounded)).foregroundStyle(Color(red: 0.35, green: 0.40, blue: 0.45)), at: p)
            }
        }
    }

    private static func drawSwell(_ context: inout GraphicsContext, radius: Double, opacity: Double) {
        var glow = context
        glow.blendMode = .plusLighter
        let c = at(KokeLayout.kokeOffset.x, KokeLayout.kokeOffset.y - 6)
        let tint = Color(red: 1.0, green: 0.80, blue: 0.48)
        glow.fill(
            Path(ellipseIn: CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2)),
            with: .radialGradient(
                Gradient(colors: [tint.opacity(opacity * 0.9), tint.opacity(opacity * 0.3), tint.opacity(0)]),
                center: c, startRadius: 0, endRadius: radius
            )
        )
    }
}

// MARK: - The horizon

/// The snoring hump on the harbor's far sky, in the fog like the far isles;
/// from the gift on, a faint warm light above it.
struct KokeFarHump: View {
    let look: FarSky.Look
    let offset: CGSize
    let size: CGSize

    var body: some View {
        let opacity = KokeLayout.farOpacity(z: look.z)
        if let koke = look.koke, opacity > 0.01 {
            let k = Double(size.width) / CameraRail.referenceWidth
            let w = KokeLayout.farHump.width * k
            // Depth fog (§2.3): the hump sits with the far isles, its lit top
            // and its shade both mixed toward the horizon colour, the shade
            // 1.25x as much.
            let haze = FogModel.amount(distance: 0.85, mist: look.mist)
            let lit = PofuRGB(red: 0.56 * look.light.red, green: 0.64 * look.light.green, blue: 0.52 * look.light.blue)
            let shade = PofuRGB(red: 0.40 * look.light.red, green: 0.48 * look.light.green, blue: 0.44 * look.light.blue)
            let fogged = FogModel.fogged(light: lit, shadow: shade, horizon: look.fog, amount: haze)
            ZStack {
                Canvas { context, canvas in
                    var hump = Path()
                    hump.move(to: CGPoint(x: 0, y: canvas.height))
                    hump.addCurve(
                        to: CGPoint(x: canvas.width, y: canvas.height),
                        control1: CGPoint(x: canvas.width * 0.08, y: -canvas.height * 0.35),
                        control2: CGPoint(x: canvas.width * 0.92, y: -canvas.height * 0.35)
                    )
                    hump.closeSubpath()
                    context.fill(
                        hump,
                        with: .linearGradient(
                            Gradient(colors: [fogged.light.color, fogged.shadow.color]),
                            startPoint: CGPoint(x: canvas.width / 2, y: 0),
                            endPoint: CGPoint(x: canvas.width / 2, y: canvas.height)
                        )
                    )
                    if koke.lit {
                        var glow = context
                        glow.blendMode = .plusLighter
                        let c = CGPoint(x: canvas.width * 0.5, y: canvas.height * 0.15)
                        let warm = Color(red: 1.0, green: 0.82, blue: 0.5)
                        glow.fill(
                            Path(ellipseIn: CGRect(x: c.x - 26, y: c.y - 26, width: 52, height: 52)),
                            with: .radialGradient(Gradient(colors: [warm.opacity(0.5), warm.opacity(0)]), center: c, startRadius: 0, endRadius: 26)
                        )
                    }
                }
                .frame(width: CGFloat(w), height: CGFloat(w * 0.5))
            }
            .opacity(opacity * (1 - 0.35 * haze))
            .position(
                x: CGFloat(KokeLayout.farHump.x) * size.width + offset.width * 0.2,
                y: CGFloat(KokeLayout.farHump.y) * size.height + offset.height * 0.2
            )
        }
    }
}

// MARK: - The gift at home

/// The moss Koke gives, lying on the home lawn after stage 4.
/// `material-moss` replaces this placeholder by name.
struct MossGiftView: View {
    /// Where the moss's base lands on the canvas.
    let point: CGPoint

    var body: some View {
        Group {
            if KokeArt.has("material-moss") {
                Image("material-moss", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46)
            } else {
                Canvas { context, size in
                    let moss = Color(red: 0.42, green: 0.66, blue: 0.34)
                    let dark = Color(red: 0.31, green: 0.52, blue: 0.26)
                    context.fill(Path(ellipseIn: CGRect(x: 2, y: size.height - 16, width: size.width - 4, height: 14)), with: .color(dark))
                    for (x, w, h) in [(0.12, 0.34, 0.5), (0.38, 0.40, 0.72), (0.62, 0.30, 0.5)] {
                        let rect = CGRect(x: size.width * x, y: size.height - 8 - size.height * h, width: size.width * w, height: size.height * h)
                        context.fill(Path(ellipseIn: rect), with: .color(moss))
                    }
                    context.fill(Path(ellipseIn: CGRect(x: size.width * 0.47, y: size.height * 0.2, width: 4, height: 4)), with: .color(Color(red: 0.99, green: 0.86, blue: 0.45)))
                }
                .frame(width: 46, height: 34)
            }
        }
        .position(x: point.x, y: point.y - 16)
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: WorldStrings.kokeGift))
    }
}
#endif
