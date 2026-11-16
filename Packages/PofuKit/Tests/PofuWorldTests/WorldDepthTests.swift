import Foundation
@testable import PofuWorld
import Testing

/// One camera with a depth function (`DepthLayer`): `k` 1 is the camera, 0 never moves, and between them
/// a layer moves a share `k` of the way (v2 section 2).
@Suite("The depth function")
struct WorldDepthTests {
    static let reference = CameraPose(scale: 2.4, look: WorldPoint(x: 10, y: 40), anchorY: 240)

    static func cameras() -> [CameraPose] {
        [
            CameraPose(scale: 0.45, look: WorldPoint(x: -300, y: 120), anchorY: 300),
            CameraPose(scale: 1.1, look: WorldPoint(x: 80, y: -20), anchorY: 400),
            CameraPose(scale: 2.4, look: WorldPoint(x: 10, y: 40), anchorY: 240),
            CameraPose(scale: 7.0, look: WorldPoint(x: -15, y: 60), anchorY: 437),
        ]
    }

    @Test func kOneIsTheCamera() {
        for camera in Self.cameras() {
            let layer = DepthLayer.pose(camera, reference: Self.reference, k: 1)
            for point in [WorldPoint(x: 0, y: 0), WorldPoint(x: 350, y: -200), WorldPoint(x: -90, y: 610)] {
                let a = layer.project(point, width: 402), b = camera.project(point, width: 402)
                #expect(abs(a.x - b.x) < 1e-9 && abs(a.y - b.y) < 1e-9)
            }
        }
    }

    @Test func kZeroNeverMoves() {
        let at = DepthLayer.pose(Self.reference, reference: Self.reference, k: 0)
        for camera in Self.cameras() {
            var steady = camera
            steady.anchorY = Self.reference.anchorY
            let layer = DepthLayer.pose(steady, reference: Self.reference, k: 0)
            #expect(layer == at)
        }
    }

    @Test func scaleAndLookFollowTheFormula() {
        let k = 0.45
        for camera in Self.cameras() {
            let layer = DepthLayer.pose(camera, reference: Self.reference, k: k)
            #expect(abs(layer.scale - Self.reference.scale * pow(camera.scale / Self.reference.scale, k)) < 1e-9)
            #expect(abs(layer.lookX - (Self.reference.lookX + k * (camera.lookX - Self.reference.lookX))) < 1e-9)
            #expect(abs(layer.lookY - (Self.reference.lookY + k * (camera.lookY - Self.reference.lookY))) < 1e-9)
            #expect(layer.anchorY == camera.anchorY)
        }
    }

    /// A horizon (k 0.05) stays where it is under the camera's anchor while the camera crosses the rail
    /// (the Map to mid, z 0 to 1): a point 50 units above Home's look moves a few points from the anchor, where the same
    /// point at the island's own depth moves by hundreds.
    @Test func horizonMovesUnderAPointAcrossTheRail() throws {
        let home = try #require(HomePlate.shipped)
        let rail = CameraRail(width: 402, height: 874, stops: home.stops, whole: home.wholeStop)
        let reference = home.skyReference(width: 402, height: 874)
        let point = WorldPoint(x: reference.lookX, y: reference.lookY - 50)
        func offsets(k: Double) -> [Double] {
            (0...20).map { step in
                let camera = rail.pose(z: Double(step) / 20)
                return DepthLayer.pose(camera, reference: reference, k: k).project(point, width: 402).y - camera.anchorY
            }
        }
        let horizon = offsets(k: 0.05), island = offsets(k: 1)
        let (h, i) = (horizon.max()! - horizon.min()!, island.max()! - island.min()!)
        #expect(h < 25, "horizon moved \(h) pt")
        #expect(i > 5 * h, "island moved \(i) pt")
    }

    /// Along the rail from the Map to mid (z 0 to 1, 100 samples) no layer's place under Home's look point changes its pace by
    /// more than 3 pt between samples (the rail itself bends at its stops): no jump where the rail changes segment.
    @Test func layerPosesAreContinuousAcrossTheRail() throws {
        let home = try #require(HomePlate.shipped)
        let rail = CameraRail(width: 402, height: 874, stops: home.stops, whole: home.wholeStop)
        let reference = home.skyReference(width: 402, height: 874)
        let point = WorldPoint(x: reference.lookX, y: reference.lookY)
        for k in [0.05, 0.25, 0.35, 0.45, 0.85] {
            var ys: [Double] = [], xs: [Double] = []
            for step in 0...100 {
                let p = DepthLayer.pose(rail.pose(z: Double(step) / 100), reference: reference, k: k).project(point, width: 402)
                xs.append(p.x)
                ys.append(p.y)
            }
            // The sample on the Island stop (z 1) is where the rail bends: its two segments run at their
            // own pace (the Map's journey-order frame sits far above Home), so it is left out.
            for n in 2...100 where n - 1 != 50 {
                #expect(abs((ys[n] - ys[n - 1]) - (ys[n - 1] - ys[n - 2])) < 3, "k \(k) y step \(n)")
                #expect(abs((xs[n] - xs[n - 1]) - (xs[n - 1] - xs[n - 2])) < 3, "k \(k) x step \(n)")
            }
        }
    }
}
