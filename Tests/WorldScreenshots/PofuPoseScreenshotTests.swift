import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// Pofu's mood on Home at 09:00, island level 10 (`path-pofu-mood-<mood>`). The mood is derived
/// from the world (`PofuMoodSource`) and no override exists, so the set is calm (a content band,
/// wellbeing 50) and happy (a cozy band, wellbeing 90): happy must show two hands, not three.
final class PofuPoseScreenshotTests: PlayerPathFrameCase {
    @MainActor
    func testRenderThePofuMoods() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == 3 }, "the path has a level 3 island")
        let moods: [(name: String, wellbeing: Double, band: WellbeingBand)] = [
            ("calm", 50, .content), ("happy", 90, .cozy),
        ]
        for mood in moods {
            var world = day.morning
            world.islandLevel = 10
            world.wellbeing = mood.wellbeing
            world.band = mood.band
            world.isBedtime = false
            world.calmIsFull = false
            world.visitor = nil
            try await home(world, hour: 9, beads: [], name: "path-pofu-mood-\(mood.name)", scene: scene, folder: folder)
        }
    }
}
