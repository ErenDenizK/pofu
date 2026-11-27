import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// The voyage row (plan row 2c, ADR-0028), the far stop, on the tester's path:
///
/// - `path-row-home`: Home in view, Köke a neighbour cut by the right edge (Köke arrived);
/// - `path-row-koke`: Köke in view, Home and Çağlayan's cloud tower as neighbours;
/// - `path-row-locked`: the first day, Köke still a cloud tower: the verb is dimmed.
final class PlayerPathRowScreenshotTests: PlayerPathFrameCase {
    private func world(level: Int, koke: WonderStatus, caglayan: WonderStatus = WonderStatus()) throws -> WorldSnapshot {
        let day = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == level }, "the path has a level \(level) island")
        var world = day.morning
        world.koke = koke
        world.caglayan = caglayan
        return world
    }

    @MainActor
    private func frame(_ world: WorldSnapshot, choose island: IslandID, name: String, scene: UIWindowScene, folder: URL) async throws {
        let model = IslandSceneModel(framing: .map)
        model.voyage.open(on: .home)
        model.voyage.choose(island)
        let view = homeView(world, hour: 12, island: model, settled: true)
        try await capture(AnyView(view), name: name, scene: scene, folder: folder, settle: 2100) {
            XCTAssertEqual(model.projectedFraming, .map, "\(name): the far stop is the row")
        }
    }

    @MainActor
    func testRenderTheVoyageRow() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let arrived = WonderStatus(phase: .arrived, stage: 0)
        let healed = WonderStatus(phase: .arrived, stage: WonderIslands.healedStage)
        try await frame(try world(level: 5, koke: arrived), choose: .home, name: "path-row-home", scene: scene, folder: folder)
        try await frame(try world(level: 5, koke: healed), choose: .koke, name: "path-row-koke", scene: scene, folder: folder)
        try await frame(try world(level: 3, koke: WonderStatus()), choose: .koke, name: "path-row-locked", scene: scene, folder: folder)
    }
}
