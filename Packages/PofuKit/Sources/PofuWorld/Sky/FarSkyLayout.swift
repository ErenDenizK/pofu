import Foundation

/// Where the far sky's painted elements sit at each framing (look round 3):
/// the batch-04 far isles in the haze and two painted clouds, composed per
/// framing like the camera rail's stops and interpolated along the rail
/// (each keeps its side, so a flight reads as parallax, not a swap), so the
/// band the island cannot fill is never dead sky.
///
/// Positions are the element's centre in unit screen coordinates (x across,
/// y down) and its width in reference points (402 pt wide); a hidden element
/// has opacity 0. Pure, so the composition is tested: nothing sits on the
/// island's band at the Island framing, and nothing covers the speech
/// bubble's column at Home.
public enum FarSkyLayout {
    public struct Placement: Hashable, Sendable {
        public var x: Double
        public var y: Double
        public var width: Double
        public var opacity: Double

        public init(x: Double, y: Double, width: Double, opacity: Double = 1) {
            self.x = x
            self.y = y
            self.width = width
            self.opacity = opacity
        }

        static func mix(_ a: Placement, _ b: Placement, _ t: Double) -> Placement {
            func lerp(_ p: Double, _ q: Double) -> Double { p + (q - p) * t }
            return Placement(x: lerp(a.x, b.x), y: lerp(a.y, b.y), width: lerp(a.width, b.width), opacity: lerp(a.opacity, b.opacity))
        }
    }

    /// The islands behind home (concept flows §1.4): A Çağlayan, B Emanet,
    /// C Mehtap, D Revontuli, G Gezgin (Nazlı).
    public enum Mark: String, CaseIterable, Hashable, Sendable {
        case caglayan, emanet, mehtap, revontuli, gezgin
    }

    public struct Element: Hashable, Sendable, Identifiable {
        /// The baked sprite (screen-space sky art).
        public var art: String
        /// A stable id (an art can stand in more than one place).
        public var id: String
        /// The map island or Gezgin this element is (concept flows §1.4):
        /// unlit and grey while stuck, coloured with one small warm light
        /// once healed. Nil for the clouds.
        public var mark: Mark?
        /// The sprite once healed, when it differs from `art`.
        public var healedArt: String?
        /// How far it is: the share of the colour script's fog it takes
        /// (1 the farthest) and how little it follows the peek.
        public var distance: Double
        /// Map, Island, Home.
        public var stops: [Placement]

        public init(
            art: String, id: String? = nil, mark: Mark? = nil, healedArt: String? = nil,
            distance: Double, stops: [Placement]
        ) {
            self.art = art
            self.id = id ?? art
            self.mark = mark
            self.healedArt = healedArt
            self.distance = distance
            self.stops = stops
        }

        /// The sprite to draw for a healed or stuck mark.
        public func art(healed: Bool) -> String {
            healed ? (healedArt ?? art) : art
        }

        /// Its placement at rail position `z`.
        public func placement(z: Double) -> Placement {
            let z = min(max(z.isFinite ? z : 2, 0), 2)
            let lower = min(Int(z.rounded(.down)), 1)
            return Placement.mix(stops[lower], stops[lower + 1], z - Double(lower))
        }
    }

    /// A map island's spot at both framings, hidden on the Map.
    static func spot(_ x: Double, _ y: Double, _ width: Double) -> [Placement] {
        [
            Placement(x: x, y: max(y - 0.05, 0.02), width: width * 402 * 0.8, opacity: 0),
            Placement(x: x, y: y, width: width * 402),
            Placement(x: x, y: y, width: width * 402),
        ]
    }

    /// The elements that are a map island or Gezgin.
    public static func element(for mark: Mark) -> Element? {
        elements.first { $0.mark == mark }
    }

    /// Back to front.
    public static let elements: [Element] = [
        // Concept flows §1.4: fractions of the screen (centre x, centre y)
        // and width / 402, at the Island and Home framings alike ("fixed at
        // every level, hour and weather"); hidden on the Map. Painted art
        // exists only for Çağlayan; the rest keep a generic far isle until
        // theirs is made. Far things are lighter, never sharper.
        // G, Gezgin (Nazlı): no sprite yet; the generic pair of isles.
        Element(art: "far-isle-3", id: "far-gezgin", mark: .gezgin, distance: 1.0, stops: spot(0.68, 0.225, 0.30)),
        // C, Mehtap: smallest and farthest (a moon-white dome, art pending).
        Element(art: "far-isle-2", id: "far-mehtap", mark: .mehtap, distance: 1.0, stops: spot(0.58, 0.13, 0.09)),
        // B, Emanet: misty, a tall stilted bureau (art pending).
        Element(art: "far-isle-2", id: "far-emanet", mark: .emanet, distance: 0.9, stops: spot(0.40, 0.235, 0.12)),
        // D, Revontuli: cool pale, slender ice towers (art pending).
        Element(art: "far-isle-1", id: "far-revontuli", mark: .revontuli, distance: 0.8, stops: spot(0.88, 0.37, 0.14)),
        // A, Çağlayan: tiered pools, a small silver fall (its stage 0 and 4 plates).
        Element(
            art: "caglayan-island-0", id: "far-caglayan", mark: .caglayan, healedArt: "caglayan-island-4",
            distance: 0.7, stops: spot(0.17, 0.33, 0.20)
        ),
        // A wide painted cloud bank under the far isles.
        Element(art: "cloud-4", distance: 0.5, stops: [
            Placement(x: 0.5, y: 0.9, width: 260, opacity: 0.0),
            Placement(x: 0.70, y: 0.232, width: 230, opacity: 0.9),
            Placement(x: 0.72, y: 0.235, width: 280, opacity: 0.85),
        ]),
        // A round cloud peeking in at the top edge.
        Element(art: "cloud-2", distance: 0.4, stops: [
            Placement(x: 0.1, y: 0.9, width: 160, opacity: 0.0),
            Placement(x: 0.06, y: 0.15, width: 150, opacity: 0.8),
            Placement(x: 0.04, y: 0.17, width: 150, opacity: 0.8),
        ]),
    ]
}
