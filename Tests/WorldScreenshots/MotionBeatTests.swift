import Observation
import PofuCore
import PofuDesignSystem
import PofuGames
import PofuWorld
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// Motion review ("beats", pro game craft §3.3, upgrade 1): short scripted
/// moments played in real time in the simulator while the CI host records
/// the screen with `xcrun simctl io recordVideo`. The founder watches the
/// clips on his phone; stills cannot show feel.
///
/// The test and the recorder meet in a folder both can see,
/// `MOTION_BEATS_DIR` (CI passes `TEST_RUNNER_MOTION_BEATS_DIR`; the
/// simulator shares the host's file system):
///
/// 1. the test lays the beat out, lets it settle, and writes
///    `<beat>.request`;
/// 2. the recorder starts `recordVideo` and answers `<beat>.recording`;
/// 3. the test plays the beat's script, then writes `<beat>.done`;
/// 4. the recorder stops the recording (SIGINT) and answers `<beat>.saved`.
///
/// Without the folder (a plain screenshot run, or Xcode) the test skips.
/// Recordings on CI virtual machines drop frames: judge choreography and
/// timing from them, not smoothness. See `.github/scripts/record-beats.sh`.
final class MotionBeatTests: XCTestCase {
    typealias Script = @MainActor () async throws -> Void

    private struct Beat {
        var name: String
        var title: String
        var style: UIUserInterfaceStyle = .light
        var makeView: @MainActor () -> (view: AnyView, script: Script)
    }

    @MainActor
    func testRecordTheBeats() async throws {
        guard let path = ProcessInfo.processInfo.environment["MOTION_BEATS_DIR"], !path.isEmpty else {
            throw XCTSkip("MOTION_BEATS_DIR is not set: no recorder is listening")
        }
        let folder = URL(fileURLWithPath: path, isDirectory: true)
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        var lines: [String] = []
        for beat in beats() {
            let started = Date()
            try await record(beat, in: scene, folder: folder)
            lines.append("\(beat.name)\t\(beat.title)\t\(String(format: "%.1f", Date().timeIntervalSince(started)))")
        }
        try lines.joined(separator: "\n").write(to: folder.appendingPathComponent("beats.tsv"), atomically: true, encoding: .utf8)
        FileManager.default.createFile(atPath: folder.appendingPathComponent("all.done").path, contents: nil)
    }

    // MARK: - The beat list

