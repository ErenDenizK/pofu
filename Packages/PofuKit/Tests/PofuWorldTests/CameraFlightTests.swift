import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Camera flight (experience v1 §1.2)")
struct CameraFlightTests {
    private func pose(x: Double, y: Double, scale: Double) -> CameraPose {
        CameraPose(scale: scale, look: WorldPoint(x: x, y: y), anchorY: 437)
    }

    @Test func theDurationGrowsWithDistanceAndIsCapped() {
        let near = CameraFlight.duration(distance: 0)
        let mid = CameraFlight.duration(distance: 400)
        let far = CameraFlight.duration(distance: 3000)
        #expect(abs(near - 0.9) < 1e-9)
        #expect(mid > near)
        #expect(far > mid)
        #expect(CameraFlight.duration(distance: 1_000_000) == 1.6)
        #expect(abs(CameraFlight.duration(distance: 1000) - 1.15) < 1e-9)
    }

    @Test func theFlightRisesTravelsAndDescends() {
        let rail = CameraRail()
        let from = rail.pose(of: .island)
        let to = pose(x: 300, y: 330, scale: from.scale)
        let apex = rail.pose(z: CameraFlight.apexZ).logScale
        let flight = CameraFlight(from: from, to: to, apexLogScale: apex)

        #expect(flight.pose(at: 0) == from)
        let end = flight.pose(at: flight.duration)
        #expect(abs(end.lookX - to.lookX) < 1e-9 && abs(end.logScale - to.logScale) < 1e-9)

        // At 35 % it is at the apex, still over where it started.
        let top = flight.pose(at: flight.duration * CameraFlight.riseShare)
        #expect(abs(top.logScale - flight.apexLogScale) < 1e-9)
        #expect(abs(top.lookX - from.lookX) < 1e-9)
        // At 65 % it is at the apex over the target.
        let over = flight.pose(at: flight.duration * (CameraFlight.riseShare + CameraFlight.travelShare))
        #expect(abs(over.logScale - flight.apexLogScale) < 1e-9)
        #expect(abs(over.lookX - to.lookX) < 1e-9)
        // In between it never dips below the apex scale.
        var t = 0.0
        while t <= flight.duration {
            #expect(flight.pose(at: t).logScale >= flight.apexLogScale - 1e-9)
            t += flight.duration / 50
        }
    }

    @Test func theSharesAddUp() {
        #expect(abs(CameraFlight.riseShare + CameraFlight.travelShare + CameraFlight.descendShare - 1) < 1e-9)
    }

    @Test func aRigFlightLandsOnTheTargetAndSettles() {
        var rig = CameraRig(framing: .island)
        let target = pose(x: 265, y: 300, scale: rig.pose.scale)
        rig.startFlight(to: target, landing: .pose(target))
        #expect(rig.flight != nil)
        #expect(rig.isMoving)
        #expect(!rig.isSettled)
        var elapsed = 0.0
        while rig.flight != nil, elapsed < 3 {
            rig.advance(1.0 / 120)
            elapsed += 1.0 / 120
        }
        #expect(rig.flight == nil)
        #expect(elapsed <= 1.6 + 0.02)
        #expect(abs(rig.pose.lookX - target.lookX) < 1e-6)
        #expect(abs(rig.pose.lookY - target.lookY) < 1e-6)
        #expect(abs(rig.pose.scale - target.scale) < 1e-6)
        rig.advance(0.5)
        #expect(rig.isSettled)
        #expect(!rig.isMoving)
    }

    @Test func aRigFlightHomeLandsOnTheRail() {
        var rig = CameraRig(framing: .island)
        let harbor = pose(x: 265, y: 300, scale: rig.pose.scale)
        rig.startFlight(to: harbor, landing: .pose(harbor))
        for _ in 0..<400 { rig.advance(1.0 / 120) }
        let home = rig.rail.pose(of: .map)
        rig.startFlight(to: home, landing: .rail(.map))
        for _ in 0..<400 { rig.advance(1.0 / 120) }
        #expect(rig.framing == .map)
        #expect(abs(rig.pose.logScale - home.logScale) < 1e-6)
        #expect(abs(rig.railPosition - 0) < 1e-6)
    }

