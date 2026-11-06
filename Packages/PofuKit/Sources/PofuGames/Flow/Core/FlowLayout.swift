import Foundation

/// Where the board sits on a portrait phone, in view points with y down:
/// a cliff lip at the top, the pool at the bottom, cells of 44 pt or more
/// (about 70 pt at 5 columns), the board in the lower two thirds so one
/// thumb reaches it, and undo and hint in the bottom corners.
public struct FlowLayout: Equatable, Sendable {
    public static let hudHeight: CGFloat = 56
    public static let controlsHeight: CGFloat = 84
    public static let poolHeight: CGFloat = 44
    public static let lipHeight: CGFloat = 26
    public static let gutter: CGFloat = 16
    public static let maxCell: CGFloat = 76
    /// The smallest touch target (HIG).
    public static let minCell: CGFloat = 44

    public let size: CGSize
    public let safeTop: CGFloat
    public let safeBottom: CGFloat
    public let columns: Int
    public let rows: Int
    public let cell: CGFloat
    public let board: CGRect

    public init(size: CGSize, safeTop: CGFloat, safeBottom: CGFloat, columns: Int, rows: Int) {
        self.size = size
        self.safeTop = safeTop
        self.safeBottom = safeBottom
        self.columns = max(1, columns)
        self.rows = max(1, rows)
        let bottom = size.height - safeBottom - Self.controlsHeight - Self.poolHeight
        let top = safeTop + Self.hudHeight + Self.lipHeight
        let fit = min((size.width - 2 * Self.gutter) / CGFloat(self.columns), (bottom - top) / CGFloat(self.rows))
        cell = max(Self.minCell, min(Self.maxCell, fit.rounded(.down)))
        let width = cell * CGFloat(self.columns)
        let height = cell * CGFloat(self.rows)
        board = CGRect(x: ((size.width - width) / 2).rounded(), y: bottom - height, width: width, height: height)
    }

    public func rect(of cell: FlowCell) -> CGRect {
        CGRect(x: board.minX + CGFloat(cell.column) * self.cell, y: board.minY + CGFloat(cell.row) * self.cell, width: self.cell, height: self.cell)
    }

    /// The cliff the spring comes out of, above the board.
    public var lip: CGRect { CGRect(x: board.minX - 10, y: board.minY - Self.lipHeight, width: board.width + 20, height: Self.lipHeight + 6) }
    /// The pool the mouths pour into, below the board.
    public var pool: CGRect { CGRect(x: board.minX - 14, y: board.maxY - 4, width: board.width + 28, height: Self.poolHeight + 4) }
}
