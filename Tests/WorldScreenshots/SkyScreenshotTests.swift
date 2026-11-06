import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Sky and fog review shots (sky and weather v1 §2.1, §2.3, §2.4; PR SW-3):
///
/// - `sky-home-0700`, `-1200`, `-1830`, `-2230`: Home at the four hours
///   (three cloud layers, luminous night with the moon's halo and stars,
///   depth fog on the far isles, height fog at the cloud-sea line);
/// - `sky-island-<hour>`: the same hours at the Island framing, where the
///   sea climbs to the island's roots;
/// - `koke-stage0-<hour>`: Koke at stage 0 (fog, one warm shaft on the
///   sprout, a cooler shade), and `koke-stage2-1200` for the fade;
/// - `sky-fog-sheet`: all of them on one sheet.
final class SkyScreenshotTests: XCTestCase {
    private let clock = Date(timeIntervalSinceReferenceDate: 815_000_000)
    private let hours: [(id: String, hour: Double, title: String)] = [
        ("0700", 7, "07:00"), ("1200", 12, "12:00"), ("1830", 18.5, "18:30"), ("2230", 22.5, "22:30"),
    ]

    private func kokeWorld(stage: Int) -> WorldSnapshot {
        var world = IslandSamples.world(
            clock: clock, tendedDays: 12, levels: [.garden: 3, .teaStall: 2, .pond: 2, .workshop: 1],
            jar: IslandSamples.midWeekJar, islands: [.home, .harbor], islandLevel: 5, isBedtime: false
        )
        world.koke = WonderStatus(phase: .arrived, stage: stage, canAdvance: stage < 4)
        return world
    }

    @MainActor
    func testRenderTheSkyAndFog() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        var rows: [[UIImage]] = [[], [], []]
        var titles: [[String]] = [[], [], []]
        for (id, hour, title) in hours {
            let home = try await render(IslandSamples.grownIsland(wellbeing: 78), framing: .home, hour: hour, in: scene)
            try write(home, name: "sky-home-\(id)", to: folder)
            rows[0].append(home)
            titles[0].append("Home \(title)")

            let island = try await render(IslandSamples.grownIsland(wellbeing: 78), framing: .island, hour: hour, in: scene)
            try write(island, name: "sky-island-\(id)", to: folder)
            rows[1].append(island)
            titles[1].append("Island \(title)")

            let koke = try await render(kokeWorld(stage: 0), framing: .island, hour: hour, isle: .koke, in: scene)
            try write(koke, name: "koke-stage0-\(id)", to: folder)
            rows[2].append(koke)
            titles[2].append("Koke stage 0 \(title)")
        }
        try write(try await render(kokeWorld(stage: 2), framing: .island, hour: 12, isle: .koke, in: scene), name: "koke-stage2-1200", to: folder)
        try write(grid(rows, titles: titles), name: "sky-fog-sheet", to: folder)
    }

    // MARK: - Rendering

    @MainActor
    private func render(_ world: WorldSnapshot, framing: WorldFraming, hour: Double, isle: IslandID? = nil, in scene: UIWindowScene) async throws -> UIImage {
        let model = IslandSceneModel(framing: framing)
        if let isle {
            model.holdIsle(isle)
        }
        let view = IslandScene(world: world, model: model)
            .environment(\.worldLook, WorldLook(hourOverride: hour))
            .environment(\.worldStillFrame, true)
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
