import CoreGraphics

/// Where everything sits in the garden scene, in SpriteKit points (origin
/// at the bottom left, y up). Pure, so it is tested on any device size.
///
/// Top to bottom: the HUD strip (SwiftUI, below the safe area), Pofu with
/// Mochi and Fındık peeking over the bed's back rim, the 8 × 8 bed, and
/// the wooden tray of three plots above the home indicator. Cells are as
/// large as the width allows (41 pt on a 402 pt iPhone 17), never above
/// 46 pt, so the thumb covers about one cell.
public struct GardenLayout: Equatable, Sendable {
    public static let hudHeight: CGFloat = 56
    public static let trayHeight: CGFloat = 132
    public static let charactersHeight: CGFloat = 100
    public static let bedPadding: CGFloat = 10
    public static let sideGutter: CGFloat = 24
    public static let maximumCell: CGFloat = 46

    public let size: CGSize
    public let cell: CGFloat
    /// The planting grid, without the rim.
    public let grid: CGRect
    /// The bed with its clay rim.
    public let bed: CGRect
    public let tray: CGRect
    /// Centres of the tray's three slots.
    public let slots: [CGPoint]
    /// Feet positions and heights of the residents.
    public let pofu: CGPoint
    public let mochi: CGPoint
    public let findik: CGPoint
    public let pofuHeight: CGFloat
    public let residentHeight: CGFloat

    public init(size: CGSize, safeTop: CGFloat, safeBottom: CGFloat) {
        self.size = size
        let hudBottom = size.height - safeTop - Self.hudHeight
        let bottom = safeBottom + 12
        tray = CGRect(x: 16, y: bottom, width: max(0, size.width - 32), height: Self.trayHeight)
        let availableTop = hudBottom - 8
        let availableBottom = tray.maxY + 18
        let available = max(0, availableTop - availableBottom)

        let byWidth = (size.width - 2 * Self.sideGutter - 2 * Self.bedPadding) / 8
        let byHeight = (available - Self.charactersHeight - 2 * Self.bedPadding) / 8
        cell = max(16, min(Self.maximumCell, floor(min(byWidth, byHeight))))
        let gridSide = cell * 8
        let bedSide = gridSide + 2 * Self.bedPadding

        let group = Self.charactersHeight + bedSide
        let top = availableTop - max(0, (available - group) / 2)
        bed = CGRect(x: (size.width - bedSide) / 2, y: top - Self.charactersHeight - bedSide, width: bedSide, height: bedSide)
        grid = bed.insetBy(dx: Self.bedPadding, dy: Self.bedPadding)

        slots = (0..<3).map { index in
            CGPoint(x: tray.minX + tray.width * (CGFloat(index) * 2 + 1) / 6, y: tray.midY)
        }
        let feet = bed.maxY - 8
        pofuHeight = 96
        residentHeight = 68
        pofu = CGPoint(x: bed.midX, y: feet)
        mochi = CGPoint(x: bed.minX + 52, y: feet)
        findik = CGPoint(x: bed.maxX - 52, y: feet)
    }

    /// The centre of a cell of the grid.
    public func center(of cell: GardenCell) -> CGPoint {
        CGPoint(
            x: grid.minX + (CGFloat(cell.column) + 0.5) * self.cell,
            y: grid.maxY - (CGFloat(cell.row) + 0.5) * self.cell
        )
    }

    /// The fractional top-left cell (row, column) of a shape whose bounding
    /// box is centred at `point`, for `GardenBoard.snap`.
    public func fractionalOrigin(of shape: PieceShape, centeredAt point: CGPoint) -> (row: Double, column: Double) {
        let topLeftX = point.x - CGFloat(shape.width - 1) / 2 * cell
        let topLeftY = point.y + CGFloat(shape.height - 1) / 2 * cell
        let column = (topLeftX - grid.minX) / cell - 0.5
        let row = (grid.maxY - topLeftY) / cell - 0.5
        return (Double(row), Double(column))
    }

    /// The centre of a shape's bounding box placed at `origin`.
    public func center(of shape: PieceShape, at origin: GardenCell) -> CGPoint {
        let topLeft = center(of: origin)
        return CGPoint(
            x: topLeft.x + CGFloat(shape.width - 1) / 2 * cell,
            y: topLeft.y - CGFloat(shape.height - 1) / 2 * cell
        )
    }

    /// Which tray slot a touch picks, generous above the tray so a thumb
    /// that lands on a plot's top edge still lifts it.
    public func slot(at point: CGPoint) -> Int? {
        let area = CGRect(x: tray.minX, y: tray.minY - 8, width: tray.width, height: tray.height + 40)
        guard area.contains(point), tray.width > 0 else { return nil }
        return min(2, max(0, Int((point.x - tray.minX) / (tray.width / 3))))
    }
}
