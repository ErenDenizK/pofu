#if os(iOS)
import Observation
import PofuCore
import PofuDesignSystem
import SwiftUI
import UIKit

extension EnvironmentValues {
    /// How night it is, 0 to 1 (`WorldLight.night`), for the tiny lights the
    /// islands keep (set by the scene).
    @Entry var worldNight: Double = 0
}

/// Çağlayan's beat: the bubble, the light swell and the haptic. A tap on the
/// island opens the stage's flow round (through `IslandSceneModel.onPlayFlow`,
/// which the app answers with a full-screen cover); finishing it advances the
/// stage in `PofuCore` and calls `roundFinished`, which crossfades the next
/// plate in (the view does that on the stage change) and plays the beat line.
@MainActor
@Observable
public final class CaglayanBeatState {
    public private(set) var line: CaglayanLine?
    public private(set) var swellStart: Date?
    public private(set) var beats = 0

    /// Çağlayan as the world last saw it; the scene sets it on every pass.
    @ObservationIgnored public var status = WonderStatus()
    @ObservationIgnored private var counter = 0
    @ObservationIgnored private var dismissTask: Task<Void, Never>?
    @ObservationIgnored private var landTask: Task<Void, Never>?
    @ObservationIgnored private var rumourSaid = false

    public init() {}

    func say(_ kind: CaglayanLineKind) {
        show(kind)
        let id = counter
        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(CaglayanLayout.lineSeconds))
            guard !Task.isCancelled, let self, self.line?.id == id else { return }
            self.line = nil
        }
    }

    /// Shows a line and keeps it (screenshots and tests).
    public func show(_ kind: CaglayanLineKind) {
        counter += 1
        dismissTask?.cancel()
        line = CaglayanLine(id: counter, kind: kind)
    }

    public func swell(at date: Date) {
        swellStart = date
    }

    /// Whether a tap would open a flow round today.
    public var canPlay: Bool {
        status.isArrived && status.canAdvance
    }

    /// A tap on the island: on a day it can advance, the stage's flow round
    /// opens; otherwise Damla's line (the water waits for a quiet day, or the
    /// healed island's last line).
    func tapped(in model: IslandSceneModel) {
        if status.canAdvance {
            model.onPlayFlow?(min(status.stage + 1, WonderIslands.healedStage))
        } else if status.stage >= WonderIslands.healedStage {
            say(.stage(WonderIslands.healedStage))
        } else {
            say(.rest)
        }
    }

    /// The round was finished and the stage advanced to `stage`: the swell,
    /// the haptic and the beat line (the plate crossfades in by itself).
    public func roundFinished(newStage stage: Int, in model: IslandSceneModel, now: Date = Date()) {
        say(.stage(stage))
        swellStart = now
        beats += 1
        model.holdMoment(seconds: CaglayanLayout.crossfadeSeconds + 0.3, from: now)
        PofuHaptics.shared.play(.growth)
    }

    /// The camera landed on an island: Damla's first line at stage 0, or the
    /// harbor's rumour, once the flight is over.
    func landed(on island: IslandID, model: IslandSceneModel) {
        landTask?.cancel()
        landTask = Task { @MainActor [weak self, weak model] in
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled, let self, let model, model.island == island else { return }
            if island == .caglayan, self.status.isArrived, self.status.stage == 0 {
                self.say(.stage(0))
            } else if island == .harbor, self.status.phase == .rumoured, !self.rumourSaid {
                self.rumourSaid = true
                self.say(.rumour)
            }
        }
    }
}

// MARK: - The bubble and the plaque

struct CaglayanBubbleOverlay: View {
    let state: CaglayanBeatState