    @Test func reduceMotionJumpsWithoutAFlight() {
        var rig = CameraRig(framing: .island)
        rig.reduceMotion = true
        let target = pose(x: 265, y: 300, scale: rig.pose.scale)
        rig.startFlight(to: target, landing: .pose(target))
        #expect(rig.flight == nil)
        #expect(abs(rig.pose.lookX - target.lookX) < 1e-9)
    }

    @Test func aPinchCatchesAFlight() {
        var rig = CameraRig(framing: .island)
        let target = pose(x: 265, y: 300, scale: rig.pose.scale)
        rig.startFlight(to: target, landing: .pose(target))
        rig.advance(0.4)
        rig.beginPinch()
        #expect(rig.flight == nil)
    }

    @Test func movingFollowsTheSprings() {
        var rig = CameraRig(framing: .home)
        #expect(!rig.isMoving)
        rig.fly(to: .island)
        #expect(rig.isMoving)
        for _ in 0..<600 { rig.advance(1.0 / 120) }
        #expect(!rig.isMoving)
        rig.panDrag(dx: 30)
        #expect(rig.isMoving)
    }
}

@Suite("Place stops and the one control (experience v1 §1.2)")
struct PlaceStopTests {
    @Test func theGlyphShowsWhereATapGoes() {
        #expect(PlaceStop.close.controlGlyph == .island)
        #expect(PlaceStop.island.controlGlyph == .archipelago)
        #expect(PlaceStop.archipelago.controlGlyph == .pofu)
    }

    @Test func aTapGoesOutOneStopAndFromTheSeaHome() {
        #expect(PlaceStop.close.controlTarget == .island)
        #expect(PlaceStop.island.controlTarget == .archipelago)
        #expect(PlaceStop.archipelago.controlTarget == .close)
        #expect(PlaceStop.close.framing == .home)
        #expect(PlaceStop.archipelago.framing == .map)
    }

    @Test func aPlaceNamesTheNearestStop() {
        #expect(CameraPlace(island: .home, z: 1.9).stop == .close)
        #expect(CameraPlace(island: .home, z: 0.4).stop == .archipelago)
        #expect(CameraPlace(island: .harbor, z: 1).stop == .island)
    }
}

@Suite("One-thumb zoom (experience v1 §1.2)")
struct OneThumbZoomTests {
    @Test func doubleTapHoldAndDragDownZoomsIn() {
        var zoom = OneThumbZoom()
        zoom.touchDown(time: 0, x: 100, y: 300)
        zoom.touchUp(time: 0.05, x: 100, y: 300)
        zoom.touchDown(time: 0.2, x: 102, y: 302)
        let early = zoom.touchMoved(y: 304)
        #expect(early == nil)
        let down = zoom.touchMoved(y: 400)
        #expect(zoom.isZooming)
        #expect((down ?? 0) > 1)
        let up = zoom.touchMoved(y: 200)
        #expect((up ?? 2) < 1)
        let ended = zoom.touchUp(time: 0.9, x: 102, y: 200)
        #expect(ended)
        #expect(!zoom.isZooming)
    }

    @Test func aSlowSecondTapIsJustATap() {
        var zoom = OneThumbZoom()
        zoom.touchDown(time: 0, x: 100, y: 300)
        zoom.touchUp(time: 0.05, x: 100, y: 300)
        zoom.touchDown(time: 1.0, x: 100, y: 300)
        let moved = zoom.touchMoved(y: 400)
        #expect(moved == nil)
        #expect(!zoom.isZooming)
    }

    @Test func aFarSecondTouchDoesNotArm() {
        var zoom = OneThumbZoom()
        zoom.touchDown(time: 0, x: 100, y: 300)
        zoom.touchUp(time: 0.05, x: 100, y: 300)
        zoom.touchDown(time: 0.2, x: 300, y: 300)
        let moved = zoom.touchMoved(y: 400)
        #expect(moved == nil)
    }

    @Test func aSingleDragNeverZooms() {
        var zoom = OneThumbZoom()
        zoom.touchDown(time: 0, x: 100, y: 300)
        let moved = zoom.touchMoved(y: 500)
        #expect(moved == nil)
    }
}
