#if os(iOS)
import SpriteKit
import UIKit

/// The flow game's palette: warm carved stone, a soft stream. Code-drawn
/// stand-ins until `batch-64-flow-pieces` lands; the asset-name hooks in
/// `FlowTextures.artName` let painted tiles replace each drawing without
/// touching the scene.
@MainActor
enum FlowPalette {
    static func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> UIColor {
        UIColor(red: r, green: g, blue: b, alpha: a)
    }

    static let skyTop = rgb(1.00, 0.95, 0.86)
    static let skyMid = rgb(0.90, 0.94, 0.90)
    static let skyBottom = rgb(0.66, 0.84, 0.88)
    static let ink = rgb(0.30, 0.22, 0.17)

    static let stoneLight = rgb(0.98, 0.93, 0.83)
    static let stoneShade = rgb(0.88, 0.79, 0.67)
    static let stoneEdge = rgb(0.66, 0.54, 0.43)
    static let grooveDark = rgb(0.50, 0.40, 0.33)
    static let groove = rgb(0.66, 0.56, 0.47)
    static let rim = rgb(0.74, 0.63, 0.52, 0.8)

    static let water = rgb(0.33, 0.69, 0.92)
    static let waterLight = rgb(0.76, 0.92, 1.00)
    static let waterDeep = rgb(0.16, 0.42, 0.68)

    static let wood = rgb(0.82, 0.60, 0.38)
    static let woodDark = rgb(0.58, 0.38, 0.22)
    static let moss = rgb(0.56, 0.72, 0.42)
    static let grass = rgb(0.74, 0.86, 0.58)
    static let grassDark = rgb(0.52, 0.70, 0.40)
    static let boulder = rgb(0.67, 0.65, 0.63)
    static let boulderDark = rgb(0.46, 0.45, 0.45)
    static let hint = rgb(1.00, 0.80, 0.24)
    static let cliff = rgb(0.78, 0.66, 0.55)
    static let cliffDark = rgb(0.60, 0.48, 0.40)
}

/// Draws and caches every texture of one cell size. `artName` carries the
/// ids from the art list (`flow-tile-straight`, ...): when the painted
/// tiles land, `stone(_:_:)` loads them by these names and the drawing
/// stays as the fallback.
@MainActor
final class FlowTextures {
    let cell: CGFloat
    private var cache: [String: SKTexture] = [:]

    init(cell: CGFloat) {
        self.cell = cell
    }

    /// The groove's width.
    private var grooveWidth: CGFloat { cell * 0.30 }

    /// The stone under the mill wheel (batch 64, `flow-tile-wheel`) and the wheel itself, one frame
    /// that code rotates (`flow-wheel`). Both hooks load by name; the drawings below stay as the fallback.
    static let wheelTileArt = "flow-tile-wheel"
    static let wheelArt = "flow-wheel"