    var body: some View {
        if let line = state.line {
            SpeechBubble {
                VStack(spacing: 2) {
                    Text(verbatim: WorldStrings.caglayanSpeaker(line.speaker))
                        .font(PofuFont.caption)
                        .foregroundStyle(PofuColor.textSecondary)
                    Text(verbatim: WorldStrings.caglayanLine(line.kind))
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

/// The plaque under the island on a day it can be played: "Akışı bağla".
struct CaglayanPlaque: View {
    let model: IslandSceneModel
    let state: CaglayanBeatState

    var body: some View {
        if model.island == .caglayan, state.canPlay, model.focus == nil, !model.hasSheet {
            Button {
                state.tapped(in: model)
            } label: {
                Text(verbatim: WorldStrings.caglayanPlaque)
            }
            .buttonStyle(PofuPlaqueStyle(.primary))
            .frame(maxWidth: 240)
            .padding(.bottom, 88)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .transition(.opacity)
        }
    }
}

// MARK: - The island

/// Çağlayan on the world canvas: the plate at its stage (a crossfade when
/// the stage rises), the stage 0 shaft on the trickle, Damla, the note in the
/// mill hut, the pool's night light and, at stage 4, the falls off the
/// underside. Drawn like `KokeIsleView`: the scene's ambient clock hands in
/// `time` (nil when settled, so a still frame costs nothing).
struct CaglayanIsleView: View {
    let stage: Int
    let swellAge: Double?
    let reduceMotion: Bool
    /// Where the island's centre lands on the canvas.
    let point: CGPoint
    /// Seconds for the falls and the mist, or `nil` for the rest pose.
    var time: Double?
    @Environment(\.worldNight) private var night

    /// The stage shown before the one now crossfading in, and how far the
    /// crossfade is (0 shows `from`, 1 shows `stage`).
    @State private var from: Int?
    @State private var progress = 1.0

    private static let canvas = CGSize(width: 320, height: 200)
    private static let origin = CGPoint(x: 160, y: 100)

    var body: some View {
        let s = CaglayanLayout.clamped(stage)
        ZStack {
            // The falls leave the underside: behind the plate, so they pour out of its lower edge.
            let strength = fallsStrength(s)
            if strength > 0.001 {
                CaglayanFalls(time: time, strength: strength)
                    .frame(width: 160, height: 300)
                    .position(x: Self.origin.x, y: Self.origin.y + CaglayanLayout.undersideY + 150)
            }
            plates(s)
            shaft(s)
            if let from, progress < 1 {
                // The old stage's shaft fades out under the new one's fade-in.
                shaftView(CaglayanLayout.shaftAlpha(stage: from) * (1 - progress))
            }
            poolLight(s)
            note(s)
            Canvas { context, _ in
                if let swellAge, let swell = KokeLayout.swell(age: swellAge, reduceMotion: reduceMotion) {
                    Self.drawSwell(&context, radius: swell.radius, opacity: swell.opacity)
                }
            }
        }
        .frame(width: Self.canvas.width, height: Self.canvas.height)
        .position(x: point.x, y: point.y)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: s) { old, new in
            guard new > old else { return }
            from = old
            progress = 0
            withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .easeInOut(duration: CaglayanLayout.crossfadeSeconds)) {
                progress = 1
            } completion: {
                from = nil
            }
        }
    }

    private func fallsStrength(_ s: Int) -> Double {
        let now = CaglayanLayout.fallStrength(stage: s)
        guard let from, progress < 1 else { return now }
        return CaglayanLayout.fallStrength(stage: from) * (1 - progress) + now * progress
    }

    @ViewBuilder
    private func plates(_ s: Int) -> some View {
        if let from, progress < 1 {
            plate(from)
            plate(s).opacity(progress)
        } else {
            plate(s)
        }
    }

    @ViewBuilder
    private func plate(_ stage: Int) -> some View {
        let name = CaglayanLayout.islandArt(stage: stage)
        if let box = WorldArt.sprite(CaglayanLayout.islandKey(stage: stage))?.sharp, KokeArt.has(name) {
            Image(name, bundle: .module)
                .resizable()
                .frame(width: box.width, height: box.height)
                .position(x: Self.origin.x + box.midX, y: Self.origin.y + box.midY)
        } else {
            // A bundle without the plates: a soft placeholder island.
            Ellipse()
                .fill(Color(red: 0.62, green: 0.74, blue: 0.52))
                .frame(width: CaglayanLayout.plateSize.width, height: 60)
                .position(Self.origin)
        }
    }

    // MARK: Stage 0: one warm shaft on the single trickle

    @ViewBuilder
    private func shaft(_ s: Int) -> some View {
        let alpha = CaglayanLayout.shaftAlpha(stage: s) * (from != nil && progress < 1 ? progress : 1)
        shaftView(alpha)
    }

    @ViewBuilder
    private func shaftView(_ alpha: Double) -> some View {
        if alpha > 0.005 {
            let target = CGPoint(x: Self.origin.x + CaglayanLayout.trickle.x, y: Self.origin.y + CaglayanLayout.trickle.y)
            let warm = KokeStageLook.shaftColour.color
            ZStack {
                if let art = UIImage(named: "world-light-shaft", in: .module, compatibleWith: nil) {
                    Image(uiImage: art)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 150)
                        .foregroundStyle(warm)
                        .opacity(min(0.55, alpha * 0.9))
                        .position(x: target.x - 48, y: target.y - 66)
                }
                Circle()
                    .fill(RadialGradient(colors: [warm.opacity(0.28 * alpha / 0.5), warm.opacity(0)], center: .center, startRadius: 0, endRadius: 18))
                    .frame(width: 36, height: 36)
                    .position(target)
            }
        }
    }

    // MARK: The pool's tiny night light

    @ViewBuilder
    private func poolLight(_ s: Int) -> some View {
        let amount = CaglayanLayout.poolLight(stage: s, night: night)
        if amount > 0.01 {
            Canvas { context, _ in
                var glow = context
                glow.blendMode = .plusLighter
                let c = CGPoint(x: Self.origin.x + CaglayanLayout.pool.x, y: Self.origin.y + CaglayanLayout.pool.y)
                let warm = Color(red: 1.0, green: 0.84, blue: 0.52)
                glow.fill(
                    Path(ellipseIn: CGRect(x: c.x - 9, y: c.y - 6, width: 18, height: 12)),
                    with: .radialGradient(Gradient(colors: [warm.opacity(0.85 * amount), warm.opacity(0)]), center: c, startRadius: 0, endRadius: 9)
                )
                glow.fill(Path(ellipseIn: CGRect(x: c.x - 1.5, y: c.y - 1.5, width: 3, height: 3)), with: .color(Color.white.opacity(0.9 * amount)))
            }
        }
    }

    // MARK: The note

    /// The old Bekçi's note on the mill hut: "Kapı gıcırdarsa, zeytinyağı."
    @ViewBuilder
    private func note(_ s: Int) -> some View {
        if CaglayanLayout.showsNote(stage: s) {
            Canvas { context, _ in
                let c = CGPoint(x: Self.origin.x + CaglayanLayout.note.x, y: Self.origin.y + CaglayanLayout.note.y)
                var paper = context
                paper.translateBy(x: c.x, y: c.y)
                paper.rotate(by: .degrees(-6))
                let rect = CGRect(x: -4.5, y: -5.5, width: 9, height: 11)
                paper.fill(Path(roundedRect: rect.offsetBy(dx: 0.6, dy: 1), cornerRadius: 1), with: .color(Color(red: 0.24, green: 0.2, blue: 0.2).opacity(0.25)))
                paper.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(Color(red: 0.99, green: 0.96, blue: 0.86)))
                for k in 0..<4 {
                    var line = Path()
                    let y = rect.minY + 2.2 + Double(k) * 2.2
                    line.move(to: CGPoint(x: rect.minX + 1.4, y: y))
                    line.addLine(to: CGPoint(x: rect.maxX - 1.4 - (k == 3 ? 3 : 0), y: y))
                    paper.stroke(line, with: .color(Color(red: 0.45, green: 0.36, blue: 0.3).opacity(0.7)), lineWidth: 0.6)
                }
                // A pin.
                paper.fill(Path(ellipseIn: CGRect(x: -1, y: -6.6, width: 2, height: 2)), with: .color(Color(red: 0.8, green: 0.35, blue: 0.3)))
            }
        }
    }

    private static func drawSwell(_ context: inout GraphicsContext, radius: Double, opacity: Double) {
        var glow = context
        glow.blendMode = .plusLighter
        let c = CGPoint(x: origin.x + CaglayanLayout.pool.x, y: origin.y - 24)
        let tint = Color(red: 0.78, green: 0.92, blue: 1.0)
        glow.fill(
            Path(ellipseIn: CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2)),
            with: .radialGradient(
                Gradient(colors: [tint.opacity(opacity * 0.9), tint.opacity(opacity * 0.3), tint.opacity(0)]),
                center: c, startRadius: 0, endRadius: radius
            )
        )
    }
}

