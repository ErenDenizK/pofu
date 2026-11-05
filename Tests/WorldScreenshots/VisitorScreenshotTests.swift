import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Wave 2's visitors and the lawn's life (experience v1 §5, §6), on screen
/// with the code-drawn stand-ins that the Codex art will replace by name:
///
/// - `visitor-v1-day`: the daily visitor at the front-lip spot V1 before the
///   harbor, with the gift parcel beside them;
/// - `visitor-h4-night` (and `visitor-h4-night-off` for comparison): the
///   guest room's window lit on a stay-over night;
/// - `visitor-quiet-day`: the quiet day's letter at V1;
/// - `dressing-il1` and `dressing-il6`: the dressing and the critters at
///   island levels 1 and 6, at Home and at the Island, by day.
///
/// PNGs go to `WORLD_SCREENSHOTS_DIR` like the other shots.
final class VisitorScreenshotTests: XCTestCase {
    private let clock = Date(timeIntervalSinceReferenceDate: 815_000_000)

    /// A world at an island level with the stations the level has opened.
    private func world(level: Int, bedtime: Bool = false) -> WorldSnapshot {
        let levels: [StationID: Int]
        switch level {
        case ...1: levels = [.garden: 1]
        case 2...3: levels = [.garden: 2, .teaStall: 1]
        default: levels = [.garden: 3, .teaStall: 2, .pond: 2, .workshop: 1]
        }
        return IslandSamples.world(
            clock: clock, tendedDays: level * 10, levels: levels, jar: IslandSamples.midWeekJar,
            islands: level >= 3 ? [.home, .harbor] : [.home], islandLevel: level, isBedtime: bedtime
        )
    }

    @MainActor
    func testRenderTheVisitorsAndTheLawnsLife() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        // The visitor at V1 by day, the parcel beside them, the camera on the spot.
        var day = world(level: 2)
        day.visitor = VisitorSnapshot(
            resident: .sumi, reason: .gift, slot: .v1, state: .present, gift: .seeds(3), hearts: 1
        )
        let v1Model = IslandSceneModel(framing: .island)
        v1Model.holdPan(start: IslandFraming.panValue(lookX: VisitorSlots.v1.x))
        try write(try await render(day, model: v1Model, hour: 12, in: scene), name: "visitor-v1-day", to: folder)

        // A help visit: the kite that needs a tap stands beside the visitor.
        var help = world(level: 2)
        help.visitor = VisitorSnapshot(resident: .damla, reason: .help, slot: .v1, state: .present)
        let helpModel = IslandSceneModel(framing: .island)
        helpModel.holdPan(start: IslandFraming.panValue(lookX: VisitorSlots.v1.x))
        try write(try await render(help, model: helpModel, hour: 12, in: scene), name: "visitor-v1-help", to: folder)

        // The quiet day's letter at V1.
        var quiet = world(level: 5)
        quiet.invitationOpen = true
        quiet.metResidents = [.sumi, .damla]
        let quietModel = IslandSceneModel(framing: .island)
        quietModel.holdPan(start: IslandFraming.panValue(lookX: VisitorSlots.v1.x))
        try write(try await render(quiet, model: quietModel, hour: 12, in: scene), name: "visitor-quiet-day", to: folder)

        // H4 lit at night when somebody stays over; dark otherwise.
        var night = world(level: 5, bedtime: true)
        night.visitor = VisitorSnapshot(resident: .boncuk, reason: .stayOver, slot: .h4, state: .present)
        let lit = try await render(night, model: IslandSceneModel(framing: .home), hour: 22, in: scene)
        var dark = world(level: 5, bedtime: true)
        dark.visitor = nil
        let off = try await render(dark, model: IslandSceneModel(framing: .home), hour: 22, in: scene)
        try write(lit, name: "visitor-h4-night", to: folder)
        try write(off, name: "visitor-h4-night-off", to: folder)

        // The dressing and the critters at IL1 and IL6.
        for level in [1, 6] {
            let w = world(level: level)
            let home = try await render(w, model: IslandSceneModel(framing: .home), hour: 12, in: scene)
            let islandModel = IslandSceneModel(framing: .island)
            islandModel.holdEstablishingShot()
            let island = try await render(w, model: islandModel, hour: 12, in: scene)
            try write(home, name: "dressing-il\(level)-home", to: folder)
            try write(island, name: "dressing-il\(level)-island", to: folder)
            try write(
                grid([[home, island]], titles: [["IL\(level) · Home", "IL\(level) · Island"]]),
                name: "dressing-il\(level)", to: folder
            )
        }
    }

    // MARK: - Rendering

    @MainActor
    private func render(_ world: WorldSnapshot, model: IslandSceneModel, hour: Double, in scene: UIWindowScene) async throws -> UIImage {
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
