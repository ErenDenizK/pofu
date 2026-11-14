import PofuCore
import PofuWorld
import XCTest
@testable import Pofu

/// The far bell's road (docs/design/days-17-21-v1.md, PR 1): the step's card
/// on the mornings of days 17 to 20, as the player meets it, with its line,
/// the name row and its button ("Mırıldan" on day 17, "Dinle" after).
/// The ordinary `path-d17-0900` to `path-d20-0900` and `path-dNN-2300` frames
/// of `PlayerPathFrameCase` show the seed-count line and the listening night lines.
final class FarBellRoadScreenshotTests: PlayerPathFrameCase {
    @MainActor
    func testRenderTheStepsCards() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        for day in Self.path {
            guard let step = FarBellPrelude.step(in: day.morning) else { continue }
            let nn = String(format: "%02d", day.day)
            try await home(
                day.morning, hour: 9, beads: [], name: "path-d\(nn)-prelude-0900",
                scene: scene, folder: folder, beats: [.news(.farNotes(step))]
            )
        }
    }
}
