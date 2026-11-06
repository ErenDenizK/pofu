import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Weather and screen haze review shots (sky and weather v1 section 2.2, 2.2b; PR SW-2):
/// Home at noon in clear, overcast, light rain, mist, rainbow and golden haze
/// (golden haze at 18:30, its hour), the screen haze (wellbeing 28) and the
/// haze parted by a resisted reach, plus `weather-sheet` with all of them.
final class WeatherScreenshotTests: XCTestCase {
    private struct Shot {
        let id: String
        let title: String
        let hour: Double
        let weather: WeatherConditions
        var wellbeing: Double = 78
        var parted = false
    }

    private let shots: [Shot] = [
        Shot(id: "clear", title: "Clear", hour: 12, weather: .clear),
        Shot(id: "overcast", title: "Overcast", hour: 12, weather: WeatherConditions(weather: .overcast)),
        Shot(id: "rain", title: "Light rain", hour: 12, weather: WeatherConditions(weather: .lightRain)),
        Shot(id: "mist", title: "Mist 08:00", hour: 8, weather: WeatherConditions(weather: .mist)),
        Shot(id: "rainbow", title: "Rainbow", hour: 12.5, weather: WeatherConditions(weather: .clear, rainbow: true)),
        Shot(id: "golden-haze", title: "Golden haze 18:30", hour: 18.5, weather: WeatherConditions(weather: .goldenHaze)),
        Shot(id: "screen-haze", title: "Screen haze", hour: 12, weather: .clear, wellbeing: 28),
        Shot(id: "screen-haze-parted", title: "Haze parted", hour: 12, weather: .clear, wellbeing: 28, parted: true),
    ]

    @MainActor
    func testRenderTheWeather() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var images: [UIImage] = []
        var titles: [String] = []
        for shot in shots {
            let image = try await render(shot, in: scene)
            try write(image, name: "weather-home-\(shot.id)", to: folder)
            images.append(image)
            titles.append(shot.title)
        }
        let half = (images.count + 1) / 2
        try write(grid([Array(images[..<half]), Array(images[half...])], titles: [Array(titles[..<half]), Array(titles[half...])]), name: "weather-sheet", to: folder)
    }

    // MARK: - Rendering

    @MainActor
    private func render(_ shot: Shot, in scene: UIWindowScene) async throws -> UIImage {
        let model = IslandSceneModel(framing: .home)
        var look = WorldLook(hourOverride: shot.hour)
        look.weatherOverride = shot.weather
        let clearing = ScreenHazeClearing(partedAt: shot.parted ? Date().addingTimeInterval(-5) : nil)
        let view = IslandScene(world: IslandSamples.grownIsland(wellbeing: shot.wellbeing), model: model)
            .environment(\.worldLook, look)
            .environment(\.worldStillFrame, true)
            .environment(\.screenHazeClearing, clearing)
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: AnyView(view))
        window.windowLevel = .alert + 3
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(1400))
        let format = UIGraphicsImageRendererFormat()
        format.scale = window.traitCollection.displayScale
        format.opaque = true
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        window.rootViewController = nil
        try await Task.sleep(for: .milliseconds(150))
        return image
    }

    private func write(_ image: UIImage, name: String, to folder: URL) throws {
        let data = try XCTUnwrap(image.pngData())
        try data.write(to: folder.appendingPathComponent("\(name).png"))
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Images in rows, each with a title above it.
    @MainActor
    private func grid(_ rows: [[UIImage]], titles: [[String]], cell: CGSize = CGSize(width: 402, height: 874)) -> UIImage {
        let pad: CGFloat = 16, label: CGFloat = 34
        let cols = rows.map(\.count).max() ?? 0
        let size = CGSize(
            width: pad + CGFloat(cols) * (cell.width + pad),
            height: pad + CGFloat(rows.count) * (cell.height + label + pad)
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor(white: 0.95, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                .foregroundColor: UIColor(white: 0.15, alpha: 1),
            ]
            for (r, row) in rows.enumerated() {
                for (c, image) in row.enumerated() {
                    let x = pad + CGFloat(c) * (cell.width + pad)
                    let y = pad + CGFloat(r) * (cell.height + label + pad)
                    let title = r < titles.count && c < titles[r].count ? titles[r][c] : ""
                    (title as NSString).draw(at: CGPoint(x: x, y: y + 8), withAttributes: attrs)
                    image.draw(in: CGRect(x: x, y: y + label, width: cell.width, height: cell.height))
                }
            }
        }
    }

    private func outputFolder() -> URL {
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
    }
}
