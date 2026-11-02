import Foundation
import Testing
@testable import PofuWorld

@Suite("Depth in motion")
struct DepthMotionTests {
    /// A Home → Island flight, `seconds` in.
    private func flight(at seconds: Double, reduceMotion: Bool = false) -> CameraRig {
        var rig = CameraRig(framing: .home)
        rig.reduceMotion = reduceMotion
        rig.fly(to: .island)
        var t = 0.0
        while t < seconds {
            rig.advance(1.0 / 120)
            t += 1.0 / 120
        }
        return rig
    }

    @Test func aRestingCameraAddsNothing() {
        let rig = CameraRig(framing: .island)
        #expect(rig.motion == .still)
        #expect(DepthMotion.shift(point: .zero, depth: 120, focus: -10, look: .zero, motion: .still) == .zero)
        #expect(DepthMotion.lens(.island, motion: .still) == .island)
    }

    @Test func theFlightStartsAndEndsWithoutParallax() {
        // Velocity, not displacement: nothing jumps on the first frame or
        // stays offset after the springs rest.
        // The first frame's speed is the springs' first step: small next to
        // the flight's peak (the large plate's Island framing made the
        // flight about twice as long in ln s, so the bound is relative).
        #expect(flight(at: 0).motion.speed < flight(at: 0.3).motion.speed * 0.4)
        #expect(flight(at: 3).motion == .still)
    }

    @Test func midFlightNearLayersMoveMoreThanTheFocusPlane() {
        let rig = flight(at: 0.3)
        let motion = rig.motion
        #expect(motion.speed > 0.3)
        let lens = rig.lens
        let look = WorldPoint(x: rig.pose.lookX, y: rig.pose.lookY)
        let point = WorldPoint(x: 150, y: 60)
        let near = DepthMotion.shift(point: point, depth: lens.focus + 100, focus: lens.focus, look: look, motion: motion)
        let onFocus = DepthMotion.shift(point: point, depth: lens.focus, focus: lens.focus, look: look, motion: motion)
        let far = DepthMotion.shift(point: point, depth: lens.focus - 100, focus: lens.focus, look: look, motion: motion)
        #expect(onFocus == .zero)
        #expect(hypot(near.x, near.y) > 0.5)
        // Behind the focus plane the layer moves the other way.
        #expect(near.x * far.x < 0 || near.y * far.y < 0)
    }

    @Test func theShiftIsBounded() {
        let fast = CameraMotion(lookX: 5000, lookY: -5000, logScale: 40)
        let s = DepthMotion.shift(point: WorldPoint(x: 400, y: 300), depth: 300, focus: -10, look: .zero, motion: fast)
        #expect(hypot(s.x, s.y) <= DepthMotion.maxShift + 1e-9)
        #expect(fast.speed == 1)
    }

    @Test func theDepthOfFieldStrengthensWithSpeedAndKeepsTheFocusSharp() {
        let rig = flight(at: 0.3)
        let moving = DepthMotion.lens(rig.lens, motion: rig.motion)
        #expect(moving.slab < rig.lens.slab)
        #expect(moving.blurLevel(depth: moving.focus) == 0)
        #expect(moving.blurLevel(depth: 120) >= rig.lens.blurLevel(depth: 120))
    }

    @Test func reduceMotionHasNoDepthMotion() {
        #expect(flight(at: 0.1, reduceMotion: true).motion == .still)
    }
}
