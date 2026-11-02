import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Look-dev review shots (decisions A, B, C): the same scene and framing
/// under each look, at Home and at the Island, a side-by-side grid
/// (`look-compare`), and frame times with the look off and on
/// (`frame-times.txt`).
final class LookScreenshotTests: XCTestCase {
    private struct Variant {
        var id: String
        var title: String
        var look: WorldLook
        var wellbeing: Double = 78
    }

    private let variants: [Variant] = [
        Variant(id: "1-softlock", title: "1 · soft-lock, no grade", look: .legacy.with(hour: 12)),
        Variant(id: "2-lightlock-day", title: "2 · lock-light + day grade",
                look: WorldLook(grade: true, hd2d: false, terrarium: false, hourOverride: 12)),
        Variant(id: "3-hd2d-golden", title: "3 · + HD-2D lite, golden hour",
                look: WorldLook(grade: true, hd2d: true, terrarium: false, hourOverride: 18.5)),
        Variant(id: "4-hd2d-night", title: "4 · + HD-2D lite, night",
                look: WorldLook(grade: true, hd2d: true, terrarium: false, hourOverride: 22)),
        Variant(id: "5-unwell", title: "5 · unwell grade (day)",
                look: WorldLook(grade: true, hd2d: true, terrarium: false, hourOverride: 12), wellbeing: 25),
        Variant(id: "6-terrarium", title: "6 · + terrarium rim (day)",
                look: WorldLook(grade: true, hd2d: true, terrarium: true, hourOverride: 12)),
    ]

    @MainActor
    func testRenderTheLooks() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        var grid: [[UIImage]] = [[], []]
        for (row, framing) in [WorldFraming.home, .island].enumerated() {
            for variant in variants {
                let world = IslandSamples.world(
                    clock: Date(timeIntervalSinceReferenceDate: 815_000_000),
                    tendedDays: 4,
                    levels: [.garden: 2, .cay: 1],
                    jar: Energy(60),
                    islands: [.aycicegi, .iskele],
                    wellbeing: variant.wellbeing
                )
                let model = IslandSceneModel(framing: framing)
                let view = LookScene(world: world, model: model).environment(\.worldLook, variant.look)
                let image = try await render(AnyView(view), in: scene, settle: 1400)
                let name = "look-\(variant.id)-\(framing == .home ? "home" : "island")"
                try write(image, name: name, to: folder)
                grid[row].append(image)
            }
        }
        try write(compare(grid), name: "look-compare", to: folder)

        // The painted celebration card over the world (system UI is glass,
        // celebration is painted).
        let card = ZStack {
            LookScene(world: IslandSamples.dayThree(), model: IslandSceneModel(framing: .island))
                .environment(\.worldLook, WorldLook(hourOverride: 12))
            CelebrationCard(kicker: "Yeni seviye", title: "Çay ocağı 2", detail: "Mochi bir tabure daha getirdi.")
        }
        try write(try await render(AnyView(card), in: scene, settle: 1400), name: "look-7-celebration-card", to: folder)

        try await measureFrameTimes(in: scene, folder: folder)
    }

    // MARK: - Frame times

    @MainActor
    private func measureFrameTimes(in scene: UIWindowScene, folder: URL) async throws {
        var lines = [
            "Frame times, \(UIDevice.current.model) simulator (\(UIDevice.current.systemVersion)).",
            "The simulator renders on the Mac's GPU: compare the rows with each other, not with a phone.",
            "GPU time is not readable in-app for SwiftUI; GPU-bound work shows as long frame intervals.",
            "",
        ]
        let looks: [(String, WorldLook)] = [
            ("look off (soft-lock, no grade)", .legacy),
            ("look on (grade + HD-2D lite + rim), golden hour", WorldLook(hourOverride: 18.5)),
        ]
        for (label, look) in looks {
            let model = IslandSceneModel(framing: .island)
            let view = LookScene(world: IslandSamples.dayThree(), model: model, still: false).environment(\.worldLook, look)
            let window = host(AnyView(view), in: scene)
            try await Task.sleep(for: .milliseconds(800))

            let meter = FrameMeter()
            meter.start()
            for target in [WorldFraming.home, .map, .island, .home, .island] {
                model.go(to: target)
                try await Task.sleep(for: .milliseconds(700))
            }
            let moving = meter.stop()

            // Let the visit end and the springs rest: the cached frame.
            try await Task.sleep(for: .seconds(LookTuning.visitSeconds + 1.5))
            meter.start()
            try await Task.sleep(for: .seconds(2))
            let rest = meter.stop()

            lines.append("\(label)")
            lines.append("  camera moving: \(moving)")
            lines.append("  settled:       \(rest)")
            window.isHidden = true
            window.rootViewController = nil
            try await Task.sleep(for: .milliseconds(150))
        }
        let text = lines.joined(separator: "\n") + "\n"
        try text.write(to: folder.appendingPathComponent("frame-times.txt"), atomically: true, encoding: .utf8)
        print(text)
    }

    // MARK: - Rendering

    @MainActor
    private func host(_ view: AnyView, in scene: UIWindowScene) -> UIWindow {
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: view)
        window.windowLevel = .alert + 3
        window.makeKeyAndVisible()
        return window
    }

    @MainActor
    private func render(_ view: AnyView, in scene: UIWindowScene, settle: Int) async throws -> UIImage {
        let window = host(view, in: scene)
        try await Task.sleep(for: .milliseconds(settle))
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

    /// Rows Home and Island, one column per variant, with titles.
    @MainActor
    private func compare(_ grid: [[UIImage]]) -> UIImage {
        let cell = CGSize(width: 402, height: 874)
        let pad: CGFloat = 16, label: CGFloat = 34
        let cols = grid.map(\.count).max() ?? 0
        let size = CGSize(
            width: pad + CGFloat(cols) * (cell.width + pad),
            height: pad + CGFloat(grid.count) * (cell.height + label + pad)
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
            for (r, row) in grid.enumerated() {
                for (c, image) in row.enumerated() {
                    let x = pad + CGFloat(c) * (cell.width + pad)
                    let y = pad + CGFloat(r) * (cell.height + label + pad)
                    let title = "\(variants[c].title) · \(r == 0 ? "Home" : "Island")"
                    (title as NSString).draw(at: CGPoint(x: x, y: y + 6), withAttributes: attrs)
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

/// The scene with the framing control and a bubble; still frames stop
/// the clouds and blinks for comparable shots (not for frame times).
private struct LookScene: View {
    let world: WorldSnapshot
    let model: IslandSceneModel
    var still = true

    var body: some View {
        ZStack(alignment: .top) {
            IslandScene(world: world, model: model) {
                SpeechBubble {
                    Text(verbatim: "Sen yokken bahçe 12 çekirdek topladı.")
                }
            }
            FramingPicker(model: model)
                .padding(.top, 8)
        }
        .environment(\.worldStillFrame, still)
    }
}

extension WorldLook {
    fileprivate func with(hour: Double) -> WorldLook {
        var copy = self
        copy.hourOverride = hour
        return copy
    }
}
