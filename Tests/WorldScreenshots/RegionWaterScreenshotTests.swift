import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// The region shaders' water (build spec WP13): Home's pond at level 10 by day and at night, at
/// mid and at near, each at two instants of the water's loop (`worldWaterClock`: a still frame
/// holds the loop's time), so the motion can be shown from stills. `water-<light>-<framing>-t<n>`
/// where t0 is 0 s and t1 is 1.5 s into the loop (`pond`: the camera focused on the pond, the lens
/// blurring the rest of the island); `water-day-mid-off` is the same frame with
/// the water as painted (a still frame without the clock).
final class RegionWaterScreenshotTests: XCTestCase {
    private struct Shot {
        var name: String
        var framing: WorldFraming
        var hour: Double
        /// `nil`: the water as painted.
        var clock: Double?
        /// The camera focused on the pond (the lens blurs the rest of the island), once the plate is up.
        var focusPond = false
        /// The shader's probe (`pofuWaterPatch`'s `gate.y`): 1 the plate's own sample, 2 the gate's alpha,
        /// 3 the water without its gate, 4 a flat grey.
        var debug = 0
        var variant = 0
    }

    @MainActor
    func testRenderTheWater() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var shots: [Shot] = [Shot(name: "water-day-mid-off", framing: .mid, hour: 12, clock: nil)]
        for (light, hour) in [("day", 12.0), ("night", 22.5)] {
            for (framing, label) in [(WorldFraming.mid, "mid"), (.near, "near")] {
                for (i, clock) in [0.0, 1.5].enumerated() {
                    shots.append(Shot(name: "water-\(light)-\(label)-t\(i)", framing: framing, hour: hour, clock: clock))
                }
            }
        }
        for (light, hour) in [("day", 12.0), ("night", 22.5)] {
            for (i, clock) in [0.0, 1.5].enumerated() {
                shots.append(Shot(name: "water-\(light)-pond-t\(i)", framing: .mid, hour: hour, clock: clock, focusPond: true))
            }
        }
        shots.removeAll { $0.name.hasPrefix("water-") && !$0.name.contains("-pond-") }
        for variant in 1...5 {
            shots.append(Shot(name: "probe-v\(variant)-night-id", framing: .mid, hour: 22.5, clock: 0, focusPond: true, debug: 1, variant: variant))
            for (i, clock) in [0.0, 1.5].enumerated() {
                shots.append(Shot(name: "probe-v\(variant)-night-t\(i)", framing: .mid, hour: 22.5, clock: clock, focusPond: true, variant: variant))
            }
            shots.append(Shot(name: "probe-v\(variant)-day-t0", framing: .mid, hour: 12, clock: 0, focusPond: true, variant: variant))
        }
        for shot in shots {
            try await render(shot, scene: scene, folder: folder)
        }
    }

    @MainActor
    private func render(_ shot: Shot, scene: UIWindowScene, folder: URL) async throws {
        let now = Date(timeIntervalSinceReferenceDate: 815_000_000)
        let world = IslandSamples.world(
            clock: nil,
            tendedDays: 60,
            levels: [.garden: 5, .teaStall: 5, .pond: 5, .windmill: 5, .workshop: 5, .bagelCart: 5, .pier: 5, .lighthouse: 5],
            jar: Energy(214),
            islands: [.home, .harbor],
            islandLevel: 10,
            wellbeing: 84
        )
        let island = IslandSceneModel(framing: shot.framing)
        let home = WorldHomeModel(now: { now }, schedulesCues: false)
        let inputs = VisitInputs(now: now, world: world, lastSettled: now.addingTimeInterval(-5 * 60), calendar: .current)
        home.beginVisit(VisitQueue.plan(inputs))
        home.acknowledgeCurrentBeat()
        var look = WorldLook(hourOverride: shot.hour)
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
        .environment(\.worldWaterClock, shot.clock)
        .environment(\.worldWaterDebug, shot.debug)
        .environment(\.worldWaterVariant, shot.variant)

        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: AnyView(view))
        window.windowLevel = .alert + 4
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(1600))
        if shot.focusPond {
            island.focusStation(.pond, animated: false)
            try await Task.sleep(for: .milliseconds(1400))
        }
        XCTAssertEqual(island.homePlate?.stage, 0, "level 10 paints stage 0, the big pond")
        let format = UIGraphicsImageRendererFormat()
        format.scale = window.traitCollection.displayScale
        format.opaque = true
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        window.rootViewController = nil
        let data = try XCTUnwrap(image.pngData())
        try data.write(to: folder.appendingPathComponent("\(shot.name).png"))
        let attachment = XCTAttachment(image: image)
        attachment.name = shot.name
        attachment.lifetime = .keepAlways
        add(attachment)
        try await Task.sleep(for: .milliseconds(150))
    }

    private func outputFolder() -> URL {
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
    }
}
