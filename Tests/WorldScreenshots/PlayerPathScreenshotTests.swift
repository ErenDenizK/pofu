import PofuCore
import PofuDesignSystem
import PofuGames
import PofuWorld
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// The player-path frames: the tester's 21 days (`PlayerPath`, the same run
/// `DemoRunTests` guards) as the player meets them, with the paintings on.
/// The studio judges the look from these frames. All at the simulator's full
/// device resolution (1206 x 2622), never reduced:
///
/// - `path-dNN-0900`, `path-dNN-2300`: Home that day at 09:00 and 23:00;
/// - `path-dNN-map-0900`: the Map on day 1 and on every day a new island
///   appeared (the harbor, the rumour, Koke, Çağlayan);
/// - `path-dNN-koke-0907`, `path-dNN-caglayan-0907`: the wonder island's stop on the
///   days the run visits it (its arrival and each stage), after the visit;
/// - `path-sheet-today`, `path-sheet-station`: the sheets over the painted Home (day 5);
/// - `path-game-garden-midround`, `path-game-flow-stage1`: the minigames;
/// - `path-onboarding-welcome`, `-apps`, `-name`, `-notifications`.
///
/// Every Home and Map frame asserts that its look has `homePlates` on and that the island
/// scene resolved a painting: a path frame is never the sprite island.
class PlayerPathFrameCase: XCTestCase {
    static let path = PlayerPath.tester()

    // MARK: Frames

    @MainActor
    func renderDays(_ days: ClosedRange<Int>) async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        for day in Self.path where days.contains(day.day) {
            let nn = String(format: "%02d", day.day)
            try await home(day.morning, hour: 9, name: "path-d\(nn)-0900", scene: scene, folder: folder)
            try await home(day.night, hour: 23, name: "path-d\(nn)-2300", scene: scene, folder: folder)
            if day.mapChanged || day.day == 1 {
                try await map(day.morning, hour: 9, name: "path-d\(nn)-map-0900", scene: scene, folder: folder)
            }
            if day.visitedKoke {
                try await stop(.koke, world: day.visit, name: "path-d\(nn)-koke-0907", scene: scene, folder: folder)
            }
            if day.visitedCaglayan {
                try await stop(.caglayan, world: day.visit, name: "path-d\(nn)-caglayan-0907", scene: scene, folder: folder)
            }
        }
    }

    @MainActor
    func homeView(_ world: WorldSnapshot, hour: Double, island: IslandSceneModel) -> some View {
        let look = WorldLook.playerPath(hour: hour)
        XCTAssertTrue(look.homePlates, "a path frame is never the sprite island")
        let now = world.clock ?? Date()
        let home = WorldHomeModel(now: { now }, schedulesCues: false)
        let inputs = VisitInputs(now: now, world: world, lastSettled: now.addingTimeInterval(-5 * 60), calendar: .current)
        home.beginVisit(VisitQueue.plan(inputs))
        home.acknowledgeCurrentBeat()
        return WorldHome(
            world: world,
            today: TodaySummary(beads: [true], guardedMinutes: world.guardedMinutesToday, dailyHourMinutes: world.dailyHourMinutes),
            scene: island,
            home: home,
            actions: WorldHome.Actions(collect: { nil }, build: { _ in nil }, openSettings: {}, repair: {}, openToday: {})
        )
        .environment(\.worldLook, look)
        .environment(\.worldStillFrame, true)
    }

    @MainActor
    func home(_ world: WorldSnapshot, hour: Double, name: String, scene: UIWindowScene, folder: URL) async throws {
        let island = IslandSceneModel(framing: .home)
        let view = homeView(world, hour: hour, island: island)
        try await capture(AnyView(view), name: name, scene: scene, folder: folder, settle: 2100) {
            XCTAssertNotNil(island.homePlate, "\(name): Home is its painting (IL\(world.islandLevel), hour \(hour))")
        }
    }

    @MainActor
    func map(_ world: WorldSnapshot, hour: Double, name: String, scene: UIWindowScene, folder: URL) async throws {
        let look = WorldLook.playerPath(hour: hour)
        XCTAssertTrue(look.homePlates, "a path frame is never the sprite island")
        let island = IslandSceneModel(framing: .map)
        let view = IslandScene(world: world, model: island)
            .environment(\.worldLook, look)
            .environment(\.worldStillFrame, true)
        try await capture(AnyView(view), name: name, scene: scene, folder: folder, settle: 1400) {
            XCTAssertNotNil(island.homePlate, "\(name): Home is its painting on the Map")
        }
    }

    @MainActor
    func stop(_ isle: IslandID, world: WorldSnapshot, name: String, scene: UIWindowScene, folder: URL) async throws {
        let look = WorldLook.playerPath(hour: 9.12)
        XCTAssertTrue(look.homePlates, "a path frame is never the sprite island")
        let island = IslandSceneModel(framing: .island)
        island.holdIsle(isle)
        let view = IslandScene(world: world, model: island)
            .environment(\.worldLook, look)
            .environment(\.worldStillFrame, true)
        try await capture(AnyView(view), name: name, scene: scene, folder: folder, settle: 1600) {}
    }

    // MARK: Capture

    @MainActor
    func capture(
        _ view: AnyView, name: String, scene: UIWindowScene, folder: URL, settle: Int = 900,
        style: UIUserInterfaceStyle = .light, check: () -> Void = {}
    ) async throws {
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = style
        window.rootViewController = UIHostingController(rootView: view)
        window.windowLevel = .alert + 6
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(settle))
        check()
        let image = snapshot(window)
        window.isHidden = true
        window.rootViewController = nil
        try write(image, name: name, to: folder)
        try await Task.sleep(for: .milliseconds(150))
    }

    @MainActor
    func snapshot(_ window: UIWindow) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = window.traitCollection.displayScale
        format.opaque = true
        return UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }

    @MainActor
    func write(_ image: UIImage, name: String, to folder: URL) throws {
        let data = try XCTUnwrap(image.pngData())
        try data.write(to: folder.appendingPathComponent("\(name).png"))
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func windowScene() throws -> UIWindowScene {
        try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
    }

    func outputFolder() throws -> URL {
        let folder: URL
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            folder = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            folder = FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
        }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}

