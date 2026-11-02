import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Look review shots, round 2:
///
/// - `look-compare`: day, golden hour, night and unwell at Home and at the
///   Island (the `grade-*` frames, measured by `tools/assets/frame_metrics.py`);
/// - `look-grades`: night and unwell before (round 1's grades) and after;
/// - `look-teapot`: the çay ocağı before and after its harmony correction;
/// - `look-motion`: six frames of a Home → Island flight with depth in
///   motion, over the same frames without it;
/// - `look-celebration-card` and `frame-times.txt`.
final class LookScreenshotTests: XCTestCase {
    private struct Shot {
        var id: String
        var title: String
        var look: WorldLook
        var wellbeing: Double = 78
    }

    /// Round 1's grades, kept here only to render the before frames.
    private static let round1Night = WorldGrade(
        lift: GradeRGB(0, 0.02, 0.06),
        gamma: GradeRGB(0.92, 0.95, 1),
        gain: GradeRGB(0.46, 0.53, 0.76),
        contrast: 1.04,
        pivot: 0.4,
        saturation: 0.72,
        vignette: 0.40
    )
    private static let round1Unwell = WorldGrade.day.layered(
        with: WorldGrade(lift: GradeRGB(0.02, 0.02, 0.025), gain: GradeRGB(0.97, 0.97, 0.98), contrast: 0.94, saturation: 0.72, vignette: 0.22),
        amount: 1
    )

    private let grades: [Shot] = [
        Shot(id: "grade-day", title: "Day", look: WorldLook(hourOverride: 12)),
        Shot(id: "grade-golden", title: "Golden hour", look: WorldLook(hourOverride: 18.5)),
        Shot(id: "grade-night", title: "Night", look: WorldLook(hourOverride: 22)),
        Shot(id: "grade-unwell", title: "Unwell (day)", look: WorldLook(hourOverride: 12), wellbeing: 25),
    ]

    private let befores: [Shot] = [
        Shot(id: "grade-night-r1", title: "Night, round 1", look: WorldLook(hourOverride: 22, gradeOverride: LookScreenshotTests.round1Night)),
        Shot(id: "grade-unwell-r1", title: "Unwell, round 1", look: WorldLook(hourOverride: 12, gradeOverride: LookScreenshotTests.round1Unwell), wellbeing: 25),
    ]

    private func world(wellbeing: Double) -> WorldSnapshot {
        IslandSamples.world(
            clock: Date(timeIntervalSinceReferenceDate: 815_000_000),
            tendedDays: 4,
            levels: [.garden: 2, .cay: 1],
            jar: Energy(60),
            islands: [.aycicegi, .iskele],
            wellbeing: wellbeing
        )
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
        for shot in grades + befores {
            for framing in [WorldFraming.home, .island] {
                let model = IslandSceneModel(framing: framing)
                let view = LookScene(world: world(wellbeing: shot.wellbeing), model: model).environment(\.worldLook, shot.look)
                let image = try await render(AnyView(view), in: scene, settle: 1400)
                let name = "\(shot.id)-\(framing == .home ? "home" : "island")"
                try write(image, name: name, to: folder)
                shots[name] = image
            }
        }
        let rows = ["home", "island"]
        try write(
            grid(rows.map { r in grades.map { shots["\($0.id)-\(r)"]! } },
                 titles: rows.map { r in grades.map { "\($0.title) · \(r == "home" ? "Home" : "Island")" } }),
            name: "look-compare", to: folder
        )
        let pairs = [befores[0], grades[2], befores[1], grades[3]]
        try write(
            grid(rows.map { r in pairs.map { shots["\($0.id)-\(r)"]! } },
                 titles: rows.map { r in pairs.map { "\($0.title == "Night" ? "Night, round 2" : $0.title == "Unwell (day)" ? "Unwell, round 2" : $0.title) · \(r == "home" ? "Home" : "Island")" } }),
            name: "look-grades", to: folder
        )

        try await renderTeapot(in: scene, folder: folder)
        try await renderMotion(in: scene, folder: folder)

        // The painted celebration card over the world (system UI is glass,
        // celebration is painted).
        let card = ZStack {
            LookScene(world: IslandSamples.dayThree(), model: IslandSceneModel(framing: .island))
                .environment(\.worldLook, WorldLook(hourOverride: 12))
            CelebrationCard(kicker: "Yeni seviye", title: "Çay ocağı 2", detail: "Mochi bir tabure daha getirdi.")
        }
        try write(try await render(AnyView(card), in: scene, settle: 1400), name: "look-celebration-card", to: folder)

        try await measureFrameTimes(in: scene, folder: folder)
    }

    // MARK: - The teapot, before and after harmony

    @MainActor
    private func renderTeapot(in scene: UIWindowScene, folder: URL) async throws {
        var crops: [UIImage] = []
        for art in [WorldLook.ArtSet.unharmonized, .lockLight] {
            let model = IslandSceneModel(framing: .island)
            let look = WorldLook(art: art, hd2d: false, hourOverride: 12)
            let image = try await render(AnyView(LookScene(world: world(wellbeing: 78), model: model).environment(\.worldLook, look)), in: scene, settle: 1400)
            let rail = CameraRail(width: Double(image.size.width), height: Double(image.size.height))
            let pose = rail.pose(of: .island)
            let cay = try XCTUnwrap(IslandLayout.stationAnchors[.cay])
            let p = pose.project(cay, width: rail.width)
            let s = pose.scale
            let box = CGRect(x: p.x - 62 * s, y: p.y - 82 * s, width: 124 * s, height: 108 * s)
            crops.append(crop(image, to: box))
        }
        try write(
            grid([crops], titles: [["Çaydanlık before harmony (rose copper)", "After harmony (warm copper)"]], cell: CGSize(width: 372, height: 324)),
            name: "look-teapot", to: folder
        )
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
