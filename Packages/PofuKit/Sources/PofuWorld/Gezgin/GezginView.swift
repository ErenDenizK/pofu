#if os(iOS)
import Observation
import PofuCore
import PofuDesignSystem
import SwiftUI

/// One of her lines: a key of the string catalog and a number that changes with every tap, so a
/// repeated line still pops in again.
struct GezginLine: Equatable {
    var id: Int
    var key: String
}

/// Her beat: the tap that wakes her, the line and the cue. Observable state is only what the views
/// read; where she is and what she wears come from the world (`Gezgin.presence`).
@MainActor
@Observable
public final class GezginBeatState {
    /// The line now, or `nil`.
    private(set) var line: GezginLine?
    /// When the last tap woke her; `nil` before the first one.
    public private(set) var wokeAt: Date?
    /// A held age of the tap, in seconds (screenshots): the frame's clock is real time, so a still frame
    /// states how old the tap is instead of when it was.
    public private(set) var heldAge: Double?

    @ObservationIgnored private var taps = 0
    @ObservationIgnored private var dismissTask: Task<Void, Never>?

    public init() {}

    /// A tap on her: she answers at once (a stretch and a hop), says a line, and at night stays awake for
    /// a while. `asleep` is whether she was asleep when touched.
    func tapped(asleep: Bool, in model: IslandSceneModel, now: Date = Date()) {
        let data = GezginData.shipped
        taps += 1
        wokeAt = now
        heldAge = nil
        show(key: Gezgin.lineKey(asleep: asleep, taps: taps - 1), seconds: data?.lineSeconds ?? 4.5)
        model.holdMoment(seconds: asleep ? (data?.awakeSeconds ?? 7) + 0.5 : 1.2, from: now)
        PofuHaptics.shared.play(.land)
        model.onGezginWake?()
    }

    /// Shows a line (screenshots and tests keep it with `seconds` of 0).
    func show(key: String, seconds: Double = 0) {
        let id = (line?.id ?? 0) + 1
        dismissTask?.cancel()
        line = GezginLine(id: id, key: key)
        guard seconds > 0 else { return }
        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled, let self, self.line?.id == id else { return }
            self.line = nil
        }
    }

    /// Wakes her at `date` without a line (screenshots hold a frame of it).
    public func wake(at date: Date) {
        wokeAt = date
    }

    /// Wakes her with the tap held at `age` seconds old (a still frame of the stretch).
    public func wake(heldAge age: Double) {
        heldAge = age
        wokeAt = Date()
    }

    /// Keeps one of her lines up, by its catalog key (`Gezgin.lineKey`), for a screenshot.
    public func hold(lineKey key: String) {
        show(key: key)
    }
}

/// Her speech bubble, over the scene near the top of the island's band.
struct GezginBubbleOverlay: View {
    let state: GezginBeatState

