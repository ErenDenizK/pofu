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
/// - `path-d21-bell-0900`: Home on the morning the far bell rings, with
///   Pofu's line and its answer (the closing beat);
/// - `path-dNN-map-0900`: the Map on day 1 and on every day a new island
///   appeared (the harbor, the rumour, Koke, Çağlayan);
/// - `path-dNN-koke-0907`, `path-dNN-caglayan-0907`: the wonder island's stop on the
///   days the run visits it (its arrival and each stage), after the visit;
/// - `path-sheet-today`, `path-sheet-station`: the sheets over the painted Home (day 5);
/// - `path-d04-grow-0000`, `-1500`, `-2400`: "Ada büyüdü" by a build, at 0.0, 1.5 and 2.4 s of its moment
///   (the old painting whole and held, mid cross-fade with the bloom, the new painting with the "Ada n" card);
/// - `path-d03-grew-0900`: the overnight landing on the old painting, Pofu's news line and its button;
///   `path-d03-grew-live-1800`: the same morning, 1.8 s after the button, through the live timers;
/// - `path-d04-build-focus`, `path-d04-build-burst`: a build's camera through the real `focusStation`
///   and the station's burst, over the held old painting;
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
            // 09:00 opens before the day's first reach, with the morning's beats waiting; 23:00
            // is bedtime, after the day's reach and its guarded minutes.
            try await home(day.morning, hour: 9, beads: [], name: "path-d\(nn)-0900", scene: scene, folder: folder)
            try await home(day.night, hour: 23, beads: day.beads, name: "path-d\(nn)-2300", scene: scene, folder: folder)
            if day.morning.bell == .ringing {
                try await home(day.morning, hour: 9, beads: [], name: "path-d\(nn)-bell-0900", scene: scene, folder: folder, beats: [.bell])
            }
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

    /// The cheek lines Pofu said on the mornings before `world`'s day, replayed through the same
    /// rule the phone applies (a frame's model is fresh, so it would otherwise say it every morning).
    @MainActor
    func cheekHistory(before world: WorldSnapshot) -> CheekLineHistory {
        guard let clock = world.clock else { return CheekLineHistory() }
        var history = CheekLineHistory()
        for day in Self.path where Calendar.current.startOfDay(for: day.morningAt) < Calendar.current.startOfDay(for: clock) {
            let home = WorldHomeModel(now: { day.morningAt }, schedulesCues: false, cheekLineHistory: history)
            home.beginVisit(VisitQueue.plan(VisitInputs(now: day.morningAt, world: day.morning, calendar: .current)))
            history = home.cheekLineHistory
        }
        return history
    }

    @MainActor
    func homeView(
        _ world: WorldSnapshot, hour: Double, island: IslandSceneModel, beads: [Bool] = [], settled: Bool = false,
        beats: [VisitBeat]? = nil, model: WorldHomeModel? = nil
    ) -> some View {
        let look = WorldLook.playerPath(hour: hour)
        XCTAssertTrue(look.homePlates, "a path frame is never the sprite island")
        let now = world.clock ?? Date()
        let home = model ?? WorldHomeModel(now: { now }, schedulesCues: false, cheekLineHistory: cheekHistory(before: world))
        if let beats {
            // A beat frame: the visit stands on `beats`, as the player meets it.
            home.beginVisit(VisitPlan(landing: .visit, showsRepairBanner: false, beats: beats))
        } else {
            // The phone's landing: the last visit settled yesterday, so the morning's beats wait
            // (a frame under a sheet keeps the settled Home it was judged on).
            let inputs = VisitInputs(now: now, world: world, lastSettled: settled ? now.addingTimeInterval(-5 * 60) : nil, calendar: .current)
            home.beginVisit(VisitQueue.plan(inputs))
            if settled { home.acknowledgeCurrentBeat() }
        }
        return WorldHome(
            world: world,
            today: TodaySummary(beads: beads, guardedMinutes: world.guardedMinutesToday, dailyHourMinutes: world.dailyHourMinutes),
            scene: island,
            home: home,
            actions: WorldHome.Actions(collect: { nil }, build: { _ in nil }, openSettings: {}, repair: {}, openToday: {})
        )
        .environment(\.worldLook, look)
        .environment(\.worldStillFrame, true)
    }

    @MainActor
    func home(_ world: WorldSnapshot, hour: Double, beads: [Bool], name: String, scene: UIWindowScene, folder: URL, beats: [VisitBeat]? = nil) async throws {
        let island = IslandSceneModel(framing: .home)
        let view = homeView(world, hour: hour, island: island, beads: beads, beats: beats)
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
        style: UIUserInterfaceStyle = .light, flip: PathFlip? = nil, check: () -> Void = {}
    ) async throws {
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = style
        window.rootViewController = UIHostingController(rootView: view)
        window.windowLevel = .alert + 6
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(settle))
        // Something changes after the first paint (a painting begins its cross-fade) and the frame waits for it.
        if let flip {
            flip.action()
            try await Task.sleep(for: .milliseconds(flip.milliseconds))
        }
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
            let back = homeView(day.morning, hour: 11, island: island, settled: true)
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

    // MARK: Ada büyüdü

    /// The painting of the island at `level`, as Home resolves it for a world that has already risen.
    @MainActor
    private func paintedAs(_ world: WorldSnapshot, level: Int, hour: Double) -> HomePlate? {
        var shown = world
        shown.islandLevel = level
        return HomePlate.resolve(world: shown, look: WorldLook.playerPath(hour: hour))
    }

    /// The island growing by a build on day 4 (level 3 to 4): the moment's own time, frozen, through the real
    /// `IslandSceneModel` and `WorldHome`.
    @MainActor
    func testRenderTheIslandGrowing() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = Self.path[3]
        let from = day.morning.islandLevel, to = day.visit.islandLevel
        XCTAssertEqual(to, from + 1, "day 4 is a level-up by a build")
        for (name, ms) in [("0000", 0), ("1500", 1500), ("2400", 2400)] {
            let seconds = Double(ms) / 1000
            let island = IslandSceneModel(framing: .home)
            // The camera and the painting of the moment's start; the cross-fade frame then flips the level.
            let first = ms == 1500 ? 0.79 : seconds
            let level = first >= IslandGrowMoment.crossFadeAt ? to : from
            island.setHomePlate(paintedAs(day.visit, level: level, hour: 9))
            island.holdIslandGrow(from: from, to: to, at: first)
            let view = homeView(day.visit, hour: 9, island: island, settled: true)
            var flip: PathFlip?
            if ms == 1500 {
                // The fade is 0.8 s from the flip: 400 ms lands mid-fade (1000 ms showed it finished).
                flip = PathFlip(waiting: 400) { island.holdIslandGrow(from: from, to: to, at: seconds) }
            }
            try await capture(AnyView(view), name: "path-d04-grow-\(name)", scene: scene, folder: folder, settle: 2100, flip: flip) {
                XCTAssertNotNil(island.homePlate, "path-d04-grow-\(name): the island is its painting")
                XCTAssertTrue(island.isGrowing)
                XCTAssertEqual(island.levelStage.shown(worldLevel: to), seconds >= IslandGrowMoment.crossFadeAt ? to : from)
            }
        }
    }

    /// The overnight rise (day 3, level 2 to 3): the app lands on the old painting with the news beat; then the
    /// button, through the live timers, 1.8 s in.
    @MainActor
    func testRenderTheOvernightGrowth() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = Self.path[2]
        let to = day.morning.islandLevel
        XCTAssertEqual(to, 3, "day 3 opens on a level reached overnight")
        let beats: [VisitBeat] = [.news(.stageGrew(to))]
        let island = IslandSceneModel(framing: .home)
        island.setHomePlate(paintedAs(day.morning, level: to - 1, hour: 9))
        island.holdPresentedLevel(to - 1)
        let view = homeView(day.morning, hour: 9, island: island, beats: beats)
        try await capture(AnyView(view), name: "path-d03-grew-0900", scene: scene, folder: folder, settle: 2100) {
            XCTAssertNotNil(island.homePlate)
            XCTAssertFalse(island.isGrowing, "the news waits for its button")
            XCTAssertEqual(island.levelStage.shown(worldLevel: to), to - 1, "the app lands on the old painting")
        }

        // The button: the news beat is taken and the moment plays from the live timers.
        let live = IslandSceneModel(framing: .home)
        live.setHomePlate(paintedAs(day.morning, level: to - 1, hour: 9))
        live.holdPresentedLevel(to - 1)
        let now = day.morning.clock ?? Date()
        let home = WorldHomeModel(now: { now }, schedulesCues: false)
        let liveView = homeView(day.morning, hour: 9, island: live, beats: beats, model: home)
        var taken = false
        let button = PathFlip(waiting: 1800) {
            home.acknowledgeCurrentBeat()
            taken = true
        }
        try await capture(AnyView(liveView), name: "path-d03-grew-live-1800", scene: scene, folder: folder, settle: 2100, flip: button) {
            XCTAssertTrue(taken)
            XCTAssertTrue(live.isGrowing, "the button starts the moment")
            XCTAssertEqual(live.levelStage.shown(worldLevel: to), to, "the cross-fade has begun")
        }
        try await Task.sleep(for: .milliseconds(3500))
        XCTAssertFalse(live.isGrowing, "the moment ends by itself")
    }

    /// A build's camera through the real `focusStation` (the painted station centred above the sheet), and
    /// the station's burst at 0.6 s, over the held old painting (day 4: the island rises to level 4).
    @MainActor
    func testRenderTheBuildFocusAndBurst() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = Self.path[3]
        let from = day.morning.islandLevel
        let built = zip(day.morning.stations, day.visit.stations).first { $0.1.level > $0.0.level }?.1
        let station = try XCTUnwrap(built, "day 4 builds a station")

        // The focus: the morning's world, the station focused as a tap does.
        let focused = IslandSceneModel(framing: .home)
        focused.setHomePlate(paintedAs(day.morning, level: from, hour: 9))
        focused.focusStation(station.id, animated: false)
        XCTAssertEqual(focused.focus, .station(station.id))
        try await capture(AnyView(homeView(day.morning, hour: 9, island: focused)), name: "path-d04-build-focus", scene: scene, folder: folder, settle: 2100) {
            XCTAssertNotNil(focused.homePlate)
        }

        // The burst: the build committed, the painting held at the old level while the station's ceremony plays.
        let island = IslandSceneModel(framing: .home)
        island.setHomePlate(paintedAs(day.visit, level: from, hour: 9))
        island.holdPresentedLevel(from)
        island.focusStation(station.id, animated: false)
        let now = day.visit.clock ?? Date()
        let home = WorldHomeModel(now: { now }, schedulesCues: false)
        home.camera = island
        let receipt = BuildReceipt(station: station.id, level: station.level, cost: Energy(10))
        home.buildStation(station.id, maxLevel: station.maxLevel) { _ in receipt }
        home.freeze(at: 0.6)
        let view = homeView(day.visit, hour: 9, island: island, settled: true, model: home)
        try await capture(AnyView(view), name: "path-d04-build-burst", scene: scene, folder: folder, settle: 2100) {
            XCTAssertEqual(island.levelStage.shown(worldLevel: day.visit.islandLevel), from, "the old painting is held during the burst")
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

/// Something that changes after a frame's first paint (a painting begins its cross-fade, the news button is
/// taken) and the frame waits `milliseconds` for it before it is taken.
struct PathFlip {
    let milliseconds: Int
    let action: () -> Void

    init(waiting milliseconds: Int, _ action: @escaping () -> Void) {
        self.milliseconds = milliseconds
        self.action = action
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
