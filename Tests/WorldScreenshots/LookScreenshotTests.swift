import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Look review shots, round 3 (the large plate, the colour script, the
/// composed far sky):
///
/// - `look-compare`: day, golden hour, night and unwell at Home and at the
///   Island with the real art (the `grade-*` frames, measured by
///   `tools/assets/frame_metrics.py`, with `frame-regions.json` naming where
///   the island and the characters are in each frame);
/// - `look-script`: the colour script's five hour cells at Home and at the
///   Island (the art director's strip);
/// - `look-teapot`: the çaydanlık's original rose copper, round 2's warm
///   shift and the colour script's rose lit by the ember, by day and night;
/// - `look-motion`: six frames of a Home → Island flight with depth in
///   motion, over the same frames without it;
/// - `look-pan`: a pan from the garden's focus to the çay ocağı's with depth
///   in motion (parallax across the island), over the same frames without;
/// - `look-celebration-card` and `frame-times.txt`.
///
/// The framing before/after sheet is drawn by CI from round 2's published
/// frames and these (`tools/assets/framing_sheet.py`).
final class LookScreenshotTests: XCTestCase {
    private struct Shot {
        var id: String
        var title: String
        var look: WorldLook
        var wellbeing: Double = 78
    }

    private let grades: [Shot] = [
        Shot(id: "grade-day", title: "Day", look: WorldLook(hourOverride: 12)),
        Shot(id: "grade-golden", title: "Golden hour", look: WorldLook(hourOverride: 18.5)),
        Shot(id: "grade-night", title: "Night", look: WorldLook(hourOverride: 22)),
        Shot(id: "grade-unwell", title: "Unwell (day)", look: WorldLook(hourOverride: 12), wellbeing: 25),
    ]

    /// The colour script's cells, at an hour inside each.
    private let script: [Shot] = [
        Shot(id: "script-dawn", title: "Dawn", look: WorldLook(hourOverride: 6.25)),
        Shot(id: "script-day", title: "Day", look: WorldLook(hourOverride: 12)),
        Shot(id: "script-golden", title: "Golden", look: WorldLook(hourOverride: 18.5)),
        Shot(id: "script-dusk", title: "Dusk", look: WorldLook(hourOverride: 20)),
        Shot(id: "script-night", title: "Night", look: WorldLook(hourOverride: 22)),
    ]

    private func world(wellbeing: Double) -> WorldSnapshot {
        IslandSamples.grownIsland(wellbeing: wellbeing)
    }

    @MainActor
    func testRenderTheLooks() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        // The grades, at Home and at the Island.
        var shots: [String: UIImage] = [:]
        var regions: [String: Any] = [:]
        for shot in grades + script {
            for framing in [WorldFraming.home, .island] {
                let model = IslandSceneModel(framing: framing)
                let view = LookScene(world: world(wellbeing: shot.wellbeing), model: model).environment(\.worldLook, shot.look)
                let image = try await render(AnyView(view), in: scene, settle: 1400)
                let name = "\(shot.id)-\(framing == .home ? "home" : "island")"
                if shot.id.hasPrefix("grade-") {
                    try write(image, name: name, to: folder)
                    regions[name] = frameRegions(framing: framing, size: image.size)
                }
                shots[name] = image
            }
        }
        let rows = ["home", "island"]
        try write(
            grid(rows.map { r in grades.map { shots["\($0.id)-\(r)"]! } },
                 titles: rows.map { r in grades.map { "\($0.title) · \(r == "home" ? "Home" : "Island")" } }),
            name: "look-compare", to: folder
        )
        try write(
            grid(rows.map { r in script.map { shots["\($0.id)-\(r)"]! } },
                 titles: rows.map { r in script.map { "\($0.title) · \(r == "home" ? "Home" : "Island")" } }),
            name: "look-script", to: folder
        )
        let json = try JSONSerialization.data(withJSONObject: regions, options: [.prettyPrinted, .sortedKeys])
        try json.write(to: folder.appendingPathComponent("frame-regions.json"))

        try await renderTeapot(in: scene, folder: folder)
        try await renderMotion(in: scene, folder: folder)
        try await renderPan(in: scene, folder: folder)

        // The painted celebration card over the world (system UI is glass,
        // celebration is painted).
        let card = ZStack {
            LookScene(world: world(wellbeing: 78), model: IslandSceneModel(framing: .island))
                .environment(\.worldLook, WorldLook(hourOverride: 12))
            CelebrationCard(kicker: "Yeni seviye", title: "Çay ocağı 3", detail: "Mochi bir tabure daha getirdi.")
        }
        try write(try await render(AnyView(card), in: scene, settle: 1400), name: "look-celebration-card", to: folder)

        try await measureFrameTimes(in: scene, folder: folder)
    }

    // MARK: - Where things are in a frame

    /// The island's rows and every character's box in a frame, in unit
    /// coordinates (x0, y0, x1, y1), for `frame_metrics.py`.
    private func frameRegions(framing: WorldFraming, size: CGSize) -> [String: Any] {
        let rail = CameraRail(width: Double(size.width), height: Double(size.height))
        let pose = rail.pose(of: framing)
        func unit(_ box: WorldBox) -> [Double] {
            let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: rail.width)
            let b = pose.project(WorldPoint(x: box.maxX, y: box.maxY), width: rail.width)
            return [a.x / rail.width, a.y / rail.height, b.x / rail.width, b.y / rail.height].map { min(max($0, 0), 1) }
        }
        var characters: [String: [Double]] = ["pofu": unit(IslandFraming.pofuBox)]
        for resident in IslandLayout.residents {
            characters[resident.id.rawValue] = unit(IslandFraming.residentBox(resident))
        }
        return [
            "island": unit(IslandFraming.islandBox),
            "topBand": IslandFraming.topBand / CameraRail.referenceHeight,
            "characters": characters,
        ]
    }

    // MARK: - The teapot: rose, round 2's warm, the colour script

    @MainActor
    private func renderTeapot(in scene: UIWindowScene, folder: URL) async throws {
        let variants: [(String, WorldLook.ArtSet, Bool)] = [
            ("original rose copper", .lockLight, false),
            ("round 2: warm shift", .round2Copper, false),
            ("colour script: rose, lit by the ember", .lockLight, true),
        ]
        var rows: [[UIImage]] = []
        var titles: [[String]] = []
        for (hour, label) in [(12.0, "day"), (22.0, "night")] {
            var row: [UIImage] = []
            var rowTitles: [String] = []
            for (title, art, lit) in variants {
                let model = IslandSceneModel(framing: .island)
                model.holdStationPan(from: .cay, to: .cay, at: 0)
                // "Unlit" shows the paint under the hour's grade only; "lit"
                // adds the colour script's practical light (HD-2D layers).
                let look = WorldLook(art: art, hd2d: lit, depthMotion: false, hourOverride: hour)
                let image = try await render(AnyView(LookScene(world: world(wellbeing: 78), model: model, picker: false).environment(\.worldLook, look)), in: scene, settle: 1400)
                // The held focus pose, as the scene drew it.
                let cay = try XCTUnwrap(IslandFraming.stationBox(.cay))
                let a = model.screenPoint(of: WorldPoint(x: cay.minX - 4, y: cay.minY - 4))
                let b = model.screenPoint(of: WorldPoint(x: cay.maxX + 4, y: cay.maxY + 4))
                row.append(crop(image, to: CGRect(x: a.x, y: a.y, width: b.x - a.x, height: b.y - a.y)))
                rowTitles.append("\(label): \(title)")
            }
            rows.append(row)
            titles.append(rowTitles)
        }
        try write(grid(rows, titles: titles, cell: CGSize(width: 372, height: 330)), name: "look-teapot", to: folder)
    }

    private func crop(_ image: UIImage, to rect: CGRect) -> UIImage {
        let k = image.scale
        let px = CGRect(x: rect.minX * k, y: rect.minY * k, width: rect.width * k, height: rect.height * k).integral
        guard let cg = image.cgImage?.cropping(to: px) else { return image }
        return UIImage(cgImage: cg, scale: k, orientation: .up)
    }

    // MARK: - Depth in motion

    @MainActor
    private func renderMotion(in scene: UIWindowScene, folder: URL) async throws {
        let times = [0.0, 0.12, 0.24, 0.36, 0.5, 2.0]
        var rows: [[UIImage]] = []
        var titles: [[String]] = []
        for depth in [true, false] {
            var row: [UIImage] = []
            var rowTitles: [String] = []
            for t in times {
                let model = IslandSceneModel(framing: .home)
                model.holdFlight(from: .home, to: .island, at: t)
                let look = WorldLook(depthMotion: depth, hourOverride: 12)
                let image = try await render(AnyView(LookScene(world: world(wellbeing: 78), model: model).environment(\.worldLook, look)), in: scene, settle: 1200)
                row.append(image)
                var rig = CameraRig(framing: .home)
                rig.fly(to: .island)
                var elapsed = 0.0
                while elapsed + 1e-9 < t {
                    rig.advance(1.0 / 120)
                    elapsed += 1.0 / 120
                }
                let speed = rig.motion.speed
                rowTitles.append(String(format: "%@ t %.2f s · speed %.2f", depth ? "depth on" : "depth off", t, speed))
                if depth {
                    try write(image, name: String(format: "motion-%.2f", t), to: folder)
                }
            }
            rows.append(row)
            titles.append(rowTitles)
        }
        try write(grid(rows, titles: titles, cell: CGSize(width: 201, height: 437)), name: "look-motion", to: folder)
    }

    /// A pan across the island, from the garden's focus (left tip) to the
    /// çay ocağı's (right tip): the near and far layers slide past each
    /// other while the camera moves and settle into the authored frame.
    @MainActor
    private func renderPan(in scene: UIWindowScene, folder: URL) async throws {
        let times = [0.0, 0.15, 0.3, 0.45, 0.7, 2.0]
        var rows: [[UIImage]] = []
        var titles: [[String]] = []
        for depth in [true, false] {
            var row: [UIImage] = []
            var rowTitles: [String] = []
            for t in times {
                let model = IslandSceneModel(framing: .island)
                model.holdStationPan(from: .garden, to: .cay, at: t)
                let look = WorldLook(depthMotion: depth, hourOverride: 12)
                let image = try await render(AnyView(LookScene(world: world(wellbeing: 78), model: model, picker: false).environment(\.worldLook, look)), in: scene, settle: 1200)
                row.append(image)
                rowTitles.append(String(format: "%@ t %.2f s", depth ? "depth on" : "depth off", t))
            }
            rows.append(row)
            titles.append(rowTitles)
        }
        try write(grid(rows, titles: titles, cell: CGSize(width: 201, height: 437)), name: "look-pan", to: folder)
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
            ("look on, depth in motion off (grade + HD-2D lite), golden hour", WorldLook(depthMotion: false, hourOverride: 18.5)),
            ("look on (grade + HD-2D lite + depth in motion), golden hour", WorldLook(hourOverride: 18.5)),
        ]
        for (label, look) in looks {
            let model = IslandSceneModel(framing: .island)
            let view = LookScene(world: IslandSamples.grownIsland(), model: model, still: false).environment(\.worldLook, look)
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
        format.scale = 1.5
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor(white: 0.95, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: cell.width < 300 ? 11 : 17, weight: .semibold),
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

/// The scene with the framing control and a bubble; still frames stop
/// the clouds and blinks for comparable shots (not for frame times).
private struct LookScene: View {
    let world: WorldSnapshot
    let model: IslandSceneModel
    var still = true
    /// The framing control (off for crops and pans).
    var picker = true

    var body: some View {
        ZStack(alignment: .top) {
            IslandScene(world: world, model: model) {
                SpeechBubble {
                    Text(verbatim: "Sen yokken bahçe 12 çekirdek topladı.")
                }
            }
            if picker {
                FramingPicker(model: model)
                    .padding(.top, 8)
            }
        }
        .environment(\.worldStillFrame, still)
    }
}
