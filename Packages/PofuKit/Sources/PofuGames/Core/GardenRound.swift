/// The rules of one round in Pofu's sunflower garden (Ayçiçeği).
///
/// The mechanic is the proven block puzzle (1010!, Block Blast): drag
/// plots from a tray of three onto an 8 × 8 bed; a full row or column
/// blooms into sunflowers and clears. Pofu's version differs where the
/// proven one is sticky (docs/product/minigames.md):
///
/// - **A round is a bag of `piecesPerRound` plots**, not "until you lose".
///   It ends when the bag is empty, or earlier, kindly, when nothing in the
///   tray fits ("the garden is full, harvest time"). Both ends pay.
/// - **No score.** The round yields a few seeds for Pofu's cheeks
///   (`SeedYield`), 2 to 5: there is no number to beat and no best.
/// - Combos exist for feel (escalating blooms), and nudge the yield by at
///   most one seed.
///
/// Pure and deterministic: a value type driven by `place(slot:at:)`; the
/// scene animates the outcomes.
public struct GardenRound: Sendable, Equatable {
    public struct Config: Sendable, Equatable {
        public var piecesPerRound: Int
        public var traySize: Int
        /// Placements without a bloom before the combo cools off.
        public var comboGrace: Int

        public init(piecesPerRound: Int = 18, traySize: Int = 3, comboGrace: Int = 3) {
            self.piecesPerRound = piecesPerRound
            self.traySize = traySize
            self.comboGrace = comboGrace
        }

        /// 18 plots: six trays, about 45–75 seconds of play.
        public static let standard = Config()
    }

    public enum Ending: String, Sendable, Equatable {
        /// Every plot in the bag is planted.
        case bagEmpty
        /// Nothing left in the tray fits: the garden is full; Pofu harvests.
        case gardenFull
    }

    public let config: Config
    public let seed: UInt64
    public private(set) var board: GardenBoard
    /// The tray's slots; `nil` once a plot is planted.
    public private(set) var tray: [PieceShape?]
    public private(set) var placed = 0
    public private(set) var linesBloomed = 0
    public private(set) var cellsBloomed = 0
    /// The current streak of blooming placements (0 when cold).
    public private(set) var combo = 0
    public private(set) var bestCombo = 0
    /// The most lines bloomed by one placement.
    public private(set) var bestBloom = 0
    public private(set) var placementsSinceBloom = 0
    public private(set) var ending: Ending?
    private var generator: PieceGenerator
    /// Plots dealt so far, including the ones in the tray.
    private var dealt = 0

    public init(seed: UInt64, config: Config = .standard) {
        self.config = config
        self.seed = seed
        self.board = GardenBoard()
        self.generator = PieceGenerator(seed: seed)
        self.tray = []
        deal()
    }

    /// A round set up mid-play, for previews, screenshots and tests: a
    /// given bed and tray, as if `placed` plots were already planted.
    public init(
        scenario board: GardenBoard,
        tray: [PieceShape],
        placed: Int = 0,
        combo: Int = 0,
        linesBloomed: Int = 0,
        seed: UInt64 = 1,
        config: Config = .standard
    ) {
        self.config = config
        self.seed = seed
        self.board = board
        self.generator = PieceGenerator(seed: seed)
        self.tray = tray.map { Optional($0) }
        self.placed = placed
        self.dealt = placed + tray.count
        self.combo = combo
        self.bestCombo = combo
        self.linesBloomed = linesBloomed
        self.cellsBloomed = linesBloomed * GardenBoard.size
    }

    public var isOver: Bool { ending != nil }
    public var piecesLeft: Int { config.piecesPerRound - placed }
    /// Seeds the round would pay if it ended now.
    public var seeds: Int { SeedYield.seeds(lines: linesBloomed, bestBloom: bestBloom, bestCombo: bestCombo) }

    public var result: GardenRoundResult {
        GardenRoundResult(
            seeds: seeds,
            lines: linesBloomed,
            bestCombo: bestCombo,
            placed: placed,
            ending: ending ?? .bagEmpty
        )
    }

    public func piece(in slot: Int) -> PieceShape? {
        tray.indices.contains(slot) ? tray[slot] : nil
    }

    public func canPlace(slot: Int, at origin: GardenCell) -> Bool {
        guard !isOver, let shape = piece(in: slot) else { return false }
        return board.canPlace(shape, at: origin)
    }

