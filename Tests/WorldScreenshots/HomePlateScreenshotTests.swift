import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// The plate-first home (ADR-0022): Home at its final level (Tam Çiçek) by
/// day in clear weather, drawn from the painted plate, with the real chrome
/// and the visit's Collect beat; then the painted states: golden hour and
/// night at level 10, and the day plates of the lower levels. CI's publish job lays the frames beside the
/// concept (`tools/plate/home_sheet.py` → `home-plate.jpg`).
///
/// - `home-plate-day-home`: Home as the app opens it;
/// - `home-plate-day-whole`: the establishing shot of the whole island;
/// - `home-plate-day-settled`: Home after Collect (no beat, the quiet line);
/// - `home-plate-full-home` and `home-plate-full-settled`: Home at the
///   simulator's full device resolution (CI keeps these as PNG, never reduced);
/// - `home-plate-full-l10-day`, `-l10-golden`, `-l10-night`, `-l5-day`,
///   `-l2-day`: the settled Home in each painted state, full resolution
///   (`tools/plate/harmony_check.py` measures them).
final class HomePlateScreenshotTests: XCTestCase {
    @MainActor
    func testRenderTheHomePlate() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let plate = try XCTUnwrap(HomePlate.shipped, "the package ships the home plate")
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        for shot in ["home", "whole", "settled"] {
            try await render(shot: shot, full: false, plate: plate, scene: scene, folder: folder)
        }
        for shot in ["home", "settled"] {
            try await render(shot: shot, full: true, plate: plate, scene: scene, folder: folder)
        }
        let states: [(name: String, level: Int, hour: Double, light: String)] = [
            ("l10-day", 10, 12, "day"), ("l10-golden", 10, 18, "golden"), ("l10-night", 10, 22.5, "night"),
            ("l5-day", 5, 12, "day"), ("l2-day", 2, 12, "day"),
        ]
        for state in states {
            try await render(shot: "settled", full: true, plate: plate, scene: scene, folder: folder, state: state)
        }
    }

    @MainActor
    private func render(
        shot: String, full: Bool, plate: HomePlate, scene: UIWindowScene, folder: URL,
        state: (name: String, level: Int, hour: Double, light: String)? = nil
    ) async throws {
        do {
            let now = Date(timeIntervalSinceReferenceDate: 815_000_000)
            let world = IslandSamples.world(
                clock: nil,
                tendedDays: 60,
                levels: [.garden: 5, .teaStall: 5, .pond: 5, .windmill: 5, .workshop: 5, .bagelCart: 5, .pier: 5, .lighthouse: 5],
                jar: Energy(214),
                islands: [.home, .harbor],
                islandLevel: state?.level ?? 10,
                wellbeing: 84
            )
            let island = IslandSceneModel(framing: .home)
            let home = WorldHomeModel(now: { now }, schedulesCues: false)
            let inputs = VisitInputs(now: now, world: world, lastSettled: shot == "settled" ? now.addingTimeInterval(-5 * 60) : nil, calendar: .current)
            home.beginVisit(VisitQueue.plan(inputs))
            if shot == "settled" {
                home.acknowledgeCurrentBeat()
            }
            var look = WorldLook(hourOverride: state?.hour ?? 12)
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
            XCTAssertEqual(island.homePlate?.light, state?.light ?? "day", "the plate shows its \(state?.name ?? "l10-day") state")
            if shot == "whole" {
                island.holdEstablishingShot()
            }
            try await Task.sleep(for: .milliseconds(900))
            let format = UIGraphicsImageRendererFormat()
            format.scale = window.traitCollection.displayScale
            format.opaque = true
            let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
                _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            window.isHidden = true
            window.rootViewController = nil
            try write(image, name: state.map { "home-plate-full-\($0.name)" } ?? (full ? "home-plate-full-\(shot)" : "home-plate-day-\(shot)"), to: folder)
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
