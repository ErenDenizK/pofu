import Foundation
import Testing
@testable import PofuWorld

/// WP7 (ADR-0027): one camera from the Map to mid to near, on the shipped plate's real stops.
@Suite("Rail v2: mid and near")
struct RailV2Tests {
    let plate: HomePlate
    let rail: CameraRail
    let map: WorldMap

    init() throws {
        plate = try #require(HomePlate.shipped)
        rail = CameraRail(width: 402, height: 874, stops: plate.stops, whole: plate.wholeStop, island: plate.islandBox)
        map = try #require(WorldMap.shipped)
    }

    func rig(_ framing: WorldFraming = .mid) -> CameraRig {
        CameraRig(framing: framing, rail: rail)
    }

    @Test func midFitsTheLevel10BoxAt1_145() {
        let mid = rail.pose(of: .mid)
        #expect(abs(mid.scale - 1.145) < 0.002)
        let box = plate.islandBox
        let lo = mid.project(WorldPoint(x: box.minX, y: box.minY), width: 402)
        let hi = mid.project(WorldPoint(x: box.maxX, y: box.maxY), width: 402)
        #expect(abs((hi.x - lo.x) - 378) < 1e-6)
        #expect(abs((lo.y + hi.y) / 2 - 383) < 1e-6)
    }

    @Test func aYoungIslandFillsAtLeast72PercentOfTheWidth() {
        for stage in 0..<plate.plate.stages {
            let young = HomePlate(plate: plate.plate, light: "day", stage: stage)
            let mid = young.midStop
            #expect(young.plateImageBox.width * mid.scale >= 0.72 * 402 - 1e-6, "stage \(stage)")
            #expect(mid.scale >= 378 / plate.islandBox.width - 1e-9)
        }
    }

    @Test(arguments: [(-60.0, 40.0, 1.6), (120.0, 700.0, 0.7), (201.0, 437.0, 3.0)])
    func pinchKeepsTheWorldPointUnderTheFingers(x: Double, y: Double, magnification: Double) {
        var rig = rig()
        rig.beginPinch()
        let world = rig.pose.unproject(x: x, y: y, width: 402)
        for m in stride(from: 1.0, through: magnification, by: (magnification - 1) / 8) {
            rig.pinch(magnification: m, keeping: world, atScreenX: x, y: y)
            let now = rig.pose.project(world, width: 402)
            #expect(abs(now.x - x) < 1e-6 && abs(now.y - y) < 1e-6, "at ×\(m): \(now)")
        }
    }

    @Test func releaseLandsOnMapMidOrStays() {
        func release(at z: Double) -> CameraRig {
            var rig = rig()
            rig.beginPinch()
            rig.pinch(magnification: exp(rail.logScale(z: z) - rail.logScale(z: 1)))
            rig.endPinch(velocity: 0, idle: 0.2)
            return CameraReleaseTests.settledRig(rig)
        }
        #expect(release(at: 0.4).z.value == 0)
        #expect(release(at: 0.5).z.value == 1)
        #expect(release(at: 1.12).z.value == 1)
        let stays = release(at: 1.4)
        #expect(abs(stays.z.value - 1.4) < 1e-6)
        #expect(stays.framing == .near)
        // Landing on mid or the Map springs the free offset home.
        #expect(release(at: 0.8).pose == rail.pose(of: .mid))
    }

    @Test func restIsZ1_73() {
        #expect(abs(rail.restZ - 1.733) < 0.002)
        #expect(abs(rail.pose(z: rail.restZ).scale - 4.5) < 1e-9)
        var rig = rig()
        rig.fly(to: .near)
        rig = CameraReleaseTests.settledRig(rig)
        #expect(abs(rig.z.value - rail.restZ) < 1e-9)
    }

