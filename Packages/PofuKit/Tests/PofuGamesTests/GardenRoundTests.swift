import Testing
@testable import PofuGames

@Suite("Seeded RNG")
struct GardenRNGTests {
    @Test func theSameSeedGivesTheSameStream() {
        var a = GardenRNG(seed: 42)
        var b = GardenRNG(seed: 42)
        var c = GardenRNG(seed: 43)
        let first = (0..<16).map { _ in a.next() }
        #expect(first == (0..<16).map { _ in b.next() })
        #expect(first != (0..<16).map { _ in c.next() })
    }

    @Test func boundedValuesStayInRange() {
        var rng = GardenRNG(seed: 7)
        for _ in 0..<2000 {
            #expect((0..<5).contains(rng.int(below: 5)))
            let unit = rng.unit()
            #expect(unit >= 0 && unit < 1)
        }
    }

    @Test func weightedChoiceFollowsTheWeights() {
        var rng = GardenRNG(seed: 9)
        var counts = [0, 0, 0]
        for _ in 0..<6000 {
            counts[rng.weightedIndex([1, 0, 3]) ?? -1] += 1
        }
        #expect(counts[1] == 0, "a zero weight is never chosen")
        #expect(counts[2] > counts[0] * 2)
        #expect(rng.weightedIndex([0, 0]) == nil)
    }

    @Test func derivedSeedsDiffer() {
        #expect(GardenRNG.derive(1, 1) != GardenRNG.derive(1, 2))
        #expect(GardenRNG.derive(1, 1) == GardenRNG.derive(1, 1))
    }
}

@Suite("Fair piece generator")
struct PieceGeneratorTests {
    /// A random bed with no full lines (as a real bed always is).
    private func randomBoard(_ rng: inout GardenRNG, fill: Double) -> GardenBoard {
        var bits: UInt64 = 0
        for index in 0..<64 where rng.unit() < fill {
            bits |= UInt64(1) << UInt64(index)
        }
        let board = GardenBoard(bits: bits)
        return GardenBoard(bits: bits & ~board.lines().mask)
    }

    @Test func everyTrayHasAPieceThatFitsEvenOnCrowdedBeds() {
        var rng = GardenRNG(seed: 2026)
        var generator = PieceGenerator(seed: 11)
        for trial in 0..<400 {
            let board = randomBoard(&rng, fill: 0.5 + Double(trial % 5) * 0.1)
            let tray = generator.tray(for: board)
            #expect(tray.count == 3)
            #expect(tray.contains { board.fits($0) }, "no fit on\n\(board)")
        }
    }

    @Test func aTrayNeverHoldsTheSameShapeTwice() {
        var generator = PieceGenerator(seed: 5)
        for _ in 0..<300 {
            let tray = generator.tray(for: GardenBoard())
            #expect(Set(tray).count == tray.count)
        }
    }

    @Test func theSameSeedDealsTheSameTrays() {
        var a = PieceGenerator(seed: 77)
        var b = PieceGenerator(seed: 77)
        for _ in 0..<20 {
            #expect(a.tray(for: GardenBoard()) == b.tray(for: GardenBoard()))
        }
    }

    @Test func crowdedBedsGetSmallerPieces() {
        let fresh = PieceGenerator.weights(forFill: 0.1)
        let crowded = PieceGenerator.weights(forFill: 0.8)
        #expect(crowded[.single]! > fresh[.single]!)
        #expect(crowded[.pair]! > fresh[.pair]!)
        #expect(crowded[.line5]! < fresh[.line5]!)
        #expect(crowded[.square3]! < fresh[.square3]!)
        #expect(crowded[.line4] == fresh[.line4], "medium pieces keep their weight")
    }

    @Test func aHelpingHandOffersABloomWhenOneExists() {
        // Row 0 lacks two cells: a pair (or a single) blooms it.
        let board = GardenBoard(rows: ["######.."])
        var generator = PieceGenerator(seed: 3, helpChance: 1)
        for _ in 0..<50 {
            let tray = generator.tray(for: board)
            let blooms = tray.contains { shape in
                board.origins(for: shape).contains { origin in
                    !board.lines(with: board.mask(of: shape, at: origin) ?? 0).isEmpty
                }
            }
            #expect(blooms)
        }
    }
}

