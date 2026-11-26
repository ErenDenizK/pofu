import Foundation

/// Where the board sits on a portrait phone, in view points with y down. The
/// painted backdrop is aspect-filled to the screen, and the board is laid on
/// its lawn plate (measured by the ingest tool into `flow-kit.json`): the
/// largest cells that fit the plate, centred in it. The HUD sits over the
/// rock and fall above, undo and hint over the sky beside the pool below.
public struct FlowLayout: Equatable, Sendable {
    public static let hudHeight: CGFloat = 56
    public static let controlsHeight: CGFloat = 84
    /// The clear margin between the screen's sides and anything of the board.
    public static let gutter: CGFloat = 16
    /// The cell is the picture's: a piece is 288 px, which is 96 pt at 3x.
    public static let maxCell: CGFloat = 96
    /// The smallest touch target (HIG).
    public static let minCell: CGFloat = 44

    public let size: CGSize
    public let safeTop: CGFloat
    public let safeBottom: CGFloat
    public let columns: Int
    public let rows: Int
    public let cell: CGFloat
    public let board: CGRect
    /// Where the backdrop's picture lies on the screen (aspect-filled, so it may reach past it).
    public let backdrop: CGRect
    /// The backdrop's lawn plate on the screen.
    public let plate: CGRect

    public init(size: CGSize, safeTop: CGFloat, safeBottom: CGFloat, columns: Int, rows: Int, kit: FlowKit = .shared) {
        self.size = size
        self.safeTop = safeTop
        self.safeBottom = safeBottom
        self.columns = max(1, columns)
        self.rows = max(1, rows)
        let height = max(size.height, size.width / CGFloat(kit.aspect))
        let width = height * CGFloat(kit.aspect)
        // The picture slides sideways until its plate is centred on the screen, as far as it still covers it.
        let centred = (size.width - width) / 2 + CGFloat(0.5 - (kit.plate.x + kit.plate.width / 2)) * width
        let originX = width > size.width ? min(0, max(size.width - width, centred)) : (size.width - width) / 2
        backdrop = CGRect(x: originX, y: (size.height - height) / 2, width: width, height: height)
        plate = CGRect(
            x: backdrop.minX + CGFloat(kit.plate.x) * width, y: backdrop.minY + CGFloat(kit.plate.y) * height,
            width: CGFloat(kit.plate.width) * width, height: CGFloat(kit.plate.height) * height
        )
        let fit = min(plate.width / CGFloat(self.columns), plate.height / CGFloat(self.rows))
        cell = max(Self.minCell, min(Self.maxCell, fit.rounded(.down)))
        let boardWidth = cell * CGFloat(self.columns)
        let boardHeight = cell * CGFloat(self.rows)
        board = CGRect(
            x: (plate.midX - boardWidth / 2).rounded(), y: (plate.midY - boardHeight / 2).rounded(),
            width: boardWidth, height: boardHeight
        )
    }

    public func rect(of cell: FlowCell) -> CGRect {
        CGRect(x: board.minX + CGFloat(cell.column) * self.cell, y: board.minY + CGFloat(cell.row) * self.cell, width: self.cell, height: self.cell)
    }
}
