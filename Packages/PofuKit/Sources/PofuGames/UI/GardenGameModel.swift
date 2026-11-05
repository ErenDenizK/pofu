#if os(iOS)
import Observation
import PofuTuning
import SpriteKit
import SwiftUI
import UIKit

/// The garden game's state for its SwiftUI shell: the set, the phase
/// (playing, paused, a round's card, the set's card), the HUD's numbers,
/// and the scene. Rules are in `GardenRound`/`GardenSet`; this only
/// sequences them.
@MainActor
@Observable
public final class GardenGameModel {
    public enum Phase: Equatable {
        case playing
        case paused
        /// A round inside the set is done: its card, "Next round".
        case roundEnd(GardenRoundResult)
        /// The set is done: the set's card, "Enough for today".
        case setEnd
    }

    public private(set) var gardenSet: GardenSet
    public private(set) var phase: Phase = .playing
    /// The seeds the current round would pay now (2–5).
    public private(set) var seeds: Int
    public private(set) var piecesLeft: Int
    public let piecesPerRound: Int
    /// The round's harvest is playing (its last plot is in).
    public private(set) var isHarvesting = false
    /// Bumps when a card lands, for its haptic.
    public private(set) var cards = 0
    /// A still of the scene shown in place of the live view (screenshots).
    public private(set) var frozenFrame: UIImage?

    @ObservationIgnored let scene: GardenScene
    @ObservationIgnored private weak var view: SKView?
    @ObservationIgnored private var inForeground = true
    @ObservationIgnored private var restTask: Task<Void, Never>?
    @ObservationIgnored private let config: GardenRound.Config
    @ObservationIgnored private let onFinish: (Int) -> Void
    @ObservationIgnored private let onRoundEnd: (GardenRoundResult) -> Void

    /// - Parameters:
    ///   - roundsAvailable: earned rounds banked (the debug entry passes 5;
    ///     the ledger will pass what the gate earned, at most 12 a day).
    ///   - seed: the set's seed; rounds replay exactly from it.
    ///   - onRoundEnd: called once per finished round, to credit its seeds
    ///     (`WorldClock.playRound`).
    ///   - onFinish: called with the set's seeds when the player stops.
    public init(
        roundsAvailable: Int = GardenSet.roundsPerSet,
        seed: UInt64 = UInt64.random(in: 1...UInt64.max),
        config: GardenRound.Config = .standard,
        onRoundEnd: @escaping (GardenRoundResult) -> Void = { _ in },
        onFinish: @escaping (Int) -> Void = { _ in }
    ) {
        let set = GardenSet(seed: seed, roundsAvailable: roundsAvailable)
        let round = set.makeRound(config: config)
        gardenSet = set
        seeds = round.seeds
        piecesLeft = round.piecesLeft
        piecesPerRound = config.piecesPerRound
        self.config = config
        self.onFinish = onFinish
        self.onRoundEnd = onRoundEnd
        scene = GardenScene(round: round, size: CGSize(width: 402, height: 874))
        scene.onEvent = { [weak self] event in self?.handle(event) }
    }

    public var sound: any GameSoundPlaying {
        get { scene.sound }
        set { scene.sound = newValue }
    }

    var roundNumber: Int { gardenSet.roundNumber }

    func attach(_ view: SKView) {
        self.view = view
        applyPause()
    }