    /// A painted texture by its art id, or nil until the batch is integrated.
    private func painted(_ name: String) -> SKTexture? {
        guard let image = UIImage(named: name, in: .module, compatibleWith: nil) else { return nil }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    /// The art id for a kind (`docs/design/flow-game.md` §7).
    static func artName(_ kind: FlowTileKind) -> String? {
        switch kind {
        case .straight: "flow-tile-straight"
        case .bend: "flow-tile-bend"
        case .split: "flow-tile-split"
        case .gate: "flow-tile-gate"
        case .source: "flow-tile-source"
        case .mouth: "flow-tile-mouth"
        case .wheel: Self.wheelTileArt
        case .rock: "flow-rock"
        case .grass: "flow-grass"
        }
    }

    // MARK: Cached textures

    func stone(_ kind: FlowTileKind, _ openings: FlowDirection) -> SKTexture {
        if kind == .wheel, let art = painted(Self.wheelTileArt) { return art }
        return cached("stone-\(kind.rawValue)-\(openings.rawValue)") { context in
            switch kind {
            case .rock: self.drawRock(context)
            case .grass: self.drawGrass(context)
            default: self.drawStone(context, kind: kind, openings: openings)
            }
        }
    }

    func water(_ kind: FlowTileKind, _ openings: FlowDirection) -> SKTexture {
        cached("water-\(kind.rawValue)-\(openings.rawValue)") { context in
            self.drawWater(context, kind: kind, openings: openings)
        }
    }

    func ghost(_ openings: FlowDirection) -> SKTexture {
        cached("ghost-\(openings.rawValue)") { context in
            let path = self.channelPath(openings)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.addPath(path)
            context.setStrokeColor(FlowPalette.hint.withAlphaComponent(0.35).cgColor)
            context.setLineWidth(self.grooveWidth * 1.35)
            context.strokePath()
            context.addPath(path)
            context.setStrokeColor(FlowPalette.hint.cgColor)
            context.setLineWidth(self.grooveWidth * 0.34)
            context.setLineDash(phase: 0, lengths: [self.cell * 0.09, self.cell * 0.07])
            context.strokePath()
        }
    }

    func ring() -> SKTexture {
        cached("ring") { context in
            let rect = CGRect(x: 0, y: 0, width: self.cell, height: self.cell).insetBy(dx: 3, dy: 3)
            context.setStrokeColor(FlowPalette.hint.cgColor)
            context.setLineWidth(3)
            context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: self.cell * 0.2).cgPath)
            context.strokePath()
        }
    }

    func wheel(blurred: Bool) -> SKTexture {
        // The painted wheel is one sharp frame; while it is "blurred" (settled) the drawn ghost stays.
        if !blurred, let art = painted(Self.wheelArt) { return art }
        return cached("wheel-\(blurred)") { context in
            let center = CGPoint(x: self.cell / 2, y: self.cell / 2)
            let radius = self.cell * 0.42
            if blurred {
                // A still image of a turning wheel: a soft disc and ghosted paddles.
                context.setFillColor(FlowPalette.wood.withAlphaComponent(0.34).cgColor)
                context.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                for index in 0..<24 {
                    self.drawPaddle(context, at: center, angle: CGFloat(index) * .pi / 12, radius: radius, alpha: 0.12)
                }
            } else {
                for index in 0..<8 {
                    self.drawPaddle(context, at: center, angle: CGFloat(index) * .pi / 4, radius: radius, alpha: 1)
                }
                context.setFillColor(FlowPalette.woodDark.cgColor)
                context.fillEllipse(in: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10))
            }
            context.setFillColor(FlowPalette.wood.cgColor)
            context.fillEllipse(in: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8))
        }
    }

    func gateBoard() -> SKTexture {
        cached("gate") { context in
            let center = CGPoint(x: self.cell / 2, y: self.cell / 2)
            let width = self.grooveWidth * 2.0
            let height = self.cell * 0.14
            let plank = CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
            context.setShadow(offset: CGSize(width: 0, height: 1.5), blur: 2, color: FlowPalette.ink.withAlphaComponent(0.35).cgColor)
            context.setFillColor(FlowPalette.wood.cgColor)
            context.addPath(UIBezierPath(roundedRect: plank, cornerRadius: height / 2).cgPath)
            context.fillPath()
            context.setShadow(offset: .zero, blur: 0, color: nil)
            context.setStrokeColor(FlowPalette.woodDark.cgColor)
            context.setLineWidth(1.2)
            context.addPath(UIBezierPath(roundedRect: plank, cornerRadius: height / 2).cgPath)
            context.strokePath()
            for x in [plank.minX + height / 2, plank.maxX - height / 2] {
                context.setFillColor(FlowPalette.woodDark.cgColor)
                context.fillEllipse(in: CGRect(x: x - 2.2, y: center.y - 2.2, width: 4.4, height: 4.4))
            }
        }
    }

    // MARK: Drawing

    private func cached(_ key: String, _ draw: @escaping (CGContext) -> Void) -> SKTexture {
        if let texture = cache[key] { return texture }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cell, height: cell), format: format)
        let image = renderer.image { draw($0.cgContext) }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        cache[key] = texture
        return texture
    }

    private func edge(_ side: FlowDirection) -> CGPoint {
        switch side {
        case .north: CGPoint(x: cell / 2, y: 0)
        case .east: CGPoint(x: cell, y: cell / 2)
        case .south: CGPoint(x: cell / 2, y: cell)
        default: CGPoint(x: 0, y: cell / 2)
        }
    }

    /// The channel's centreline: a curve for a bend, lines to the centre
    /// otherwise.
    private func channelPath(_ openings: FlowDirection) -> CGPath {
        let middle = CGPoint(x: cell / 2, y: cell / 2)
        let sides = FlowDirection.sides.filter { openings.contains($0) }
        let path = CGMutablePath()
        let isBend = sides.count == 2 && openings != [.north, .south] && openings != [.east, .west]
        if isBend {
            path.move(to: edge(sides[0]))
            path.addQuadCurve(to: edge(sides[1]), control: middle)
        } else {
            for side in sides {
                path.move(to: edge(side))
                path.addLine(to: middle)
            }
        }
        return path
    }

    private func drawStone(_ context: CGContext, kind: FlowTileKind, openings: FlowDirection) {
        let bounds = CGRect(x: 0, y: 0, width: cell, height: cell)
        let rect = bounds.insetBy(dx: 2, dy: 2)
        let radius = cell * 0.17
        let body = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 2), blur: 3, color: FlowPalette.ink.withAlphaComponent(0.28).cgColor)
        context.setFillColor(FlowPalette.stoneShade.cgColor)
        context.addPath(body)
        context.fillPath()
        context.restoreGState()
        context.saveGState()
        context.addPath(body)
        context.clip()
        let colors = [FlowPalette.stoneLight.cgColor, FlowPalette.stoneShade.cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
            context.drawLinearGradient(gradient, start: CGPoint(x: rect.minX, y: rect.minY), end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])
        }
        context.restoreGState()
        context.setStrokeColor(FlowPalette.stoneEdge.cgColor)
        context.setLineWidth(1.2)
        context.addPath(body)
        context.strokePath()
        // A soft top-left highlight.
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.55).cgColor)
        context.setLineWidth(1.4)
        context.addPath(UIBezierPath(roundedRect: rect.insetBy(dx: 2.2, dy: 2.2), cornerRadius: radius - 2).cgPath)
        context.strokePath()
        // Fixed tiles carry a carved rim; turnable ones are plain.
        if !kind.isTurnable {
            context.setStrokeColor(FlowPalette.rim.cgColor)
            context.setLineWidth(1.6)
            context.setLineDash(phase: 0, lengths: [5, 3])
            context.addPath(UIBezierPath(roundedRect: rect.insetBy(dx: 6, dy: 6), cornerRadius: radius - 4).cgPath)
            context.strokePath()
            context.setLineDash(phase: 0, lengths: [])
        }
        // The groove: a dark lip, then the recessed floor.
        let path = channelPath(openings)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.addPath(path)
        context.setStrokeColor(FlowPalette.grooveDark.cgColor)
        context.setLineWidth(grooveWidth + 3)
        context.strokePath()
        context.addPath(path)
        context.setStrokeColor(FlowPalette.groove.cgColor)
        context.setLineWidth(grooveWidth)
        context.strokePath()
        if kind == .source || kind == .mouth {
            let middle = CGPoint(x: cell / 2, y: cell / 2)
            let ring = grooveWidth * (kind == .source ? 1.2 : 1.1)
            context.setFillColor((kind == .source ? FlowPalette.moss : FlowPalette.stoneEdge).cgColor)
            context.fillEllipse(in: CGRect(x: middle.x - ring, y: middle.y - ring, width: ring * 2, height: ring * 2))
            context.setFillColor(FlowPalette.grooveDark.cgColor)
            let inner = grooveWidth * 0.95
            context.fillEllipse(in: CGRect(x: middle.x - inner, y: middle.y - inner, width: inner * 2, height: inner * 2))
            context.setFillColor(FlowPalette.groove.cgColor)
            let floor = grooveWidth * 0.8
            context.fillEllipse(in: CGRect(x: middle.x - floor, y: middle.y - floor, width: floor * 2, height: floor * 2))
        }
    }

    private func drawWater(_ context: CGContext, kind: FlowTileKind, openings: FlowDirection) {
        let path = channelPath(openings)
        let middle = CGPoint(x: cell / 2, y: cell / 2)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        // The stone darkens where it is wet.
        context.addPath(path)
        context.setStrokeColor(FlowPalette.waterDeep.withAlphaComponent(0.16).cgColor)
        context.setLineWidth(grooveWidth * 1.9)
        context.strokePath()
        context.addPath(path)
        context.setStrokeColor(FlowPalette.water.cgColor)
        context.setLineWidth(grooveWidth * 0.92)
        context.strokePath()
        context.saveGState()
        context.translateBy(x: -grooveWidth * 0.12, y: -grooveWidth * 0.12)
        context.addPath(path)
        context.setStrokeColor(FlowPalette.waterLight.withAlphaComponent(0.85).cgColor)
        context.setLineWidth(grooveWidth * 0.26)
        context.setLineDash(phase: 0, lengths: [cell * 0.22, cell * 0.10])
        context.strokePath()
        context.restoreGState()
        if kind == .source || kind == .mouth {
            let radius = grooveWidth * (kind == .source ? 0.95 : 1.0)
            context.setFillColor(FlowPalette.water.cgColor)
            context.fillEllipse(in: CGRect(x: middle.x - radius, y: middle.y - radius, width: radius * 2, height: radius * 2))
            context.setFillColor(FlowPalette.waterLight.withAlphaComponent(0.8).cgColor)
            context.fillEllipse(in: CGRect(x: middle.x - radius * 0.55, y: middle.y - radius * 0.7, width: radius * 0.55, height: radius * 0.35))
        }
    }

    private func drawPaddle(_ context: CGContext, at center: CGPoint, angle: CGFloat, radius: CGFloat, alpha: CGFloat) {
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: angle)
        let paddle = CGRect(x: -3.2, y: -radius, width: 6.4, height: radius - 3)
        context.setFillColor(FlowPalette.wood.withAlphaComponent(alpha).cgColor)
        context.addPath(UIBezierPath(roundedRect: paddle, cornerRadius: 2.2).cgPath)
        context.fillPath()
        if alpha >= 1 {
            context.setStrokeColor(FlowPalette.woodDark.cgColor)
            context.setLineWidth(1)
            context.addPath(UIBezierPath(roundedRect: paddle, cornerRadius: 2.2).cgPath)
            context.strokePath()
        }
        context.restoreGState()
    }

    private func drawGrass(_ context: CGContext) {
        let rect = CGRect(x: 0, y: 0, width: cell, height: cell).insetBy(dx: 2, dy: 2)
        context.setFillColor(FlowPalette.grass.withAlphaComponent(0.55).cgColor)
        context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: cell * 0.17).cgPath)
        context.fillPath()
        context.setStrokeColor(FlowPalette.grassDark.withAlphaComponent(0.6).cgColor)
        context.setLineWidth(1.6)
        context.setLineCap(.round)
        for (x, y) in [(0.3, 0.62), (0.52, 0.45), (0.7, 0.68)] {
            let base = CGPoint(x: cell * x, y: cell * y)
            context.move(to: base)
            context.addLine(to: CGPoint(x: base.x - 3, y: base.y - cell * 0.12))
            context.move(to: base)
            context.addLine(to: CGPoint(x: base.x + 3, y: base.y - cell * 0.1))
            context.strokePath()
        }
    }

    private func drawRock(_ context: CGContext) {
        drawGrass(context)
        let blob = CGRect(x: cell * 0.22, y: cell * 0.30, width: cell * 0.56, height: cell * 0.46)
        context.setShadow(offset: CGSize(width: 0, height: 2), blur: 3, color: FlowPalette.ink.withAlphaComponent(0.3).cgColor)
        context.setFillColor(FlowPalette.boulder.cgColor)
        context.fillEllipse(in: blob)
        context.setShadow(offset: .zero, blur: 0, color: nil)
        context.setStrokeColor(FlowPalette.boulderDark.cgColor)
        context.setLineWidth(1.2)
        context.strokeEllipse(in: blob)
        context.setFillColor(UIColor.white.withAlphaComponent(0.4).cgColor)
        context.fillEllipse(in: CGRect(x: blob.minX + blob.width * 0.18, y: blob.minY + blob.height * 0.14, width: blob.width * 0.34, height: blob.height * 0.22))
    }
}
#endif
