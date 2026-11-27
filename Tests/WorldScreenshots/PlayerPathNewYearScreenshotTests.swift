import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// New Year's kit (island calendar v1, C3) on the tester's path, on 31 December 2026:
///
/// - `path-newyear-i3`, `path-newyear-i10`: Home at noon with the kit standing (island 3 and island 10);
/// - `path-newyear-night`: island 10 at 21:00, the kit lit, before the fireworks;
/// - `path-newyear-fireworks-0.0` ... `-2.0`: island 10 at 23:00 with the fireworks pinned to 0.0, 0.5, 1.0, 1.5 and 2.0 s;
/// - `path-newyear-quiet`: 1 January at noon: the kit stands, the sky is quiet.
final class PlayerPathNewYearScreenshotTests: PlayerPathFrameCase {
    @MainActor
    private func world(island: Int, day: (Int, Int, Int), hour: Int) throws -> WorldSnapshot {
        let base = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == 3 }, "the path has a level 3 island")
        var world = base.morning
        world.islandLevel = island
        var parts = DateComponents()
        (parts.year, parts.month, parts.day, parts.hour) = (day.0, day.1, day.2, hour)
        let clock = try XCTUnwrap(Calendar.current.date(from: parts))
        world.clock = clock
        world.specialDay = SpecialDays.shipped.current(on: LocalDay(containing: clock, in: .current), at: hour * 60)
        XCTAssertEqual(world.specialDay, .newYear, "the table names New Year on \(day)")
        return world
    }

    @MainActor
    private func frame(_ world: WorldSnapshot, hour: Double, time: Double? = nil, name: String, scene: UIWindowScene, folder: URL) async throws {
        let island = IslandSceneModel(framing: .mid)
        let view = homeView(world, hour: hour, island: island, settled: true).environment(\.skyEventTime, time)
        try await capture(AnyView(view), name: name, scene: scene, folder: folder, settle: 2100) {
            XCTAssertNotNil(island.homePlate, "\(name): Home is its painting")
        }
    }

    @MainActor
    func testRenderTheNewYearKit() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let eve = (2026, 12, 31)
        try await frame(try world(island: 3, day: eve, hour: 12), hour: 12, name: "path-newyear-i3", scene: scene, folder: folder)
        try await frame(try world(island: 10, day: eve, hour: 12), hour: 12, name: "path-newyear-i10", scene: scene, folder: folder)
        try await frame(try world(island: 10, day: eve, hour: 21), hour: 21, name: "path-newyear-night", scene: scene, folder: folder)
        try await frame(try world(island: 10, day: (2027, 1, 1), hour: 12), hour: 12, name: "path-newyear-quiet", scene: scene, folder: folder)
        let night = try world(island: 10, day: eve, hour: 23)
        for t in [0.0, 0.5, 1.0, 1.5, 2.0] {
            try await frame(night, hour: 23, time: t, name: "path-newyear-fireworks-\(String(format: "%.1f", t))", scene: scene, folder: folder)
        }
    }
}