    @MainActor
    private func beats() -> [Beat] {
        [
            Beat(name: "01-home-idle", title: "Home idle, 5 s") {
                let stage = BeatWorld(framing: .home, settled: true)
                let script: Script = {
                    try await Task.sleep(for: .seconds(5))
                }
                return (AnyView(stage.view), script)
            },
            Beat(name: "02-home-to-island", title: "Home to Island and back") {
                let stage = BeatWorld(framing: .home, settled: true)
                let script: Script = {
                    try await Task.sleep(for: .milliseconds(600))
                    stage.island.go(to: .island)
                    try await Task.sleep(for: .milliseconds(3000))
                    stage.island.go(to: .home)
                    try await Task.sleep(for: .milliseconds(2800))
                }
                return (AnyView(stage.view), script)
            },
            Beat(name: "03-collect", title: "Collect the seeds") {
                let stage = BeatWorld(framing: .home, settled: false)
                let script: Script = {
                    try await Task.sleep(for: .milliseconds(700))
                    stage.collect()
                    try await Task.sleep(for: .milliseconds(4800))
                }
                return (AnyView(stage.view), script)
            },
            Beat(name: "04-build", title: "Build a level") {
                let stage = BeatWorld(framing: .island, settled: false, collected: true)
                let script: Script = {
                    try await Task.sleep(for: .milliseconds(500))
                    let station = stage.world.buildableStation ?? .cay
                    stage.island.focusStation(station)
                    try await Task.sleep(for: .milliseconds(1500))
                    stage.build(station)
                    try await Task.sleep(for: .milliseconds(4500))
                }
                return (AnyView(stage.view), script)
            },
            Beat(name: "06-island-pan", title: "Arrive at the island, pan, flick, snap") {
                let stage = BeatWorld(framing: .island, settled: true)
                let island = stage.island
                // A finger dragging `distance` points over `seconds`, then
                // lifting at `velocity` points a second.
                @MainActor func drag(_ distance: Double, over seconds: Double, release velocity: Double) async throws {
                    let steps = 24
                    for i in 1...steps {
                        let t = Double(i) / Double(steps)
                        island.scriptedDrag(dx: distance * (1 - (1 - t) * (1 - t)))
                        try await Task.sleep(for: .seconds(seconds / Double(steps)))
                    }
                    island.scriptedRelease(velocityX: velocity)
                }
                let script: Script = {
                    // The establishing shot plays on arrival, then settles on Pofu.
                    try await Task.sleep(for: .milliseconds(2200))
                    // A slow drag left (toward the çay ocağı), released gently: it snaps.
                    try await drag(-140, over: 0.7, release: -120)
                    try await Task.sleep(for: .milliseconds(1400))
                    // A flick right: momentum carries it to the far end, banded.
                    try await drag(160, over: 0.25, release: 1400)
                    try await Task.sleep(for: .milliseconds(1600))
                    // Past the end: the rubber band, then back.
                    try await drag(220, over: 0.5, release: 0)
                    try await Task.sleep(for: .milliseconds(1400))
                    // Back to Pofu.
                    island.pan(to: nil)
                    try await Task.sleep(for: .milliseconds(1400))
                }
                return (AnyView(stage.view), script)
            },
            Beat(name: "05-shield-hop", title: "The shield, then Hop!") {
                let stage = ShieldHopStage(model: AppModel.shared)
                let script: Script = {
                    try await Task.sleep(for: .milliseconds(2600))
                    stage.hop()
                    try await Task.sleep(for: .milliseconds(5000))
                    stage.finish()
                }
                return (AnyView(ShieldHopBeat(stage: stage)), script)
            },
            Beat(name: "07-garden-round", title: "A garden round to its harvest and card") {
                // A nine-plot bag, played by the autoplayer about as fast as
                // a calm player, to the harvest and the round's card.
                let model = GardenGameModel(seed: 9, config: GardenRound.Config(piecesPerRound: 9))
                let script: Script = {
                    for _ in 0..<9 {
                        guard model.playSuggestedMove() else { break }
                        try await Task.sleep(for: .milliseconds(1300))
                    }
                    try await Task.sleep(for: .milliseconds(4500))
                }
                return (AnyView(GardenGameView(model: model)), script)
            },
        ]
    }

    // MARK: - Recording

    @MainActor
    private func record(_ beat: Beat, in scene: UIWindowScene, folder: URL) async throws {
        let (view, script) = beat.makeView()
        let host = UIHostingController(rootView: view)
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = beat.style
        window.rootViewController = host
        window.windowLevel = .alert + 3
        window.makeKeyAndVisible()
        defer {
            if host.presentedViewController != nil {
                host.dismiss(animated: false)
            }
            window.isHidden = true
            window.rootViewController = nil
        }
        // Lay out and let the first frame settle before the camera rolls.
        try await Task.sleep(for: .milliseconds(1200))

        try signal(beat.name, "request", in: folder)
        try await awaitSignal(beat.name, "recording", in: folder, timeout: 240)
        try await Task.sleep(for: .milliseconds(300))
        try await script()
        try await Task.sleep(for: .milliseconds(300))
        try signal(beat.name, "done", in: folder)
        try await awaitSignal(beat.name, "saved", in: folder, timeout: 60)
        try await Task.sleep(for: .milliseconds(200))
    }

    @MainActor
    private func signal(_ beat: String, _ step: String, in folder: URL) throws {
        try Data().write(to: folder.appendingPathComponent("\(beat).\(step)"))
    }

    @MainActor
    private func awaitSignal(_ beat: String, _ step: String, in folder: URL, timeout: TimeInterval) async throws {
        let url = folder.appendingPathComponent("\(beat).\(step)")
        let deadline = Date().addingTimeInterval(timeout)
        while !FileManager.default.fileExists(atPath: url.path) {
            if Date() > deadline {
                XCTFail("The recorder did not answer \(beat).\(step) within \(Int(timeout)) s")
                throw CancellationError()
            }
            try await Task.sleep(for: .milliseconds(100))
        }
    }
}

// MARK: - World beats

/// The sample game, observable so Collect and Build redraw the world.
@MainActor
@Observable
private final class BeatGame {
    var game = IslandSamples.playedWeek()

