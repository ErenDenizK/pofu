#if os(iOS)
import Observation
import SpriteKit
import SwiftUI
import UIKit

/// The flow game's state for its SwiftUI shell: the round, the phase, the
/// hint, and the scene. The rules are in `FlowRound`; this sequences them
/// (tap, pour, next board, finish), runs Damla's 20 s idle hint, and owns
/// the frame policy: the SKView runs only while something animates (30 Hz)
/// and rests at 0 Hz otherwise.
@MainActor
@Observable
public final class FlowGameModel {
    public enum Phase: Equatable {
        case playing
        /// The last connection is pouring; the next board (or the card) is
        /// a moment away.
        case pouring
        /// Every board is solved: the card with its one "Done".
        case finished
    }

    public private(set) var round: FlowRound
    public private(set) var phase: Phase = .playing
    public private(set) var wet: Set<FlowCell>
    /// The tile Damla (or Pofu) points at, while a hint is up.
    public private(set) var hint: FlowHint?
    /// Bumps when a board is solved, for the success haptic.
    public private(set) var solvedCount = 0
    /// A still of the scene shown in place of the live view (screenshots).
    public private(set) var frozenFrame: UIImage?
    public let skin: FlowSkin

    @ObservationIgnored let scene: FlowScene
    @ObservationIgnored private weak var view: SKView?
    @ObservationIgnored private var inForeground = true
    @ObservationIgnored private var isSceneAwake = true
    @ObservationIgnored private var idleTask: Task<Void, Never>?
    @ObservationIgnored private var pourTask: Task<Void, Never>?
    @ObservationIgnored private var shownHints: Set<FlowCell> = []
    @ObservationIgnored private let hintDelay: Duration
    @ObservationIgnored private let pourPause: Duration
    @ObservationIgnored private let onLeave: (FlowRound) -> Void
    @ObservationIgnored private let onFinish: () -> Void

    /// - Parameters:
    ///   - round: a fresh round, or a saved one to resume.
    ///   - hintDelay: idle time before a hint (20 s; screenshots shorten it).
    ///   - pourPause: how long a solved board pours before the next slides in.
    ///   - onLeave: the player left mid-round; the round to save.
    ///   - onFinish: every board is solved and the player said "Done".
    public init(
        round: FlowRound,
        skin: FlowSkin = .water,
        hintDelay: Duration = .seconds(FlowRound.hintDelay),
        pourPause: Duration = .milliseconds(1200),
        onLeave: @escaping (FlowRound) -> Void = { _ in },
        onFinish: @escaping () -> Void = {}
    ) {
        self.round = round
        self.skin = skin
        self.hintDelay = hintDelay
        self.pourPause = pourPause
        self.onLeave = onLeave
        self.onFinish = onFinish
        wet = round.wet
        scene = FlowScene(board: round.board, size: CGSize(width: 402, height: 874))
        scene.onWake = { [weak self] in self?.sceneWoke() }
        scene.onSettled = { [weak self] in self?.sceneSettled() }
        if round.isBoardSolved { phase = round.isLastBoard ? .finished : .playing }
    }

    public var sound: any FlowSoundPlaying {
        get { scene.sound }
        set { scene.sound = newValue }
    }

    public var board: FlowBoard { round.board }
    public var canUndo: Bool { phase == .playing && round.canUndo }
    public var boardNumber: Int { round.index + 1 }
    /// Boards solved, the one pouring now included: the pips fill on solve.
    public var boardsSolved: Int { round.boardsSolved }
    public var isBoardSolved: Bool { round.isBoardSolved }
    public var targetsWet: Int { round.board.targets.filter(wet.contains).count }
    public var targetCount: Int { round.board.targets.count }
    /// Damla on the water island, Pofu on the others where she is not.
    var helperName: String { skin == .water ? FlowStrings.damla : FlowStrings.pofu }

    // MARK: View plumbing and the frame policy

    func attach(_ view: SKView) {
        self.view = view
        applyPause()
    }

    private func applyPause() {
        guard let view else { return }
        view.isPaused = !(isSceneAwake && inForeground && frozenFrame == nil)
    }

    private func sceneWoke() {
        isSceneAwake = true
        applyPause()
    }

    private func sceneSettled() {
        isSceneAwake = false
        applyPause()
    }

    func setInForeground(_ value: Bool) {
        guard inForeground != value else { return }
        inForeground = value
        if value {
            scene.nudge()
            restartIdleTimer()
        } else {
            idleTask?.cancel()
        }
        applyPause()
    }

