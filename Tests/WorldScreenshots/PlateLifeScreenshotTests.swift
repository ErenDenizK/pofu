import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// The plate's living layer (game solid v1, PR 6): what the game draws over the painted home plate by
/// day. Level 5, noon, clear, the settled frame at the simulator's full device resolution:
///
/// - `plate-life-visitor-l5`: a gift visit, the visitor on the lawn and the parcel beside them;
/// - `plate-life-gifts-l5`: Koke's moss on the lawn and Çağlayan's fountain over the pond;
/// - `plate-life-build-l5`: the tea stall's level-up at its burst (dust, light, "Seviye N!");
/// - `plate-life-greeted-l5`: the same visit just greeted, the heart over the visitor;
/// - `plate-life-gifts-new-l5`: both gifts on the day they arrive, each with its paper tag.
///
/// Each frame is also written as `home-plate-full-life-<name>-l5`, which CI keeps as a PNG, so
/// `tools/plate/harmony_check.py` can measure the characters beside the new layer.
final class PlateLifeScreenshotTests: XCTestCase {
    private enum Shot: String, CaseIterable {
        case visitor
        case gifts
        case build
        case greeted
        case giftsNew = "gifts-new"

        /// The shots the harmony check measures (`home-plate-full-life-*`).
        var isMeasured: Bool { [.visitor, .gifts, .build].contains(self) }
    }

    @MainActor
    func testRenderThePlatesLivingLayer() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for shot in Shot.allCases {
            let image = try await render(shot, in: scene)
            try write(image, name: "plate-life-\(shot.rawValue)-l5", to: folder)
            if shot.isMeasured {
                try write(image, name: "home-plate-full-life-\(shot.rawValue)-l5", to: folder, attach: false)
            }
        }
    }

    @MainActor
    private func render(_ shot: Shot, in scene: UIWindowScene) async throws -> UIImage {
        let now = Date(timeIntervalSinceReferenceDate: 815_000_000)
        var world = IslandSamples.world(
            clock: nil,
            tendedDays: 60,
            levels: [.garden: 5, .teaStall: 4, .pond: 5, .windmill: 5, .workshop: 5, .bagelCart: 5, .pier: 5, .lighthouse: 5],
            jar: Energy(214),
            islands: [.home, .harbor],
            islandLevel: 5,
            wellbeing: 84
        )
        switch shot {
        case .visitor:
            world.visitor = VisitorSnapshot(resident: .damla, reason: .gift, slot: .v1, state: .present, gift: .seeds(3), hearts: 1)
        case .gifts:
            world.koke = WonderStatus(phase: .arrived, stage: 4)
            world.caglayan = WonderStatus(phase: .arrived, stage: 4)
        case .build:
            break
        case .greeted:
            world.visitor = VisitorSnapshot(resident: .damla, reason: .gift, slot: .v1, state: .greeted, gift: .seeds(3), hearts: 1)
        case .giftsNew:
            world.koke = WonderStatus(phase: .arrived, stage: 4, giftIsNew: true)
            world.caglayan = WonderStatus(phase: .arrived, stage: 4, giftIsNew: true)
        }
        let island = IslandSceneModel(framing: .home)
        let home = WorldHomeModel(now: { now }, schedulesCues: false)
        if shot == .build {
            // The tea stall's fifth level; the burst of light is blooming 0.72 s in, the tag just in.
            home.buildStation(.teaStall, maxLevel: 5) { _ in BuildReceipt(station: .teaStall, level: 5, cost: Energy(80)) }
            home.freeze(at: 0.72)
        }
        var look = WorldLook(hourOverride: 12)
        look.weatherOverride = .clear
        let view = IslandScene(world: world, model: island, home: home)
            .environment(\.worldLook, look)
            .environment(\.worldStillFrame, true)

        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: AnyView(view))
        window.windowLevel = .alert + 4
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(1400))
        XCTAssertNotNil(island.homePlate, "the plate shows at level 5 by day in clear weather")
        try await Task.sleep(for: .milliseconds(900))
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

    private func write(_ image: UIImage, name: String, to folder: URL, attach: Bool = true) throws {
        let data = try XCTUnwrap(image.pngData())
        try data.write(to: folder.appendingPathComponent("\(name).png"))
        guard attach else { return }
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