    var body: some View {
        if let line = state.line {
            SpeechBubble {
                VStack(spacing: 2) {
                    Text(verbatim: WorldStrings.gezginName)
                        .font(PofuFont.caption)
                        .foregroundStyle(PofuColor.textSecondary)
                    Text(verbatim: WorldStrings.gezginLine(line.key))
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

/// How the hour tints her where the plate's own character light is not at hand (Köke, Çağlayan): the same
/// numbers as the ride's grade of her (`VoyageGrade.whale`).
struct GezginTint: Equatable {
    var saturation: Double
    var red: Double
    var green: Double
    var blue: Double

    static func of(_ grade: VoyageGrade) -> GezginTint {
        GezginTint(saturation: grade.saturation, red: grade.red, green: grade.green, blue: grade.blue)
    }
}

/// The Gezgin moored at an island's berth, drawn on the world canvas (units of the world): one cut-out for
/// her level and pose, her tail piece swaying over its own place in it, a bob, and the stretch and hop of
/// a tap. She takes the island's light (`tint`). She is seen from the side or the front, never from behind,
/// and nothing stands in front of her. The post stands on the rim and a slack line runs from it to her bow.
struct GezginMooredView: View {
    let data: GezginData
    let berth: GezginBerth
    let level: Int
    let pose: GezginPose
    let tint: GezginTint
    /// Her feet on the canvas.
    let point: CGPoint
    /// The frame's time (0 in a still frame) and the seconds since the last tap, if any.
    let time: Double
    let wakeAge: Double?

    var body: some View {
        // The cut-out box's size in world units: the body's width is the berth's.
        let bodyPixels = max(data.art.body[2] - data.art.body[0], 1)
        let unit = berth.width / bodyPixels
        let width = data.art.canvas[0] * unit
        let height = data.art.canvas[1] * unit
        let feetRow = data.art.body[3] * unit
        let answer = Gezgin.answer(age: wakeAge)
        let blinking = pose == .awake && Gezgin.blinking(time: time, data: data)
        // The data's bob is in pixels of a 250-px-wide mooring.
        let bob = Gezgin.bob(time: time, data: data) * berth.width / 250
        let lift = answer.lift * berth.width / 250
        let bodyArt = Image(Gezgin.art(level: level, blinking ? "asleep" : pose.rawValue), bundle: .module)
        let tailArt = Image(Gezgin.art(level: level, "tail"), bundle: .module)
        let pivot = UnitPoint(x: CGFloat(data.art.tailPivot[0] / data.art.canvas[0]), y: CGFloat(data.art.tailPivot[1] / data.art.canvas[1]))
        let figure = ZStack {
            bodyArt.resizable()
            tailArt.resizable()
                .rotationEffect(.degrees(Gezgin.swayDegrees(time: time, data: data)), anchor: pivot)
        }
        .frame(width: CGFloat(width), height: CGFloat(height))
        .saturation(tint.saturation)
        .colorMultiply(Color(red: tint.red, green: tint.green, blue: tint.blue))
        .scaleEffect(x: CGFloat(2 - answer.squash), y: CGFloat(answer.squash), anchor: UnitPoint(x: 0.5, y: CGFloat(feetRow / height)))
        .position(x: point.x, y: point.y - CGFloat(feetRow) + CGFloat(height) / 2 + CGFloat(bob - lift))
        .allowsHitTesting(false)
        // Everything is placed from her feet: the post and the line are offsets of them.
        let dx = point.x - CGFloat(berth.feet.x), dy = point.y - CGFloat(berth.feet.y)
        let post = CGPoint(x: CGFloat(berth.post.x) + dx, y: CGFloat(berth.post.y) + dy)
        let tie = CGPoint(x: CGFloat(berth.tie.x) + dx, y: CGFloat(berth.tie.y) + dy)
        let bow = CGPoint(x: CGFloat(berth.bow.x) + dx, y: CGFloat(berth.bow.y) + dy + CGFloat(bob - lift))
        ZStack(alignment: .topLeading) {
            MooringLine(post: post, tie: tie, bow: bow, poleHeight: CGFloat(berth.postHeight), sag: berth.rope.sag, thickness: CGFloat(max(berth.rope.thickness * berth.width, 0.8)), tint: tint)
            figure
        }
        .allowsHitTesting(false)
    }
}

/// The post and the slack line from it to her bow: the line goes down behind her, the figure is drawn over it.
struct MooringLine: View {
    let post: CGPoint
    let tie: CGPoint
    let bow: CGPoint
    let poleHeight: CGFloat
    let sag: Double
    let thickness: CGFloat
    let tint: GezginTint

    var body: some View {
        let imageHeight = poleHeight / CGFloat(GezginPost.poleShare)
        let imageWidth = imageHeight / CGFloat(GezginPost.aspect)
        let control = GezginData.Rope.control(
            tie: WorldPoint(x: Double(tie.x), y: Double(tie.y)), bow: WorldPoint(x: Double(bow.x), y: Double(bow.y)), sag: sag
        )
        let curve = Path { path in
            path.move(to: tie)
            path.addQuadCurve(to: bow, control: CGPoint(x: control.x, y: control.y))
        }
        let shade = Color(red: 0.45, green: 0.30, blue: 0.17)
        let cord = Color(red: 0.95, green: 0.84, blue: 0.62)
        ZStack(alignment: .topLeading) {
            // A darker line under a lighter one, so it reads as a twisted rope at the picture's own size.
            curve.stroke(shade.opacity(0.85), style: StrokeStyle(lineWidth: thickness * 1.5, lineCap: .round))
            curve.stroke(cord, style: StrokeStyle(lineWidth: thickness * 1.0, lineCap: .round))
            // A lighter line along the top, for roundness.
            curve.stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: thickness * 0.35, lineCap: .round))
                .offset(y: -thickness * 0.2)
            // Its small contact shadow on the grass.
            Ellipse()
                .fill(Color.black.opacity(0.18))
                .frame(width: imageWidth * 0.5, height: imageWidth * 0.14)
                .position(x: post.x, y: post.y)
            Image("world-gezgin-post", bundle: .module)
                .resizable()
                .frame(width: imageWidth, height: imageHeight)
                .saturation(tint.saturation)
                .colorMultiply(Color(red: tint.red, green: tint.green, blue: tint.blue))
                .position(
                    x: post.x + imageWidth * CGFloat(0.5 - GezginPost.footX),
                    y: post.y + imageHeight * CGFloat(0.5 - GezginPost.footY)
                )
        }
        .allowsHitTesting(false)
    }
}

/// Her shadow crossing the cloud sea before she arrives: the soft silhouette of her level-one body,
/// drifting from one side of the plate to the other, over the cloud below the island.
struct GezginShadowView: View {
    let data: GezginData
    let plate: HomePlate
    let mooring: PlateMooring
    /// Its centre on the canvas.
    let point: CGPoint

    var body: some View {
        let bodyPixels = max(data.art.body[2] - data.art.body[0], 1)
        let unit = mooring.width * plate.unitsPerPixel / bodyPixels
        let width = data.art.canvas[0] * unit
        let height = data.art.canvas[1] * unit
        // Darker and a little larger than the art: on the pale cloud the painted shade alone is faint (2b
        // review), and she flies high, so her shadow is wide.
        Image(Gezgin.art(level: 1, "cloudshade"), bundle: .module)
            .resizable()
            .frame(width: CGFloat(width), height: CGFloat(height))
            .colorMultiply(Color(red: 0.60, green: 0.63, blue: 0.84))
            .scaleEffect(1.3)
            .opacity(data.shadow.opacity)
            .position(x: point.x, y: point.y)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
#endif