    func setSafeArea(top: CGFloat, bottom: CGFloat) {
        scene.safeTop = top
        scene.safeBottom = bottom
    }

    func setReduceMotion(_ value: Bool) {
        scene.reduceMotion = value
    }

    // MARK: Play

    /// Turns the tile at `cell` (one tap). Fixed tiles thunk; a solved
    /// board is locked.
    public func tap(_ cell: FlowCell) {
        guard phase == .playing else { return }
        let result = round.tap(at: cell)
        guard result.turned else {
            if round.board[cell]?.isFixed == true { scene.thunk(at: cell) }
            return
        }
        clearHint()
        wet = round.wet
        scene.apply(round.board)
        announce(after: cell, result: result)
        if result.solved {
            beginPour()
        } else {
            restartIdleTimer()
        }
    }

    public func undo() {
        guard canUndo, round.undo() != nil else { return }
        clearHint()
        wet = round.wet
        scene.apply(round.board, reverse: true)
        UIAccessibility.post(notification: .announcement, argument: FlowStrings.targetsAccessibility(targetsWet, of: targetCount))
        restartIdleTimer()
    }

    /// The hint button: points at a tile now (free, unlimited).
    public func requestHint() {
        guard phase == .playing else { return }
        idleTask?.cancel()
        Task { [weak self] in
            await self?.showHint()
            self?.restartIdleTimer()
        }
    }

    /// Leaving mid-round saves the round as it is.
    public func leave() {
        idleTask?.cancel()
        pourTask?.cancel()
        view?.isPaused = true
        onLeave(round)
    }

    /// "Done", from the card.
    public func finish() {
        guard phase == .finished else { return }
        view?.isPaused = true
        onFinish()
    }

    // MARK: Pour and next board

    private func beginPour() {
        phase = .pouring
        solvedCount += 1
        idleTask?.cancel()
        scene.celebrate()
        if !round.isLastBoard {
            UIAccessibility.post(notification: .announcement, argument: FlowStrings.boardDone)
        }
        let pause = pourPause
        pourTask = Task { [weak self] in
            try? await Task.sleep(for: pause)
            guard !Task.isCancelled else { return }
            self?.afterPour()
        }
    }

    /// Skips the pour's pause (screenshots drive the round by hand).
    public func continueNow() {
        guard phase == .pouring else { return }
        pourTask?.cancel()
        afterPour()
    }

    private func afterPour() {
        guard phase == .pouring else { return }
        if round.isLastBoard {
            phase = .finished
            UIAccessibility.post(notification: .announcement, argument: FlowStrings.doneTitle)
        } else {
            round.advance()
            wet = round.wet
            shownHints = []
            scene.present(round.board, animated: true)
            phase = .playing
            restartIdleTimer()
        }
    }

    // MARK: Hints

    private func restartIdleTimer() {
        idleTask?.cancel()
        guard phase == .playing, inForeground else { return }
        let delay = hintDelay
        idleTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled, let self else { return }
                await self.showHint()
            }
        }
    }

    private func showHint() async {
        guard phase == .playing else { return }
        let board = round.board
        let skipped = shownHints
        let found = await Task.detached(priority: .userInitiated) {
            FlowHint.next(board, excluding: skipped)
        }.value
        // The board may have changed while the search ran.
        guard phase == .playing, round.board == board, let found else { return }
        shownHints.insert(found.cell)
        hint = found
        scene.showHint(found)
        UIAccessibility.post(notification: .announcement, argument: FlowStrings.hintCaption(helper: helperName))
    }

    private func clearHint() {
        hint = nil
        shownHints = []
        scene.clearHint()
    }

    private func announce(after cell: FlowCell, result: FlowTapResult) {
        guard let tile = round.board[cell] else { return }
        var parts = [FlowStrings.opens(tile.openings.names)]
        for wetCell in result.newlyWet {
            if let kind = round.board[wetCell]?.kind, kind.isTarget { parts.append(FlowStrings.reaches(kind)) }
        }
        parts.append(FlowStrings.targetsAccessibility(targetsWet, of: targetCount))
        UIAccessibility.post(notification: .announcement, argument: parts.joined(separator: ". "))
    }

    // MARK: Screenshots and previews

    /// Taps the hint's tile, as a player who knew the way would. Returns
    /// whether it tapped.
    @discardableResult
    public func playSuggestedTap() -> Bool {
        guard phase == .playing, let hint = FlowHint.next(round.board) else { return false }
        tap(hint.cell)
        return true
    }

    /// Shows the hint for the current board now, without the idle wait.
    public func showHintNow() async {
        await showHint()
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
