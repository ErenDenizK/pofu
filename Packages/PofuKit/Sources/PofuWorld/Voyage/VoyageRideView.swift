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
            let start = startSpot(size: size)
            PofuTimeline(hz: PofuFrameRate.direct, paused: model.rideHeld != nil, kind: .essential) { context in
                let t = model.rideElapsed(at: context.date) ?? ride.duration
                rideFrame(at: t, start: start, size: size)
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
        .ignoresSafeArea()
    }

    /// Where she lay in the row: moored at the island the player is leaving, with the row on the island in view.
    private func startSpot(size: CGSize) -> VoyageRide.Spot {
        let layout = VoyageRowLayout(width: Double(size.width), height: Double(size.height))
        let stops = VoyageRoute.stops(koke: world.koke, caglayan: world.caglayan)
        let from = VoyageRoute.index(of: ride.from, in: stops)
        let shown = VoyageRoute.index(of: model.voyage.island, in: stops)
        return layout.mooredSpot(at: layout.place(index: from, position: Double(shown)))
    }

    private var level: Int {
        Gezgin.presence(koke: world.koke, caglayan: world.caglayan, data: data).level ?? 1
    }

    @ViewBuilder
    private func rideFrame(at t: Double, start: VoyageRide.Spot, size: CGSize) -> some View {
        let spot = ride.whale(at: t, start: start)
        let width = spot.width * Double(size.width)
        let height = width * data.art.canvas[1] / max(data.art.canvas[0], 1)
        let beat = ride.beat(at: t)
        let flying = beat.beat == .fly
        let bobSeconds = 2.4
        let bob = sin(2 * .pi * t / bobSeconds) * 0.014 * width * (flying ? 1 : 0.35)
        let centre = CGPoint(x: spot.x * Double(size.width), y: spot.y * Double(size.height) + bob)
        let whaleGrade = VoyageGrade.whale(light: model.homePlate?.light ?? "day")
        ZStack(alignment: .topLeading) {
            if flying {
                CloudWake(centre: centre, width: width, toTheRight: ride.toTheRight, time: t, strength: min(beat.progress / 0.2, (1 - beat.progress) / 0.2, 1))
            }
            GezginFlyer(
                data: data, level: level, width: width, flip: ride.toTheRight, time: t, tilt: ride.tilt(at: t)
            )
            .saturation(whaleGrade.saturation)
            .brightness(whaleGrade.brightness)
            .colorMultiply(Color(red: whaleGrade.red, green: whaleGrade.green, blue: whaleGrade.blue))
            .position(centre)
            ForEach(Array(passengers.enumerated()), id: \.offset) { index, passenger in
                let place = passengerPlace(index: index, beat: beat, centre: centre, width: width, height: height)
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
        .opacity(ride.whaleOpacity(at: t))
    }

    /// Who rides: Pofu, and Fındık with him. Their width against her cut-out's.
    private var passengers: [(art: String, share: Double)] {
        [("pofu", 0.2), ("findik", 0.13)]
    }

    /// A passenger's feet and opacity: on the shore while she waits, in the air as he hops aboard, on her back
    /// through the flight, in the air again as he hops off.
    private func passengerPlace(index: Int, beat: (beat: VoyageRide.Beat, progress: Double), centre: CGPoint, width: Double, height: Double) -> (x: CGFloat, y: CGFloat, opacity: Double) {
        let count = passengers.count
        let top = Double(centre.y) - height / 2
        let seat = VoyageRide.seat(index: index, count: count, toTheRight: ride.toTheRight)
        let shore = VoyageRide.shore(index: index, toTheRight: ride.toTheRight)
        func point(_ p: (dx: Double, feetY: Double)) -> (x: Double, y: Double) {
            (Double(centre.x) + p.dx * width, top + p.feetY * height)
        }
        let seated = point(seat), onShore = point(shore)
        switch beat.beat {
        case .board:
            let hop = VoyageRide.hop(VoyageRide.hopProgress(index: index, count: count, beatProgress: beat.progress))
            return (
                CGFloat(onShore.x + (seated.x - onShore.x) * hop.along),
                CGFloat(onShore.y + (seated.y - onShore.y) * hop.along - hop.lift * width),
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
        .scaleEffect(x: flip ? -1 : 1, y: 1)
        .rotationEffect(.degrees(tilt))
    }
}

/// A few soft puffs of cloud streaming off her tail while she flies. The first thing to go if the ride drops
/// frames: nothing else depends on it.
private struct CloudWake: View {
    let centre: CGPoint
    let width: Double
    let toTheRight: Bool
    let time: Double
    let strength: Double

    var body: some View {
        let behind = toTheRight ? -1.0 : 1.0
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                let phase = (time * 0.55 + Double(i) * 0.2).truncatingRemainder(dividingBy: 1)
                let d = width * (0.42 + 0.9 * phase)
                let diameter = width * (0.16 + 0.12 * phase)
                Circle()
                    .fill(RadialGradient(colors: [.white.opacity(0.7), .white.opacity(0)], center: .center, startRadius: 0, endRadius: CGFloat(diameter / 2)))
                    .frame(width: CGFloat(diameter), height: CGFloat(diameter))
                    .opacity(strength * (1 - phase))
                    .position(
                        x: centre.x + CGFloat(behind * d),
                        y: centre.y + CGFloat(width * (0.02 + 0.05 * sin(Double(i) * 1.7 + time)))
                    )
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