@Suite("A garden round")
struct GardenRoundTests {
    private func shape(_ id: String) throws -> PieceShape {
        try #require(PieceCatalog.shape(id: id), "no shape \(id)")
    }

    @Test func aRoundStartsWithAFullTrayAndAnEmptyBed() {
        let round = GardenRound(seed: 1)
        #expect(round.board.isEmpty)
        #expect(round.tray.compactMap { $0 }.count == 3)
        #expect(round.piecesLeft == 18)
        #expect(round.seeds == SeedYield.base)
        #expect(!round.isOver)
    }

    @Test func placingEmptiesTheSlotAndTheTrayIsDealtAgainWhenEmpty() throws {
        var round = GardenRound(seed: 4)
        for step in 0..<3 {
            let move = try #require(GardenAutoplayer.bestMove(in: round))
            let outcomeResult = round.place(slot: move.slot, at: move.origin)
            let outcome = try #require(outcomeResult)
            #expect(round.piece(in: move.slot) == nil || step == 2)
            #expect((outcome.dealtTray != nil) == (step == 2))
        }
        #expect(round.tray.compactMap { $0 }.count == 3)
        #expect(round.placed == 3)
    }

    @Test func invalidPlacementsChangeNothing() throws {
        var round = GardenRound(seed: 8)
        let before = round
        #expect(round.place(slot: 5, at: GardenCell(row: 0, column: 0)) == nil)
        #expect(round.place(slot: 0, at: GardenCell(row: 9, column: 0)) == nil)
        #expect(round == before)
        let move = try #require(GardenAutoplayer.bestMove(in: round))
        _ = round.place(slot: move.slot, at: move.origin)
        #expect(round.place(slot: move.slot, at: GardenCell(row: 0, column: 0)) == nil, "the slot is empty now")
    }

    @Test func consecutiveBloomsBuildACombo() throws {
        let single = try shape("single.0")
        var round = GardenRound(
            scenario: GardenBoard(rows: ["#######.", "#######.", "#######."]),
            tray: [single, single, single]
        )
        let firstResult = round.place(slot: 0, at: GardenCell(row: 0, column: 7))
        let first = try #require(firstResult)
        #expect(first.cleared.rows == [0])
        #expect(first.combo == 1)
        let secondResult = round.place(slot: 1, at: GardenCell(row: 1, column: 7))
        let second = try #require(secondResult)
        #expect(second.combo == 2)
        let thirdResult = round.place(slot: 2, at: GardenCell(row: 2, column: 7))
        let third = try #require(thirdResult)
        #expect(third.combo == 3)
        #expect(round.bestCombo == 3)
        #expect(round.linesBloomed == 3)
    }

    @Test func theComboCoolsAfterThreeQuietPlacements() throws {
        let single = try shape("single.0")
        var round = GardenRound(
            scenario: GardenBoard(rows: ["", "", "", "", "", "", "", "#######."]),
            tray: [single, single, single],
            combo: 2,
            config: GardenRound.Config(piecesPerRound: 18, traySize: 3, comboGrace: 3)
        )
        _ = round.place(slot: 0, at: GardenCell(row: 0, column: 0))
        _ = round.place(slot: 1, at: GardenCell(row: 0, column: 2))
        #expect(round.combo == 2, "still warm after two quiet placements")
        _ = round.place(slot: 2, at: GardenCell(row: 0, column: 4))
        #expect(round.combo == 0)
    }

    @Test func aDoubleBloomIsAGoodRound() throws {
        let single = try shape("single.0")
        var round = GardenRound(
            scenario: GardenBoard(rows: [
                "#######.",
                ".......#",
                ".......#",
                ".......#",
                ".......#",
                ".......#",
                ".......#",
                ".......#",
            ]),
            tray: [single]
        )
        let outcomeResult = round.place(slot: 0, at: GardenCell(row: 0, column: 7))
        let outcome = try #require(outcomeResult)
        #expect(outcome.cleared.count == 2)
        #expect(outcome.seedsBefore == 2)
        #expect(outcome.seedsAfter == 3, "the good-round seed")
    }

