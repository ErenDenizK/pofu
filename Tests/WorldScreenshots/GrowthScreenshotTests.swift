import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Home growth seen level by level (tracker, "Half-finished", item 4):
///
/// - `home-il01` to `home-il10`: Home at noon at each island level, every
///   open station built to the cap of that level, and only the islands and
///   residents that have arrived by then (İskele from island level 3;
///   Mochi at the çay ocağı and Fındık at the workshop appear with their
///   stations);
/// - `home-growth-il1-il10`: all ten on one sheet, two rows of five, each
///   titled with its island level, station cap and tended-day floor.
///
/// The worlds are `IslandSamples.world`, read through the standard catalog,
/// so costs, caps and slots are the real ones. This answers "does every
/// level visibly change?" and "is island level 1 sparse?".
final class GrowthScreenshotTests: XCTestCase {
    private let clock = Date(timeIntervalSinceReferenceDate: 815_000_000)

    /// The world at island level `level`: every station whose slot is open
    /// is built to that level's cap (or its own top level).
    private func world(atIslandLevel level: Int) -> WorldSnapshot {
        let catalog = ArchipelagoCatalog.standard
        let cap = catalog.stationCap(atIslandLevel: level)
        let islands: [IslandID] = level >= 3 ? [.home, .harbor] : [.home]
        var levels: [StationID: Int] = [:]
        for spec in catalog.stations where islands.contains(spec.island) && spec.opensAt <= level {
            levels[spec.id] = min(cap, spec.maxLevel)
        }
        let floor = catalog.islandLevelRule(level)?.tendedDayFloor ?? 1
        return IslandSamples.world(
            clock: clock, tendedDays: floor, levels: levels, jar: IslandSamples.midWeekJar,
            islands: islands, islandLevel: level, wellbeing: 90, isBedtime: false
        )
    }

    @MainActor
    func testRenderHomeGrowthFromIslandLevelOneToTen() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let catalog = ArchipelagoCatalog.standard

        var shots: [UIImage] = []
        var titles: [String] = []
        for level in 1...10 {
            let snapshot = world(atIslandLevel: level)
            let image = try await render(snapshot, in: scene)
            try write(image, name: String(format: "home-il%02d", level), to: folder)
            shots.append(image)
            let rule = catalog.islandLevelRule(level)
            let built = snapshot.stations.reduce(0) { $0 + $1.level }
            titles.append("IL\(level) · cap \(rule?.stationCap ?? 0) · \(built) levels · day \(rule?.tendedDayFloor ?? 0)")
        }
        let rows = [Array(shots[0..<5]), Array(shots[5..<10])]
        let rowTitles = [Array(titles[0..<5]), Array(titles[5..<10])]
        try write(grid(rows, titles: rowTitles), name: "home-growth-il1-il10", to: folder)
    }

    // MARK: - Rendering

    @MainActor
    private func render(_ world: WorldSnapshot, in scene: UIWindowScene) async throws -> UIImage {
        let model = IslandSceneModel(framing: .home)
        let view = IslandScene(world: world, model: model)
            .environment(\.worldLook, WorldLook(hourOverride: 12))
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
