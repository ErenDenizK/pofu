import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// The voyage ride (plan row 2d, ADR-0028), the verb of the row, as motion beats: the same ride held still at
/// each half second of its length, Home to Köke:
///
/// - `voyage-0.0`, `-0.5`: the row, she moored at Home, the characters hopping aboard;
/// - `voyage-1.0` to `-3.0`: the camera's flight, she on the wing in the middle of the frame;
/// - `voyage-3.5`, `-4.0`: the camera has arrived, she glides to her place and the characters hop off.
///
/// Plus `voyage-row-night` and `voyage-row-home-night`, the row in the night (graded by the hour), and
/// `voyage-back-2.0`, the way home mid-flight, she facing the other way.
final class PlayerPathRideScreenshotTests: PlayerPathFrameCase {
    private func world(level: Int, night: Bool = false) throws -> WorldSnapshot {
        let day = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == level }, "the path has a level \(level) island")
        var world = night ? day.night : day.morning
        world.koke = WonderStatus(phase: .arrived, stage: 0)
        return world
    }

    @MainActor
    private func frame(
        _ world: WorldSnapshot, hour: Double, from origin: IslandID, to target: IslandID, at seconds: Double?,
        name: String, scene: UIWindowScene, folder: URL
    ) async throws {
        let model = IslandSceneModel(framing: .map)
        model.voyage.open(on: origin)
        model.voyage.choose(target)
        let view = homeView(world, hour: hour, island: model, settled: true)
        let flip = seconds.map { moment in
            PathFlip(waiting: 900) { model.holdRide(from: origin, to: target, at: moment) }
        }
        try await capture(AnyView(view), name: name, scene: scene, folder: folder, settle: 2100, flip: flip) {
            XCTAssertNotNil(model.homePlate, "\(name): Home is its painting")
        }
    }

    @MainActor
    func testRenderTheRide() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let world = try world(level: 5)
        for tenths in stride(from: 0, through: 40, by: 5) {
            let seconds = Double(tenths) / 10
            try await frame(
                world, hour: 12, from: .home, to: .koke, at: seconds,
                name: String(format: "voyage-%.1f", seconds), scene: scene, folder: folder
            )
        }
        try await frame(world, hour: 12, from: .koke, to: .home, at: 2.0, name: "voyage-back-2.0", scene: scene, folder: folder)
    }

    @MainActor
    func testRenderTheRowAtNight() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let night = try world(level: 5, night: true)
        try await frame(night, hour: 23, from: .home, to: .koke, at: nil, name: "voyage-row-night", scene: scene, folder: folder)
        try await frame(night, hour: 23, from: .home, to: .home, at: nil, name: "voyage-row-home-night", scene: scene, folder: folder)
    }
}
