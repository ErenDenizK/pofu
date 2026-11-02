import Foundation
import Testing
@testable import PofuWorld

@Suite("Detent selection")
struct CameraReleaseTests {
    let rail = CameraRail()

    private func landing(z: Double, velocity: Double, idle: Double = 0) -> CameraRelease.Landing {
        CameraRelease.landing(logScale: rail.logScale(z: z), velocity: velocity, idle: idle, rail: rail)
    }

    @Test func aSlowReleaseLandsOnTheNearestFraming() {
        #expect(landing(z: 1.4, velocity: 0).framing == .island)
        #expect(landing(z: 1.6, velocity: 0).framing == .home)
        #expect(landing(z: 0.45, velocity: 0).framing == .map)
        #expect(landing(z: 0.55, velocity: 0).framing == .island)
    }

    @Test func aFlickProjectsOneFramingFurther() {
        // z 1.3 is nearer the Island, but a quick spread carries it Home.
        #expect(landing(z: 1.3, velocity: 3).framing == .home)
        // And a quick pinch from z 1.7 lands on the Island.
        #expect(landing(z: 1.7, velocity: -3).framing == .island)
    }

    @Test func aFastFlickMaySkipAFraming() {
        #expect(landing(z: 0.6, velocity: 6).framing == .home)
        #expect(landing(z: 1.4, velocity: -6).framing == .map)
    }

    @Test func projectionUsesAFixedTimeAndAClampedVelocity() {
        let l = rail.logScale(z: 1)
        let projected = CameraRelease.projectedZ(logScale: l, velocity: 100, idle: 0, rail: rail)
        #expect(abs(projected - rail.z(logScale: l + 6 * 0.18)) < 1e-9)
    }

    @Test func fingersThatRestedBeforeLiftingDoNotFling() {
        #expect(landing(z: 1.3, velocity: 3, idle: 0.1).framing == .island)
        #expect(CameraRelease.effectiveVelocity(3, idle: 0.06) == 3)
        #expect(CameraRelease.effectiveVelocity(3, idle: 0.061) == 0)
    }

    @Test func theLandingSpringInheritsTheVelocityAlongTheRail() {
        let result = landing(z: 1.5, velocity: 2)
        #expect(abs(result.velocityZ - 2 * rail.zPerLogScale(at: 1.5)) < 1e-9)
        #expect(!result.fromBand)
    }

    @Test func fromABandTheCameraLandsOnTheEndWithoutVelocity() {
        let pastHome = landing(z: 2.2, velocity: 5)
        #expect(pastHome.framing == .home)
        #expect(pastHome.fromBand)
        #expect(pastHome.velocityZ == 0)
        let pastMap = landing(z: -0.2, velocity: -5)
        #expect(pastMap.framing == .map)
        #expect(pastMap.velocityZ == 0)
    }

    @Test func theDetentTickFollowsTheProjection() {
        let l = rail.logScale(z: 1.3)
        #expect(CameraRelease.projectedFraming(logScale: l, velocity: 0, idle: 0, rail: rail) == .island)
        #expect(CameraRelease.projectedFraming(logScale: l, velocity: 3, idle: 0, rail: rail) == .home)
    }
}

@Suite("Camera rig")
struct CameraRigTests {
    private func settled(_ rig: CameraRig, seconds: Double = 4) -> CameraRig {
        var rig = rig
        for _ in 0..<Int(seconds * 120) {
            rig.advance(1.0 / 120)
        }
        return rig
    }

    @Test func aPinchScrubsTheRailAndSettlesOnADetent() {
        var rig = CameraRig(framing: .island)
        rig.beginPinch()
        rig.pinch(magnification: 1.3)
        let during = rig.z.value
        #expect(during > 1 && during < 2)
        rig.endPinch(velocity: 0, idle: 0.2)
        let after = settled(rig)
        #expect(after.isSettled)
        #expect(after.z.value == WorldFraming.nearest(to: during).z)
    }

    @Test func pinchingPastHomeRubberBandsAndComesBackWithoutOvershoot() {
        var rig = CameraRig(framing: .home)
        rig.beginPinch()
        rig.pinch(magnification: 4)
        #expect(rig.z.value > 2)
        #expect(rig.pose.scale < rig.rail.pose(of: .home).scale * 1.25)
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
        var rig = CameraRig(framing: .island)
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
        var rig = CameraRig(framing: .island)
        rig.focus(pose: CameraPose(scale: 1.7, look: WorldPoint(x: 78, y: -72), anchorY: 330), lens: .station(depth: 0))
        rig = settled(rig)
        rig.releaseFocus()
        rig = settled(rig)
        #expect(rig.pose == rig.rail.pose(of: .island))
        #expect(rig.lens == Lens.island)
    }

    @Test func aFlightCanBeCaughtMidway() {
        var rig = CameraRig(framing: .home)
        rig.fly(to: .map)
        for _ in 0..<30 {
            rig.advance(1.0 / 120)
        }
        let caught = rig.z.value
        rig.beginPinch()
        // The camera stops where it is: no jump when the fingers land.
        #expect(abs(rig.z.value - caught) < 1e-9)
        #expect(rig.z.velocity == 0)
    }

    @Test func thePeekRubberBandsAndSpringsBack() {
        var rig = CameraRig(framing: .island)
        rig.peek(dx: 400, dy: -400)
        #expect(rig.offsetX.value < CameraRig.peekLimit)
        #expect(rig.offsetY.value > -CameraRig.peekLimit)
        rig.settleOffset()
        rig = settled(rig, seconds: 2)
        #expect(rig.offsetX.value == 0)
        #expect(rig.offsetY.value == 0)
    }
}