    @Test func nearPanRubberBandsPast10Percent() throws {
        var rig = rig(.near)
        rig = CameraReleaseTests.settledRig(rig)
        let bounds = try #require(rail.nearBounds)
        let box = plate.islandBox
        #expect(abs(bounds.width - box.width * 1.1) < 1e-6)
        // Inside the bounds the island follows the finger one to one.
        let s = rig.pose.scale
        rig.freeDrag(dx: 20, dy: -10)
        #expect(abs(rig.freeX.value + 20 / s) < 1e-9 && abs(rig.freeY.value - 10 / s) < 1e-9)
        // Far past the edge the screen's centre stops within 30 pt of the bounds.
        rig.freeDrag(dx: -5000, dy: 0)
        let centre = rig.pose.unproject(x: 201, y: 437, width: 402)
        #expect(centre.x > bounds.maxX)
        #expect((centre.x - bounds.maxX) * s < CameraRail.nearBand)
        // Let go: it springs back inside.
        rig.endFreeDrag(vx: 0, vy: 0)
        rig = CameraReleaseTests.settledRig(rig)
        let back = rig.pose.unproject(x: 201, y: 437, width: 402)
        #expect(back.x <= bounds.maxX + 1e-6)
    }

    @Test func chromeFadesBetween1_05And1_25() {
        let l = rail.pose(of: .mid).logScale
        #expect(rail.chromeOpacity(logScale: l) == 1)
        #expect(rail.chromeOpacity(logScale: l + log(1.05)) == 1)
        #expect(abs(rail.chromeOpacity(logScale: l + log(1.15)) - 0.5) < 1e-9)
        #expect(rail.chromeOpacity(logScale: l + log(1.25)) == 0)
        // The anchor eases with it, from row 383 to 437.
        #expect(abs(rail.pose(z: rail.z(logScale: l + log(1.15))).anchorY - 410) < 1e-9)
        #expect(abs(rail.pose(z: rail.z(logScale: l + log(1.25))).anchorY - 437) < 1e-9)
    }

    @Test func aDoubleTapRestsOnTheCharactersFeet() {
        var rig = rig()
        let shot = NearShot.rest(width: 402, height: 874, facesLeft: false)
        #expect(abs(shot.x - 0.38 * 402) < 1e-9 && abs(shot.y - 0.60 * 874) < 1e-9)
        rig.rest(on: IslandLayout.pofu, screenX: shot.x, screenY: shot.y, animated: false)
        let feet = rig.pose.project(IslandLayout.pofu, width: 402)
        #expect(abs(rig.pose.scale - 4.5) < 1e-9)
        #expect(abs(feet.y - shot.y) < 1e-6)
        // The look room is at most 0.12 of the width, toward the middle when the bounds stop it.
        #expect(feet.x >= shot.x - 1e-6 && feet.x <= 201 + 1e-6)
    }

    // MARK: C1 on the real stops

    @Test func c1HoldsForMidOnTheRealStop() {
        let mid = rail.pose(of: .mid)
        let box = plate.islandBox
        let lo = mid.project(WorldPoint(x: box.minX, y: box.minY), width: 402)
        let hi = mid.project(WorldPoint(x: box.maxX, y: box.maxY), width: 402)
        var frame = CompositionFrame.mid(level: 10, map: map, plate: plate.plate)
        frame.hero = ScreenBox(minX: lo.x, minY: lo.y, maxX: hi.x, maxY: hi.y)
        let c1 = CompositionRules.c1(frame)
        #expect(c1.passed, "\(c1.detail)")
    }

    @Test func c1HoldsForNearRestOnTheRealStop() {
        var rig = rig()
        let shot = NearShot.rest(width: 402, height: 874, facesLeft: false)
        rig.rest(on: IslandLayout.pofu, screenX: shot.x, screenY: shot.y, animated: false)
        let feet = rig.pose.project(IslandLayout.pofu, width: 402)
        var frame = CompositionFrame.near(scale: 4.5, map: map, plate: plate.plate)
        frame.feet = (feet.x, feet.y)
        let c1 = CompositionRules.c1(frame)
        #expect(c1.passed, "\(c1.detail)")
    }

    @Test func nearBeginsAt1_25TimesMid() {
        let start = rail.z(logScale: rail.pose(of: .mid).logScale + log(1.25))
        #expect(abs(start - WorldFraming.nearAboveZ) < 0.002)
    }

    @Test func layersReadMidAsHome() {
        #expect(rig(.mid).layerPosition == 2)
        #expect(rig(.map).layerPosition == 0)
        #expect(rig(.near).layerPosition == 2)
    }
}

extension CameraReleaseTests {
    static func settledRig(_ rig: CameraRig, seconds: Double = 4) -> CameraRig {
        CameraRigTests.settled(rig, seconds: seconds)
    }
}
