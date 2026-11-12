import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// The painted sky everywhere (docs/design/demo-one-world-v1.md, D2 and D7): Koke's stop and the harbor's
/// stand under Home's painted sky of the hour's light (its sky set, the island layer left out), and rain
/// falls over a painted Home. All frames at the simulator's full device resolution, never reduced:
///
/// - `koke-sky-s0-day`, `koke-sky-s2-night`, `koke-sky-s4-golden`: Koke at three stages and three hours,
///   compare their sky with `home-plate-full-l10-day`, `-golden`, `-night`;
/// - `harbor-sky-rumour-day`: the harbor stop on the rumour day;
/// - `home-plate-full-l5-rain` and `-overcast`: Home at level 5 in light rain (streaks and splashes over
///   the day painting, no puddle glints) and overcast (the day painting, nothing over it): the second
///   equals `home-plate-full-l5-day`.
final class PaintedSkyScreenshotTests: XCTestCase {
    private let clock = Date(timeIntervalSinceReferenceDate: 815_000_000)

    private func world(koke: WonderStatus, bedtime: Bool = false) -> WorldSnapshot {
        var world = IslandSamples.world(
            clock: clock, tendedDays: 12, levels: [.garden: 3, .teaStall: 2, .pond: 2, .workshop: 1],
            jar: IslandSamples.midWeekJar, islands: [.home, .harbor], islandLevel: 5, isBedtime: bedtime
        )
        world.koke = koke
        return world
    }

    @MainActor
    func testRenderThePaintedSky() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let koke: [(name: String, stage: Int, hour: Double, bedtime: Bool)] = [
            ("koke-sky-s0-day", 0, 12, false), ("koke-sky-s2-night", 2, 23, true), ("koke-sky-s4-golden", 4, 18, false),
        ]
        for shot in koke {
            let model = IslandSceneModel(framing: .island)
            model.holdIsle(.koke)
            let status = WonderStatus(phase: .arrived, stage: shot.stage, canAdvance: shot.stage < 4)
            let image = try await render(IslandScene(world: world(koke: status, bedtime: shot.bedtime), model: model), look: look(shot.hour), in: scene)
            try write(image, name: shot.name, to: folder)
        }

        let rumour = IslandSceneModel(framing: .island)
        rumour.holdIsle(.harbor)
        rumour.koke.show(.rumour)
        try write(
            try await render(IslandScene(world: world(koke: WonderStatus(phase: .rumoured)), model: rumour), look: look(12), in: scene),
            name: "harbor-sky-rumour-day", to: folder
        )

        try await renderHome(name: "home-plate-full-l5-rain", weather: WeatherConditions(weather: .lightRain), scene: scene, folder: folder)
        try await renderHome(name: "home-plate-full-l5-overcast", weather: WeatherConditions(weather: .overcast), scene: scene, folder: folder)
    }

    private func look(_ hour: Double, weather: WeatherConditions = .clear) -> WorldLook {
        var look = WorldLook(hourOverride: hour)
        look.weatherOverride = weather
        return look
    }

    @MainActor
    private func renderHome(name: String, weather: WeatherConditions, scene: UIWindowScene, folder: URL) async throws {
        let now = Date(timeIntervalSinceReferenceDate: 815_000_000)
        var world = IslandSamples.world(
            clock: nil,
            tendedDays: 60,
            levels: [.garden: 5, .teaStall: 5, .pond: 5, .windmill: 5, .workshop: 5, .bagelCart: 5, .pier: 5, .lighthouse: 5],
            jar: Energy(214),
            islands: [.home, .harbor],
            islandLevel: 5,
            wellbeing: 84
        )
        world.nextIslandLevel = IslandLevelRequirement(level: 6, tendedDaysLeft: 0, levelsLeft: 2)
        let island = IslandSceneModel(framing: .home)
        let home = WorldHomeModel(now: { now }, schedulesCues: false)
        let inputs = VisitInputs(now: now, world: world, lastSettled: now.addingTimeInterval(-5 * 60), calendar: .current)
        home.beginVisit(VisitQueue.plan(inputs))
        home.acknowledgeCurrentBeat()
        let view = WorldHome(
            world: world,
            today: TodaySummary(beads: [false, true, false, true], guardedMinutes: 22, dailyHourMinutes: 60),
            scene: island,
            home: home,
            actions: WorldHome.Actions(collect: { nil }, build: { _ in nil }, openSettings: {}, repair: {}, openToday: {})
        )
        let image = try await render(view, look: look(12, weather: weather), in: scene, settle: 2100) {
            XCTAssertEqual(island.homePlate?.light, "day", "\(name): the day painting shows in this weather")
        }
        try write(image, name: name, to: folder)
    }

    // MARK: - Rendering

    @MainActor
    private func render<V: View>(
        _ content: V, look: WorldLook, in scene: UIWindowScene, settle: Int = 1400, check: () -> Void = {}
    ) async throws -> UIImage {
        let view = content
            .environment(\.worldLook, look)
            .environment(\.worldStillFrame, true)
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: AnyView(view))
        window.windowLevel = .alert + 5
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(settle))
        check()
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

    private func outputFolder() -> URL {
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
    }
}
