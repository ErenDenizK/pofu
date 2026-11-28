import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// The near camera's ground (mainflow plan row 3a): near's rest on Pofu and on the tea stall by day
/// (`path-near-pofu`, `-stall`; the rig clamps away from the pond, so there is no pond shot), and on Pofu at golden hour, at night and in autumn
/// (`path-near-pofu-golden`, `-night`, `-autumn`). Island level 10 (stage 0, the only state that has all four
/// lights), the stall at level 3, clear weather, full device resolution (1206 x 2622).
final class NearGroundScreenshotTests: PlayerPathFrameCase {
    private enum Shot { case pofu, stall }

    @MainActor
    func testRenderTheNearGround() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == 3 }, "the path has a level 3 island")
        var world = day.morning
        world.islandLevel = 10
        world.stations = world.stations.map { status in
            var status = status
            if status.id == .teaStall { status.level = 3 }
            return status
        }
        let frames: [(name: String, hour: Double, season: Season?, shot: Shot)] = [
            ("path-near-pofu", 12, nil, .pofu),
            ("path-near-stall", 12, nil, .stall),
            ("path-near-pofu-golden", 18, nil, .pofu),
            ("path-near-pofu-night", 22, nil, .pofu),
            ("path-near-pofu-autumn", 12, .autumn, .pofu),
        ]
        for frame in frames {
            var look = WorldLook.playerPath(hour: frame.hour)
            look.seasonOverride = frame.season
            let plate = try XCTUnwrap(HomePlate.resolve(world: world, look: look), "\(frame.name): the state is painted")
            let island = IslandSceneModel(framing: .mid)
            island.setHomePlate(plate)
            switch frame.shot {
            case .pofu: island.holdNearRest()
            case .stall: island.holdNearRest(on: plate.world(PlatePoint(x: 640, y: 860)))
            }
            let view = homeView(world, hour: frame.hour, island: island, settled: true, season: frame.season, weather: .clear)
            try await capture(AnyView(view), name: frame.name, scene: scene, folder: folder, settle: 2100) {
                XCTAssertNotNil(island.homePlate, "\(frame.name): Home is its painting")
            }
        }
    }
}