// MARK: - The falls off the underside

/// Stage 4's signature: the waterfall pours off the island's underside into
/// the cloud sea, as a long fall below the plate. Code-drawn ribbons that
/// taper and fade, a scrolling highlight and a mist puff where they meet the
/// clouds. `time` runs only while the scene's ambient clock does (30 Hz,
/// visiting); `nil` draws one still frame.
struct CaglayanFalls: View {
    let time: Double?
    let strength: Double

    var body: some View {
        Canvas { context, size in
            Self.draw(&context, size: size, time: time, strength: strength)
        }
        .allowsHitTesting(false)
    }

    /// The canvas is 160 wide and 300 tall; its top is a little above the
    /// underside line, x centred on the island.
    static func draw(_ context: inout GraphicsContext, size: CGSize, time: Double?, strength: Double) {
        let mid = size.width / 2
        let water = Color(red: 0.74, green: 0.90, blue: 1.0)
        let deep = Color(red: 0.42, green: 0.68, blue: 0.92)
        let top = 4.0
        for ribbon in CaglayanLayout.ribbons {
            let x = mid + ribbon.x
            let w = ribbon.width
            let end = top + ribbon.length
            // Tapers from the underside, widens a little as it falls, and fades out into the clouds.
            var shape = Path()
            shape.move(to: CGPoint(x: x - w * 0.5, y: top))
            shape.addQuadCurve(to: CGPoint(x: x - w * 0.8, y: end), control: CGPoint(x: x - w * 0.45, y: top + ribbon.length * 0.5))
            shape.addLine(to: CGPoint(x: x + w * 0.8, y: end))
            shape.addQuadCurve(to: CGPoint(x: x + w * 0.5, y: top), control: CGPoint(x: x + w * 0.45, y: top + ribbon.length * 0.5))
            shape.closeSubpath()
            context.fill(
                shape,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: deep.opacity(0.85 * strength), location: 0),
                        .init(color: water.opacity(0.6 * strength), location: 0.35),
                        .init(color: water.opacity(0), location: 1),
                    ]),
                    startPoint: CGPoint(x: x, y: top), endPoint: CGPoint(x: x, y: end)
                )
            )
            // The running highlight: pale dashes sliding down the ribbon.
            let phase = CaglayanLayout.fallPhase(ribbon, time: time)
            var strands = context
            strands.clip(to: shape)
            for k in 0..<4 {
                let share = (Double(k) / 4 + phase).truncatingRemainder(dividingBy: 1)
                let y = top + share * ribbon.length
                var dash = Path()
                dash.move(to: CGPoint(x: x - w * 0.12, y: y))
                dash.addLine(to: CGPoint(x: x - w * 0.12, y: y + ribbon.length * 0.12))
                strands.stroke(dash, with: .color(.white.opacity(0.7 * strength * (1 - share))), style: StrokeStyle(lineWidth: max(1, w * 0.22), lineCap: .round))
            }
            // The mist puff where the fall meets the clouds.
            let breathe = time.map { 0.5 + 0.5 * sin($0 * 2.1 + ribbon.phase * 6) } ?? 0.5
            for (dx, r) in [(-w * 1.2, 13.0), (w * 0.2, 17.0), (w * 1.4, 12.0)] {
                let radius = r * (0.9 + 0.2 * breathe)
                context.fill(
                    Path(ellipseIn: CGRect(x: x + dx - radius, y: end - radius * 0.7, width: radius * 2, height: radius * 1.4)),
                    with: .radialGradient(
                        Gradient(colors: [Color.white.opacity(0.55 * strength), Color.white.opacity(0)]),
                        center: CGPoint(x: x + dx, y: end), startRadius: 0, endRadius: radius
                    )
                )
            }
        }
    }
}

