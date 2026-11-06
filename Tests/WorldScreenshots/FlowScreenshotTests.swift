import PofuGames
import SwiftUI
import UIKit
import XCTest

/// Renders the flow game for review: Çağlayan stage 1 unsolved, mid-way
/// (with Damla's hint on a stone) and solved, the unsolved start of stage 3's
/// wheel board, and stage 4's full falls solved. Same recipe as the garden:
/// each shot freezes the scene and shows SpriteKit's render of it in place
/// of the live view before the window is drawn, so the SwiftUI layer (HUD,
/// controls) sits on top as on the phone.
final class FlowScreenshotTests: XCTestCase {
    @MainActor
    func testRenderTheFlowGame() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var written: [String] = []

        // Stage 1, board 1: the first bend, nothing turned yet.
        try await shoot("40-flow-stage1-start", in: scene, folder: folder, written: &written, stage: 1) { _ in }

        // Mid-way: one of the two remaining bends turned, the water running
        // on, and Damla's hint on the next stone.
        try await shoot("41-flow-stage1-mid", in: scene, folder: folder, written: &written, stage: 1) { model in
            model.playSuggestedTap()
            try await Task.sleep(for: .milliseconds(900))
            await model.showHintNow()
            try await Task.sleep(for: .milliseconds(700))
        }

        // Solved: the last tap, the pour. Held on the solved board.
        try await shoot("42-flow-stage1-solved", in: scene, folder: folder, written: &written, stage: 1) { model in
            while model.phase == .playing, model.playSuggestedTap() {
                try await Task.sleep(for: .milliseconds(350))
            }
            try await Task.sleep(for: .milliseconds(1100))
        }

        // Stage 3's second board: the wheel, before any tap (the round's first
        // board is solved by hand to get there).
        try await shoot("43-flow-stage3-wheel-start", in: scene, folder: folder, written: &written, stage: 3) { _ in }

        // Stage 4's last board, solved: two mouths and a turning wheel.
        try await shoot("44-flow-stage4-solved", in: scene, folder: folder, written: &written, stage: 4) { model in
            try await Self.solveBoard(model)
            model.continueNow()
            try await Task.sleep(for: .milliseconds(900))
            try await Self.solveBoard(model)
            try await Task.sleep(for: .milliseconds(1400))
        }

        let summary = written.joined(separator: "\n")
        try summary.write(to: folder.appendingPathComponent("README-flow.txt"), atomically: true, encoding: .utf8)
        print("Flow screenshots in \(folder.path):\n\(summary)")
        XCTAssertEqual(written.count, 5)
    }

    /// Follows the hint to the end of the current board.
    @MainActor
    private static func solveBoard(_ model: FlowGameModel) async throws {
        var guardCount = 0
        while model.phase == .playing, guardCount < 40, model.playSuggestedTap() {
            guardCount += 1
            try await Task.sleep(for: .milliseconds(120))
        }
        try await Task.sleep(for: .milliseconds(600))
    }

    @MainActor
    private func host(_ model: FlowGameModel, in scene: UIWindowScene) async throws -> UIWindow {
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: FlowGameView(model: model))
        window.windowLevel = .alert + 3
        window.makeKeyAndVisible()
        // Let SwiftUI lay out, the SKView present the scene and the scene
        // build its board.
        try await Task.sleep(for: .milliseconds(900))
        return window
    }

    @MainActor
    private func shoot(
        _ name: String,
        in scene: UIWindowScene,
        folder: URL,
        written: inout [String],
        stage: Int,
        prepare: (FlowGameModel) async throws -> Void
    ) async throws {
        let round = try XCTUnwrap(FlowLibrary.round(stage: stage))
        // A long idle and pour pause: the screenshots drive the round by hand.
        let model = FlowGameModel(round: round, hintDelay: .seconds(600), pourPause: .seconds(600))
        let window = try await host(model, in: scene)
        if stage == 3 {
            // The wheel board is the round's second board.
            try await Self.solveBoard(model)
            model.continueNow()
            try await Task.sleep(for: .milliseconds(1100))
        }
        try await prepare(model)
        model.freeze()
        try await Task.sleep(for: .milliseconds(250))
        let image = snapshot(window)
        try XCTUnwrap(image.pngData()).write(to: folder.appendingPathComponent("\(name).png"))
        written.append("\(name): \(Int(window.bounds.width))×\(Int(window.bounds.height)) pt, scene still \(model.frozenFrame == nil ? "missing" : "rendered")")
        add(attachment(image, name: name))
        window.isHidden = true
        window.rootViewController = nil
        try await Task.sleep(for: .milliseconds(150))
    }

    @MainActor
    private func snapshot(_ window: UIWindow) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = window.traitCollection.displayScale
        format.opaque = true
        return UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }

    @MainActor
    private func attachment(_ image: UIImage, name: String) -> XCTAttachment {
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        return attachment
    }

    private func outputFolder() -> URL {
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
    }
}
