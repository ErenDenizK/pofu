/// Deals trays of three plots, fairly.
///
/// Fairness rules (each tested):
/// 1. **A tray always has a piece that fits.** If the random draw has none,
///    the last piece is redrawn from the shapes that fit. A single sprout
///    always fits (a bed can never be full: a full row clears), so this
///    never fails.
/// 2. **Mercy when crowded.** As the bed fills, big families get rarer and
///    small ones commoner, so a crowded garden loosens instead of jamming.
/// 3. **A helping hand.** When some shape would bloom a line right now, a
///    tray includes one such shape with probability `helpChance`. Proven
///    block puzzles do this quietly; it is what makes "just one more" feel
///    lucky rather than rigged, and here it makes the round's end kinder.
/// 4. **Variety.** No tray holds the same shape twice.
///
/// Deterministic: the same seed and the same boards give the same trays.
public struct PieceGenerator: Sendable, Equatable {
    public private(set) var rng: GardenRNG
    public var helpChance: Double

    public init(seed: UInt64, helpChance: Double = 0.35) {
        self.rng = GardenRNG(seed: seed)
        self.helpChance = helpChance
    }

    /// The family weights for a bed this full.
    public static func weights(forFill fill: Double) -> [PieceFamily: Int] {
        var result: [PieceFamily: Int] = [:]
        for family in PieceFamily.allCases {
            let size = PieceCatalog.shapes(of: family)[0].count
            var weight = Double(family.weight)
            if fill > 0.45 {
                let crowd = min(1, (fill - 0.45) / 0.3)
                if size >= 5 { weight *= 1 - 0.7 * crowd }
                if size <= 3 { weight *= 1 + 0.8 * crowd }
            }
            result[family] = max(1, Int((weight * 10).rounded()))
        }
        return result
    }

    public mutating func tray(for board: GardenBoard, count: Int = 3) -> [PieceShape] {
        guard count > 0 else { return [] }
        let fill = Double(board.plantedCount) / Double(GardenBoard.cellCount)
        let weights = Self.weights(forFill: fill)
        var tray: [PieceShape] = []
        var attempts = 0
        while tray.count < count {
            let shape = draw(weights: weights)
            attempts += 1
            if tray.contains(shape), attempts < 32 { continue }
            tray.append(shape)
        }

        // A helping hand: swap in a shape that blooms a line now.
        if rng.unit() < helpChance {
            let helpers = PieceCatalog.all.filter { shape in
                !tray.contains(shape) && board.origins(for: shape).contains { origin in
                    guard let mask = board.mask(of: shape, at: origin) else { return false }
                    return !board.lines(with: mask).isEmpty
                }
            }
            if !helpers.isEmpty {
                let pick = helpers[rng.int(below: helpers.count)]
                tray[rng.int(below: tray.count)] = pick
            }
        }

        // The guarantee: at least one piece fits.
        if !tray.contains(where: { board.fits($0) }) {
            let fitting = PieceCatalog.all.filter { board.fits($0) && !tray.contains($0) }
            let fittingWeights = fitting.map { weights[$0.family] ?? 1 }
            if let index = rng.weightedIndex(fittingWeights) {
                tray[tray.count - 1] = fitting[index]
            }
        }
        return tray
    }

    private mutating func draw(weights: [PieceFamily: Int]) -> PieceShape {
        let families = PieceFamily.allCases
        let index = rng.weightedIndex(families.map { weights[$0] ?? 1 }) ?? 0
        let shapes = PieceCatalog.shapes(of: families[index])
        return shapes[rng.int(below: shapes.count)]
    }
}