    /// The lines a placement would bloom, for the scene's preview glow.
    public func preview(slot: Int, at origin: GardenCell) -> LineSet {
        guard let shape = piece(in: slot), let mask = board.mask(of: shape, at: origin), board.bits & mask == 0 else {
            return LineSet.empty
        }
        return board.lines(with: mask)
    }

    /// Plants the plot in `slot` at `origin`. Returns `nil`, changing
    /// nothing, when the round is over, the slot is empty or it does not fit.
    public mutating func place(slot: Int, at origin: GardenCell) -> PlacementOutcome? {
        guard !isOver, let shape = piece(in: slot) else { return nil }
        let seedsBefore = seeds
        let comboBefore = combo
        guard let placement = board.place(shape, at: origin) else { return nil }
        let cleared = placement.cleared
        tray[slot] = nil
        placed += 1

        if cleared.isEmpty {
            placementsSinceBloom += 1
            if placementsSinceBloom >= config.comboGrace { combo = 0 }
        } else {
            combo = comboBefore > 0 ? comboBefore + 1 : 1
            placementsSinceBloom = 0
            linesBloomed += cleared.count
            cellsBloomed += cleared.cells.count
            bestBloom = max(bestBloom, cleared.count)
            bestCombo = max(bestCombo, combo)
        }

        var dealtTray: [PieceShape]?
        if tray.allSatisfy({ $0 == nil }) {
            if piecesLeft <= 0 {
                ending = .bagEmpty
            } else {
                deal()
                dealtTray = tray.compactMap { $0 }
            }
        }
        if ending == nil, !tray.compactMap({ $0 }).contains(where: { board.fits($0) }) {
            ending = .gardenFull
        }

        return PlacementOutcome(
            slot: slot,
            shape: shape,
            origin: origin,
            planted: GardenBoard.cells(in: placement.planted),
            cleared: cleared,
            combo: cleared.isEmpty ? 0 : combo,
            seedsBefore: seedsBefore,
            seedsAfter: seeds,
            dealtTray: dealtTray,
            ending: ending
        )
    }

    private mutating func deal() {
        let count = min(config.traySize, config.piecesPerRound - dealt)
        guard count > 0 else { return }
        tray = generator.tray(for: board, count: count).map { Optional($0) }
        dealt += count
    }
}

/// What one placement did, for the scene to animate and the HUD to show.
public struct PlacementOutcome: Sendable, Equatable {
    public let slot: Int
    public let shape: PieceShape
    public let origin: GardenCell
    public let planted: [GardenCell]
    public let cleared: LineSet
    /// The combo this placement reached (0 when it bloomed nothing).
    public let combo: Int
    public let seedsBefore: Int
    public let seedsAfter: Int
    /// The new tray, when this placement emptied the old one.
    public let dealtTray: [PieceShape]?
    public let ending: GardenRound.Ending?
}

public struct GardenRoundResult: Sendable, Equatable, Hashable {
    public var seeds: Int
    public var lines: Int
    public var bestCombo: Int
    public var placed: Int
    public var ending: GardenRound.Ending

    public init(seeds: Int, lines: Int, bestCombo: Int, placed: Int, ending: GardenRound.Ending) {
        self.seeds = seeds
        self.lines = lines
        self.bestCombo = bestCombo
        self.placed = placed
        self.ending = ending
    }
}

/// Seeds for Pofu's cheeks from a round: small, deterministic, never zero.
///
/// - 2 for playing at all (no failure: archipelago-system §4.3 rule 1),
/// - +1 at 3 lines bloomed, +1 at 7,
/// - +1 for a good round: a double bloom or a combo of 4,
/// - at most 5.
///
/// Calibrated by simulation (docs/product/minigames.md §6): a greedy
/// expert averages about 4.2 seeds, random play about 2.4; the archipelago
/// economy expects about 4 a round. Tunable here only.
public enum SeedYield {
    public static let base = 2
    public static let maximum = 5
    public static let lineSteps = [3, 7]
    public static let goodCombo = 4

    public static func seeds(lines: Int, bestBloom: Int, bestCombo: Int) -> Int {
        var seeds = base
        seeds += lineSteps.filter { lines >= $0 }.count
        if bestBloom >= 2 || bestCombo >= goodCombo { seeds += 1 }
        return min(seeds, maximum)
    }
}