final class PlayerPathWeek1ScreenshotTests: PlayerPathFrameCase {
    @MainActor func testRenderWeek1() async throws { try await renderDays(1...7) }
}

final class PlayerPathWeek2ScreenshotTests: PlayerPathFrameCase {
    @MainActor func testRenderWeek2() async throws { try await renderDays(8...14) }
}

final class PlayerPathWeek3ScreenshotTests: PlayerPathFrameCase {
    @MainActor func testRenderWeek3() async throws { try await renderDays(15...21) }
}

/// The sheets, the games and the onboarding screens of the path.
final class PlayerPathScreensScreenshotTests: PlayerPathFrameCase {
    @MainActor
    func testRenderTheSheetsOverThePaintedHome() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = Self.path[4]
        let model = AppModel.shared
        let status = day.morning.stations.first { $0.id == .teaStall }
        for (name, fraction) in [("path-sheet-today", 0.9), ("path-sheet-station", 0.5)] {
            let island = IslandSceneModel(framing: .home)
            let back = homeView(day.morning, hour: 11, island: island)
            let view: AnyView
            if name == "path-sheet-today" {
                view = AnyView(PathSheetFrame(fraction: fraction, back: AnyView(back)) { TodaySheet(model: model, hourOverride: 11) })
            } else {
                view = AnyView(PathSheetFrame(fraction: fraction, back: AnyView(back)) {
                    StationSheet(station: .teaStall, status: status, jar: day.morning.jar, onBuild: { _ in }, onClose: {})
                })
            }
            try await capture(view, name: name, scene: scene, folder: folder, settle: 2100) {
                XCTAssertNotNil(island.homePlate, "\(name): the sheet sits over the painted Home")
            }
        }
    }

    @MainActor
    func testRenderTheGames() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()

        let garden = GardenGameModel(seed: 2026)
        let gardenWindow = gameWindow(GardenGameView(model: garden), scene: scene)
        try await Task.sleep(for: .milliseconds(900))
        garden.autoplay(moves: 6)
        for _ in 0..<8 where !garden.canBloom {
            garden.autoplay(moves: 1)
        }
        try await Task.sleep(for: .milliseconds(400))
        garden.holdSuggestedMove()
        try await Task.sleep(for: .milliseconds(450))
        garden.freeze()
        try await Task.sleep(for: .milliseconds(250))
        try write(snapshot(gardenWindow), name: "path-game-garden-midround", to: folder)
        gardenWindow.isHidden = true
        gardenWindow.rootViewController = nil
        try await Task.sleep(for: .milliseconds(150))

        let round = try XCTUnwrap(FlowLibrary.round(stage: 1))
        let flow = FlowGameModel(round: round, hintDelay: .seconds(600), pourPause: .seconds(600))
        let flowWindow = gameWindow(FlowGameView(model: flow), scene: scene)
        try await Task.sleep(for: .milliseconds(900))
        flow.freeze()
        try await Task.sleep(for: .milliseconds(250))
        try write(snapshot(flowWindow), name: "path-game-flow-stage1", to: folder)
        flowWindow.isHidden = true
        flowWindow.rootViewController = nil
        try await Task.sleep(for: .milliseconds(150))
    }

    @MainActor
    private func gameWindow<Content: View>(_ view: Content, scene: UIWindowScene) -> UIWindow {
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: view)
        window.windowLevel = .alert + 6
        window.makeKeyAndVisible()
        return window
    }

    @MainActor
    func testRenderTheOnboarding() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let model = AppModel.shared
        for (name, step) in [("welcome", 0), ("apps", 2), ("name", 3), ("notifications", 5)] {
            try await capture(
                AnyView(OnboardingView(model: model, startingAtStep: step)),
                name: "path-onboarding-\(name)", scene: scene, folder: folder, settle: 1000
            )
        }
    }
}

/// A sheet's paper at a detent's height at the bottom of the screen, over a
/// dimmed `back` (the painted Home).
private struct PathSheetFrame<Content: View>: View {
    let fraction: Double
    let back: AnyView
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                back
                Color.black.opacity(0.35).ignoresSafeArea()
                ZStack(alignment: .top) {
                    PofuPaperSheetBackground()
                    Capsule().fill(Color.gray.opacity(0.5)).frame(width: 36, height: 5).padding(.top, 6)
                    content.padding(.top, 14)
                }
                .frame(height: proxy.size.height * fraction)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
            }
        }
        .environment(\.colorScheme, .light)
    }
}