    @Test func theRoundEndsKindlyWhenNothingFits() throws {
        let square3 = try shape("square3.0")
        let single = try shape("single.0")
        // A checkerboard-ish bed with no 3 × 3 gap anywhere.
        let rows = (0..<8).map { row in
            String((0..<8).map { column in (row + column) % 3 == 0 ? "#" : "." })
        }
        var round = GardenRound(scenario: GardenBoard(rows: rows), tray: [single, square3])
        let origin = try #require(round.board.origins(for: single).first)
        let outcomeResult = round.place(slot: 0, at: origin)
        let outcome = try #require(outcomeResult)
        #expect(outcome.ending == .gardenFull)
        #expect(round.isOver)
        #expect(round.result.seeds >= SeedYield.base, "a full garden still pays")
        #expect(round.place(slot: 1, at: GardenCell(row: 0, column: 0)) == nil)
    }

    @Test func wholeRoundsEndWithinTheBagAndPayTwoToFive() {
        var seeds: [Int] = []
        for seed in UInt64(1)...60 {
            var round = GardenRound(seed: seed)
            var guardrail = 0
            while !round.isOver, let move = GardenAutoplayer.bestMove(in: round), guardrail < 100 {
                _ = round.place(slot: move.slot, at: move.origin)
                guardrail += 1
            }
            #expect(round.isOver)
            #expect(round.placed <= 18)
            #expect((SeedYield.base...SeedYield.maximum).contains(round.result.seeds))
            seeds.append(round.result.seeds)
        }
        let mean = Double(seeds.reduce(0, +)) / Double(seeds.count)
        // A greedy expert lands near 4 (simulated 4.1); never pinned at 5.
        #expect(mean > 3.3 && mean < 4.8, "mean \(mean)")
    }

    @Test func aRoundReplaysExactlyFromItsSeed() {
        func play(_ seed: UInt64) -> [PlacementOutcome] {
            var round = GardenRound(seed: seed)
            var outcomes: [PlacementOutcome] = []
            while !round.isOver, let move = GardenAutoplayer.bestMove(in: round) {
                if let outcome = round.place(slot: move.slot, at: move.origin) { outcomes.append(outcome) }
            }
            return outcomes
        }
        #expect(play(31) == play(31))
        #expect(play(31) != play(32))
    }

    @Test func previewShowsTheLinesAPlacementWouldBloom() throws {
        let pair = try #require(PieceCatalog.shapes(of: .pair).first { $0.width == 2 })
        let round = GardenRound(scenario: GardenBoard(rows: ["######.."]), tray: [pair])
        #expect(round.preview(slot: 0, at: GardenCell(row: 0, column: 6)).rows == [0])
        #expect(round.preview(slot: 0, at: GardenCell(row: 1, column: 6)).isEmpty)
        #expect(round.preview(slot: 0, at: GardenCell(row: 0, column: 5)).isEmpty, "overlaps a sprout")
    }
}

@Suite("Seed yield and sets")
struct SeedYieldAndSetTests {
    @Test func theYieldTable() {
        #expect(SeedYield.seeds(lines: 0, bestBloom: 0, bestCombo: 0) == 2)
        #expect(SeedYield.seeds(lines: 2, bestBloom: 1, bestCombo: 2) == 2)
        #expect(SeedYield.seeds(lines: 3, bestBloom: 1, bestCombo: 1) == 3)
        #expect(SeedYield.seeds(lines: 7, bestBloom: 1, bestCombo: 3) == 4)
        #expect(SeedYield.seeds(lines: 7, bestBloom: 2, bestCombo: 1) == 5)
        #expect(SeedYield.seeds(lines: 20, bestBloom: 4, bestCombo: 9) == 5, "capped")
    }

    private func result(_ seeds: Int) -> GardenRoundResult {
        GardenRoundResult(seeds: seeds, lines: 3, bestCombo: 1, placed: 18, ending: .bagEmpty)
    }

