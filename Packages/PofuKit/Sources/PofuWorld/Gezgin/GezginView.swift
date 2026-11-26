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

    @ObservationIgnored private var taps = 0
    @ObservationIgnored private var dismissTask: Task<Void, Never>?

    public init() {}

    /// A tap on her: she answers at once (a stretch and a hop), says a line, and at night stays awake for
    /// a while. `asleep` is whether she was asleep when touched.
    func tapped(asleep: Bool, in model: IslandSceneModel, now: Date = Date()) {
        let data = GezginData.shipped
        taps += 1
        wokeAt = now
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

/// The Gezgin moored at the pier, drawn on the world canvas (units of the plate's world): one cut-out for
/// her level and pose, her tail piece swaying over its own place in it, a bob, and the stretch and hop of
/// a tap. She takes the plate's character light, so she sleeps dim in the night plate. She is seen from
/// the side or the front, never from behind, and nothing stands in front of her.
struct GezginMooredView: View {
    let data: GezginData
    let plate: HomePlate
    let mooring: PlateMooring
    let level: Int
    let pose: GezginPose
    /// Her feet on the canvas.
    let point: CGPoint
    /// The frame's time (0 in a still frame) and the seconds since the last tap, if any.
    let time: Double
    let wakeAge: Double?

    var body: some View {
        // The cut-out box's size in world units: the body's width is the mooring's.
        let bodyPixels = max(data.art.body[2] - data.art.body[0], 1)
        let unit = mooring.width * plate.unitsPerPixel / bodyPixels
        let width = data.art.canvas[0] * unit
        let height = data.art.canvas[1] * unit
        let feetRow = data.art.body[3] * unit
        let answer = Gezgin.answer(age: wakeAge)
        let blinking = pose == .awake && Gezgin.blinking(time: time, data: data)
        let bob = Gezgin.bob(time: time, data: data) * plate.unitsPerPixel
        let lift = answer.lift * plate.unitsPerPixel
        let light = plate.characterLight(
            at: plate.world(plate.plate.characters["findik"] ?? mooring.feet),
            width: width, height: height, id: "gezgin"
        )
        let bodyArt = Image(Gezgin.art(level: level, blinking ? "asleep" : pose.rawValue), bundle: .module)
        let tailArt = Image(Gezgin.art(level: level, "tail"), bundle: .module)
        let pivot = UnitPoint(x: CGFloat(data.art.tailPivot[0] / data.art.canvas[0]), y: CGFloat(data.art.tailPivot[1] / data.art.canvas[1]))
        ZStack {
            bodyArt.resizable()
            tailArt.resizable()
                .rotationEffect(.degrees(Gezgin.swayDegrees(time: time, data: data)), anchor: pivot)
        }
        .frame(width: CGFloat(width), height: CGFloat(height))
        .saturation(light.saturation)
        .colorMultiply(Color(red: light.paint.red, green: light.paint.green, blue: light.paint.blue))
        .scaleEffect(x: CGFloat(2 - answer.squash), y: CGFloat(answer.squash), anchor: UnitPoint(x: 0.5, y: CGFloat(feetRow / height)))
        .position(x: point.x, y: point.y - CGFloat(feetRow) + CGFloat(height) / 2 + CGFloat(bob - lift))
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
        Image(Gezgin.art(level: 1, "shadow"), bundle: .module)
            .resizable()
            .frame(width: CGFloat(width), height: CGFloat(height))
            .opacity(data.shadow.opacity)
            .position(x: point.x, y: point.y)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
#endif
