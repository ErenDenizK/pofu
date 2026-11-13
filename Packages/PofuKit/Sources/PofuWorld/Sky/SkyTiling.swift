import Foundation

/// Where the copies of a drifting, wrapping sky tile land on screen.
///
/// A tile is drawn as three copies side by side. Each copy's left and right edge is snapped to the device
/// pixel grid, and a copy's right edge is the next copy's left edge computed from the same number, so
/// the copies meet exactly: no gap (a faint dark seam) and no overlap (a column of cloud drawn twice,
/// which shows as a pale 1 px line through semi-transparent clouds).
public enum SkyTiling {
    /// The horizontal extent of one copy: its left and right edge in points.
    public struct Span: Equatable, Sendable {
        public var x: Double
        public var maxX: Double
        public var width: Double { maxX - x }
    }

    /// The spans of the copies `copies` (default `-1, 0, 1`) of a tile whose rest left edge is `left`, `width` points wide,
    /// shifted by `shift`, on a screen of `pixelsPerPoint` device pixels per point.
    public static func spans(left: Double, width: Double, shift: Double, pixelsPerPoint: Double, copies: ClosedRange<Int> = -1...1) -> [Span] {
        let s = max(pixelsPerPoint, 1)
        func snap(_ x: Double) -> Double { (x * s).rounded() / s }
        return copies.map { i in
            let n = Double(i)
            let a = snap(left + shift + n * width)
            let b = snap(left + shift + (n + 1) * width)
            return Span(x: a, maxX: b)
        }
    }
}
