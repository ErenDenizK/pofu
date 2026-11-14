import Foundation

/// Where the board sits on a portrait phone, in view points with y down:
/// a cliff lip at the top, the pool at the bottom, cells of 44 pt or more
/// (about 70 pt at 5 columns), the block centred between the HUD and the
/// controls, and undo and hint in the bottom corners.
public struct FlowLayout: Equatable, Sendable {
    public static let hudHeight: CGFloat = 56
    public static let controlsHeight: CGFloat = 84
    public static let poolHeight: CGFloat = 44
    public static let lipHeight: CGFloat = 26
    /// The clear margin between the screen's sides and anything of the
    /// board, the pool's rim included.
    public static let gutter: CGFloat = 16
    /// How far the pool reaches past the board on each side (the cliff lip
    /// and the bank reach less).
    public static let poolOverhang: CGFloat = 14
    /// The pool's rim stroke, drawn half outside its rect.
    static let rimAllowance: CGFloat = 2
    public static let maxCell: CGFloat = 88
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
        let fit = min((size.width - 2 * (Self.gutter + Self.poolOverhang + Self.rimAllowance)) / CGFloat(self.columns), (bottom - top) / CGFloat(self.rows))
        cell = max(Self.minCell, min(Self.maxCell, fit.rounded(.down)))
        let width = cell * CGFloat(self.columns)
        let height = cell * CGFloat(self.rows)
        // The cliff, board and pool sit as one block, centred in the clear
        // space between the HUD and the controls, so the frame has no empty
        // top. A tall board that fills the space lands where it always did.
        let spaceTop = safeTop + Self.hudHeight
        let spaceBottom = size.height - safeBottom - Self.controlsHeight
        let block = Self.lipHeight + height + Self.poolHeight
        let blockTop = spaceTop + max(0, (spaceBottom - spaceTop - block) / 2)
        board = CGRect(x: ((size.width - width) / 2).rounded(), y: (blockTop + Self.lipHeight).rounded(), width: width, height: height)
    }

    public func rect(of cell: FlowCell) -> CGRect {
        CGRect(x: board.minX + CGFloat(cell.column) * self.cell, y: board.minY + CGFloat(cell.row) * self.cell, width: self.cell, height: self.cell)
    }

    /// The cliff the spring comes out of, above the board.
    public var lip: CGRect { CGRect(x: board.minX - 10, y: board.minY - Self.lipHeight, width: board.width + 20, height: Self.lipHeight + 6) }
    /// The pool the mouths pour into, below the board.
    public var pool: CGRect { CGRect(x: board.minX - Self.poolOverhang, y: board.maxY - 4, width: board.width + 2 * Self.poolOverhang, height: Self.poolHeight + 4) }
}
