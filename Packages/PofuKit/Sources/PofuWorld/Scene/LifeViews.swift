#if os(iOS)
import PofuCore
import SwiftUI

/// A piece of dressing leaving in the reveal's puff: the piece's scale and
/// opacity and the cloud's radius and opacity (`DressingReveal.frame`).
typealias DressingLeave = (scale: Double, opacity: Double, puffRadius: Double, puffOpacity: Double)

/// One piece of the lawn's dressing at its feet (experience v1 §6). It draws
/// the baked sprite named `piece.art` when the pipeline has one, otherwise the
/// code-drawn stand-in of its Codex job (`dressing-meadow`, `dressing-garden`,
/// `dressing-harbor`). It never moves by itself: a brush sways it about its
/// base, and a slot that opens sends it off in a soft puff.
struct DressingView: View {
    let piece: DressingPiece
    /// Its feet on the canvas.
    let point: CGPoint
    let level: Double
    /// A brushing finger's sway, in degrees about the base (§1.3).
    var sway = 0.0
    var leave: DressingLeave?

    var body: some View {
        let kind = piece.kind
        let anchor = UnitPoint(x: point.x / IslandLayout.canvasWidth, y: point.y / IslandLayout.canvasHeight)
        ZStack(alignment: .topLeading) {
            Group {
                if let sprite = WorldArt.sprite(piece.art) {
                    DepthImage(name: piece.art, sprite: sprite, level: level, anchor: point)
                } else {
                    let size = LifeArt.size(of: kind)
                    Canvas { context, canvasSize in
                        LifeArt.drawDressing(kind, in: &context, size: canvasSize)
                    }
                    .standing(on: point, width: size.width, height: size.height)
                }
            }
            .scaleEffect(CGFloat(leave?.scale ?? 1), anchor: anchor)
            .opacity(leave?.opacity ?? 1)
            if let leave {
                // The reveal's puff: a soft white cloud over the spot.
                let radius = CGFloat(leave.puffRadius)
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.white.opacity(leave.puffOpacity), Color.white.opacity(0)],
                        center: .center, startRadius: 0, endRadius: radius
                    ))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: point.x, y: point.y - 6)
                    .allowsHitTesting(false)
            }
        }
        .rotationEffect(.degrees(sway), anchor: anchor)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// One fixed painted thing of the home island: a door in the earth face or
/// the hive (`HomeFixtures`). It is part of the scenery, so it never moves,
/// has no tap target and is hidden from accessibility, like the plate.
struct FixtureView: View {
    let art: String
    /// Its slot on the canvas.
    let point: CGPoint
    let level: Double

