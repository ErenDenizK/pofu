import Foundation
import Testing
@testable import PofuWorld

@Suite("Camera rail")
struct CameraRailTests {
    let rail = CameraRail()

    @Test func theFramingsAreTheReferenceStops() {
        for framing in WorldFraming.allCases {
            let stop = CameraRail.referenceStops[framing.rawValue]
            let pose = rail.pose(z: framing.z)
            #expect(abs(pose.scale - stop.scale) < 1e-9)
            #expect(pose.lookX == stop.look.x)
            #expect(pose.lookY == stop.look.y)
            #expect(pose.anchorY == stop.anchorY)
        }
    }

    @Test func pofuIsAbout38PercentOfTheWidthAtHome() {
        let width = 64 * rail.pose(of: .home).scale
        #expect(abs(width - 153.6) < 0.01)
        #expect(abs(width / CameraRail.referenceWidth - 0.38) < 0.005)
        // His feet sit at the Home framing's anchor row, at most a quarter
        // of the width off centre (nudged so no resident is cut).
        let feet = rail.pose(of: .home).project(IslandLayout.pofu, width: CameraRail.referenceWidth)
        #expect(abs(feet.x - 201) <= CameraRail.referenceWidth * 0.25 + 1e-9)
        #expect(abs(feet.y - 600) < 1e-9)
    }

    @Test func scaleInterpolatesInLogSpace() {
        let map = CameraRail.referenceStops[0].scale
        let island = CameraRail.referenceStops[1].scale
        let mid = rail.pose(z: 1.5).scale
        #expect(abs(mid - (island * 2.40).squareRoot()) < 1e-9)
        let quarter = rail.pose(z: 0.25).scale
        #expect(abs(quarter - exp(log(map) * 0.75 + log(island) * 0.25)) < 1e-9)
    }

    @Test func positionInterpolatesLinearlyWithTheSameFraction() {
        let island = CameraRail.referenceStops[1]
        let pose = rail.pose(z: 1.25)
        let home = IslandLayout.pofu.y
        #expect(abs(pose.lookY - (island.look.y + (home - island.look.y) * 0.25)) < 1e-9)
        #expect(abs(pose.anchorY - (island.anchorY + (600 - island.anchorY) * 0.25)) < 1e-9)
    }

    @Test func zAndLogScaleAreInverses() {
        for z in stride(from: -0.4, through: 2.4, by: 0.1) {
            let back = rail.z(logScale: rail.logScale(z: z))
            #expect(abs(back - z) < 1e-9)
        }
    }

    @Test func pastTheEndsTheRailKeepsItsLookPoint() {
        let past = rail.pose(z: 2.3)
        let home = rail.pose(of: .home)
        #expect(past.lookX == home.lookX)
        #expect(past.anchorY == home.anchorY)
        #expect(past.scale > home.scale)
    }

    @Test func scalesFollowTheWidthAndRowsTheHeight() {
        let wide = CameraRail(width: 440, height: 956)
        let home = wide.pose(of: .home)
        #expect(abs(home.scale - 2.40 * 440 / 402) < 1e-9)
        #expect(abs(home.anchorY - 600 * 956 / 874) < 1e-9)
    }

    @Test func projectAndUnprojectAreInverses() {
        let pose = rail.pose(z: 1.3)
        let point = WorldPoint(x: 37, y: -12)
        let screen = pose.project(point, width: 402)
        let back = pose.unproject(x: screen.x, y: screen.y, width: 402)
        #expect(abs(back.x - point.x) < 1e-9)
        #expect(abs(back.y - point.y) < 1e-9)
    }
}

@Suite("Rubber band")
struct RubberBandTests {
    let rail = CameraRail()

    @Test func theBandStartsAtZeroAndTracksAtFiftyFivePercent() {
        #expect(CameraRail.rubberBand(0, limit: 1) == 0)
        let tiny = CameraRail.rubberBand(1e-6, limit: 1)
        #expect(abs(tiny / 1e-6 - 0.55) < 1e-3)
    }

    @Test func theBandGrowsButNeverReachesItsLimit() {
        var previous = 0.0
        for x in stride(from: 0.1, through: 50, by: 0.1) {
            let banded = CameraRail.rubberBand(x, limit: 0.2)
            #expect(banded > previous)
            #expect(banded < 0.2)
            previous = banded
        }
    }

    @Test func insideTheRailThereIsNoBand() {
        let l = rail.logScale(z: 1.3)
        #expect(rail.bandedLogScale(raw: l) == l)
    }

    @Test func pastHomeTheCameraBandsUpToAQuarterMore() {
        let home = rail.pose(of: .home).logScale
        let banded = rail.bandedLogScale(raw: home + 5)
        #expect(banded > home)
        #expect(exp(banded - home) < 1.25)
    }

    @Test func pastTheMapTheCameraBandsDownToEightyPercent() {
        let map = rail.pose(of: .map).logScale
        let banded = rail.bandedLogScale(raw: map - 5)
        #expect(banded < map)
        #expect(exp(banded - map) > 0.8)
    }
}
