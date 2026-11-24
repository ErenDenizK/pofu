#if os(iOS)
import SpriteKit
import UIKit

/// The few colours the code still paints with: the hint, the sky behind a
/// loading backdrop, the dribble's water.
enum FlowPalette {
    static func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> UIColor {
        UIColor(red: r, green: g, blue: b, alpha: a)
    }

    static let skyTop = rgb(1.00, 0.95, 0.86)
    static let skyMid = rgb(0.90, 0.94, 0.90)
    static let water = rgb(0.33, 0.69, 0.92)
    static let waterLight = rgb(0.76, 0.92, 1.00)
    static let hint = rgb(1.00, 0.80, 0.24)
    static let woodTint = rgb(0.99, 0.96, 0.91)
}

/// Loads and caches every texture of one cell size. The painted art comes
/// from the bundle by the names in `FlowArtSlot`; a missing file stops the
/// app on the spot (and fails `FlowGroundTests`), never a drawing in its
/// place. What the code draws is only the water, the hint and the dribble.
@MainActor
final class FlowTextures {
    let cell: CGFloat
    private var cache: [String: SKTexture] = [:]
    private var imageCache: [String: UIImage] = [:]

    init(cell: CGFloat) {
        self.cell = cell
    }

    /// The hint's channel stroke: about the width of a painted bed.
    private var grooveWidth: CGFloat { cell * 0.16 }

    /// The mill wheel over its hub, against the cell: the painted wheel's rim spans 83 percent of its picture.
    static let wheelScale: CGFloat = 0.72

    /// Aspect-fills `image` into `rect`, centred (UIKit drawing).
    static func drawCover(_ image: UIImage, in rect: CGRect) {
        let scale = max(rect.width / image.size.width, rect.height / image.size.height)
        let width = image.size.width * scale
        let height = image.size.height * scale
        image.draw(in: CGRect(x: rect.midX - width / 2, y: rect.midY - height / 2, width: width, height: height))
    }

    // MARK: Painted art

    func image(_ name: String) -> UIImage {
        if let hit = imageCache[name] { return hit }
        guard let image = UIImage(named: name, in: .module, compatibleWith: nil) else {
            preconditionFailure("flow art \(name) is missing from the bundle")
        }
        imageCache[name] = image
        return image
    }

    private func texture(named name: String) -> SKTexture {
        if let hit = cache[name] { return hit }
        let texture = SKTexture(image: image(name))
        texture.filteringMode = .linear
        cache[name] = texture
        return texture
    }

    /// The block under a cell: its painted block, or the socket under a dial.
    func block(_ kind: FlowTileKind, flowered: Bool) -> SKTexture {
        texture(named: FlowArtSlot.blockName(of: kind, flowered: flowered))
    }

    /// The dial a turnable kind wears, drawn upright at rotation 0 (the node turns it).
    func dial(_ kind: FlowTileKind) -> SKTexture? {
        FlowArtSlot.dialName(of: kind).map { texture(named: $0) }
    }

    func backdrop() -> UIImage { image(FlowArtSlot.backdrop) }

    // MARK: Water

    /// The middle of the seamless water, mirrored per cell by `flip`, so its wrap seam never shows; its
    /// middle 30 percent has the pool's ripple size at the cell's scale.
    static let waterCrop = CGRect(x: 0.35, y: 0.35, width: 0.30, height: 0.30)

    static func flip(of cell: FlowCell) -> Int { (cell.column & 1) | ((cell.row & 1) << 1) }

    /// The water in a kind's bed, turned `rotation` quarter turns clockwise like the dial above it. Nil for a
    /// kind with no channel.
    func water(_ kind: FlowTileKind, rotation: Int, flip: Int) -> SKTexture? {
        guard let bedName = FlowArtSlot.bedName(of: kind) else { return nil }
        return cached("water-\(bedName)-\(rotation)-\(flip)") { context in
            let rect = CGRect(x: 0, y: 0, width: self.cell, height: self.cell)
            self.drawSeamless(self.image(FlowArtSlot.water), crop: Self.waterCrop, flip: flip, in: rect.insetBy(dx: -3, dy: -3), context)
            // The bed's shape is the alpha of a white picture; `destinationIn` keeps the water only inside it.
            context.saveGState()
            context.translateBy(x: self.cell / 2, y: self.cell / 2)
            context.rotate(by: CGFloat(rotation) * .pi / 2)
            self.image(bedName).draw(in: CGRect(x: -self.cell / 2, y: -self.cell / 2, width: self.cell, height: self.cell), blendMode: .destinationIn, alpha: 1)
            context.restoreGState()
        }
    }