    func inputs(lastSettled: Date? = nil) -> VisitInputs {
        VisitInputs(now: game.now, world: game.snapshot, lastSettled: lastSettled, calendar: .current)
    }

    var buildableStation: StationID? {
        let world = game.snapshot
        if case .build(let station, _)? = VisitQueue.affordableBuild(in: world, seeds: world.jar) {
            return station
        }
        return nil
    }
}

/// Home as the app shows it, live (not still-frame): clouds drift, Pofu
/// breathes and blinks, moments play in real time.
@MainActor
private final class BeatWorld {
    let world: BeatGame
    let island: IslandSceneModel
    let home: WorldHomeModel

    init(framing: WorldFraming, settled: Bool, collected: Bool = false) {
        let world = BeatGame()
        self.world = world
        island = IslandSceneModel(framing: framing)
        home = WorldHomeModel(now: { Date() })
        if settled || collected {
            _ = world.game.collect()
        }
        let lastSettled: Date? = settled ? world.game.now.addingTimeInterval(-5 * 60) : nil
        home.beginVisit(VisitQueue.plan(world.inputs(lastSettled: lastSettled)))
    }

    var view: some View {
        BeatHome(world: world, island: island, home: home)
    }

    /// What Home's Collect button does: seeds leave the built stations
    /// and Pofu and fly to the pill at the top.
    func collect() {
        let snapshot = world.game.snapshot
        var points: [WorldPoint] = snapshot.stations
            .filter { $0.island == .aycicegi && $0.level > 0 }
            .compactMap { status in
                IslandLayout.stationAnchors[status.id].map { WorldPoint(x: $0.x, y: $0.y - 24) }
            }
        points.append(WorldPoint(x: IslandLayout.pofu.x, y: IslandLayout.pofu.y - 30))
        let screen = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.screen
        let width = Double(screen?.bounds.width ?? 402)
        let sources = points.map { point in
            let p = island.screenPoint(of: point)
            return MomentPoint(x: min(max(p.x, 16), width - 16), y: max(p.y, 140))
        }
        let world = world
        home.collectSeeds(
            jarBefore: snapshot.jar.units,
            sources: sources,
            target: MomentPoint(x: width / 2, y: 74),
            commit: { world.game.collect() }
        )
    }

    func build(_ station: StationID) {
        let maxLevel = world.game.snapshot.stations.first { $0.id == station }?.maxLevel ?? 5
        let world = world
        home.buildStation(station, maxLevel: maxLevel) { world.game.build($0) }
    }
}

private struct BeatHome: View {
    let world: BeatGame
    let island: IslandSceneModel
    let home: WorldHomeModel

    var body: some View {
        WorldHome(
            world: world.game.snapshot,
            today: world.game.today,
            scene: island,
            home: home,
            actions: WorldHome.Actions(
                collect: { world.game.collect() },
                build: { world.game.build($0) },
                openSettings: {},
                repair: {}
            )
        )
    }
}

// MARK: - The shield and Hop!

/// The reach: the shield replica (the copy the extension would draw for a
/// second reach of the morning), then Hop! taking the screen as Pofu
/// coming forward does.
@MainActor
@Observable
private final class ShieldHopStage {
    let model: AppModel
    private(set) var showsHop = false

    init(model: AppModel) {
        self.model = model
    }

    let copy = ShieldCopy.make(
        context: ShieldContext(
            appName: "Instagram",
            bundleIdentifier: "com.burbn.instagram",
            hour: 10,
            dayOfYear: 306,
            reachesToday: 3,
            resistedToday: 2,
            reachesThisHour: 1,
            calm: 1.4
        ),
        language: .turkish
    )

    func hop() {
        model.startHop(for: .instagram)
        showsHop = true
    }

    /// Leaves the Hop! open in the model as a dismissal, not a skip, so
    /// the rehearsal data the run leaves behind stays clean.
    func finish() {
        model.dismissHop()
    }
}

private struct ShieldHopBeat: View {
    let stage: ShieldHopStage

    var body: some View {
        ZStack {
            ShieldReplicaView(model: stage.model, copy: stage.copy)
            if stage.showsHop {
                HopView(model: stage.model)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .animation(.spring(duration: 0.5, bounce: 0.1), value: stage.showsHop)
    }
}
