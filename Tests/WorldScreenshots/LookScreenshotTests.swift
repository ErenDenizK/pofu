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
/// - `look-teapot`: the çaydanlık at level 1 unlit, lit by the ember, and
///   with tea-stall-1-lit's painted flame (look round 4), by day and night;
/// - `look-plates`: the shipped v3 plate and batch 03's v2, to choose;
/// - `look-motion`: six frames of a Home → Island flight with depth in
///   motion, over the same frames without it;
/// - `look-pan`: the Island pan (look round 4), a flick from Pofu toward
///   the çay ocağı coasting onto its snap point, depth in motion on and off;
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
        try await renderPlates(in: scene, folder: folder)

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

    /// Experience v1 §2.3's night shots: warm pools under the lantern and
    /// the door window at Home and at the Island (`light-night-*`), the
    /// lantern at calm x1.0 against x2.0 (`light-calm-compare`), and the
    /// dusk lights coming on (`light-dusk-*`).
    @MainActor
    func testRenderTheLightField() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        func shot(_ framing: WorldFraming, hour: Double, calm: Double = 1.7) async throws -> UIImage {
            var snapshot = world(wellbeing: 78)
            snapshot.calm = calm
            let model = IslandSceneModel(framing: framing)
            let view = LookScene(world: snapshot, model: model).environment(\.worldLook, WorldLook(hourOverride: hour))
            return try await render(AnyView(view), in: scene, settle: 1400)
        }

        let nightHome = try await shot(.home, hour: 22)
        let nightIsland = try await shot(.island, hour: 22)
        try write(nightHome, name: "light-night-home", to: folder)
        try write(nightIsland, name: "light-night-island", to: folder)
        let dim = try await shot(.home, hour: 22, calm: 1.0)
        let bright = try await shot(.home, hour: 22, calm: 2.0)
        try write(
            grid([[dim, bright]], titles: [["Calm x1.0", "Calm x2.0"]]),
            name: "light-calm-compare", to: folder
        )
        let duskHome = try await shot(.home, hour: 20)
        let duskIsland = try await shot(.island, hour: 20)
        try write(
            grid([[duskHome, duskIsland, nightHome, nightIsland]], titles: [["Dusk · Home", "Dusk · Island", "Night · Home", "Night · Island"]],
                 cell: CGSize(width: 201, height: 437)),
            name: "light-dusk-night", to: folder
        )
    }

    /// Light and shadow v2 (LS-1): Home at 07:00, 12:00, 18:30 and 22:30
    /// (`shadow-home-*` and the `shadow-times` sheet), and Pofu's close-up at
    /// the Island framing at noon and at 18:30 (`shadow-pofu-*`).
    @MainActor
    func testRenderTheSunShadows() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        func shot(_ framing: WorldFraming, hour: Double) async throws -> UIImage {
            let model = IslandSceneModel(framing: framing)
            let view = LookScene(world: world(wellbeing: 78), model: model).environment(\.worldLook, WorldLook(hourOverride: hour))
            return try await render(AnyView(view), in: scene, settle: 1400)
        }

        let times: [(String, Double, String)] = [("0700", 7, "07:00"), ("1200", 12, "12:00"), ("1830", 18.5, "18:30"), ("2230", 22.5, "22:30")]
        var homes: [UIImage] = []
        for (id, hour, _) in times {
            let image = try await shot(.home, hour: hour)
            try write(image, name: "shadow-home-\(id)", to: folder)
            homes.append(image)
        }
        try write(
            grid([homes], titles: [times.map { "Home · \($0.2)" }], cell: CGSize(width: 201, height: 437)),
            name: "shadow-times", to: folder
        )
        for (id, hour) in [("1200", 12.0), ("1830", 18.5)] {
            try write(try await shot(.island, hour: hour), name: "shadow-pofu-\(id)", to: folder)
        }
        // The wide shot: the establishing frame, the whole island, so every
        // station and the shadow under it (and at night its light) is in view.
        func wide(hour: Double, debug: Bool = false) async throws -> UIImage {
            let model = IslandSceneModel(framing: .island)
            model.holdEstablishingShot()
            var look = WorldLook(hourOverride: hour)
            look.shadowDebug = debug
            let view = LookScene(world: world(wellbeing: 78), model: model).environment(\.worldLook, look)
            return try await render(AnyView(view), in: scene, settle: 1400)
        }
        let wideTimes: [(String, Double, String)] = [("1200", 12, "12:00"), ("1830", 18.5, "18:30"), ("2230", 22.5, "22:30")]
        var wides: [UIImage] = []
        for (id, hour, _) in wideTimes {
            let image = try await wide(hour: hour)
            try write(image, name: "shadow-wide-\(id)", to: folder)
            wides.append(image)
        }
        try write(
            grid([wides], titles: [wideTimes.map { "Wide · \($0.2)" }], cell: CGSize(width: 268, height: 582)),
            name: "shadow-wide", to: folder
        )
        // Debug: the baked shadow layer alone, full opacity, magenta, to prove
        // where it lands (away from the sun, toward the camera).
        try write(try await wide(hour: 18.5, debug: true), name: "shadow-debug-1830", to: folder)
        try write(try await wide(hour: 12, debug: true), name: "shadow-debug-1200", to: folder)
    }

    /// Light and shadow v2 (LS-3): a çay ocağı level-up at 12:00 and at
    /// 22:30 frozen at 0, 300, 600 and 900 ms (`levelup-<ms>ms-<hour>`; the
    /// ceremony of light starts with the art swap at 420 ms), and the noon
    /// island with its cloud shadows (`clouds-1200`).
    @MainActor
    func testRenderTheLevelUpLight() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let after = IslandSamples.world(
            clock: Date(timeIntervalSinceReferenceDate: 815_000_000),
            tendedDays: 120,
            levels: [.garden: 3, .teaStall: 2, .pond: 2, .workshop: 1, .windmill: 2],
            jar: IslandSamples.midWeekJar,
            islands: [.home, .harbor],
            islandLevel: 8
        )
        for (id, hour) in [("1200", 12.0), ("2230", 22.5)] {
            for ms in [0, 300, 600, 900] {
                let model = IslandSceneModel(framing: .island)
                model.holdStationPan(from: .teaStall, to: .teaStall, at: 0)
                let home = WorldHomeModel(now: { Date() })
                home.buildStation(.teaStall, maxLevel: 5) { _ in BuildReceipt(station: .teaStall, level: 2, cost: Energy(10)) }
                home.freeze(at: Double(ms) / 1000)
                let view = LookScene(world: after, model: model, home: home).environment(\.worldLook, WorldLook(hourOverride: hour))
                try write(try await render(AnyView(view), in: scene, settle: 1400), name: "levelup-\(ms)ms-\(id)", to: folder)
            }
        }
        let model = IslandSceneModel(framing: .island)
        model.holdEstablishingShot()
        let view = LookScene(world: world(wellbeing: 78), model: model).environment(\.worldLook, WorldLook(hourOverride: 12))
        try write(try await render(AnyView(view), in: scene, settle: 1400), name: "clouds-1200", to: folder)
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

    // MARK: - The teapot: paint, the ember's light, the lit flame

    @MainActor
    private func renderTeapot(in scene: UIWindowScene, folder: URL) async throws {
        // The çay ocağı at level 1, the level batch 07 painted a lit flame for.
        let world = IslandSamples.world(
            clock: Date(timeIntervalSinceReferenceDate: 815_000_000),
            tendedDays: 120,
            levels: [.garden: 3, .teaStall: 1, .pond: 2, .workshop: 1, .windmill: 2],
            jar: IslandSamples.midWeekJar,
            islands: [.home, .harbor]
        )
        let variants: [(String, Bool, Bool)] = [
            ("rose copper, unlit", false, false),
            ("lit by the ember (round 3)", true, false),
            ("+ tea-stall-1-lit's flame (round 4)", true, true),
        ]
        var rows: [[UIImage]] = []
        var titles: [[String]] = []
        for (hour, label) in [(12.0, "day"), (22.0, "night")] {
            var row: [UIImage] = []
            var rowTitles: [String] = []
            for (title, lit, flame) in variants {
                let model = IslandSceneModel(framing: .island)
                model.holdStationPan(from: .teaStall, to: .teaStall, at: 0)
                var look = WorldLook(hd2d: lit, depthMotion: false, hourOverride: hour)
                look.litOverlays = flame
                let image = try await render(AnyView(LookScene(world: world, model: model).environment(\.worldLook, look)), in: scene, settle: 1400)
                // The held focus pose, as the scene drew it.
                let teaStall = try XCTUnwrap(IslandFraming.stationBox(.teaStall))
                let a = model.screenPoint(of: WorldPoint(x: teaStall.minX - 4, y: teaStall.minY - 4))
                let b = model.screenPoint(of: WorldPoint(x: teaStall.maxX + 4, y: teaStall.maxY + 4))
                row.append(crop(image, to: CGRect(x: a.x, y: a.y, width: b.x - a.x, height: b.y - a.y)))
                rowTitles.append("\(label): \(title)")
            }
            rows.append(row)
            titles.append(rowTitles)
        }
        try write(grid(rows, titles: titles, cell: CGSize(width: 372, height: 330)), name: "look-teapot", to: folder)
    }

    // MARK: - The plates: v3 (shipped) and v2

    /// The founder chooses the plate: the establishing shot, the Island
    /// pan and Home by day, and the Island at night, for v3 and v2.
    @MainActor
    private func renderPlates(in scene: UIWindowScene, folder: URL) async throws {
        let shots: [(String, WorldFraming?, Double)] = [
            ("establishing", nil, 12), ("Island", .island, 12), ("Home", .home, 12), ("Island · night", .island, 22),
        ]
        var rows: [[UIImage]] = []
        var titles: [[String]] = []
        for (label, art) in [("v3 (batch 05, shipped)", WorldLook.ArtSet.lockLight), ("v2 (batch 03)", .plateV2)] {
            var row: [UIImage] = []
            var rowTitles: [String] = []
            for (title, framing, hour) in shots {
                let model = IslandSceneModel(framing: framing ?? .island)
                if framing == nil {
                    model.holdEstablishingShot()
                }
                let look = WorldLook(art: art, hourOverride: hour)
                row.append(try await render(AnyView(LookScene(world: world(wellbeing: 78), model: model).environment(\.worldLook, look)), in: scene, settle: 1400))
                rowTitles.append("\(label) · \(title)")
            }
            rows.append(row)
            titles.append(rowTitles)
        }
        try write(grid(rows, titles: titles), name: "look-plates", to: folder)
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

    /// The Island pan (look round 4): a flick toward the çay ocağı from
    /// Pofu's centred view, coasting, then settling on the snap point, with
    /// depth in motion and without.
    @MainActor
    private func renderPan(in scene: UIWindowScene, folder: URL) async throws {
        let times = [0.0, 0.08, 0.16, 0.26, 0.4, 2.0]
        var rows: [[UIImage]] = []
        var titles: [[String]] = []
        for depth in [true, false] {
            var row: [UIImage] = []
            var rowTitles: [String] = []
            for t in times {
                let model = IslandSceneModel(framing: .island)
                model.holdPan(start: 0, velocity: -1100, at: t)
                let look = WorldLook(depthMotion: depth, hourOverride: 12)
                let image = try await render(AnyView(LookScene(world: world(wellbeing: 78), model: model).environment(\.worldLook, look)), in: scene, settle: 1200)
                row.append(image)
                rowTitles.append(String(format: "%@ t %.2f s", depth ? "depth on" : "depth off", t))
                if depth, t == 2.0 {
                    try write(image, name: "island-pan-settled", to: folder)
                }
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
    var home: WorldHomeModel?
    var still = true

    var body: some View {
        // The scene carries the one place control itself (PlaceControl).
        IslandScene(world: world, model: model, home: home) {
            SpeechBubble {
                Text(verbatim: "Sen yokken bahçe 12 çekirdek topladı.")
            }
        }
        .environment(\.worldStillFrame, still)
    }
}