// MARK: - The gift at home

/// The pool's fountain at home once Çağlayan is healed: a thin, soft jet and
/// its ripples, over the pond station. Code-drawn; `time` is nil when settled.
struct HomeFountainView: View {
    /// Where the fountain's base lands on the canvas.
    let point: CGPoint
    var time: Double?

    var body: some View {
        Canvas { context, size in
            let base = CGPoint(x: size.width / 2, y: size.height - 10)
            let t = time ?? 0
            let water = Color(red: 0.74, green: 0.90, blue: 1.0)
            // Three arcs leave the spout and fall back, the highlight running along them.
            for k in 0..<3 {
                let spread = Double(k - 1) * 7
                var arc = Path()
                arc.move(to: CGPoint(x: base.x, y: base.y - 22))
                arc.addQuadCurve(to: CGPoint(x: base.x + spread * 1.6, y: base.y), control: CGPoint(x: base.x + spread * 0.6, y: base.y - 46 - 3 * sin(t * 4 + Double(k))))
                context.stroke(arc, with: .color(water.opacity(0.85)), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
                context.stroke(arc, with: .color(.white.opacity(0.7)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round, dash: [3, 5], dashPhase: -t * 14))
            }
            for k in 0..<2 {
                let grow = time.map { ($0 * 0.8 + Double(k) * 0.5).truncatingRemainder(dividingBy: 1) } ?? 0.4
                let r = 6 + 10 * grow
                context.stroke(
                    Path(ellipseIn: CGRect(x: base.x - r, y: base.y - r * 0.35, width: r * 2, height: r * 0.7)),
                    with: .color(.white.opacity(0.6 * (1 - grow))), lineWidth: 1
                )
            }
        }
        .frame(width: 90, height: 90)
        .position(x: point.x, y: point.y - 30)
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: WorldStrings.caglayanGift))
    }
}
/// Damla, on Çağlayan's lawn or at the top of the falls: drawn in the
/// scene's characters layer, so the character light grades her like Pofu
/// (the island's LUT is fitted to lawn, earth and props and left her pale
/// and peach). Same canvas and position as `CaglayanIsleView`.
struct CaglayanDamlaView: View {
    let stage: Int
    /// Where the island's centre lands on the canvas.
    let point: CGPoint
    let characterGrade: WorldGrade

    private static let canvas = CGSize(width: 320, height: 200)
    private static let origin = CGPoint(x: 160, y: 100)

    var body: some View {
        let s = CaglayanLayout.clamped(stage)
        let name = CaglayanLayout.damlaArt(stage: s)
        let feet = CaglayanLayout.damlaPoint(stage: s)
        if KokeArt.has(name), let box = WorldArt.sprite(CaglayanLayout.damlaKey(stage: s))?.sharp {
            let k = CaglayanLayout.damlaScale
            ZStack {
                // Her contact shadow, then she.
                Ellipse()
                    .fill(Color(red: 0.24, green: 0.24, blue: 0.30).opacity(0.22))
                    .frame(width: 18, height: 5)
                    .position(x: Self.origin.x + feet.x, y: Self.origin.y + feet.y)
                Image(name, bundle: .module)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: box.width * k, height: box.height * k)
                    .position(x: Self.origin.x + feet.x + box.midX * k, y: Self.origin.y + feet.y + box.midY * k)
            }
            .frame(width: Self.canvas.width, height: Self.canvas.height)
            .gradedIfNeeded(characterGrade)
            .position(x: point.x, y: point.y)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
#endif
