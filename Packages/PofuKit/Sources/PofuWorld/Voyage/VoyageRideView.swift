#if os(iOS)
import PofuCompanion
import PofuCore
import PofuDesignSystem
import SwiftUI

/// The ride's views (plan row 2d): the Gezgin over the world, the passengers on her back, and the soft wake
/// behind her. Over the scene, above the row; it draws nothing when no ride is under way, and nothing under
/// Reduce Motion (the camera's cross-fade is the whole ride then).
struct VoyageRideOverlay: View {
    let model: IslandSceneModel
    let world: WorldSnapshot

    var body: some View {
        if let ride = model.ride, !ride.reduced, let data = GezginData.shipped {
            VoyageRideScene(model: model, ride: ride, world: world, data: data)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

private struct VoyageRideScene: View {
    let model: IslandSceneModel
    let ride: VoyageRide
    let world: WorldSnapshot
    let data: GezginData


    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            PofuTimeline(hz: PofuFrameRate.direct, paused: model.rideHeld != nil, kind: .essential) { context in
                let t = model.rideElapsed(at: context.date) ?? ride.duration
                rideFrame(at: t, start: startSpot(size: size, at: t), size: size)
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
        .ignoresSafeArea()
    }

    /// Where she lies in the row `t` seconds into the ride: moored at the island the player is leaving, which
    /// the row has glided to (`VoyageRide.rowPosition`), so the same spot the row's own drawing would give her.
    private func startSpot(size: CGSize, at t: Double) -> VoyageRide.Spot {
        // A trip that did not start in the row has no mooring to lift off from: she comes in at the cruise.
        guard ride.fromRow else { return VoyageRide.cruise }
        let layout = VoyageRowLayout(width: Double(size.width), height: Double(size.height))
        let stops = VoyageRoute.stops(koke: world.koke, caglayan: world.caglayan)
        let from = VoyageRoute.index(of: ride.from, in: stops)
        let shown = VoyageRoute.index(of: model.voyage.island, in: stops)
        let position = ride.rowPosition(at: t, selected: Double(shown), origin: Double(from))
        return layout.mooredSpot(at: layout.place(index: from, position: position))
    }

    /// Her width on the screen once the world is what is drawn: the same share of an island's width as in the
    /// row, at the camera's own scale, so she and the islands grow and shrink together.
    private func worldWidth(at t: Double) -> Double {
        // The island her width is a share of: the one she leaves, handed over to the one she goes to as the
        // camera crosses, so her size never steps.
        let (beat, progress) = ride.beat(at: t)
        let u = beat == .board ? 0 : beat == .fly ? VoyageRide.ease(progress) : 1
        // At a berth her width settles at her cut-out's own width there.
        let from = islandWidth(ride.from)
        let to = berth.map { $0.canvasWidth(data: data) / VoyageRide.islandShare } ?? islandWidth(ride.to)
        return (from + (to - from) * u) * VoyageRide.islandShare * model.engine.rig.pose.scale
    }

    /// Her place at the island she goes to, or `nil`: she hovers beside it.
    private var berth: GezginBerth? {
        Gezgin.berth(at: ride.to, data: data, home: model.homePlate)
    }

    /// A world point on the screen, by the camera as it is now (the scene's own projection).
    private func screen(_ point: WorldPoint, size: CGSize) -> CGPoint {
        let rig = model.engine.rig
        let p = rig.pose.project(point, width: Double(size.width))
        return CGPoint(x: p.x + Double(rig.offsetX.value), y: p.y + Double(rig.offsetY.value))
    }

    /// An island's width in world units.
    private func islandWidth(_ island: IslandID) -> Double {
        switch island {
        case .koke: KokeLayout.islandBox.width
        case .caglayan: CaglayanLayout.islandBox.width
        default: model.homePlate?.islandBox.width ?? KokeLayout.islandBox.width
        }
    }

    private var level: Int {
        Gezgin.presence(koke: world.koke, caglayan: world.caglayan, data: data).level ?? 1
    }

    @ViewBuilder
    private func rideFrame(at t: Double, start: VoyageRide.Spot, size: CGSize) -> some View {
        let berth = self.berth
        let berthSpot = berth.map { b -> VoyageRide.Spot in
            let c = screen(b.canvasCentre(data: data), size: size)
            let w = b.canvasWidth(data: data) * model.engine.rig.pose.scale
            return VoyageRide.Spot(x: Double(c.x) / Double(size.width), y: Double(c.y) / Double(size.height), width: w / Double(size.width))
        }
        let spot = ride.whale(at: t, start: start, berth: berthSpot)
        let width = ride.whaleWidth(at: t, row: start.width * Double(size.width), world: worldWidth(at: t))
        let height = width * data.art.canvas[1] / max(data.art.canvas[0], 1)
        let beat = ride.beat(at: t)
        let flying = beat.beat == .fly
        let bobSeconds = 2.4
        let bob = sin(2 * .pi * t / bobSeconds) * 0.014 * width * (flying ? 1 : 0.35)
        let centre = CGPoint(x: spot.x * Double(size.width), y: spot.y * Double(size.height) + bob)
        let whaleGrade = VoyageGrade.whale(light: model.homePlate?.light ?? "day")
        ZStack(alignment: .topLeading) {
            if VoyageWake.isVisible(ride: ride, at: t) {
                CloudWake(ride: ride, time: t, centre: centre, width: width, grade: whaleGrade)
            }
            if let berth, beat.beat == .moor {
                // Her post and the slack line to her bow come in as she nears the berth (the post stands on the
                // island, the same one the island's own scene draws when the ride hands her over).
                let near = VoyageRide.ease((beat.progress - 0.3) / 0.4)
                let scale = model.engine.rig.pose.scale
                let canvasWidth = berth.canvasWidth(data: data)
                let k = width / max(canvasWidth * scale, 1)
                let facing = ride.facing(at: t, berthed: true)
                let ownCentre = screen(berth.canvasCentre(data: data), size: size)
                let bowRest = screen(berth.bow, size: size)
                let post = screen(berth.post, size: size)
                let tie = screen(berth.tie, size: size)
                // Her bow follows her body: its rest offset from her centre, scaled and turned with her.
                let bow = CGPoint(
                    x: centre.x + (bowRest.x - ownCentre.x) * CGFloat(k * facing),
                    y: centre.y + (bowRest.y - ownCentre.y) * CGFloat(k)
                )
                MooringLine(post: post, tie: tie, bow: bow, poleHeight: CGFloat(berth.postHeight * scale), sag: berth.rope.sag, thickness: CGFloat(max(berth.rope.thickness * berth.width * scale, 0.8)), tint: GezginTint.of(whaleGrade))
                    .opacity(near)
            }
            GezginFlyer(
                data: data, level: level, width: width, flip: ride.toTheRight,
                facing: ride.facing(at: t, berthed: berth != nil), time: t, tilt: ride.tilt(at: t)
            )
            .saturation(whaleGrade.saturation)
            .brightness(whaleGrade.brightness)
            .colorMultiply(Color(red: whaleGrade.red, green: whaleGrade.green, blue: whaleGrade.blue))
            .position(centre)
            ForEach(Array(passengers.enumerated()), id: \.offset) { index, passenger in
                let landing = VoyageRide.landing(index: index, in: berth?.landing ?? []).map { screen($0, size: size) }
                let place = passengerPlace(index: index, beat: beat, centre: centre, width: width, height: height, landing: landing)
                if passenger.art == "pofu" {
                    // Pofu is the companion's own full-body picture (his sprite has no sharp layer: the live
                    // rig draws it).
                    if let art = CompanionArt.placeholder {
                        let rig = art.rig
                        let w = width * passenger.share, h = w / rig.aspectRatio
                        Image(decorative: art.base, scale: 1)
                            .resizable()
                            .frame(width: CGFloat(w), height: CGFloat(h))
                            .opacity(place.opacity)
                            .position(
                                x: place.x - CGFloat(w * rig.ground.x) + CGFloat(w / 2),
                                y: place.y - CGFloat(h * rig.ground.y) + CGFloat(h / 2)
                            )
                    }
                } else if let sprite = WorldArt.sprite(passenger.art), let box = sprite.sharp {
                    DepthImage(
                        name: passenger.art, sprite: sprite, level: 0, anchor: CGPoint(x: place.x, y: place.y),
                        scale: CGFloat(width * passenger.share) / CGFloat(max(box.width, 1)), opacity: place.opacity
                    )
                }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .opacity(ride.whaleOpacity(at: t, berthed: berth != nil))
    }

    /// Who rides: Pofu, and Fındık with him. Their width against her cut-out's.
    private var passengers: [(art: String, share: Double)] {
        [("pofu", 0.2), ("findik", 0.13)]
    }

    /// A passenger's feet and opacity: on the shore while she waits, in the air as he hops aboard, on her back
    /// through the flight, in the air again as he hops off.
    private func passengerPlace(index: Int, beat: (beat: VoyageRide.Beat, progress: Double), centre: CGPoint, width: Double, height: Double, landing: CGPoint?) -> (x: CGFloat, y: CGFloat, opacity: Double) {
        let count = passengers.count
        let top = Double(centre.y) - height / 2
        let seat = VoyageRide.seat(index: index, count: count, toTheRight: ride.toTheRight)
        let shore = VoyageRide.shore(index: index, toTheRight: ride.toTheRight)
        func point(_ p: (dx: Double, feetY: Double)) -> (x: Double, y: Double) {
            (Double(centre.x) + p.dx * width, top + p.feetY * height)
        }
        let seated = point(seat)
        // At a berth they land on the island, at its landing spots; otherwise beside her.
        let onShore = landing.map { (x: Double($0.x), y: Double($0.y)) } ?? point(shore)
        switch beat.beat {
        case .board:
            // Boarding is from the island she leaves, beside her: never the landing of the island she goes to.
            let from = point(shore)
            let hop = VoyageRide.hop(VoyageRide.hopProgress(index: index, count: count, beatProgress: VoyageRide.boardProgress(beat.progress)))
            return (
                CGFloat(from.x + (seated.x - from.x) * hop.along),
                CGFloat(from.y + (seated.y - from.y) * hop.along - hop.lift * width),
                1
            )
        case .fly:
            return (CGFloat(seated.x), CGFloat(seated.y), 1)
        case .moor, .done:
            let p = VoyageRide.hopProgress(index: index, count: count, beatProgress: beat.beat == .done ? 1 : beat.progress)
            let hop = VoyageRide.hop(p)
            return (
                CGFloat(seated.x + (onShore.x - seated.x) * hop.along),
                CGFloat(seated.y + (onShore.y - seated.y) * hop.along - hop.lift * width),
                1 - VoyageRide.ease((p - 0.7) / 0.3)
            )
        }
    }
}

/// The Gezgin on the wing, or moored in the row: her body and her tail piece (it sways), by her level. Facing
/// left as painted, mirrored when she goes right; never from behind.
struct GezginFlyer: View {
    let data: GezginData
    let level: Int
    let width: Double
    var flip = false
    /// The horizontal scale of her art when it is not simply `flip` (turning at a berth), or `nil`.
    var facing: Double?
    /// 0 is a still frame: the rest pose, eyes open, the tail straight.
    var time = 0.0
    var tilt = 0.0

    var body: some View {
        let canvas = data.art.canvas
        let height = width * canvas[1] / max(canvas[0], 1)
        let pivot = UnitPoint(x: CGFloat(data.art.tailPivot[0] / canvas[0]), y: CGFloat(data.art.tailPivot[1] / canvas[1]))
        let blinking = Gezgin.blinking(time: time, data: data)
        ZStack {
            Image(Gezgin.art(level: level, blinking ? "asleep" : "awake"), bundle: .module).resizable()
            Image(Gezgin.art(level: level, "tail"), bundle: .module).resizable()
                .rotationEffect(.degrees(Gezgin.swayDegrees(time: time, data: data) * 2.5), anchor: pivot)
        }
        .frame(width: CGFloat(width), height: CGFloat(height))
        .scaleEffect(x: CGFloat(facing ?? (flip ? -1 : 1)), y: 1)
        .rotationEffect(.degrees(tilt))
    }
}

/// The cloud wake streaming off her tail while she flies (`VoyageWake`): the short cluster at take-off and
/// landing, the long chain between. Two cut-outs, no masks or blurs at draw time (the far end's fade is in the
/// art), so it is the cheap thing to cut if the ride drops frames.
private struct CloudWake: View {
    let ride: VoyageRide
    let time: Double
    let centre: CGPoint
    let width: Double
    let grade: VoyageGrade

    var body: some View {
        ZStack {
            ForEach(VoyageWake.Piece.allCases, id: \.self) { piece in
                let opacity = VoyageWake.opacity(piece, ride: ride, at: time)
                if opacity > 0.001 {
                    let w = width * piece.share
                    let offset = VoyageWake.offset(piece, ride: ride, at: time)
                    // Painted with the big puff on the left; going right the wake trails to the left.
                    Image(piece.asset, bundle: .module).resizable()
                        .frame(width: CGFloat(w), height: CGFloat(w * piece.aspect))
                        .scaleEffect(x: ride.toTheRight ? -1 : 1, y: 1)
                        .saturation(grade.saturation)
                        .brightness(grade.brightness)
                        .colorMultiply(Color(red: grade.red, green: grade.green, blue: grade.blue))
                        .opacity(opacity)
                        .position(
                            x: centre.x + CGFloat((offset.dx + (ride.toTheRight ? -0.5 : 0.5) * piece.share) * width),
                            y: centre.y + CGFloat(offset.dy * width)
                        )
                }
            }
        }
    }
}

/// The bed of cloud an island of the row lies in: a wide bank behind its foot and a low lip in front, so the
/// island sits in the sea and does not float above it. `foot` is the screen row of the island's foot.
struct VoyageBed: View {
    let x: Double
    let foot: Double
    let width: Double
    let weight: Double
    let grade: VoyageGrade
    /// The lip is the part in front of the island.
    var front = false

    var body: some View {
        let tint = Color(red: min(grade.red + 0.04, 1), green: min(grade.green + 0.04, 1), blue: min(grade.blue + 0.02, 1))
        let puffs: [(dx: Double, dy: Double, size: Double)] = front
            ? [(-0.40, -0.02, 0.34), (-0.14, 0.01, 0.42), (0.14, 0.0, 0.40), (0.40, -0.02, 0.34), (0.0, 0.06, 0.48)]
            : [(-0.52, -0.02, 0.30), (-0.26, -0.05, 0.36), (0.02, -0.06, 0.40), (0.3, -0.05, 0.36), (0.54, -0.02, 0.30)]
        ZStack {
            if !front {
                // A wide soft bank: a circle squashed flat, so its gradient fades before any edge.
                Circle()
                    .fill(RadialGradient(colors: [tint.opacity(0.9), tint.opacity(0)], center: .center, startRadius: 0, endRadius: CGFloat(width * 0.65)))
                    .frame(width: CGFloat(width * 1.3), height: CGFloat(width * 1.3))
                    .scaleEffect(x: 1, y: 0.26)
                    .position(x: CGFloat(x), y: CGFloat(foot))
            }
            ForEach(Array(puffs.enumerated()), id: \.offset) { _, puff in
                Circle()
                    .fill(RadialGradient(
                        colors: [tint.opacity(front ? 0.95 : 0.9), tint.opacity(front ? 0.6 : 0.4), tint.opacity(0)],
                        center: .center, startRadius: 0, endRadius: CGFloat(width * puff.size / 2)
                    ))
                    .frame(width: CGFloat(width * puff.size), height: CGFloat(width * puff.size))
                    .position(x: CGFloat(x + puff.dx * width), y: CGFloat(foot + puff.dy * width))
            }
        }
        .opacity(0.55 + 0.45 * weight)
        .saturation(grade.saturation)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
