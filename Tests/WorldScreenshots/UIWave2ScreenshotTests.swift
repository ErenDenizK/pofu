import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// UI v3 wave 2 proof (docs/design/ui-v3.md section 6): the station sheet,
/// Today and Settings, each in day, night and at accessibility text size.
/// The station sheet is hosted at the medium detent's height (42 % of the
/// screen) to prove nothing clips there.
final class UIWave2ScreenshotTests: XCTestCase {
    @MainActor
    func testRenderTodaySettingsAndTheStationSheet() async throws {
        let model = AppModel.shared
        let world = IslandSamples.dayThree()
        let status = world.stations.first { $0.id == .teaStall }
        let short = world.stations.first { $0.id == .garden }

        var shots: [(String, UIUserInterfaceStyle, DynamicTypeSize, AnyView)] = [
            ("15-menu-today-v3-day", .light, .large, AnyView(TodaySheet(model: model, hourOverride: 11))),
            ("15-menu-today-v3-night", .dark, .large, AnyView(TodaySheet(model: model, hourOverride: 22))),
            ("15-menu-today-v3-xxl", .light, .accessibility2, AnyView(TodaySheet(model: model, hourOverride: 18))),
            ("16-menu-settings-v3-day", .light, .large, AnyView(SettingsView(model: model))),
            ("16-menu-settings-v3-night", .dark, .large, AnyView(SettingsView(model: model))),
            ("16-menu-settings-v3-xxl", .light, .accessibility2, AnyView(SettingsView(model: model))),
        ]
        for (name, night, size) in [("day", false, DynamicTypeSize.large), ("night", true, .large), ("xxl", false, .accessibility2)] {
            for (detent, fraction) in [("medium", 0.42), ("large", 0.9)] {
                shots.append((
                    "17-sheet-station-v3-\(name)-\(detent)",
                    night ? .dark : .light,
                    size,
                    AnyView(SheetFrame(fraction: fraction, night: night) {
                        StationSheet(station: .teaStall, status: status, jar: Energy(1), onBuild: { _ in }, onClose: {})
                    })
                ))
            }
        }
        shots.append((
            "17-sheet-station-v3-day-ready-medium", .light, .large,
            AnyView(SheetFrame(fraction: 0.42, night: false) {
                StationSheet(station: .garden, status: short, jar: world.jar, onBuild: { _ in }, onClose: {})
            })
        ))
        for (name, style, size, view) in shots {
            let window = try makeWindow(AnyView(view.dynamicTypeSize(size)), style: style)
            try await Task.sleep(for: .milliseconds(900))
            try capture(window, name: name)
            window.isHidden = true
            window.rootViewController = nil
            try await Task.sleep(for: .milliseconds(150))
        }
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

    private func outputFolder() -> URL {
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
    }
}

/// A sheet's paper at a detent's height, at the bottom of the screen over
/// a dimmed backdrop.
private struct SheetFrame<Content: View>: View {
    let fraction: Double
    let night: Bool
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.35).ignoresSafeArea()
                ZStack(alignment: .top) {
                    PofuPaperSheetBackground()
                    Capsule().fill(Color.gray.opacity(0.5)).frame(width: 36, height: 5).padding(.top, 6)
                    content.padding(.top, 14)
                }
                .frame(height: proxy.size.height * fraction)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
            }
        }
        .pofuNight(night)
        .environment(\.colorScheme, night ? .dark : .light)
    }
}
