import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// The painted nights of the lower levels and the IL1 day (docs/design/demo-one-world-v1.md, PR 2):
/// Home settled in each state at the simulator's full device resolution, with the real chrome and
/// the level's own sprites. `tools/plate/harmony_check.py` measures the nights.
///
/// - `home-plate-full-l1-day`: day 1, the painted IL1;
/// - `home-plate-full-l1-night`: day 1 at night, the painted IL1 night;
/// - `home-plate-full-l2-night`, `-l4-night`, `-l7-night`: the painted night of the level;
/// - `home-plate-full-l5-golden`: 18:00 at level 5, which has no painted golden hour and borrows
///   the night (`HomePlate.borrowed`);
/// - `home-plate-full-l5-dawn`: 06:00 at level 5, the day ("Morning" in the Rehearsal panel);
/// - `home-plate-full-l3-night`, `-l5-`, `-l6-`, `-l8-`, `-l9-night`: the other painted nights, for
///   `harmony_check.py`.
final class HomeNightScreenshotTests: XCTestCase {
    @MainActor
    func testRenderTheHomeNights() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let states: [State] = [
            State(name: "l1-day", level: 1, hour: 12, light: "day"),
            State(name: "l2-night", level: 2, hour: 22.5, light: "night"),
            State(name: "l1-night", level: 1, hour: 22.5, light: "night"),
            State(name: "l4-night", level: 4, hour: 22.5, light: "night"),
            State(name: "l7-night", level: 7, hour: 22.5, light: "night"),
            State(name: "l5-golden", level: 5, hour: 18, light: "night"),
            State(name: "l5-dawn", level: 5, hour: 6, light: "day"),
        ] + [3, 5, 6, 8, 9].map { State(name: "l\($0)-night", level: $0, hour: 22.5, light: "night") }
        for state in states {
            try await render(state: state, scene: scene, folder: folder)
        }
    }

    private struct State {
        var name: String
        var level: Int
        var hour: Double
        /// The painted light the plate must draw (golden hour at level 5 draws the night).
        var light: String
    }

    @MainActor
    private func render(state: State, scene: UIWindowScene, folder: URL) async throws {
        do {
            let now = Date(timeIntervalSinceReferenceDate: 815_000_000)
            let world = IslandSamples.world(
                clock: nil,
                tendedDays: 60,
                levels: [.garden: 5, .teaStall: 5, .pond: 5, .windmill: 5, .workshop: 5, .bagelCart: 5, .pier: 5, .lighthouse: 5],
                jar: Energy(214),
                islands: [.home, .harbor],
                islandLevel: state.level,
                wellbeing: 84
            )
            let island = IslandSceneModel(framing: .home)
            let home = WorldHomeModel(now: { now }, schedulesCues: false)
            let inputs = VisitInputs(now: now, world: world, lastSettled: now.addingTimeInterval(-5 * 60), calendar: .current)
            home.beginVisit(VisitQueue.plan(inputs))
            home.acknowledgeCurrentBeat()
            var look = WorldLook(hourOverride: state.hour)
            look.weatherOverride = .clear
            let view = WorldHome(
                world: world,
                today: TodaySummary(beads: [false, true, false, true], guardedMinutes: 22, dailyHourMinutes: 60),
                scene: island,
                home: home,
                actions: WorldHome.Actions(collect: { nil }, build: { _ in nil }, openSettings: {}, repair: {}, openToday: {})
            )
            .environment(\.worldLook, look)
            .environment(\.worldStillFrame, true)

            let window = UIWindow(windowScene: scene)
            window.overrideUserInterfaceStyle = .light
            window.rootViewController = UIHostingController(rootView: AnyView(view))
            window.windowLevel = .alert + 4
            window.makeKeyAndVisible()
            try await Task.sleep(for: .milliseconds(1200))
            XCTAssertEqual(island.homePlate?.light, state.light, "the plate shows its \(state.name) state")
            // Only level 10's states draw a sky set (ADR-0025); these draw the plate and its backdrop.
            XCTAssertNil(island.homePlate?.skySet, "\(state.name) has no sky set")
            try await Task.sleep(for: .milliseconds(900))
            let format = UIGraphicsImageRendererFormat()
            format.scale = window.traitCollection.displayScale
            format.opaque = true
            let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
                _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            window.isHidden = true
            window.rootViewController = nil
            try write(image, name: "home-plate-full-\(state.name)", to: folder)
            try await Task.sleep(for: .milliseconds(150))
        }
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
