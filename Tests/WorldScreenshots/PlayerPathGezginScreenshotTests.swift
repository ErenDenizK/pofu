import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// The Gezgin moored at Home's pier (plan row 2b, ADR-0028), on the tester's path:
///
/// - `path-gezgin-moored-l1`, `-l2`, `-l3`: her three levels by day, awake, at island levels 3, 5 and 7;
/// - `path-gezgin-night`: asleep in the night plate (level 2, bedtime);
/// - `path-gezgin-wake`: a tap at night, 0.15 s after it, with her line up;
/// - `path-gezgin-shadow`: before she arrives, Koke a hump on the horizon, her shadow on the cloud;
/// - `path-gezgin-none`: before the hump, nothing (the control).
final class PlayerPathGezginScreenshotTests: PlayerPathFrameCase {
    /// The path's morning (or its night) of an island level, with the wonder islands as given.
    private func world(level: Int, night: Bool = false, koke: WonderStatus, caglayan: WonderStatus = WonderStatus()) throws -> WorldSnapshot {
        let day = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == level }, "the path has a level \(level) island")
        var world = night ? day.night : day.morning
        world.koke = koke
        world.caglayan = caglayan
        return world
    }

    @MainActor
    private func frame(_ world: WorldSnapshot, hour: Double, name: String, scene: UIWindowScene, folder: URL, prepare: (IslandSceneModel) -> Void = { _ in }) async throws {
        let island = IslandSceneModel(framing: .mid)
        prepare(island)
        let view = homeView(world, hour: hour, island: island, settled: true)
        try await capture(AnyView(view), name: name, scene: scene, folder: folder, settle: 2100) {
            XCTAssertNotNil(island.homePlate, "\(name): Home is its painting")
        }
    }

    @MainActor
    func testRenderTheGezginMoored() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let healed = WonderStatus(phase: .arrived, stage: WonderIslands.healedStage)
        let arrived = WonderStatus(phase: .arrived, stage: 0)
        let levels: [(level: Int, island: Int, koke: WonderStatus, caglayan: WonderStatus)] = [
            (1, 3, arrived, WonderStatus()), (2, 5, healed, WonderStatus()), (3, 7, healed, healed),
        ]
        for item in levels {
            XCTAssertEqual(
                Gezgin.presence(koke: item.koke, caglayan: item.caglayan, data: try XCTUnwrap(GezginData.shipped)), .moored(level: item.level)
            )
            let world = try world(level: item.island, koke: item.koke, caglayan: item.caglayan)
            try await frame(world, hour: 12, name: "path-gezgin-moored-l\(item.level)", scene: scene, folder: folder)
        }
    }

    /// Her place at Köke and at Çağlayan (row 2e): moored beside the island, her post on its rim, a slack line.
    @MainActor
    func testRenderTheGezginAtTheWonderIslands() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let arrived = WonderStatus(phase: .arrived, stage: 0)
        let healed = WonderStatus(phase: .arrived, stage: WonderIslands.healedStage)
        try await frame(try world(level: 5, koke: arrived), hour: 12, name: "path-gezgin-koke", scene: scene, folder: folder) { $0.holdIsle(.koke) }
        try await frame(try world(level: 5, koke: healed, caglayan: arrived), hour: 12, name: "path-gezgin-caglayan", scene: scene, folder: folder) { $0.holdIsle(.caglayan) }
        try await frame(try world(level: 7, koke: healed, caglayan: healed), hour: 12, name: "path-gezgin-caglayan-l3", scene: scene, folder: folder) { $0.holdIsle(.caglayan) }
        try await frame(try world(level: 5, koke: healed), hour: 12, name: "path-gezgin-koke-l2", scene: scene, folder: folder) { $0.holdIsle(.koke) }
    }

    @MainActor
    func testRenderTheGezginAsleepAndWoken() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let healed = WonderStatus(phase: .arrived, stage: WonderIslands.healedStage)
        let night = try world(level: 5, night: true, koke: healed)
        try await frame(night, hour: 23, name: "path-gezgin-night", scene: scene, folder: folder)
        try await frame(night, hour: 23, name: "path-gezgin-wake", scene: scene, folder: folder) { island in
            // The frame's clock is real time, so the frame states the tap's age: 0.15 s.
            island.gezgin.wake(heldAge: 0.15)
            island.gezgin.hold(lineKey: Gezgin.lineKey(asleep: true, taps: 1))
        }
    }

    @MainActor
    func testRenderTheGezginsShadow() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let hump = WonderStatus(phase: .rumoured)
        try await frame(try world(level: 5, koke: hump), hour: 12, name: "path-gezgin-shadow", scene: scene, folder: folder)
        try await frame(try world(level: 5, koke: WonderStatus()), hour: 12, name: "path-gezgin-none", scene: scene, folder: folder)
    }
}
