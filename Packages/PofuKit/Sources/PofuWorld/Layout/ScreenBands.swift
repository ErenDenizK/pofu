import Foundation

/// A rectangle in screen points, y down.
public struct ScreenBox: Hashable, Sendable {
    public var minX: Double
    public var minY: Double
    public var maxX: Double
    public var maxY: Double

    public init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }

    public init(_ array: [Double]) {
        precondition(array.count == 4, "a box is [minX, minY, maxX, maxY]")
        self.init(minX: array[0], minY: array[1], maxX: array[2], maxY: array[3])
    }

    public var width: Double { maxX - minX }
    public var height: Double { maxY - minY }
    public var midX: Double { (minX + maxX) / 2 }
    public var midY: Double { (minY + maxY) / 2 }

    /// The box scaled about the origin, `sx` across and `sy` down.
    public func scaled(x sx: Double, y sy: Double) -> ScreenBox {
        ScreenBox(minX: minX * sx, minY: minY * sy, maxX: maxX * sx, maxY: maxY * sy)
    }

    public func intersects(_ other: ScreenBox) -> Bool {
        minX < other.maxX && maxX > other.minX && minY < other.maxY && maxY > other.minY
    }

    /// The straight-line distance between the nearest edges; 0 when they touch or overlap.
    public func gap(to other: ScreenBox) -> Double {
        let dx = max(0, minX - other.maxX, other.minX - maxX)
        let dy = max(0, minY - other.maxY, other.minY - maxY)
        return (dx * dx + dy * dy).squareRoot()
    }

    /// How many rows of `[y0, y1]` the box covers.
    public func overlap(rows y0: Double, _ y1: Double) -> Double {
        max(0, min(maxY, y1) - max(minY, y0))
    }
}

/// The screen's bands (docs/design/world-presentation-v2.md section 1.1): the one
/// place that knows where the safe areas, the chrome rows and the corner control
/// sit, so that nothing else hard-codes a band.
///
/// The numbers are v2's, measured on the iPhone 17 frames at 402 x 874 pt. Another
/// phone scales the horizontal values by its width; the bands keep their heights in
/// points, so the top bands hang from the top and the bottom bands from the bottom.
public struct ScreenBands: Hashable, Sendable {
    /// The reference screen (iPhone 17), in points.
    public static let referenceWidth = 402.0
    public static let referenceHeight = 874.0
    /// The scene's default top inset (`IslandSceneModel.safeTop`).
    public static let defaultSafeTop = 59.0

    /// The band's heights, in points.
    public static let topRowHeight = 59.0
    public static let bottomSafeHeight = 34.0
    public static let midChromeHeight = 212.0
    public static let cornerHeight = 74.0

    public let width: Double
    public let height: Double
    public let safeTop: Double

    public static let reference = ScreenBands(width: referenceWidth, height: referenceHeight)

    public init(width: Double, height: Double, safeTop: Double = ScreenBands.defaultSafeTop) {
        self.width = width > 0 ? width : Self.referenceWidth
        self.height = height > 0 ? height : Self.referenceHeight
        self.safeTop = safeTop
    }

    public init(size: (width: Double, height: Double), safeTop: Double = ScreenBands.defaultSafeTop) {
        self.init(width: size.width, height: size.height, safeTop: safeTop)
    }

    /// Points per reference point across.
    public var widthScale: Double { width / Self.referenceWidth }

    // MARK: Rows (y)

    /// Sky only: no tappable pixel, no label. 0 to 59.
    public var topSafe: ClosedRange<Double> { 0 ... safeTop }
    /// The gear at mid. Sky, far isles, whale. 59 to 118.
    public var topRow: ClosedRange<Double> { safeTop ... safeTop + Self.topRowHeight }
    /// The subject's band: below the top row to the bottom chrome at mid.
    public var stage: ClosedRange<Double> { topRow.upperBound ... midChrome.lowerBound }
    /// Line card, the one action, the glance at mid. 628 to 840.
    public var midChrome: ClosedRange<Double> { (height - Self.bottomSafeHeight - Self.midChromeHeight) ... (height - Self.bottomSafeHeight) }
    /// Nothing tappable. 840 to 874.
    public var bottomSafe: ClosedRange<Double> { (height - Self.bottomSafeHeight) ... height }

    // MARK: Boxes

    /// The corner keep-out of the Map and of mid (right, 314 to 386 x 766 to 840): the place
    /// control at the Map, the corner control at mid.
    public var corner: ScreenBox {
        ScreenBox(minX: 314 * widthScale, minY: bottomSafe.lowerBound - Self.cornerHeight, maxX: 386 * widthScale, maxY: bottomSafe.lowerBound)
    }

    /// The corner mirrored to the left: the back control at near.
    public var cornerMirrored: ScreenBox {
        ScreenBox(minX: width - corner.maxX, minY: corner.minY, maxX: width - corner.minX, maxY: corner.maxY)
    }

    /// The part of the screen that carries chrome at mid.
    public var midChromeBox: ScreenBox {
        ScreenBox(minX: 0, minY: midChrome.lowerBound, maxX: width, maxY: midChrome.upperBound)
    }

    /// Whether a tappable box may sit in the safe bands: no.
    public func isInSafeBand(_ box: ScreenBox) -> Bool {
        box.minY < safeTop || box.maxY > bottomSafe.lowerBound
    }
}
