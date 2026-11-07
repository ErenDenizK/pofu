import Foundation

/// Look pipeline v2, phase 1 (`docs/research/reference-look.md` §6,
/// `docs/research/look-lab.md` §8): a fitted 3D LUT per layer group and
/// colour-script cell, looked up after the cell's parametric grade.
///
/// `tools/looklab/bake_luts.py` fits each LUT offline as a per-material
/// colour transfer (the lawn, the earth face and the props toward the same
/// material in the founder's references; the characters toward their own day
/// colours, so they keep their warmth) and bakes it as a 17³ strip into
/// `World.xcassets` (`world-lut-<group>-<set>`). At runtime a grade carries a
/// `Blend` (weights over the sets); `pofuWorldGrade` samples at most three
/// LUTs and mixes them, one texture lookup each (well under 0.1 ms).
///
/// The sky and the cloud sea are flat palette colours, so their "LUT" is the
/// colour script's own sky and sea colours, written by the same tool as
/// final colours from the references (`WorldLight.backdropGrade`).
public enum LookLUT {
    /// The LUT's edge length.
    public static let size = 17

    /// The layer groups that take a LUT in a shader.
    public enum Group: String, CaseIterable, Hashable, Sendable {
        /// The plate, the earth face and the stations (the world canvas).
        case island
        /// Pofu and the residents.
        case characters
    }

    /// One baked LUT per cell, and the rain weather's.
    public enum Set: String, CaseIterable, Hashable, Sendable {
        case dawn, day, golden, dusk, night, rain

        init(_ cell: ColourCell.Name) {
            switch cell {
            case .dawn: self = .dawn
            case .day: self = .day
            case .golden: self = .golden
            case .dusk: self = .dusk
            case .night: self = .night
            }
        }

        /// Cells lit by the sun: rain dims them toward the rain LUT. Dusk
        /// and night keep their own (the rain reference is a day).
        var takesRain: Bool {
            self == .dawn || self == .day || self == .golden
        }
    }

    /// The asset catalog name of a baked LUT strip.
    public static func assetName(_ group: Group, _ set: Set) -> String {
        "world-lut-\(group.rawValue)-\(set.rawValue)"
    }

    /// How much of the rain LUT a weather asks for: all of it in rain, part
    /// of it under an overcast sky (the pipeline's "overcast = rain state at
    /// low strength"), none otherwise.
    public static func rainAmount(_ weather: Weather) -> Double {
        switch weather {
        case .lightRain: 1
        case .overcast: 0.6
        case .clear, .mist, .goldenHaze: 0
        }
    }

    /// The LUTs a grade looks up and how much of each: weights over the
    /// sets that sum to at most 1 (the rest is the identity).
    public struct Blend: Hashable, Sendable {
        public var group: Group
        public var weights: [Set: Double]

        public init(group: Group, weights: [Set: Double]) {
            self.group = group
            self.weights = weights.filter { $0.value > 0 }
        }

        /// The blend for the colour script's cell weights at an hour, with
        /// `rain` (0…1) of the sun-lit cells moved to the rain LUT.
        public init(group: Group, cells: [ColourCell.Name: Double], rain: Double = 0) {
            let r = min(max(rain.isFinite ? rain : 0, 0), 1)
            var w: [Set: Double] = [:]
            for (cell, weight) in cells where weight > 0 {
                let set = Set(cell)
                if set.takesRain, r > 0 {
                    w[set, default: 0] += weight * (1 - r)
                    w[.rain, default: 0] += weight * r
                } else {
                    w[set, default: 0] += weight
                }
            }
            self.init(group: group, weights: w)
        }

        /// This blend for another group (the characters take the island's
        /// weights).
        public func `for`(_ group: Group) -> Blend {
            Blend(group: group, weights: weights)
        }

        /// The weights in a fixed order (`Set.allCases`), for animation.
        public var vector: [Double] {
            Set.allCases.map { weights[$0] ?? 0 }
        }

        /// A blend from `vector`'s order.
        public init(group: Group, vector: [Double]) {
            var w: [Set: Double] = [:]
            for (set, value) in zip(Set.allCases, vector) where value > 1e-4 {
                w[set] = value
            }
            self.init(group: group, weights: w)
        }

        /// The (at most) three heaviest LUTs and their weights, renormalised
        /// to the blend's total: what the shader samples. Ties keep
        /// `Set.allCases` order, so the choice is stable.
        public var top3: [(set: Set, weight: Double)] {
            let total = weights.values.reduce(0, +)
            let sorted = Set.allCases
                .compactMap { s in weights[s].map { (set: s, weight: $0) } }
                .sorted { $0.weight > $1.weight }
            let kept = Array(sorted.prefix(3))
            let keptTotal = kept.reduce(0) { $0 + $1.weight }
            guard keptTotal > 0 else { return [] }
            return kept.map { (set: $0.set, weight: $0.weight / keptTotal * min(total, 1)) }
        }

        /// The straight blend of two blends' weights.
        public static func mix(_ a: Blend, _ b: Blend, _ t: Double) -> Blend {
            let t = min(max(t.isFinite ? t : 0, 0), 1)
            var w: [Set: Double] = [:]
            for set in Set.allCases {
                let v = (a.weights[set] ?? 0) * (1 - t) + (b.weights[set] ?? 0) * t
                if v > 0 { w[set] = v }
            }
            return Blend(group: t < 0.5 ? a.group : b.group, weights: w)
        }
    }
}
