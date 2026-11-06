import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// Renders the menus, the shield and the launch screen for review (the
/// acceptance of experience v1 section 3.6), beside the world screenshots:
/// same window hosting, same folder.
///
/// - Today in light, dark and AX3, and Settings.
/// - The station sheet: glass over the frozen world at medium, paper at
///   large.
/// - The shield replica in four palettes (dawn, day, dusk, night), with
///   every title 28 characters or fewer.
/// - The launch sky and the cloud curtain.
final class MenuScreenshotTests: XCTestCase {
    @MainActor
    func testRenderTheMenus() async throws {
        let model = AppModel.shared
        let shots: [(String, UIUserInterfaceStyle, DynamicTypeSize, AnyView)] = [
            ("15-menu-today-light", .light, .large, AnyView(TodaySheet(model: model))),
            ("15-menu-today-dark", .dark, .large, AnyView(TodaySheet(model: model))),
            ("15-menu-today-ax3-light", .light, .accessibility3, AnyView(TodaySheet(model: model))),
            ("16-menu-settings-light", .light, .large, AnyView(SettingsView(model: model))),
            ("16-menu-settings-dark", .dark, .large, AnyView(SettingsView(model: model))),
        ]
        for (name, style, size, view) in shots {
            let window = try makeWindow(AnyView(view.dynamicTypeSize(size)), style: style)
            try await Task.sleep(for: .milliseconds(900))
            try capture(window, name: name)
            tearDown(window)
            try await Task.sleep(for: .milliseconds(150))
        }
    }

    /// The station sheet over the world: at the medium detent the frozen
    /// island glows through glass; at large nothing shows behind it and the
    /// sheet is paper. The freeze is `isCovered`'s flatten; the test sets
    /// the same flag the flatten sets, so the glass has a still world.
    @MainActor
    func testRenderTheStationSheetGlassAndPaper() async throws {
        PofuWorldFreeze.shared.isFrozen = true
        defer { PofuWorldFreeze.shared.isFrozen = false }
        for (name, detent) in [("17-sheet-station-medium-glass", StationSheetDetent.medium), ("18-sheet-station-large-paper", .large)] {
            let island = IslandSceneModel(framing: .island)
            let window = try makeWindow(
                AnyView(IslandScene(world: IslandSamples.dayThree(), model: island) { EmptyView() }),
                style: .light
            )
            try await Task.sleep(for: .milliseconds(900))
            island.focusStation(.teaStall, animated: false)
            try await Task.sleep(for: .milliseconds(1400))
            island.sheetDetent = detent
            try await Task.sleep(for: .milliseconds(1200))
            try capture(window, name: name)
            if window.rootViewController?.presentedViewController != nil {
                window.rootViewController?.dismiss(animated: false)
            }
            tearDown(window)
            try await Task.sleep(for: .milliseconds(150))
        }
    }

    /// The shield replica in the four palettes of the colour script's sky.
    @MainActor
    func testRenderTheShieldInFourPalettes() async throws {
        let model = AppModel.shared
        let context = ShieldContext(
            appName: "Instagram",
            bundleIdentifier: "com.burbn.instagram",
            hour: 10,
            dayOfYear: 306,
            reachesToday: 3,
            resistedToday: 2,
            reachesThisHour: 1,
            calm: 1.4
        )
        let copy = ShieldCopy.make(context: context, language: .turkish)
        for sky in ShieldSky.allCases {
            let window = try makeWindow(AnyView(ShieldReplicaView(model: model, copy: copy, sky: sky)), style: .light)
            try await Task.sleep(for: .milliseconds(700))
            try capture(window, name: "19-shield-\(sky.rawValue)")
            tearDown(window)
            try await Task.sleep(for: .milliseconds(150))
        }
    }

    /// The gate's landing painted for the hours of the day (gate v2 section
    /// 5.1): 07:00, 12:00, 18:30, 22:30, and the rain postcard.
    @MainActor
    func testRenderTheGateLandingAtFourHoursAndInRain() async throws {
        let model = AppModel.shared
        model.startHop(for: .instagram)
        defer { model.dismissHop() }
        let shots: [(String, GateHour)] = [
            ("20-gate-0700", .dawn), ("20-gate-1200", .day), ("20-gate-1830", .golden),
            ("20-gate-2230", .night), ("20-gate-rain", .rain),
        ]
        for (name, hour) in shots {
            let window = try makeWindow(AnyView(HopView(model: model, hourOverride: hour)), style: .light)
            try await Task.sleep(for: .milliseconds(900))
            try capture(window, name: name)
            tearDown(window)
            try await Task.sleep(for: .milliseconds(150))
        }
    }

    /// Every title the shield can show fits the 28-character rule of the
    /// copy (experience v1 section 3.4), in both languages and at every hour.
    func testEveryShieldTitleIsAtMostTwentyEightCharacters() {
        for language in ShieldLanguage.allCases {
            for hour in 0..<24 {
                for reachesThisHour in [1, 2, 3, 9] {
                    for app in [("Instagram", "com.burbn.instagram"), ("TikTok", "com.zhiliaoapp.musically"), ("Kitapçıkolik", "")] {
                        let context = ShieldContext(
                            appName: app.0,
                            bundleIdentifier: app.1.isEmpty ? nil : app.1,
                            hour: hour,
                            isBedtime: hour >= 23 || hour < 6,
                            reachesToday: 4,
                            resistedToday: 2,
                            reachesThisHour: reachesThisHour
                        )
                        let copy = ShieldCopy.make(context: context, language: language)
                        XCTAssertLessThanOrEqual(copy.title.count, 28, copy.title)
                    }
                }
            }
        }
    }

    /// The launch sky (the first 100 ms) and the cloud curtain with its
    /// honest line (after two seconds of loading).
    @MainActor
    func testRenderTheLaunchScreen() async throws {
        let sky = try makeWindow(AnyView(LaunchCurtain(isReady: false)), style: .light)
        try await Task.sleep(for: .milliseconds(60))
        try capture(sky, name: "20-launch-sky")
        try await Task.sleep(for: .milliseconds(2600))
        try capture(sky, name: "21-launch-curtain-and-line")
        tearDown(sky)
    }

    // MARK: Hosting

    @MainActor
    private func makeWindow(_ view: AnyView, style: UIUserInterfaceStyle) throws -> UIWindow {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = style
        window.rootViewController = UIHostingController(rootView: view)
        window.windowLevel = .alert + 3
        window.makeKeyAndVisible()
        return window
    }

    @MainActor
    private func capture(_ window: UIWindow, name: String) throws {
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
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
    }

    @MainActor
    private func tearDown(_ window: UIWindow) {
        window.isHidden = true
        window.rootViewController = nil
    }

    private func outputFolder() -> URL {
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
    }
}