    /// A dribble's puddle on the bank: the painted water in a small oval with a light rim.
    func puddle() -> SKTexture {
        cached("puddle") { context in
            let oval = CGRect(x: self.cell * 0.37, y: self.cell * 0.415, width: self.cell * 0.26, height: self.cell * 0.17)
            context.saveGState()
            context.addEllipse(in: oval)
            context.clip()
            self.drawSeamless(self.image(FlowArtSlot.water), crop: Self.waterCrop, flip: 0, in: CGRect(x: 0, y: 0, width: self.cell, height: self.cell), context)
            context.restoreGState()
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.7).cgColor)
            context.setLineWidth(1.2)
            context.strokeEllipse(in: oval.insetBy(dx: 0.6, dy: 0.6))
        }
    }

    // MARK: Hint

    func ghost(_ openings: FlowDirection) -> SKTexture {
        cached("ghost-\(openings.rawValue)") { context in
            let path = self.channelPath(openings)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.addPath(path)
            context.setStrokeColor(FlowPalette.hint.withAlphaComponent(0.35).cgColor)
            context.setLineWidth(self.grooveWidth * 1.6)
            context.strokePath()
            context.addPath(path)
            context.setStrokeColor(FlowPalette.hint.cgColor)
            context.setLineWidth(self.grooveWidth * 0.4)
            context.setLineDash(phase: 0, lengths: [self.cell * 0.09, self.cell * 0.07])
            context.strokePath()
        }
    }

    /// The hint's ring: round round a dial, a rounded square round a block.
    func ring(round: Bool) -> SKTexture {
        cached("ring-\(round)") { context in
            let rect = CGRect(x: 0, y: 0, width: self.cell, height: self.cell).insetBy(dx: 3, dy: 3)
            context.setStrokeColor(FlowPalette.hint.cgColor)
            context.setLineWidth(3)
            let path = round ? UIBezierPath(ovalIn: rect) : UIBezierPath(roundedRect: rect, cornerRadius: self.cell * 0.2)
            context.addPath(path.cgPath)
            context.strokePath()
        }
    }

    // MARK: Wheel

    func wheel(blurred: Bool) -> SKTexture {
        let art = wood(FlowArtSlot.wheel)
        // One sharp frame; while it is "blurred" (settled) the same wheel smeared over one eighth turn, which
        // for eight spokes is a still, soft disc of a turning wheel.
        if !blurred { return texture(of: art) }
        return cached("wheel-blur") { context in
            let bounds = CGRect(x: 0, y: 0, width: self.cell, height: self.cell)
            let steps = 8
            for index in 0..<steps {
                context.saveGState()
                context.translateBy(x: self.cell / 2, y: self.cell / 2)
                context.rotate(by: CGFloat(index) * (.pi / 4) / CGFloat(steps))
                context.translateBy(x: -self.cell / 2, y: -self.cell / 2)
                art.draw(in: bounds, blendMode: .normal, alpha: 1 / CGFloat(index + 1))
                context.restoreGState()
            }
        }
    }

    private func texture(of image: UIImage) -> SKTexture {
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    static let woodDesaturate: CGFloat = 0.30
    private var woodCache: [String: UIImage] = [:]

    /// The painted wheel at 512 px, with part of the saturation taken out and a warm multiply inside its own
    /// alpha, so it sits beside the cream stone. The art file itself is not recoloured.
    private func wood(_ name: String) -> UIImage {
        if let hit = woodCache[name] { return hit }
        let source = image(name)
        guard let mask = source.cgImage else { preconditionFailure("flow art \(name) has no bitmap") }
        let side: CGFloat = 512
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let rect = CGRect(x: 0, y: 0, width: side, height: side)
        let result = UIGraphicsImageRenderer(size: rect.size, format: format).image { rendered in
            let context = rendered.cgContext
            source.draw(in: rect)
            context.saveGState()
            // `clip(to:mask:)` reads the mask upright in the native (y up) space.
            context.translateBy(x: 0, y: side)
            context.scaleBy(x: 1, y: -1)
            context.clip(to: rect, mask: mask)
            context.setBlendMode(.saturation)
            context.setFillColor(UIColor(white: 0.5, alpha: Self.woodDesaturate).cgColor)
            context.fill(rect)
            context.setBlendMode(.multiply)
            context.setFillColor(FlowPalette.woodTint.cgColor)
            context.fill(rect)
            context.restoreGState()
        }
        woodCache[name] = result
        return result
    }

    // MARK: Drawing

    private var cropCache: [String: UIImage] = [:]

    /// Draws the middle of a seamless picture into `rect`, mirrored by the cell's `flip` bits.
    private func drawSeamless(_ image: UIImage, crop: CGRect, flip: Int, in rect: CGRect, _ context: CGContext) {
        let key = "\(crop.minX)-\(crop.width)-\(image.size.width)"
        var piece = cropCache[key]
        if piece == nil, let cg = image.cgImage {
            let pixels = CGRect(x: crop.minX * CGFloat(cg.width), y: crop.minY * CGFloat(cg.height), width: crop.width * CGFloat(cg.width), height: crop.height * CGFloat(cg.height)).integral
            if let part = cg.cropping(to: pixels) { piece = UIImage(cgImage: part) }
            if let piece { cropCache[key] = piece }
        }
        context.saveGState()
        context.translateBy(x: rect.midX, y: rect.midY)
        context.scaleBy(x: flip & 1 == 1 ? -1 : 1, y: flip & 2 == 2 ? -1 : 1)
        context.translateBy(x: -rect.midX, y: -rect.midY)
        (piece ?? image).draw(in: rect)
        context.restoreGState()
    }

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

    /// The channel's centreline for the hint: a curve for a bend, lines to the centre otherwise.
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
}
#endif