    var body: some View {
        if let sprite = WorldArt.sprite(art) {
            DepthImage(name: art, sprite: sprite, level: level, anchor: point)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// A critter at its rest spot (experience v1 §6, rule 3): the baked sprite
/// named `kind.art` or the stand-in, offset by the pose. Outside Ambient the
/// pose is the rest pose, so a settled frame is the same image every time.
struct CritterView: View {
    let critter: Critter
    /// Its rest spot on the canvas.
    let point: CGPoint
    let level: Double
    let pose: CritterMotion.Pose
    /// A brushing finger's sway, in degrees about the base (§1.3).
    var sway = 0.0
    var grade: WorldGrade = .neutral

    var body: some View {
        let kind = critter.kind
        let frame = pose.frame
        let at = CGPoint(x: point.x + CGFloat(pose.dx), y: point.y + CGFloat(pose.dy))
        let anchor = UnitPoint(x: at.x / IslandLayout.canvasWidth, y: at.y / IslandLayout.canvasHeight)
        ZStack(alignment: .topLeading) {
            if critter.isOnLawn {
                ContactShadow(width: 12, height: 3, strength: 0.7)
                    .position(x: point.x + CGFloat(pose.dx) * 0.4, y: point.y)
            }
            Group {
                if let sprite = WorldArt.sprite(kind.art(frame: frame)) {
                    // The sheets are drawn facing right; a pose that faces left mirrors the sprite about its feet.
                    DepthImage(name: kind.art(frame: frame), sprite: sprite, level: level, anchor: at, grade: grade)
                        .scaleEffect(x: pose.facesLeft ? -1 : 1, y: 1, anchor: anchor)
                } else {
                    let size = LifeArt.size(of: kind)
                    Canvas { context, canvasSize in
                        LifeArt.drawCritter(kind, frame: frame, in: &context, size: canvasSize)
                    }
                    .scaleEffect(x: pose.facesLeft ? -1 : 1, y: 1)
                    .standing(on: at, width: size.width, height: size.height, grade: grade)
                }
            }
        }
        .rotationEffect(.degrees(sway), anchor: anchor)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The visitor's offset and opacity at the arrival beat (`VisitorStage.arrival`).
typealias VisitorArrivalFrame = (dx: Double, dy: Double, opacity: Double, seed: Double)

/// One part of today's visit in the world: the visitor, the gift parcel, the
/// help target or the quiet day's letter. Each draws the baked sprite named
/// after its Codex job when it exists (`gift-parcel`, `guest-letter`,
/// `visitor-dandelion`) and a code-drawn stand-in until then.
struct VisitorPartView: View {
    let part: VisitorStage.Placed
    let visitor: VisitorSnapshot?
    /// Its feet on the canvas.
    let point: CGPoint
    let level: Double
    /// The arrival beat, while it runs.
    var arrival: VisitorArrivalFrame?
    /// The idle bob, in world units (Ambient only).
    var bob = 0.0
    var grade: WorldGrade = .neutral
    /// Bumped by every tap on the part: a squish.
    var pulse = 0

    var body: some View {
        let beat = part.part == .visitor ? arrival : nil
        let at = CGPoint(x: point.x + CGFloat(beat?.dx ?? 0), y: point.y + CGFloat(beat?.dy ?? 0) + CGFloat(part.part == .visitor ? bob : 0))
        // Nothing of the visit is there before the camera has panned.
        let opacity = arrival?.opacity ?? 1
        ZStack(alignment: .topLeading) {
            if part.part != .help {
                ContactShadow(width: part.part == .visitor ? 22 : 16, height: 5, strength: 0.9)
                    .position(x: point.x, y: point.y)
            }
            switch part.part {
            case .visitor:
                visitorBody(at: at)
                if let seed = beat?.seed, seed > 0.01 {
                    dandelion(above: at)
                        .opacity(seed)
                }
            case .gift:
                art(VisitorArt.giftParcel, size: LifeArt.parcelSize, at: at) { context, size in
                    LifeArt.drawParcel(in: &context, size: size)
                }
            case .help:
                art("help-kite", size: LifeArt.kiteSize, at: at) { context, size in
                    LifeArt.drawKite(in: &context, size: size)
                }
            case .letter:
                art(VisitorArt.guestLetter, size: LifeArt.letterSize, at: at) { context, size in
                    LifeArt.drawLetter(in: &context, size: size)
                }
            }
        }
        .opacity(opacity)
        .modifier(TapSquish(
            trigger: pulse,
            anchor: UnitPoint(x: point.x / IslandLayout.canvasWidth, y: point.y / IslandLayout.canvasHeight)
        ))
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func visitorBody(at: CGPoint) -> some View {
        let resident = visitor?.resident
        // A painted visitor, when one exists, is named for the resident.
        if let resident, let sprite = WorldArt.sprite("visitor-\(resident.rawValue)") {
            DepthImage(name: "visitor-\(resident.rawValue)", sprite: sprite, level: level, anchor: at, grade: grade)
        } else {
            Canvas { context, size in
                LifeArt.drawVisitor(resident ?? ResidentID(rawValue: ""), in: &context, size: size)
            }
            .standing(on: at, width: LifeArt.visitorSize.width, height: LifeArt.visitorSize.height, grade: grade)
        }
    }

    /// The dandelion seed over the visitor's head during a drift.
    @ViewBuilder
    private func dandelion(above at: CGPoint) -> some View {
        let top = CGPoint(x: at.x, y: at.y - LifeArt.visitorSize.height + 6)
        if let sprite = WorldArt.sprite(VisitorArt.dandelion) {
            DepthImage(name: VisitorArt.dandelion, sprite: sprite, level: level, anchor: top)
        } else {
            Canvas { context, size in
                LifeArt.drawDandelion(in: &context, size: size)
            }
            .standing(on: top, width: LifeArt.dandelionSize.width, height: LifeArt.dandelionSize.height)
        }
    }

    /// A part's baked sprite by name, or its stand-in.
    @ViewBuilder
    private func art(
        _ name: String,
        size: CGSize,
        at: CGPoint,
        draw: @escaping @Sendable (inout GraphicsContext, CGSize) -> Void
    ) -> some View {
        if let sprite = WorldArt.sprite(name) {
            DepthImage(name: name, sprite: sprite, level: level, anchor: at, grade: grade)
        } else {
            Canvas { context, canvasSize in
                draw(&context, canvasSize)
            }
            .standing(on: at, width: size.width, height: size.height, grade: grade)
        }
    }
}
#endif
