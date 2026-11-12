import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Çağlayan, the second wonder island (the waterfall frozen mid-air in the
/// noon sun):
///
/// - `caglayan-rumour-harbor`: Pofu's line at the harbor;
/// - `caglayan-stage-0` to `-4` and `caglayan-stages` (side by side): the
///   same camera, the water coming back; stage 4 pours off the underside;
/// - `caglayan-beat-3`: Mochi reads the mill's wall; `caglayan-beat-0`: Damla;
/// - `caglayan-plaque`: the "Akışı bağla" plaque on a day it can be played;
/// - `caglayan-night-0` and `-4`: the tiny light in the pool, out when healed;
/// - `caglayan-map`: the island on the Map;
/// - `caglayan-gift-home`: the pool fountain flowing at home on the day it
///   arrives, with its paper tag.
final class CaglayanScreenshotTests: XCTestCase {
    private let clock = Date(timeIntervalSinceReferenceDate: 815_000_000)

    private func world(caglayan: WonderStatus, level: Int = 5, pond: Int = 2) -> WorldSnapshot {
        var world = IslandSamples.world(
            clock: clock, tendedDays: 16, levels: [.garden: 3, .teaStall: 2, .pond: pond, .workshop: 1],
            jar: IslandSamples.midWeekJar, islands: [.home, .harbor], islandLevel: level, isBedtime: false
        )
        world.koke = WonderStatus(phase: .arrived, stage: 4)
        world.caglayan = caglayan
        return world
    }

    private func status(_ stage: Int, canAdvance: Bool? = nil) -> WonderStatus {
        WonderStatus(phase: .arrived, stage: stage, canAdvance: canAdvance ?? (stage < 4))
    }

    @MainActor
    func testRenderCaglayan() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let rumour = IslandSceneModel(framing: .island)
        rumour.holdIsle(.harbor)
        rumour.caglayan.show(.rumour)
        try write(try await render(world(caglayan: WonderStatus(phase: .rumoured)), model: rumour, in: scene), name: "caglayan-rumour-harbor", to: folder)

        var stages: [UIImage] = []
        for stage in 0...4 {
            let model = IslandSceneModel(framing: .island)
            model.holdIsle(.caglayan)
            let image = try await render(world(caglayan: status(stage, canAdvance: false)), model: model, in: scene)
            try write(image, name: "caglayan-stage-\(stage)", to: folder)
            stages.append(image)
        }
        try write(grid([stages], titles: [(0...4).map { "Çağlayan · stage \($0)" }]), name: "caglayan-stages", to: folder)

        for (stage, canAdvance) in [(0, false), (3, false)] {
            let beat = IslandSceneModel(framing: .island)
            beat.holdIsle(.caglayan)
            beat.caglayan.show(.stage(stage))
            try write(try await render(world(caglayan: status(stage, canAdvance: canAdvance)), model: beat, in: scene), name: "caglayan-beat-\(stage)", to: folder)
        }

        let plaque = IslandSceneModel(framing: .island)
        plaque.holdIsle(.caglayan)
        try write(try await render(world(caglayan: status(1, canAdvance: true)), model: plaque, in: scene), name: "caglayan-plaque", to: folder)

        for stage in [0, 4] {
            let night = IslandSceneModel(framing: .island)
            night.holdIsle(.caglayan)
            try write(try await render(world(caglayan: status(stage, canAdvance: false)), model: night, hour: 23, in: scene), name: "caglayan-night-\(stage)", to: folder)
        }

        let map = IslandSceneModel(framing: .map)
        try write(try await render(world(caglayan: status(2)), model: map, in: scene), name: "caglayan-map", to: folder)

        let home = IslandSceneModel(framing: .home)
        var arrived = status(4, canAdvance: false)
        arrived.giftIsNew = true
        try write(try await render(world(caglayan: arrived), model: home, in: scene), name: "caglayan-gift-home", to: folder)
        let island = IslandSceneModel(framing: .island)
        try write(try await render(world(caglayan: status(4, canAdvance: false)), model: island, in: scene), name: "caglayan-gift-island", to: folder)
    }

    // MARK: - Rendering

    @MainActor
    private func render(_ world: WorldSnapshot, model: IslandSceneModel, hour: Double = 12, in scene: UIWindowScene) async throws -> UIImage {
        let view = IslandScene(world: world, model: model)
            .environment(\.worldLook, WorldLook.islandStop(hour: hour))
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

    /// Images in a row, each with a title above it.
    @MainActor
    private func grid(_ rows: [[UIImage]], titles: [[String]], cell: CGSize = CGSize(width: 402, height: 874)) -> UIImage {
        let pad: CGFloat = 16, label: CGFloat = 34
        let cols = rows.map(\.count).max() ?? 0
        let size = CGSize(
            width: pad + CGFloat(cols) * (cell.width + pad),
            height: pad + CGFloat(rows.count) * (cell.height + label + pad)
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.5
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