    @Test func aSetIsFiveRoundsThenStops() {
        var set = GardenSet(seed: 1, roundsAvailable: 8)
        #expect(set.length == 5)
        for number in 1...5 {
            #expect(set.roundNumber == number)
            #expect(!set.isComplete)
            set.record(result(3))
        }
        #expect(set.isComplete)
        set.record(result(3))
        #expect(set.results.count == 5, "a complete set takes no more rounds")
        #expect(set.seedsTotal == 15)
        #expect(set.roundsLeftAfterSet == 3)
        #expect(set.nextSet()?.length == 3)
    }

    @Test func aSetIsShorterWhenFewerRoundsAreEarned() {
        var set = GardenSet(seed: 1, roundsAvailable: 2)
        #expect(set.length == 2)
        set.record(result(2))
        set.record(result(4))
        #expect(set.isComplete)
        #expect(set.nextSet() == nil)
    }

    @Test func roundSeedsAreStableAndDistinct() {
        let set = GardenSet(seed: 99, roundsAvailable: 5)
        #expect(set.roundSeed(1) == GardenSet(seed: 99, roundsAvailable: 3).roundSeed(1))
        #expect(Set((1...5).map(set.roundSeed)).count == 5)
    }
}

@Suite("Feel math")
struct GardenFeelTests {
    @Test func easingsStartAtZeroAndEndAtOne() {
        let curves: [(Double) -> Double] = [
            GameEasing.linear, GameEasing.outCubic, GameEasing.inQuad, GameEasing.inOutSine,
            { GameEasing.outBack($0) },
        ]
        for curve in curves {
            #expect(abs(curve(0)) < 1e-9)
            #expect(abs(curve(1) - 1) < 1e-9)
        }
        #expect(GameEasing.outBack(0.6) > 1, "outBack overshoots")
        #expect(abs(GameEasing.squash(0) - 1) < 1e-9)
        #expect(abs(GameEasing.squash(1) - 1) < 0.01)
        #expect(GameEasing.squash(0.2) > 1.04)
    }

    @Test func theShakeBudgetIsTinyAndRare() {
        var budget = ShakeBudget()
        #expect(budget.request(lines: 1, combo: 1, at: 0, reduceMotion: false) == 0, "never for one line")
        let double = budget.request(lines: 2, combo: 1, at: 1, reduceMotion: false)
        #expect(double > 0 && double <= budget.maximum)
        #expect(budget.request(lines: 3, combo: 3, at: 1.5, reduceMotion: false) == 0, "cooling down")
        #expect(budget.request(lines: 4, combo: 9, at: 3, reduceMotion: false) == budget.maximum, "capped")
        #expect(budget.request(lines: 4, combo: 9, at: 10, reduceMotion: true) == 0, "never with Reduce Motion")
    }

    @Test func comboEscalationIsCapped() {
        #expect(GardenFeel.bloomOvershoot(combo: 1) < GardenFeel.bloomOvershoot(combo: 3))
        #expect(GardenFeel.bloomOvershoot(combo: 50) == 2.8)
        #expect(GardenFeel.petals(combo: 50) == 7)
        #expect(GardenFeel.bloomHaptic(lines: 1, combo: 1) < 1)
        #expect(GardenFeel.bloomHaptic(lines: 4, combo: 6) == 1)
    }

    @Test func bloomsClimbThePentatonicLadder() {
        #expect(PentatonicLadder.midi(step: 0) == 62)
        #expect(PentatonicLadder.midi(step: 4) == 71)
        #expect(PentatonicLadder.midi(step: 5) == 74)
        #expect(PentatonicLadder.midi(step: 99) == 86, "capped two octaves up")
        #expect(PentatonicLadder.bloomNote(index: 0, combo: 3) > PentatonicLadder.bloomNote(index: 0, combo: 1))
        let pitchClasses = Set([2, 4, 6, 9, 11])
        for step in 0...10 {
            #expect(pitchClasses.contains(PentatonicLadder.midi(step: step) % 12))
        }
    }
}
