import PofuDesignSystem
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// Renders the Today and Settings sheets' content for review (painted
/// icons, paper panels, the painted button face), light and dark and at a
/// large text size, beside the world screenshots: same window hosting,
/// same folder. The station sheet is in the world shots (04 to 06).
final class MenuScreenshotTests: XCTestCase {
    @MainActor
    func testRenderTheMenus() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let model = AppModel.shared
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let shots: [(String, UIUserInterfaceStyle, DynamicTypeSize, AnyView)] = [
            ("15-menu-today-light", .light, .large, AnyView(TodaySheet(model: model))),
            ("15-menu-today-dark", .dark, .large, AnyView(TodaySheet(model: model))),
            ("15-menu-today-ax3-light", .light, .accessibility3, AnyView(TodaySheet(model: model))),
            ("16-menu-settings-light", .light, .large, AnyView(SettingsView(model: model))),
            ("16-menu-settings-dark", .dark, .large, AnyView(SettingsView(model: model))),
        ]

        for (name, style, size, view) in shots {
            let host = UIHostingController(rootView: view.dynamicTypeSize(size))
            let window = UIWindow(windowScene: scene)
            window.overrideUserInterfaceStyle = style
            window.rootViewController = host
            window.windowLevel = .alert + 3
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