    /// Whether the scene should run: only while a round is being played,
    /// the app is in front and no still is shown. Everything else leaves
    /// the SpriteKit loop idle so the phone does not render a static board.
    private func applyPause() {
        restTask?.cancel()
        restTask = nil
        guard let view else { return }
        let running = inForeground && frozenFrame == nil && phase == .playing
        if running {
            view.isPaused = false
        } else if phase == .playing || phase == .paused || !inForeground || frozenFrame != nil {
            view.isPaused = true
        } else {
            // A card is up: let the last harvest beat finish behind the
            // scrim, then stop rendering.
            restTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(1.2))
                guard !Task.isCancelled, let self else { return }
                self.view?.isPaused = true
            }
        }
    }

    /// Called from the view when the app leaves or returns to the front.
    func setInForeground(_ value: Bool) {
        guard inForeground != value else { return }
        inForeground = value
        applyPause()
    }

    func setSafeArea(top: CGFloat, bottom: CGFloat) {
        scene.safeTop = top
        scene.safeBottom = bottom
    }

    /// The tuned feel; the tuning lab panel changes it live.
    public func setFeel(_ values: TuningValues.Garden) {
        guard scene.feel.values != values else { return }
        scene.feel = GardenFeel(values)
    }

    func setReduceMotion(_ reduceMotion: Bool) {
        scene.reduceMotion = reduceMotion
    }

    private func handle(_ event: GardenSceneEvent) {
        switch event {
        case .progress(let seeds, let piecesLeft):
            self.seeds = seeds
            self.piecesLeft = piecesLeft
        case .harvestBegan:
            isHarvesting = true
        case .roundEnded(let result):
            isHarvesting = false
            gardenSet.record(result)
            onRoundEnd(result)
            seeds = result.seeds
            phase = gardenSet.isComplete ? .setEnd : .roundEnd(result)
            scene.setCardShown(true)
            cards += 1
            applyPause()
        }
    }

    // MARK: Actions

    public func pause() {
        guard phase == .playing else { return }
        phase = .paused
        applyPause()
    }

    public func resume() {
        guard phase == .paused else { return }
        phase = .playing
        applyPause()
    }

    /// "Next round": only from a round's card; never automatic (A23).
    public func nextRound() {
        guard case .roundEnd = phase, !gardenSet.isComplete else { return }
        startRound()
    }

    /// "Another set": only when earned rounds are banked.
    public func anotherSet() {
        guard phase == .setEnd, let next = gardenSet.nextSet() else { return }
        gardenSet = next
        startRound()
    }

    /// "Enough for today": hands the set's seeds to the caller.
    public func finish() {
        view?.isPaused = true
        onFinish(gardenSet.seedsTotal)
    }

    private func startRound() {
        let round = gardenSet.makeRound(config: config)
        seeds = round.seeds
        piecesLeft = round.piecesLeft
        phase = .playing
        isHarvesting = false
        applyPause()
        scene.begin(round)
    }

    // MARK: Screenshots and previews

    /// Slows (or speeds) the scene's clock: 0.25 is quarter-speed.
    public var sceneSpeed: CGFloat {
        get { scene.speed }
        set { scene.speed = newValue }
    }

    /// Whether some plot in the tray would bloom a line now.
    public var canBloom: Bool {
        GardenAutoplayer.bloomingMove(in: scene.round) != nil
    }

    /// Plays `moves` placements at once with the greedy autoplayer.
    public func autoplay(moves: Int) {
        for _ in 0..<moves {
            guard !scene.round.isOver, let move = GardenAutoplayer.bestMove(in: scene.round) else { return }
            scene.play(move, animated: false)
        }
    }

    /// Plays one placement that blooms a line, animated, setting the bed
    /// up with the autoplayer first if no bloom is possible yet. Returns
    /// whether a bloom was played.
    @discardableResult
    public func playBloom() -> Bool {
        for _ in 0..<config.piecesPerRound {
            if let move = GardenAutoplayer.bloomingMove(in: scene.round) {
                return scene.play(move, animated: true) != nil
            }
            guard !scene.round.isOver, let move = GardenAutoplayer.bestMove(in: scene.round) else { return false }
            scene.play(move, animated: false)
        }
        return false
    }

    /// Plays the autoplayer's choice (a bloom when there is one), animated,
    /// as a drop would. Returns whether a plot was planted.
    @discardableResult
    public func playSuggestedMove() -> Bool {
        guard !scene.round.isOver,
            let move = GardenAutoplayer.bloomingMove(in: scene.round) ?? GardenAutoplayer.bestMove(in: scene.round)
        else { return false }
        return scene.play(move, animated: true) != nil
    }

    /// Plays `slot` at `origin`, animated, as a drop would.
    @discardableResult
    public func play(slot: Int, at origin: GardenCell) -> Bool {
        scene.play(GardenAutoplayer.Move(slot: slot, origin: origin), animated: true) != nil
    }

    /// Loads a round mid-play (a scenario bed and tray).
    public func load(_ round: GardenRound) {
        phase = .playing
        seeds = round.seeds
        piecesLeft = round.piecesLeft
        scene.load(round)
    }

    /// Holds a plot in the air over `origin` with its ghost and glow.
    public func hold(slot: Int, over origin: GardenCell) {
        scene.hold(slot: slot, over: origin)
    }

    /// Holds the autoplayer's choice in the air (a blooming one if there
    /// is one, so the preview glow shows). Returns whether it held one.
    @discardableResult
    public func holdSuggestedMove() -> Bool {
        guard let move = GardenAutoplayer.bloomingMove(in: scene.round) ?? GardenAutoplayer.bestMove(in: scene.round) else { return false }
        scene.hold(slot: move.slot, over: move.origin)
        return true
    }

    /// The bed and the residents, in view points (y down), for cropping
    /// frame sequences.
    public var gardenRect: CGRect {
        let layout = scene.layout
        let top = layout.pofu.y + layout.pofuHeight + 12
        let bottom = layout.bed.minY - 8
        return CGRect(x: layout.bed.minX - 8, y: layout.size.height - top, width: layout.bed.width + 16, height: top - bottom)
    }

    /// Ends the round now with `result`, as the harvest would.
    public func showRoundEnd(_ result: GardenRoundResult) {
        handle(.roundEnded(result))
    }

    /// The scene as an image, rendered by SpriteKit.
    public func captureScene() -> UIImage? {
        guard let view, let texture = view.texture(from: scene) else { return nil }
        let image = texture.cgImage()
        let scale = CGFloat(image.width) / max(1, scene.size.width)
        return UIImage(cgImage: image, scale: scale, orientation: .up)
    }

    /// Pauses the scene and shows a still of it in place of the live view,
    /// so a window snapshot always contains the game.
    public func freeze() {
        view?.isPaused = true
        frozenFrame = captureScene()
        applyPause()
    }

    public func unfreeze() {
        frozenFrame = nil
        applyPause()
    }
}
#endif
