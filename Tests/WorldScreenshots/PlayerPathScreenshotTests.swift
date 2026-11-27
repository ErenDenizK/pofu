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
/// - `path-dNN-1800`: Home at golden hour on days 1, 3, 5, 10, 12 and 21 (islands 1, 3, 4, 5, 6 and 7), day 1 on
///   the borrowed night plate, the others on their own golden plate;
/// - `path-d21-bell-0900`: Home on the morning the far bell rings, with
///   Pofu's line and its answer (the closing beat);
/// - `path-dNN-map-0900`: the Map on day 1 and on every day a new island
///   appeared (the harbor, the rumour, Koke, Çağlayan);
/// - `path-dNN-koke-0907`, `path-dNN-caglayan-0907`: the wonder island's stop on the
///   days the run visits it (its arrival and each stage), after the visit;
/// - `path-sheet-today`: the sheet over the painted Home (day 5);
/// - `path-card-station-a`, `-b`, `-b-open`, `-a-edge-left`, `-a-edge-right`, `-a-refused`, `-a-night`, `path-card-garden-a`:
///   the station card by the tea stall (day 5), in both variants and its edge cases;
/// - `path-d04-grow-0000`, `-1500`, `-2400`: "Ada büyüdü" by a build, at 0.0, 1.5 and 2.4 s of its moment
///   (the old painting whole and held, mid cross-fade with the bloom, the new painting with the "Ada n" card);
/// - `path-season-autumn-i10-0900-mill-l2`, `-mill-l5`, `path-season-autumn-i10-2300`: Home in autumn at island level 10 (the
///   Rehearsal season override: the season is not complete), by day over the windmill's level 2 and 5 looks and by night;
///   `path-season-turn-0000`, `-0750`, `-1000`, `-1250`, `-1500`: spring turning to autumn (the painting's cross-fade, 0.8 s
///   long, seen 0, 750, 1000, 1250 and 1500 ms after the season changes; the first 750 ms are still spring on the CI runner). The level 3 autumn state is not painted yet, so it has no frame;
/// - `path-d03-grew-0900`: the overnight landing on the old painting, Pofu's news line and its button;
///   `path-d03-grew-live-1800`: the same morning, 1.8 s after the button, through the live timers;
/// - `path-d04-build-focus`, `path-d04-build-burst`: a build's camera through the real `focusStation`
///   and the station's burst, over the held old painting;
/// - `path-d04-near-rest`: near at rest on Pofu, full size (the thin lens, WP11);
/// - `path-game-garden-midround`, `path-game-flow-stage1`: the minigames;
/// - `path-home-pass-pill`: Home with a running pass, the glass pill top leading;
/// - `path-hop-instagram-1200`: the Door, the midday reach for Instagram (the Hop screen the player meets);
/// - `path-onboarding-welcome`, `-apps`, `-name`, `-notifications`.
///
/// Every Home and Map frame asserts that its look has `homePlates` on and that the island
/// scene resolved a painting: a path frame is never the sprite island.
class PlayerPathFrameCase: XCTestCase {
    static let path = PlayerPath.tester()
    static let goldenDays: Set<Int> = [1, 3, 5, 10, 12, 21]

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
            if Self.goldenDays.contains(day.day) {
                // Golden hour: day 1 (IL1) keeps the borrowed night plate, days 3 (IL3), 5 (IL4), 10 (IL5), 12 (IL6)
                // and 21 (IL7) paint their own golden plate.
                try await home(day.morning, hour: 18, beads: [], name: "path-d\(nn)-1800", scene: scene, folder: folder)
            }
            if day.day == 16 {
                // The skip pots by day: four skips (blooms) and one open (a bud), for the painted bloom.
                try await home(day.morning, hour: 15, beads: [true, true, false, true, true], name: "path-d\(nn)-pots-1500", scene: scene, folder: folder)
            }
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
        beats: [VisitBeat]? = nil, model: WorldHomeModel? = nil, pofuStand: WorldPoint? = nil, season: Season? = nil
    ) -> some View {
        var look = WorldLook.playerPath(hour: hour)
        look.pofuStand = pofuStand
        look.seasonOverride = season
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
        let island = IslandSceneModel(framing: .mid)
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
        let island = IslandSceneModel(framing: .mid)
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
        for (name, fraction) in [("path-sheet-today", 0.9)] {
            let island = IslandSceneModel(framing: .mid)
            let back = homeView(day.morning, hour: 11, island: island, settled: true)
            let view = AnyView(PathSheetFrame(fraction: fraction, back: AnyView(back)) { TodaySheet(model: model, hourOverride: 11) })
            try await capture(view, name: name, scene: scene, folder: folder, settle: 2100) {
                XCTAssertNotNil(island.homePlate, "\(name): the sheet sits over the painted Home")
            }
        }
    }

    /// The station card, in its two variants, as the player meets it on day 5: the tea stall, Hap opened, the
    /// leftmost and rightmost stations, a refused build, the night plate and the garden's play.
    @MainActor
    func testRenderTheStationCards() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = Self.path[4]
        let defaults = UserDefaults.standard
        defer { defaults.removeObject(forKey: StationCardVariant.storageKey) }
        let plate = paintedAs(day.morning, level: day.morning.islandLevel, hour: 11)
        let built = day.morning.stations.filter { $0.level > 0 && plate?.stationBox($0.id) != nil }
        let byX = built.sorted { (plate?.stationBox($0.id)?.midX ?? 0) < (plate?.stationBox($1.id)?.midX ?? 0) }
        guard let left = byX.first?.id, let right = byX.last?.id else { return XCTFail("no built stations on the plate") }
        var poor = day.morning
        poor.jar = Energy(1)
        XCTAssertNotNil(poor.stations.first { $0.id == .teaStall }?.nextCost, "the tea stall has a next level to be refused")
        let frames: [(name: String, variant: StationCardVariant, station: StationID, world: WorldSnapshot, hour: Double, open: Bool)] = [
            ("path-card-station-a", .tag, .teaStall, day.morning, 11, false),
            ("path-card-station-b", .pill, .teaStall, day.morning, 11, false),
            ("path-card-station-b-open", .pill, .teaStall, day.morning, 11, true),
            ("path-card-station-a-edge-left", .tag, left, day.morning, 11, false),
            ("path-card-station-a-edge-right", .tag, right, day.morning, 11, false),
            ("path-card-station-a-refused", .tag, .teaStall, poor, 11, false),
            ("path-card-station-a-night", .tag, .teaStall, day.morning, 22, false),
            ("path-card-garden-a", .tag, .garden, day.morning, 11, false),
        ]
        for frame in frames {
            defaults.set(frame.variant.rawValue, forKey: StationCardVariant.storageKey)
            let island = IslandSceneModel(framing: .mid)
            let view = homeView(frame.world, hour: frame.hour, island: island, settled: true)
            let focus = PathFlip(waiting: 1500) {
                // Home sets these from its actions on appear; the frame wants the garden's door open.
                island.playableRounds = 2
                island.onPlay = {}
                island.focusStation(frame.station, animated: false)
                island.cardExpanded = frame.open
            }
            try await capture(AnyView(view), name: frame.name, scene: scene, folder: folder, settle: 2100, flip: focus) {
                XCTAssertEqual(island.card?.station, frame.station, "\(frame.name): the card hangs by its station")
            }
        }
    }

    /// A running pass on the painted Home: the glass pill top leading, level with the gear
    /// (`HomeView` places the same view the same way).
    @MainActor
    func testRenderThePassPill() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = Self.path[4]
        let island = IslandSceneModel(framing: .mid)
        let back = homeView(day.morning, hour: 11, island: island, settled: true)
        let view = ZStack {
            back
            VStack {
                HStack {
                    PassPill(app: .instagram, fallbackName: "instagram", minutesLeft: 4, refund: Energy(3), onEnd: {})
                    Spacer(minLength: 0)
                }
                .padding(.top, PofuSpacing.s)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, PofuSpacing.screen)
        }
        try await capture(AnyView(view), name: "path-home-pass-pill", scene: scene, folder: folder, settle: 2100) {
            XCTAssertNotNil(island.homePlate, "the pill sits over the painted Home")
        }
    }

    /// The Door (Hop): the reach for Instagram at midday, the screen a player meets right after the shield.
    @MainActor
    func testRenderTheDoor() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let model = AppModel.shared
        model.startHop(for: .instagram)
        defer { model.dismissHop() }
        try await capture(AnyView(HopView(model: model, hourOverride: .day)), name: "path-hop-instagram-1200", scene: scene, folder: folder, settle: 1200)
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
            let island = IslandSceneModel(framing: .mid)
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
        let island = IslandSceneModel(framing: .mid)
        island.setHomePlate(paintedAs(day.morning, level: to - 1, hour: 9))
        island.holdPresentedLevel(to - 1)
        let view = homeView(day.morning, hour: 9, island: island, beats: beats)
        try await capture(AnyView(view), name: "path-d03-grew-0900", scene: scene, folder: folder, settle: 2100) {
            XCTAssertNotNil(island.homePlate)
            XCTAssertFalse(island.isGrowing, "the news waits for its button")
            XCTAssertEqual(island.levelStage.shown(worldLevel: to), to - 1, "the app lands on the old painting")
        }

        // The button: the news beat is taken and the moment plays from the live timers.
        let live = IslandSceneModel(framing: .mid)
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

    /// The tea stall's looks on Home (WP8): the stall's level shows at every island level whose day plate has an
    /// erased base (islands 3, 4, 6, 7). Island 3 at stall levels 1, 3 and 5 (`path-stall-l<level>`), the other
    /// islands at levels 1 and 5 (`path-stall-i<island>-l<level>`), at noon (the stall's base is the day plate), one
    /// frame each. A level 5 stall on a young island is not a state the player reaches today; the frames are for the
    /// looks. Islands 5 and 2 keep their painted stall (no clean base) and are shown as controls.
    @MainActor
    func testRenderTheTeaStallLooks() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == 3 }, "the path has a level 3 island")
        let frames: [(island: Int, levels: [Int])] = [(3, [1, 3, 5]), (4, [1, 5]), (5, [3]), (6, [1, 5]), (7, [1, 5]), (2, [3])]
        for (islandLevel, levels) in frames {
            for level in levels {
                var world = day.morning
                world.islandLevel = islandLevel
                world.stations = world.stations.map { status in
                    var status = status
                    if status.id == .teaStall { status.level = level }
                    return status
                }
                let island = IslandSceneModel(framing: .mid)
                let view = homeView(world, hour: 12, island: island, settled: true)
                let name = islandLevel == 3 ? "path-stall-l\(level)" : "path-stall-i\(islandLevel)-l\(level)"
                try await capture(AnyView(view), name: name, scene: scene, folder: folder, settle: 2100) {
                    XCTAssertNotNil(island.homePlate, "\(name): Home is its painting")
                }
            }
        }
    }

    /// The windmill's looks on Home (plan row 1b): its level shows at the island levels whose day plate has an erased
    /// base (10 to 8: stages 0 to 2). Island 10 at windmill levels 1
    /// to 5 (`path-mill-l<level>`; level 1 has no look that ships and draws the empty plot), island 9 at level 3
    /// (`path-mill-i9-l3`), and island 8 at level 3 (`path-mill-i8-l3`, its base wired with 1c), at noon. A level 5 mill on island
    /// 10 is not a state the player reaches today; the frames are for the looks.
    @MainActor
    func testRenderTheWindmillLooks() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == 3 }, "the path has a level 3 island")
        let frames: [(island: Int, level: Int)] = [(10, 1), (10, 2), (10, 3), (10, 4), (10, 5), (9, 3), (8, 3)]
        for (islandLevel, level) in frames {
            var world = day.morning
            world.islandLevel = islandLevel
            XCTAssertTrue(world.stations.contains { $0.id == .windmill }, "the windmill is a station of the world")
            world.stations = world.stations.map { status in
                var status = status
                if status.id == .windmill { status.level = level }
                return status
            }
            let island = IslandSceneModel(framing: .mid)
            let view = homeView(world, hour: 12, island: island, settled: true)
            let name = islandLevel == 10 ? "path-mill-l\(level)" : "path-mill-i\(islandLevel)-l\(level)"
            try await capture(AnyView(view), name: name, scene: scene, folder: folder, settle: 2100) {
                XCTAssertNotNil(island.homePlate, "\(name): Home is its painting")
            }
        }
    }

    /// Home in autumn at island level 10 (season-system-v1 S3): by day over the windmill's levels 2 and 5, by night, and the
    /// turn from spring (a season change is a cross-fade of two whole paintings, like a level's). The season is the Rehearsal
    /// override, because autumn is not `complete`: the frames show what the stepper shows on the phone.
    @MainActor
    func testRenderTheAutumnSlice() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == 3 }, "the path has a level 3 island")
        func world(windmill level: Int) -> WorldSnapshot {
            var world = day.morning
            world.islandLevel = 10
            world.stations = world.stations.map { status in
                var status = status
                if status.id == .windmill { status.level = level }
                return status
            }
            return world
        }
        for (name, level, hour) in [("path-season-autumn-i10-0900-mill-l2", 2, 9.0), ("path-season-autumn-i10-0900-mill-l5", 5, 9.0), ("path-season-autumn-i10-2300", 3, 23.0)] {
            let island = IslandSceneModel(framing: .mid)
            let view = homeView(world(windmill: level), hour: hour, island: island, settled: true, season: .autumn)
            try await capture(AnyView(view), name: name, scene: scene, folder: folder, settle: 2100) {
                XCTAssertEqual(island.homePlate?.season, .autumn, "\(name): the state is autumn's own painting")
            }
        }
        for (name, ms) in [("0000", 0), ("0750", 750), ("1000", 1000), ("1250", 1250), ("1500", 1500)] {
            let dial = PathSeasonDial()
            let island = IslandSceneModel(framing: .mid)
            let shown = world(windmill: 3)
            let view = PathSeasonFrame(dial: dial) { season in
                AnyView(self.homeView(shown, hour: 9, island: island, settled: true, season: season))
            }
            try await capture(AnyView(view), name: "path-season-turn-\(name)", scene: scene, folder: folder, settle: 2100, flip: PathFlip(waiting: ms) { dial.season = .autumn }) {
                XCTAssertNotNil(island.homePlate, "path-season-turn-\(name): Home is its painting")
            }
        }
    }

    /// The pond's looks on Home (plan row 1c): its level shows at the island levels whose day plate has an erased base for
    /// it (10 to 7: stages 0 to 3). Island 10 at pond levels 1 to 5 (`path-pond-l<level>`), island 8 at level 3
    /// (`path-pond-i8-l3`, the windmill's base is shared) and island 7 at level 3 (`path-pond-i7-l3`, the tea stall's), at
    /// noon. A level 5 pond on island 10 is not a state the player reaches today; the frames are for the looks.
    @MainActor
    func testRenderThePondLooks() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == 3 }, "the path has a level 3 island")
        let frames: [(island: Int, level: Int)] = [(10, 1), (10, 2), (10, 3), (10, 4), (10, 5), (8, 3), (7, 3)]
        for (islandLevel, level) in frames {
            var world = day.morning
            world.islandLevel = islandLevel
            XCTAssertTrue(world.stations.contains { $0.id == .pond }, "the pond is a station of the world")
            world.stations = world.stations.map { status in
                var status = status
                if status.id == .pond { status.level = level }
                return status
            }
            let island = IslandSceneModel(framing: .mid)
            let view = homeView(world, hour: 12, island: island, settled: true)
            let name = islandLevel == 10 ? "path-pond-l\(level)" : "path-pond-i\(islandLevel)-l\(level)"
            try await capture(AnyView(view), name: name, scene: scene, folder: folder, settle: 2100) {
                XCTAssertNotNil(island.homePlate, "\(name): Home is its painting")
            }
        }
    }

    /// The workshop's looks on Home (plan row 1c): island 10 at levels 1 to 5 of each (`path-garden-l<level>`,
    /// `path-workshop-l<level>`), at noon, and at 22:00 for the night control (the looks are day art, the night keeps its painted
    /// stations). The other stations stay at level 3. Level 5 on island 10 is not a state the player reaches; the frames are for the looks.
    @MainActor
    func testRenderTheWorkshopLooks() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == 3 }, "the path has a level 3 island")
        for (id, name) in [(StationID.workshop, "workshop")] {
            for level in 1...5 {
                for (hour, suffix) in [(12.0, ""), (22.0, "-night")] where level == 3 || hour == 12 {
                    var world = day.morning
                    world.islandLevel = 10
                    XCTAssertTrue(world.stations.contains { $0.id == id }, "\(name) is a station of the world")
                    world.stations = world.stations.map { status in
                        var status = status
                        if status.id == id { status.level = level }
                        return status
                    }
                    let island = IslandSceneModel(framing: .mid)
                    let view = homeView(world, hour: hour, island: island, settled: true)
                    let frame = "path-\(name)-l\(level)\(suffix)"
                    try await capture(AnyView(view), name: frame, scene: scene, folder: folder, settle: 2100) {
                        XCTAssertNotNil(island.homePlate, "\(frame): Home is its painting")
                    }
                }
            }
        }
    }

    /// The whole island at mixed station levels, one frame per island stage that has looks (plan row 1c,
    /// `path-levels-i<island level>`): judged whole, no station takes over the island. Island 10: windmill 3, pond 2;
    /// island 9: windmill 4, pond 3; island 8: windmill 2, pond 4; island 7: tea stall 3, pond 1; at noon.
    @MainActor
    func testRenderTheMixedLevels() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == 3 }, "the path has a level 3 island")
        let frames: [(island: Int, levels: [StationID: Int])] = [
            (10, [.windmill: 3, .pond: 2, .workshop: 1]), (9, [.windmill: 4, .pond: 3, .workshop: 5]),
            (8, [.windmill: 2, .pond: 4, .workshop: 3]), (7, [.teaStall: 3, .pond: 1, .workshop: 4]),
        ]
        for (islandLevel, levels) in frames {
            var world = day.morning
            world.islandLevel = islandLevel
            world.stations = world.stations.map { status in
                var status = status
                if let level = levels[status.id] { status.level = level }
                return status
            }
            let island = IslandSceneModel(framing: .mid)
            let view = homeView(world, hour: 12, island: island, settled: true)
            let name = "path-levels-i\(islandLevel)"
            try await capture(AnyView(view), name: name, scene: scene, folder: folder, settle: 2100) {
                XCTAssertNotNil(island.homePlate, "\(name): Home is its painting")
            }
        }
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
        let focused = IslandSceneModel(framing: .mid)
        focused.setHomePlate(paintedAs(day.morning, level: from, hour: 9))
        focused.focusStation(station.id, animated: false)
        XCTAssertEqual(focused.focus, .station(station.id))
        try await capture(AnyView(homeView(day.morning, hour: 9, island: focused)), name: "path-d04-build-focus", scene: scene, folder: folder, settle: 2100) {
            XCTAssertNotNil(focused.homePlate)
        }

        // Near at rest on Pofu, full size (WP11's lens: the band edges and his feet at 1:1).
        let near = IslandSceneModel(framing: .mid)
        near.setHomePlate(paintedAs(day.morning, level: from, hour: 9))
        near.holdNearRest()
        try await capture(AnyView(homeView(day.morning, hour: 9, island: near)), name: "path-d04-near-rest", scene: scene, folder: folder, settle: 2100) {
            XCTAssertNotNil(near.homePlate)
        }

        // The burst: the build committed, the painting held at the old level while the station's ceremony plays.
        let island = IslandSceneModel(framing: .mid)
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

    /// The plate compositor (WP10): island 3 at noon, the tea stall at level 3, Pofu stood at the nearest of his spots to the stall's
    /// foot and just in front of it (`path-stall-pofu-nearest-spot`, `-front`: the look sorts with him by `footY`), and the
    /// same state on the Map (`path-stall-map-l3`: the far picture, a snapshot of the composite). The snapshot's
    /// render time is printed (`FarSnapshot:`), cold and warm.
    @MainActor
    func testRenderThePlateCompositor() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == 3 }, "the path has a level 3 island")
        var world = day.morning
        world.islandLevel = 3
        world.stations = world.stations.map { status in
            var status = status
            if status.id == .teaStall { status.level = 3 }
            return status
        }
        let plate = try XCTUnwrap(paintedAs(world, level: 3, hour: 12))
        let compositor = PlateCompositor(plate: plate, levels: HomePlate.stationLevels(world))
        let look = try XCTUnwrap(compositor.looks.first { $0.station == "teaStall" }, "island 3 has the stall's look")
        let x = plate.plate(look.foot).x
        // Pofu at the nearest of his spots to the stall's foot (whole: his spots are clear of every taller occluder),
        // and just in front of the stall's foot.
        let nearest = try XCTUnwrap(plate.plate.spots["pofu"]?.min { a, b in
            hypot(a.x - x, a.y - look.footY) < hypot(b.x - x, b.y - look.footY)
        })
        for (name, at) in [("path-stall-pofu-nearest-spot", nearest), ("path-stall-pofu-front", PlatePoint(x: x - 8, y: look.footY + 30))] {
            let stand = plate.world(at)
            let island = IslandSceneModel(framing: .mid)
            let view = homeView(world, hour: 12, island: island, settled: true, pofuStand: stand)
            try await capture(AnyView(view), name: name, scene: scene, folder: folder, settle: 2100) {
                XCTAssertNotNil(island.homePlate, "\(name): Home is its painting")
            }
        }
        let rendersBefore = FarSnapshot.renders
        try await map(world, hour: 12, name: "path-stall-map-l3", scene: scene, folder: folder)
        print("FarSnapshot: \(FarSnapshot.renders - rendersBefore) render(s), last \(FarSnapshot.lastRenderMilliseconds ?? -1) ms (key \(compositor.snapshotKey))")
        // A warm render of another state (the stall one level up), timed alone.
        var next = world
        next.stations = next.stations.map { status in
            var status = status
            if status.id == .teaStall { status.level = 4 }
            return status
        }
        try await map(next, hour: 12, name: "path-stall-map-l4", scene: scene, folder: folder)
        print("FarSnapshot: warm, last \(FarSnapshot.lastRenderMilliseconds ?? -1) ms, \(FarSnapshot.renders) renders in all")
    }

    /// The day-10 island's characters seen at more than one spot: `path-life-d10-1...6`, one visit pinned at six
    /// seconds (everyone on their painted spot; one hop in the air; each of the three after their move), and
    /// `path-card-resident-moved`, Mochi's or Fındık's card opened at a spot that is not the painted one.
    @MainActor
    func testRenderTheCharactersChangingSpots() async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = Self.path[9]
        let world = day.morning
        let plate = try XCTUnwrap(paintedAs(world, level: world.islandLevel, hour: 12))
        let spots = plate.plate.spots
        let built: (StationID) -> Bool = { station in (world.stations.first { $0.id == station }?.level ?? 0) > 0 }
        let present = ["pofu"] + (built(.teaStall) ? ["mochi"] : []) + (built(.workshop) ? ["findik"] : [])
        // Who stands on the day-10 plate follows the built stations; the strip shows every one of them moving.
        let movers = present.count
        XCTAssertGreaterThanOrEqual(movers, 2, "day 10 has Pofu and at least one resident")
        let first = ResidentLife.day(of: world.clock ?? day.morningAt)
        // A pinned day whose first moves are each a different character, over the first five minutes.
        var picked: (day: Int, moves: [PlateMoves.Move])?
        for candidate in first..<(first + 200) {
            var state = PlateMoves.State()
            var moves: [PlateMoves.Move] = []
            var t = 0.0
            while t < 300, moves.count < movers {
                state.advance(day: candidate, elapsed: t, spots: spots, present: present, allowed: true)
                if let move = state.active, !moves.contains(where: { $0.slot == move.slot }) { moves.append(move) }
                t += 0.05
            }
            if moves.count == movers, Set(moves.map(\.id)).count == movers {
                picked = (candidate, moves)
                break
            }
        }
        let chosen = try XCTUnwrap(picked, "a day whose first moves are each a different character")
        let a = chosen.moves[0], b = chosen.moves[1]
        var times = [
            1.0,
            a.start + PlateMoves.hopSeconds / 2,
            a.start + a.duration + 1,
            b.start + PlateMoves.hopSeconds / 2,
            b.start + b.duration + 1,
        ]
        if let c = chosen.moves.dropFirst(2).first { times.append(c.start + c.duration + 1) }
        for (index, t) in times.enumerated() {
            let island = IslandSceneModel(framing: .mid)
            let view = homeView(world, hour: 12, island: island, settled: true)
                .environment(\.worldResidentPin, ResidentLife.Pin(day: chosen.day, elapsed: t))
            try await capture(AnyView(view), name: "path-life-d10-\(index + 1)", scene: scene, folder: folder, settle: 2100) {
                XCTAssertNotNil(island.homePlate, "path-life-d10-\(index + 1): Home is its painting")
            }
        }

        // Mochi's or Fındık's card, a little after their move, over the spot they stand on now.
        let mover = try XCTUnwrap(chosen.moves.first { $0.id != "pofu" })
        let after = mover.start + mover.duration + 1
        let island = IslandSceneModel(framing: .mid)
        island.setHomePlate(plate)
        island.stand(mover.id, at: plate.world(mover.to))
        island.focusResident(ResidentID(rawValue: mover.id), animated: false)
        XCTAssertEqual(island.focus, .resident(ResidentID(rawValue: mover.id)))
        let view = homeView(world, hour: 12, island: island, settled: true)
            .environment(\.worldResidentPin, ResidentLife.Pin(day: chosen.day, elapsed: after))
        try await capture(AnyView(view), name: "path-card-resident-moved", scene: scene, folder: folder, settle: 2100) {}
    }

    /// The tea stall's level-up reveal (v2 §9.2) from level 2 to 3 on island 3, the moment frozen at the focus
    /// (0.45 s), the dip (0.74 s), the ring opening with its honey rim (1.0 s), the settle (1.6 s) and settled (2.4 s):
    /// `path-stall-reveal-<ms>`.
    @MainActor
    func testRenderTheStallReveal() async throws {
        try await renderReveal(.teaStall, name: "stall", islandLevel: 3, from: 2, times: [0.45, 0.74, 1.0, 1.6, 2.4])
    }

    /// The windmill's and the pond's reveals, level 2 to 3 on island level 8 (stage 2, where both stand as looks):
    /// `path-windmill-reveal-<ms>`, `path-pond-reveal-<ms>` at the dip (0.74 s), the ring's peak (1.0 s) and the
    /// settle (1.6 s).
    @MainActor
    func testRenderTheWindmillAndPondReveals() async throws {
        try await renderReveal(.windmill, name: "windmill", islandLevel: 8, from: 2, times: [0.74, 1.0, 1.6])
        try await renderReveal(.pond, name: "pond", islandLevel: 8, from: 2, times: [0.74, 1.0, 1.6])
    }

    @MainActor
    private func renderReveal(_ station: StationID, name: String, islandLevel: Int, from: Int, times: [Double]) async throws {
        let scene = try windowScene()
        let folder = try outputFolder()
        let day = try XCTUnwrap(Self.path.first { $0.morning.islandLevel == 3 }, "the path has a level 3 island")
        func world(_ level: Int) -> WorldSnapshot {
            var world = day.morning
            world.islandLevel = islandLevel
            world.stations = world.stations.map { status in
                var status = status
                if status.id == station { status.level = level }
                return status
            }
            return world
        }
        let after = world(from + 1)
        let maxLevel = after.stations.first { $0.id == station }?.maxLevel ?? 10
        for t in times {
            let island = IslandSceneModel(framing: .mid)
            island.setHomePlate(paintedAs(after, level: islandLevel, hour: 12))
            island.focusStation(station, animated: false)
            let now = after.clock ?? Date()
            let home = WorldHomeModel(now: { now }, schedulesCues: false)
            home.camera = island
            home.buildStation(station, maxLevel: maxLevel) { _ in BuildReceipt(station: station, level: from + 1, cost: Energy(10)) }
            XCTAssertTrue(home.build?.moment.reveal ?? false, "the \(name)'s build plays the look's reveal")
            home.freeze(at: t)
            let view = homeView(after, hour: 12, island: island, settled: true, model: home)
            try await capture(AnyView(view), name: "path-\(name)-reveal-\(Int(t * 1000))", scene: scene, folder: folder, settle: 2100) {}
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

        // The flow game on the dial board: the start, mid-way with the hint, solved, the 6 by 5 board of stage 4
        // and a dial pinned mid-turn.
        try await renderFlow("path-game-flow-stage1", stage: 1, scene: scene, folder: folder) { _ in }
        try await renderFlow("path-game-flow-stage1-mid", stage: 1, scene: scene, folder: folder) { model in
            model.playSuggestedTap()
            try await Task.sleep(for: .milliseconds(900))
            await model.showHintNow()
            try await Task.sleep(for: .milliseconds(700))
        }
        try await renderFlow("path-game-flow-stage1-solved", stage: 1, scene: scene, folder: folder) { model in
            while model.phase == .playing, model.playSuggestedTap() {
                try await Task.sleep(for: .milliseconds(350))
            }
            try await Task.sleep(for: .milliseconds(1100))
        }
        // Stage 4's second board is the 6 by 5 one; the first is solved by hand to reach it.
        try await renderFlow("path-game-flow-stage4", stage: 4, scene: scene, folder: folder) { model in
            while model.phase == .playing, model.playSuggestedTap() {
                try await Task.sleep(for: .milliseconds(120))
            }
            try await Task.sleep(for: .milliseconds(600))
            model.continueNow()
            try await Task.sleep(for: .milliseconds(1400))
        }
        try await renderFlow("path-game-flow-turning", stage: 1, scene: scene, folder: folder) { model in
            XCTAssertTrue(model.holdSuggestedTurn(fraction: 0.45), "stage 1's first move turns a dial")
            try await Task.sleep(for: .milliseconds(60))
        }
    }

    @MainActor
    private func renderFlow(
        _ name: String, stage: Int, scene: UIWindowScene, folder: URL,
        prepare: (FlowGameModel) async throws -> Void
    ) async throws {
        let round = try XCTUnwrap(FlowLibrary.round(stage: stage))
        let flow = FlowGameModel(round: round, hintDelay: .seconds(600), pourPause: .seconds(600))
        let flowWindow = gameWindow(FlowGameView(model: flow), scene: scene)
        try await Task.sleep(for: .milliseconds(900))
        try await prepare(flow)
        flow.freeze()
        try await Task.sleep(for: .milliseconds(250))
        try write(snapshot(flowWindow), name: name, to: folder)
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
/// The season a frame is drawn in, changed after the first paint (`PlayerPathFrameCase.testRenderTheAutumnSlice`: the turn).
@MainActor
final class PathSeasonDial: ObservableObject {
    @Published var season: Season?
}

/// A view that reads its season from a `PathSeasonDial`, so a frame can start in spring and turn.
struct PathSeasonFrame: View {
    @ObservedObject var dial: PathSeasonDial
    let content: (Season?) -> AnyView

    var body: some View { content(dial.season) }
}

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
