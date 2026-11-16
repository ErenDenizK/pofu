import Foundation
import Testing
@testable import PofuWorld

@Suite("Release table (ADR-0027)")
struct CameraReleaseTests {
    let rail = CameraRail()

    private func land(_ z: Double, velocity: Double = 0, idle: Double = 0.2) -> CameraRelease.Landing {
        CameraRelease.landing(logScale: rail.logScale(z: z), velocity: velocity, idle: idle, rail: rail)
    }

    @Test func aSlowReleaseLandsOnTheMapMidOrStaysNear() {
        #expect(land(0.3).framing == .map && land(0.3).z == 0)
        #expect(land(0.6).framing == .mid && land(0.6).z == 1)
        #expect(land(1.1).framing == .mid && land(1.1).z == 1)
        #expect(land(1.5).framing == .near && abs(land(1.5).z - 1.5) < 1e-9)
    }

    @Test func aFlickProjectsForward() {
        // A zoom-in flick from mid's half of the rail carries into near.
        let flick = land(1.05, velocity: 3, idle: 0)
        #expect(flick.framing == .near)
        #expect(flick.z > WorldFraming.nearAboveZ && flick.z <= 2)
        // A zoom-out flick from near lands on mid.
        #expect(land(1.2, velocity: -3, idle: 0).framing == .mid)
    }

    @Test func projectionUsesAFixedTimeAndAClampedVelocity() {
        let l = rail.logScale(z: 1)
        let fast = CameraRelease.projectedZ(logScale: l, velocity: 100, idle: 0, rail: rail)
        let capped = rail.z(logScale: l + CameraRelease.maxVelocity * CameraRelease.projectionTime)
        #expect(abs(fast - capped) < 1e-9)
    }

    @Test func fingersThatRestedBeforeLiftingDoNotFling() {
        #expect(CameraRelease.effectiveVelocity(4, idle: 0.2) == 0)
        #expect(CameraRelease.effectiveVelocity(4, idle: 0.01) == 4)
    }

    @Test func fromABandTheCameraLandsOnTheEndWithoutVelocity() {
        let past = land(2.2, velocity: 4, idle: 0)
        #expect(past.fromBand && past.framing == .near && past.z == 2 && past.velocityZ == 0)
        let under = land(-0.2, velocity: -4, idle: 0)
        #expect(under.fromBand && under.framing == .map && under.z == 0 && under.velocityZ == 0)
    }

    @Test func theDetentTickFollowsTheProjection() {
        let l = rail.logScale(z: 1.0)
        #expect(CameraRelease.projectedFraming(logScale: l, velocity: 0, idle: 0, rail: rail) == .mid)
        #expect(CameraRelease.projectedFraming(logScale: l, velocity: 3, idle: 0, rail: rail) == .near)
    }
}

@Suite("Camera rig")
struct CameraRigTests {
    static func settled(_ rig: CameraRig, seconds: Double = 4) -> CameraRig {
        var rig = rig
        for _ in 0..<Int(seconds * 120) {
            rig.advance(1.0 / 120)
        }
        return rig
    }

    @Test func aPinchScrubsTheRailAndSettlesByTheTable() {
        var rig = CameraRig(framing: .mid)
        rig.beginPinch()
        rig.pinch(magnification: 0.8)
        let during = rig.z.value
        #expect(during > 0.5 && during < 1)
        rig.endPinch(velocity: 0, idle: 0.2)
        let after = Self.settled(rig)
        #expect(after.isSettled)
        #expect(after.z.value == 1)
    }

    @Test func pinchingPastTheLimitRubberBandsAndComesBackWithoutOvershoot() {
        var rig = CameraRig(framing: .near)
        rig.beginPinch()
        rig.pinch(magnification: 4)
        #expect(rig.z.value > 2)
        #expect(rig.pose.scale < rig.rail.pose(of: .near).scale * 1.12)
        rig.endPinch(velocity: 3, idle: 0)
        var lowest = rig.z.value
        for _ in 0..<480 {
            rig.advance(1.0 / 120)
            lowest = min(lowest, rig.z.value)
        }
        #expect(lowest > 2 - 1e-6)
        #expect(abs(rig.z.value - 2) < 1e-6)
    }

    @Test func aFocusRacksTheLensThroughIntermediateDepths() {
        var rig = CameraRig(framing: .mid)
        let target = Lens.station(depth: IslandLayout.depth(ofY: -26))
        let start = rig.lens.focus
        rig.focus(pose: CameraPose(scale: 1.7, look: WorldPoint(x: 78, y: -72), anchorY: 330), lens: target)
        var sawBetween = false
        for _ in 0..<240 {
            rig.advance(1.0 / 120)
            let f = rig.lens.focus
            if f < max(start, target.focus) - 1, f > min(start, target.focus) + 1 {
                sawBetween = true
            }
        }
        #expect(sawBetween)
        #expect(abs(rig.lens.focus - target.focus) < 1e-3)
        #expect(abs(rig.pose.scale - 1.7) < 1e-3)
    }

    @Test func releasingAFocusReturnsWhereTheUserCameFrom() {
        var rig = CameraRig(framing: .mid)
        rig.focus(pose: CameraPose(scale: 1.7, look: WorldPoint(x: 78, y: -72), anchorY: 330), lens: .station(depth: 0))
        rig = Self.settled(rig)
        rig.releaseFocus()
        rig = Self.settled(rig)
        #expect(rig.pose == rig.rail.pose(of: .mid))
        #expect(rig.lens == Lens.home)
    }

    @Test func aFlightCanBeCaughtMidway() {
        var rig = CameraRig(framing: .mid)
        rig.fly(to: .map)
        for _ in 0..<30 {
            rig.advance(1.0 / 120)
        }
        let caught = rig.pose
        rig.beginPinch()
        // The camera stops where it is: no jump when the fingers land.
        #expect(abs(rig.pose.scale - caught.scale) < 1e-9)
        #expect(abs(rig.pose.lookX - caught.lookX) < 1e-9)
        #expect(rig.z.velocity == 0)
    }

    @Test func thePeekRubberBandsAndSpringsBack() {
        var rig = CameraRig(framing: .mid)
        rig.peek(dx: 400, dy: -400)
        #expect(rig.offsetX.value < CameraRig.peekLimit)
        #expect(rig.offsetY.value > -CameraRig.peekLimit)
        rig.settleOffset()
        rig = Self.settled(rig, seconds: 2)
        #expect(rig.offsetX.value == 0)
        #expect(rig.offsetY.value == 0)
    }

    @Test func aFocusFoldsIntoThePinchWithoutAJump() {
        var rig = CameraRig(framing: .mid)
        rig.focus(pose: CameraPose(scale: 2.4, look: WorldPoint(x: 60, y: -40), anchorY: 330), lens: .station(depth: 0))
        rig = Self.settled(rig)
        let before = rig.pose
        rig.beginPinch()
        let p = WorldPoint(x: 10, y: -20)
        let a = before.project(p, width: 402), b = rig.pose.project(p, width: 402)
        #expect(abs(a.x - b.x) < 1e-6 && abs(a.y - b.y) < 1e-6)
    }
}
