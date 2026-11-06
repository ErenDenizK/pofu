import PofuCore
import PofuDesignSystem
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// UI v3 wave 1 proof (docs/design/ui-v3.md section 6): the component kit
/// sheet in every state, day and night, at the default and an XXL type
/// size, and the breathing room at three moments of the breath.
final class UIV3ScreenshotTests: XCTestCase {
    /// The kit sheet, laid out at full height and rendered without a window.
    @MainActor
    func testRenderTheKitSheet() throws {
        let shots: [(String, Bool, DynamicTypeSize)] = [
            ("kit-v3-day-large", false, .large),
            ("kit-v3-night-large", true, .large),
            ("kit-v3-day-xxl", false, .xxxLarge),
            ("kit-v3-night-xxl", true, .xxxLarge),
        ]
        for (name, night, size) in shots {
            let view = PofuKitSheet(night: night, scrolls: false)
                .dynamicTypeSize(size)
                .frame(width: 393)
                .fixedSize(horizontal: false, vertical: true)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 3
            renderer.isOpaque = true
            let image = try XCTUnwrap(renderer.uiImage, name)
            try save(image, name: name)
        }
    }

    /// The breath at the in-breath (ring half full), the hold at the top
    /// of the breath (ring full), the out-breath (ring unwinding), and the
    /// hold at night.
    @MainActor
    func testRenderTheBreathRoom() async throws {
        let model = AppModel.shared
        let attempt = CheckInAttempt(
            id: UUID(),
            target: ProtectedApp.instagram.target,
            attemptedAt: Date(),
            ladderRung: .pause,
            rung: .pause,
            cheapestPrice: nil
        )
        let plan = BreathPlan(rules: .standard, overLimitOpen: 1, explains: false)
        let shots: [(String, Bool, BreathFreeze)] = [
            ("breath-1-in", false, BreathFreeze(phase: .breathingIn, ring: 0.5, lift: 0.5)),
            ("breath-2-hold", false, BreathFreeze(phase: .breathingIn, ring: 1, lift: 1)),
            ("breath-3-out", false, BreathFreeze(phase: .breathingOut, ring: 0.5, lift: 0.5)),
            ("breath-4-hold-night", true, BreathFreeze(phase: .breathingIn, ring: 1, lift: 1)),
        ]
        for (name, night, freeze) in shots {
            let session = HopSession(app: .instagram, attempt: attempt, isNight: night, reachOrdinal: 3, shieldedApp: nil, calm: nil)
            let window = try makeWindow(AnyView(BreathRoom(model: model, session: session, plan: plan, frozen: freeze)))
            try await Task.sleep(for: .milliseconds(700))
            try capture(window, name: name)
            window.isHidden = true
            window.rootViewController = nil
            try await Task.sleep(for: .milliseconds(150))
        }
    }

    // MARK: Hosting

    @MainActor
    private func makeWindow(_ view: AnyView) throws -> UIWindow {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: view)
        window.windowLevel = .alert + 3
        window.makeKeyAndVisible()
        return window
    }

    @MainActor
    private func capture(_ window: UIWindow, name: String) throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = window.traitCollection.displayScale
        format.opaque = true
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        try save(image, name: name)
    }

    @MainActor
    private func save(_ image: UIImage, name: String) throws {
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let data = try XCTUnwrap(image.pngData())
        try data.write(to: folder.appendingPathComponent("\(name).png"))
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func outputFolder() -> URL {
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
    }
}
