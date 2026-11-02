import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// Renders Rehearsal mode's shield replica and Prova panel for review,
/// beside the world screenshots: same window hosting, same folder.
final class RehearsalScreenshotTests: XCTestCase {
    @MainActor
    func testRenderTheShieldReplicaAndThePanel() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        // The free build's own model, which rehearses by default.
        let model = AppModel.shared
        let rehearsal = try XCTUnwrap(model.rehearsal, "the Pofu scheme runs in Rehearsal mode")
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        // A second reach of the morning, the copy the extension would draw.
        let copy = ShieldCopy.make(
            context: ShieldContext(
                appName: "Instagram",
                bundleIdentifier: "com.burbn.instagram",
                hour: 10,
                dayOfYear: 306,
                reachesToday: 3,
                resistedToday: 2,
                reachesThisHour: 1,
                calm: 1.4
            ),
            language: .turkish
        )
        let shots: [(String, AnyView)] = [
            ("06-shield-replica-light", AnyView(ShieldReplicaView(model: model, copy: copy))),
            (
                "07-prova-panel-light",
                AnyView(
                    ZStack {
                        IslandScene(world: IslandSamples.dayThree(), model: IslandSceneModel(framing: .home)) {
                            SpeechBubble {
                                Text(verbatim: "Sen yokken bahçe 12 çekirdek topladı.")
                            }
                        }
                        RehearsalPanel(model: model, rehearsal: rehearsal)
                    }
                )
            ),
        ]

        for (name, view) in shots {
            let host = UIHostingController(rootView: view)
            let window = UIWindow(windowScene: scene)
            window.overrideUserInterfaceStyle = .light
            window.rootViewController = host
            window.windowLevel = .alert + 2
            window.makeKeyAndVisible()
            try await Task.sleep(for: .milliseconds(900))

            let format = UIGraphicsImageRendererFormat()
            format.scale = window.traitCollection.displayScale
            format.opaque = true
            let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
                _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            let data = try XCTUnwrap(image.pngData())
            try data.write(to: folder.appendingPathComponent("\(name).png"))
            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)

            window.isHidden = true
            window.rootViewController = nil
            try await Task.sleep(for: .milliseconds(150))
        }
    }

    private func outputFolder() -> URL {
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
    }
}
