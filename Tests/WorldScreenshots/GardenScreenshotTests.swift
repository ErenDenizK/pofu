import PofuGames
import SwiftUI
import UIKit
import XCTest

/// Renders the Ayçiçeği garden game for review, beside the world
/// screenshots: mid-round with a plot in the air (ghost and bloom glow),
/// a bloom, a combo, the round's card and the set's card, plus a frame
/// sequence of one bloom in slow motion.
///
/// SpriteKit draws into a Metal layer that a window snapshot may miss, so
/// each shot freezes the scene and shows SpriteKit's own render of it in
/// place of the live view (`GardenGameModel.freeze`) before the window is
/// drawn; the HUD and cards are SwiftUI on top, as on the phone.
final class GardenScreenshotTests: XCTestCase {
    @MainActor
    func testRenderTheGarden() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var written: [String] = []

        // Mid-round: seven plots planted, the next one held over the spot
        // the autoplayer likes, with its ghost and (if it blooms) the glow.
        try await shoot("20-garden-midround-light", in: scene, folder: folder, written: &written, model: GardenGameModel(seed: 2026)) { model in
            model.autoplay(moves: 7)
            try await Task.sleep(for: .milliseconds(400))
            model.holdSuggestedMove()
            try await Task.sleep(for: .milliseconds(450))
        }

        // A bloom: the moment the sunflowers pop, before the seeds fly.
        try await shoot("21-garden-bloom-light", in: scene, folder: folder, written: &written, model: GardenGameModel(seed: 7)) { model in
            model.playBloom()
            try await Task.sleep(for: .milliseconds(330))
        }

        // A combo: a double bloom on a warm streak (combo 3).
        try await shoot("22-garden-combo-light", in: scene, folder: folder, written: &written, model: GardenGameModel(seed: 11)) { model in
            model.load(Self.comboScenario())
            try await Task.sleep(for: .milliseconds(500))
            model.play(slot: 0, at: GardenCell(row: 0, column: 6))
            try await Task.sleep(for: .milliseconds(420))
        }

        // The round's card, over the garden it grew.
        try await shoot("23-garden-round-end-light", in: scene, folder: folder, written: &written, model: GardenGameModel(seed: 5)) { model in
            model.autoplay(moves: 12)
            try await Task.sleep(for: .milliseconds(300))
            model.showRoundEnd(GardenRoundResult(seeds: 4, lines: 6, bestCombo: 3, placed: 18, ending: .bagEmpty))
            try await Task.sleep(for: .milliseconds(1600))
        }

        // The set's card: five rounds, "Enough for today", and another set
        // offered as plain text because three earned rounds are banked.
        try await shoot("24-garden-set-end-light", in: scene, folder: folder, written: &written, model: GardenGameModel(roundsAvailable: 8, seed: 3)) { model in
            model.autoplay(moves: 9)
            for seeds in [3, 4, 2, 5, 4] {
                model.showRoundEnd(GardenRoundResult(seeds: seeds, lines: seeds + 1, bestCombo: 2, placed: 18, ending: .bagEmpty))
            }
            try await Task.sleep(for: .milliseconds(1600))
        }

        // A bloom in slow motion, eight frames, cropped to the garden.
        let sequence = try await frames(in: scene, model: GardenGameModel(seed: 7))
        let strip = Self.contactStrip(sequence, columns: 4)
        try XCTUnwrap(strip.pngData()).write(to: folder.appendingPathComponent("25-garden-bloom-frames.png"))
        written.append("25-garden-bloom-frames: \(sequence.count) frames at 0.2× speed")
        add(attachment(strip, name: "25-garden-bloom-frames"))

        let summary = written.joined(separator: "\n")
        try summary.write(to: folder.appendingPathComponent("README-garden.txt"), atomically: true, encoding: .utf8)
        print("Garden screenshots in \(folder.path):\n\(summary)")
        XCTAssertEqual(written.count, 6)
    }

    /// A bed two plots from a double bloom, on a streak of two.
    static func comboScenario() -> GardenRound {
        let board = GardenBoard(rows: [
            "######..",
            "######..",
            "##..#...",
            "#...##..",
            "....#..#",
            "##.....#",
            "###...##",
            "####..##",
        ])
        let tray = [
            PieceCatalog.shapes(of: .square2)[0],
            PieceCatalog.shapes(of: .line3)[0],
            PieceCatalog.shapes(of: .corner3)[1],
        ]
        return GardenRound(scenario: board, tray: tray, placed: 9, combo: 2, linesBloomed: 4, seed: 11)
    }

    @MainActor
    private func host(_ model: GardenGameModel, in scene: UIWindowScene) async throws -> UIWindow {
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: GardenGameView(model: model))
        window.windowLevel = .alert + 3
        window.makeKeyAndVisible()
        // Let SwiftUI lay out, the SKView present the scene and the scene
        // build its bed and deal the tray.
        try await Task.sleep(for: .milliseconds(900))
        return window
    }

    @MainActor
    private func shoot(
        _ name: String,
        in scene: UIWindowScene,
        folder: URL,
        written: inout [String],
        model: GardenGameModel,
        prepare: (GardenGameModel) async throws -> Void
    ) async throws {
        let window = try await host(model, in: scene)
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
    private func frames(in scene: UIWindowScene, model: GardenGameModel) async throws -> [UIImage] {
        let window = try await host(model, in: scene)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        model.sceneSpeed = 0.2
        guard model.playBloom() else { return [] }
        let crop = model.gardenRect
        var images: [UIImage] = []
        // Scene seconds after the drop: the landing, the squash, the sweep,
        // the pop, the hold, the seeds' flight, the gulp.
        var elapsed = 0.0
        for time in [0.04, 0.1, 0.17, 0.26, 0.38, 0.62, 0.86, 1.12] {
            let wait = (time - elapsed) / 0.2
            elapsed = time
            try await Task.sleep(for: .milliseconds(Int(wait * 1000)))
            if let frame = model.captureScene(), let cropped = Self.crop(frame, to: crop) {
                images.append(cropped)
            }
        }
        return images
    }

    @MainActor
    private static func crop(_ image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let scale = image.scale
        let pixels = CGRect(x: rect.minX * scale, y: rect.minY * scale, width: rect.width * scale, height: rect.height * scale)
            .intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        guard let cropped = cgImage.cropping(to: pixels) else { return nil }
        return UIImage(cgImage: cropped, scale: scale, orientation: .up)
    }

    @MainActor
    private static func contactStrip(_ frames: [UIImage], columns: Int) -> UIImage {
        guard let first = frames.first else {
            return UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in }
        }
        let cell = first.size
        let gap: CGFloat = 12
        let rows = Int((Double(frames.count) / Double(columns)).rounded(.up))
        let size = CGSize(
            width: gap + CGFloat(columns) * (cell.width + gap),
            height: gap + CGFloat(rows) * (cell.height + gap + 18)
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.5
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            for (index, frame) in frames.enumerated() {
                let x = gap + CGFloat(index % columns) * (cell.width + gap)
                let y = gap + CGFloat(index / columns) * (cell.height + gap + 18)
                let label = "\(index + 1)" as NSString
                label.draw(at: CGPoint(x: x, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 13, weight: .semibold)])
                frame.draw(in: CGRect(x: x, y: y + 18, width: cell.width, height: cell.height))
            }
        }
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
