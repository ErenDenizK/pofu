import PofuCore
import PofuWorld
import XCTest
@testable import Pofu

/// The far bell's notes in the sky (docs/design/days-17-21-v1.md, PR 2): the
/// rings of light a held tune draws, on day 20's step and on the bell's day.
/// The nights' light is in the ordinary `path-dNN-2300` frames.
final class FarBellSkyScreenshotTests: PlayerPathFrameCase {
    @MainActor
    func testRenderTheNotesInTheSky() async throws {
        defer { FarBellStage.shared.clear() }
        let scene = try windowScene()
        let folder = try outputFolder()
        let d20 = try XCTUnwrap(Self.path.first { $0.day == 20 })
        FarBellStage.shared.hold(
            FarBellTune.prelude(step: 4),
            age: 3 * FarBellTune.humGap + FarBellTune.breath + FarBellTune.farGap + 0.3
        )
        try await home(d20.morning, hour: 9, beads: [], name: "path-d20-prelude-notes-0900", scene: scene, folder: folder, beats: [.news(.farNotes(4))])
        let d21 = try XCTUnwrap(Self.path.first { $0.day == 21 })
        FarBellStage.shared.hold(FarBellTune.bell(), age: FarBellTune.bellLead + 4 * FarBellTune.farGap + 0.3)
        try await home(d21.morning, hour: 9, beads: [], name: "path-d21-bell-notes-0900", scene: scene, folder: folder, beats: [.bell])
    }
}
