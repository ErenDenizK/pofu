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

    public struct Element: Hashable, Sendable, Identifiable {
        /// The baked sprite (screen-space sky art).
        public var art: String
        /// How far it is: the share of the colour script's fog it takes
        /// (1 the farthest) and how little it follows the peek.
        public var distance: Double
        /// Map, Island, Home.
        public var stops: [Placement]

        public var id: String {
            art
        }

        /// Its placement at rail position `z`.
        public func placement(z: Double) -> Placement {
            let z = min(max(z.isFinite ? z : 2, 0), 2)
            let lower = min(Int(z.rounded(.down)), 1)
            return Placement.mix(stops[lower], stops[lower + 1], z - Double(lower))
        }
    }

    /// Back to front.
    public static let elements: [Element] = [
        // The pair of small isles: farthest, high on one side.
        Element(art: "far-isle-3", distance: 1.0, stops: [
            Placement(x: 0.80, y: 0.08, width: 150, opacity: 0.0),
            Placement(x: 0.78, y: 0.19, width: 190),
            Placement(x: 0.80, y: 0.20, width: 210),
        ]),
        // The small round isle with its tree.
        Element(art: "far-isle-2", distance: 0.85, stops: [
            Placement(x: 0.5, y: 0.06, width: 60, opacity: 0.0),
            Placement(x: 0.58, y: 0.175, width: 64),
            Placement(x: 0.58, y: 0.18, width: 66),
        ]),
        // The long isle: nearer, lower.
        Element(art: "far-isle-1", distance: 0.7, stops: [
            Placement(x: 0.2, y: 0.9, width: 180, opacity: 0.0),
            Placement(x: 0.22, y: 0.205, width: 240),
            Placement(x: 0.18, y: 0.32, width: 260),
        ]),
        // A wide painted cloud bank under the far isles.
        Element(art: "cloud-4", distance: 0.5, stops: [
            Placement(x: 0.5, y: 0.9, width: 260, opacity: 0.0),
            Placement(x: 0.70, y: 0.232, width: 230, opacity: 0.9),
            Placement(x: 0.72, y: 0.39, width: 280, opacity: 0.85),
        ]),
        // A round cloud peeking in at the top edge.
        Element(art: "cloud-2", distance: 0.4, stops: [
            Placement(x: 0.1, y: 0.9, width: 160, opacity: 0.0),
            Placement(x: 0.06, y: 0.15, width: 150, opacity: 0.8),
            Placement(x: 0.04, y: 0.22, width: 150, opacity: 0.8),
        ]),
    ]
}
