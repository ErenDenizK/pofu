import Foundation
import Testing
@testable import PofuWorld

@Suite("Camera rail (ADR-0027)")
struct CameraRailTests {
    let rail = CameraRail()

    @Test func theFramingsAreTheReferenceStops() {
        for framing in WorldFraming.allCases {
            let stop = CameraRail.referenceStops[framing.rawValue]
            let pose = rail.pose(z: framing.z)
            #expect(abs(pose.scale - stop.scale) < 1e-9)
            #expect(pose.lookX == stop.look.x)
            #expect(pose.lookY == stop.look.y)
            #expect(abs(pose.anchorY - stop.anchorY) < 1e-9)
        }
    }

    @Test func theNearLimitIs7_4PointsAUnitAnchoredMidScreen() {
        let near = rail.pose(of: .near)
        #expect(abs(near.scale - 7.4) < 1e-9)
        #expect(near.anchorY == 437)
        #expect(near.lookX == rail.pose(of: .mid).lookX)
    }

    @Test func scaleInterpolatesInLogSpace() {
        let map = rail.pose(of: .map).scale
        let mid = rail.pose(of: .mid).scale
        #expect(abs(rail.pose(z: 0.5).scale - (map * mid).squareRoot()) < 1e-9)
        let near = rail.pose(of: .near).scale
        #expect(abs(rail.pose(z: 1.5).scale - (mid * near).squareRoot()) < 1e-9)
    }

    @Test func positionInterpolatesLinearlyFromTheMapToMid() {
        let a = rail.pose(of: .map), b = rail.pose(of: .mid)
        let p = rail.pose(z: 0.25)
        #expect(abs(p.lookX - (a.lookX + (b.lookX - a.lookX) * 0.25)) < 1e-9)
        #expect(abs(p.lookY - (a.lookY + (b.lookY - a.lookY) * 0.25)) < 1e-9)
        #expect(abs(p.anchorY - (a.anchorY + (b.anchorY - a.anchorY) * 0.25)) < 1e-9)
    }

    @Test func pastMidTheLookStaysAndTheAnchorEasesWithTheChrome() {
        let mid = rail.pose(of: .mid)
        for z in stride(from: 1.0, through: 2.0, by: 0.05) {
            let p = rail.pose(z: z)
            #expect(p.lookX == mid.lookX && p.lookY == mid.lookY)
            let t = 1 - rail.chromeOpacity(logScale: p.logScale)
            #expect(abs(p.anchorY - (416 + 21 * t)) < 1e-9)
        }
        #expect(abs(rail.pose(z: 1.5).anchorY - 437) < 1e-9)
    }

    @Test func zAndLogScaleAreInverses() {
        for z in stride(from: -0.3, through: 2.3, by: 0.1) {
            #expect(abs(rail.z(logScale: rail.logScale(z: z)) - z) < 1e-9)
        }
    }

    @Test func pastTheEndsTheRailKeepsItsLookPoint() {
        let map = rail.pose(of: .map), mid = rail.pose(of: .mid)
        #expect(rail.pose(z: -0.2).lookX == map.lookX)
        #expect(rail.pose(z: -0.2).scale < map.scale)
        #expect(rail.pose(z: 2.2).lookX == mid.lookX)
        #expect(rail.pose(z: 2.2).scale > rail.pose(of: .near).scale)
    }

    @Test func scalesFollowTheWidthAndRowsTheHeight() {
        let big = CameraRail(width: 804, height: 1748)
        #expect(abs(big.pose(of: .mid).scale - 2 * rail.pose(of: .mid).scale) < 1e-9)
        #expect(abs(big.pose(of: .mid).anchorY - 2 * rail.pose(of: .mid).anchorY) < 1e-9)
    }

    @Test func projectAndUnprojectAreInverses() {
        let pose = rail.pose(z: 1.3)
        let p = WorldPoint(x: 37, y: -12)
        let s = pose.project(p, width: 402)
        let back = pose.unproject(x: s.x, y: s.y, width: 402)
        #expect(abs(back.x - p.x) < 1e-9 && abs(back.y - p.y) < 1e-9)
    }

    @Test func theFramingOfAPositionFollowsTheReleaseTable() {
        #expect(WorldFraming.nearest(to: 0.49) == .map)
        #expect(WorldFraming.nearest(to: 0.5) == .mid)
        #expect(WorldFraming.nearest(to: 1.12) == .mid)
        #expect(WorldFraming.nearest(to: 1.13) == .near)
        #expect(WorldFraming.map.stepIn == .mid)
        #expect(WorldFraming.mid.stepIn == .near)
        #expect(WorldFraming.near.stepIn == nil)
        #expect(WorldFraming.near.stepOut == .mid)
    }
}

@Suite("Rubber band")
struct RubberBandTests {
    let rail = CameraRail()

    @Test func theBandStartsAtZeroAndTracksAtFiftyFivePercent() {
        #expect(CameraRail.rubberBand(0, limit: 1) == 0)
        let small = CameraRail.rubberBand(0.001, limit: 1)
        #expect(abs(small / 0.001 - 0.55) < 0.01)
    }

    @Test func theBandGrowsButNeverReachesItsLimit() {
        var last = 0.0
        for x in stride(from: 0.1, through: 50, by: 0.5) {
            let b = CameraRail.rubberBand(x, limit: 1)
            #expect(b > last && b < 1)
            last = b
        }
    }

    @Test func insideTheRailThereIsNoBand() {
        let l = rail.logScale(z: 1.4)
        #expect(rail.bandedLogScale(raw: l) == l)
    }

    @Test func pastTheNearLimitTheCameraBandsUpTo1_12() {
        let hi = rail.pose(of: .near).logScale
        let banded = rail.bandedLogScale(raw: hi + 10)
        #expect(banded > hi && exp(banded - hi) < 1.12)
    }

    @Test func pastTheMapTheCameraBandsDownTo0_85() {
        let lo = rail.pose(of: .map).logScale
        let banded = rail.bandedLogScale(raw: lo - 10)
        #expect(banded < lo && exp(banded - lo) > 0.85)
    }
}
