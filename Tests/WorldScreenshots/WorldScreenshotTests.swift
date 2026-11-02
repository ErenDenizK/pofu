import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Renders `IslandScene` in the simulator and writes PNGs for review: the
/// founder reviews screenshots, never web prototypes.
///
/// The scene is hosted in a real window of the Pofu app, so the station
/// sheet, native glass and Pofu's Metal shader draw as they do on a phone
/// (`ImageRenderer` draws neither sheets nor glass). The PNGs go to
/// `WORLD_SCREENSHOTS_DIR` (CI passes it as
/// `TEST_RUNNER_WORLD_SCREENSHOTS_DIR`), or a temporary folder, and are
/// attached to the test result too.
final class WorldScreenshotTests: XCTestCase {
    private enum Shot: String, CaseIterable {
        case home = "01-home"
        case island = "02-island"
        case map = "03-map"
        case station = "04-station-sheet"
        case resident = "05-resident-card"

        var framing: WorldFraming {
            switch self {
            case .home: .home
            case .map: .map
            case .island, .station, .resident: .island
            }
        }

        @MainActor
        func apply(to model: IslandSceneModel) {
            switch self {
            case .home, .island, .map: break
            case .station: model.focusStation(.cay, animated: false)
            case .resident: model.focusResident(.mochi, animated: false)
            }
        }
    }

    @MainActor
    func testRenderTheIslandScene() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var written: [String] = []

        for style in [UIUserInterfaceStyle.light, .dark] {
            for shot in Shot.allCases {
                let name = "\(shot.rawValue)-\(style == .dark ? "dark" : "light")"
                let model = IslandSceneModel(framing: shot.framing)
                let host = UIHostingController(rootView: ScreenshotScene(world: IslandSamples.dayThree(), model: model))
                let window = UIWindow(windowScene: scene)
                window.overrideUserInterfaceStyle = style
                window.rootViewController = host
                window.windowLevel = .alert + 1
                window.makeKeyAndVisible()

                // Let the scene lay out (the camera needs the viewport),
                // then focus, then let the sheet and springs land.
                try await Task.sleep(for: .milliseconds(700))
                shot.apply(to: model)
                try await Task.sleep(for: .milliseconds(shot == .home || shot == .island || shot == .map ? 600 : 1600))

                let format = UIGraphicsImageRendererFormat()
                format.scale = window.traitCollection.displayScale
                format.opaque = true
                let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
                    _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                }
                let data = try XCTUnwrap(image.pngData())
                try data.write(to: folder.appendingPathComponent("\(name).png"))
                written.append("\(name): \(Int(window.bounds.width))×\(Int(window.bounds.height)) pt @\(Int(format.scale))x")

                let attachment = XCTAttachment(image: image)
                attachment.name = name
                attachment.lifetime = .keepAlways
                add(attachment)

                // Close the sheet without animation and drop the window.
                if host.presentedViewController != nil {
                    host.dismiss(animated: false)
                }
                window.isHidden = true
                window.rootViewController = nil
                try await Task.sleep(for: .milliseconds(150))
            }
        }

        let summary = written.joined(separator: "\n")
        try summary.write(to: folder.appendingPathComponent("README.txt"), atomically: true, encoding: .utf8)
        print("World screenshots in \(folder.path):\n\(summary)")
        XCTAssertEqual(written.count, Shot.allCases.count * 2)
    }

    private func outputFolder() -> URL {
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
    }
}

/// The scene as Home shows it, with the framing control on top and a
/// sample bubble.
private struct ScreenshotScene: View {
    let world: WorldSnapshot
    let model: IslandSceneModel

    var body: some View {
        ZStack(alignment: .top) {
            IslandScene(world: world, model: model) {
                SpeechBubble {
                    Text(verbatim: "Sen yokken bahçe 12 çekirdek topladı.")
                }
            }
            FramingPicker(model: model)
                .padding(.top, 8)
        }
    }
}
