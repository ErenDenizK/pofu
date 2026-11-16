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

    /// The painted gate and wheel's size against the cell. The gate plank spans 86 percent of its tile and
    /// the wheel 84 percent, which would touch the cell's edges.
    static let gateScale: CGFloat = 0.74
    static let wheelScale: CGFloat = 0.92

    /// Aspect-fills `image` into `rect`, centred (UIKit drawing).
    static func drawCover(_ image: UIImage, in rect: CGRect) {
        let scale = max(rect.width / image.size.width, rect.height / image.size.height)
        let width = image.size.width * scale
        let height = image.size.height * scale
        image.draw(in: CGRect(x: rect.midX - width / 2, y: rect.midY - height / 2, width: width, height: height))
    }
    static let wheelArt = "flow-wheel"

    /// The painted bank tiles (grass, rock), read from the named slots in `FlowArtSlot`. A slot with no
    /// art in the bundle keeps the code drawing, so this stays on.
    static let paintsBankTiles = true

    /// A warm multiply over a bank picture, so it sits in the stone's colour family.
    static let bankTint = FlowPalette.rgb(1.0, 0.97, 0.90)

    private var imageCache: [String: [UIImage]] = [:]

    /// Every picture of a slot: `name`, `name-2`, ... while the files exist.
    func images(_ base: String) -> [UIImage] {
        if let hit = imageCache[base] { return hit }
        var found: [UIImage] = []
        for index in 0..<FlowArtSlot.maxVariants {
            guard let image = UIImage(named: FlowArtSlot.variantName(base, index), in: .module, compatibleWith: nil) else { break }
            found.append(image)
        }
        imageCache[base] = found
        return found
    }

    func art(_ base: String) -> UIImage? { images(base).first }

    /// The lawn of method B: the painted lawn, or the grass bank picture until the lawn is painted.
    private var lawnImage: UIImage? { art(FlowArtSlot.lawn) ?? art(FlowArtSlot.grass) }

    /// Whether method B can lay a lawn at all.
    var hasLawn: Bool { lawnImage != nil }

    /// One seamless lawn for the whole board, made in board space: the picture is tiled two cells wide,
    /// every other tile mirrored so the joins cannot show, then cut to a rounded rect.
    func lawn(size: CGSize) -> SKTexture? {
        guard let image = lawnImage else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = false
        let rect = CGRect(origin: .zero, size: size)
        let side = cell * 2
        let radius = cell * 0.22
        let picture = UIGraphicsImageRenderer(size: size, format: format).image { rendered in
            let context = rendered.cgContext
            context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath)
            context.clip()
            for column in 0..<Int((size.width / side).rounded(.up)) {
                for row in 0..<Int((size.height / side).rounded(.up)) {
                    context.saveGState()
                    let flipX = column % 2 == 1
                    let flipY = row % 2 == 1
                    context.translateBy(x: CGFloat(column) * side + (flipX ? side : 0), y: CGFloat(row) * side + (flipY ? side : 0))
                    context.scaleBy(x: flipX ? -1 : 1, y: flipY ? -1 : 1)
                    image.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
                    context.restoreGState()
                }
            }
            context.setBlendMode(.multiply)
            context.setFillColor(Self.bankTint.cgColor)
            context.fill(rect)
            context.setBlendMode(.normal)
            context.setStrokeColor(FlowPalette.cliffDark.withAlphaComponent(0.45).cgColor)
            context.setLineWidth(2)
            context.addPath(UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: radius).cgPath)
            context.strokePath()
        }
        let texture = SKTexture(image: picture)
        texture.filteringMode = .linear
        return texture
    }

    /// A bank cell's picture, picked by the board's variant picker. Method A: a keycap square per cell.
    /// Method B: grass is the lawn itself (a clear cell) and a rock is a cut-out piece. Nil while the
    /// slot has no art, so the code drawing stays.
    func bank(_ kind: FlowTileKind, cell at: FlowCell, picker: FlowVariantPicker, method: FlowGroundMethod) -> SKTexture? {
        guard Self.paintsBankTiles, kind == .rock || kind == .grass else { return nil }
        let onLawn = method == .lawn && hasLawn
        let turns = kind == .grass ? picker.quarterTurns(of: at) : 0
        let mirrored = picker.mirrored(at)
        if onLawn, kind == .grass { return cached("bank-clear") { _ in } }
        let slot = kind == .rock ? FlowArtSlot.rock : FlowArtSlot.grass
        let cut = onLawn && kind == .rock ? images(FlowArtSlot.rockCut) : []
        let pool = cut.isEmpty ? images(slot) : cut
        guard !pool.isEmpty else { return nil }
        let index = picker.variant(of: at, count: pool.count)
        let key = "bank-\(kind.rawValue)-\(index)-\(turns)-\(mirrored)-\(onLawn)-\(cut.isEmpty)"
        return cached(key) { context in
            self.drawBank(context, image: pool[index], turns: turns, mirrored: mirrored, keycap: !onLawn, cutOut: !cut.isEmpty)
        }
    }

    private func drawBank(_ context: CGContext, image: UIImage, turns: Int, mirrored: Bool, keycap: Bool, cutOut: Bool) {
        let bounds = CGRect(x: 0, y: 0, width: cell, height: cell)
        func placed(_ rect: CGRect) {
            context.saveGState()
            context.translateBy(x: cell / 2, y: cell / 2)
            context.rotate(by: CGFloat(turns) * .pi / 2)
            context.scaleBy(x: mirrored ? -1 : 1, y: 1)
            context.translateBy(x: -cell / 2, y: -cell / 2)
            image.draw(in: rect)
            context.restoreGState()
        }
        if cutOut {
            // A cut-out piece lying on the lawn, with a soft contact shadow.
            context.setShadow(offset: CGSize(width: 0, height: 2), blur: 3, color: FlowPalette.ink.withAlphaComponent(0.3).cgColor)
            placed(bounds.insetBy(dx: cell * 0.08, dy: cell * 0.08))
            return
        }
        if !keycap {
            // Method B without a cut-out: the picture's own rock, lifted off its grass by a soft oval.
            context.setShadow(offset: CGSize(width: 0, height: 2), blur: 3, color: FlowPalette.ink.withAlphaComponent(0.3).cgColor)
            context.saveGState()
            context.addPath(CGPath(ellipseIn: bounds.insetBy(dx: cell * 0.03, dy: cell * 0.12), transform: nil))
            context.clip()
            placed(bounds)
            context.restoreGState()
            return
        }
        let rect = bounds.insetBy(dx: 2.5, dy: 2.5)
        let radius = cell * 0.15
        let body = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 2), blur: 3, color: FlowPalette.ink.withAlphaComponent(0.34).cgColor)
        context.setFillColor(FlowPalette.grassDark.cgColor)
        context.addPath(body)
        context.fillPath()
        context.restoreGState()
        context.saveGState()
        context.addPath(body)
        context.clip()
        placed(bounds)
        context.setBlendMode(.multiply)
        context.setFillColor(Self.bankTint.cgColor)
        context.fill(bounds)
        context.setBlendMode(.normal)
        context.restoreGState()
        context.setStrokeColor(FlowPalette.grassDark.withAlphaComponent(0.75).cgColor)
        context.setLineWidth(1.2)
        context.addPath(body)
        context.strokePath()
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
        context.addPath(UIBezierPath(roundedRect: rect.insetBy(dx: 1.6, dy: 1.6), cornerRadius: max(0, radius - 1.6)).cgPath)
        context.strokePath()
    }

    /// The painted blank stone (batch 114, `x-flow-stone-c` takes 1 and 2), full bleed and even, so cells
    /// sit edge to edge without a seam. The code carves the channel into it.
    static let stoneArt = ["flow-stone", "flow-stone-2"]

    /// A warm multiply over the stone: the art is about 20 percent less chromatic than the straight tile.
    static let stoneTint = FlowPalette.rgb(1.0, 0.96, 0.89)

    private func texture(of image: UIImage) -> SKTexture {
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

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

    /// Which way a cell mirrors the seamless materials (bed and water): bit 0 mirrors left to right on odd
    /// columns, bit 1 top to bottom on odd rows. Two neighbours then meet on a mirrored edge, which is
    /// continuous by construction, so no wrap seam of the tile can fall on a cell boundary.
    static func flip(of cell: FlowCell) -> Int { (cell.column & 1) | ((cell.row & 1) << 1) }

    func stone(_ kind: FlowTileKind, _ openings: FlowDirection, flip: Int = 0) -> SKTexture {
        if kind == .wheel, let art = painted(Self.wheelTileArt) { return art }
        return cached("stone-\(kind.rawValue)-\(openings.rawValue)-\(flip)") { context in
            switch kind {
            case .rock: self.drawRock(context)
            case .grass: self.drawGrass(context)
            default: self.drawStone(context, kind: kind, openings: openings, flip: flip)
            }
        }
    }

    /// The painted pool as three slices of one picture (left cap, a middle that is stretched, right cap),
    /// so a rim of river stones can run the width of the board. `nil` until the art is in the bundle.
    static let poolArt = "flow-pool"

    func poolSlices() -> (left: SKTexture, middle: SKTexture, right: SKTexture, aspect: CGFloat)? {
        guard let whole = painted(Self.poolArt) else { return nil }
        let size = whole.size()
        func slice(_ from: CGFloat, _ to: CGFloat) -> SKTexture {
            let part = SKTexture(rect: CGRect(x: from, y: 0, width: to - from, height: 1), in: whole)
            part.filteringMode = .linear
            return part
        }
        return (slice(0, 0.4), slice(0.4, 0.6), slice(0.6, 1), size.width / size.height)
    }

    func water(_ kind: FlowTileKind, _ openings: FlowDirection, flip: Int = 0) -> SKTexture {
        cached("water-\(kind.rawValue)-\(openings.rawValue)-\(flip)") { context in
            self.drawWater(context, kind: kind, openings: openings, flip: flip)
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
        if let art = wood(Self.wheelArt) {
            if !blurred { return texture(of: art) }
            // Settled: the same painted wheel smeared over one eighth turn, which for eight spokes is a
            // still, soft disc of a turning wheel.
            return cached("wheel-painted-blur") { context in
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
        if let art = wood(FlowArtSlot.gate) { return texture(of: art) }
        return cached("gate") { context in
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

    /// The part of each seamless tile that is used, as fractions of the picture. The water tile is paler and
    /// pinker along its left and right edges and its wrap step is 8 to 12 times the interior's, so only its
    /// even middle is used; the bed tile is used without its outer fifth.
    static let waterCrop = CGRect(x: 0.29, y: 0.29, width: 0.42, height: 0.42)
    static let bedCrop = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)

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

    /// The warm family of the stone, for the painted wood: part of the saturation is taken out, then a warm
    /// multiply, so wheel and gate sit beside the cream stone. The art file itself is not recoloured.
    static let woodTint = FlowPalette.rgb(0.99, 0.96, 0.91)
    static let woodDesaturate: CGFloat = 0.30

    private var woodCache: [String: UIImage] = [:]

    /// A painted prop (wheel, gate) at 512 px, with the wood tint applied inside its own alpha.
    func wood(_ name: String) -> UIImage? {
        if let hit = woodCache[name] { return hit }
        guard let image = UIImage(named: name, in: .module, compatibleWith: nil), let mask = image.cgImage else { return nil }
        let side: CGFloat = 512
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let rect = CGRect(x: 0, y: 0, width: side, height: side)
        let result = UIGraphicsImageRenderer(size: rect.size, format: format).image { rendered in
            let context = rendered.cgContext
            image.draw(in: rect)
            context.saveGState()
            // `clip(to:mask:)` reads the mask upright in the native (y up) space.
            context.translateBy(x: 0, y: side)
            context.scaleBy(x: 1, y: -1)
            context.clip(to: rect, mask: mask)
            context.setBlendMode(.saturation)
            context.setFillColor(UIColor(white: 0.5, alpha: Self.woodDesaturate).cgColor)
            context.fill(rect)
            context.setBlendMode(.multiply)
            context.setFillColor(Self.woodTint.cgColor)
            context.fill(rect)
            context.restoreGState()
        }
        woodCache[name] = result
        return result
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

    private func drawStone(_ context: CGContext, kind: FlowTileKind, openings: FlowDirection, flip: Int) {
        if paintedStone(context, kind: kind, openings: openings, flip: flip) { return }
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

    /// The painted stone with the channel carved in by code. The variant (which take, which quarter turn,
    /// mirrored or not) comes from the tile's kind and openings, so a board reads hand-laid while the same
    /// tile always looks the same. Returns false until the art is in the bundle.
    private func paintedStone(_ context: CGContext, kind: FlowTileKind, openings: FlowDirection, flip: Int) -> Bool {
        let hash = kind.rawValue.unicodeScalars.reduce(7) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF } &+ Int(openings.rawValue) &* 13
        guard let image = UIImage(named: Self.stoneArt[hash % Self.stoneArt.count], in: .module, compatibleWith: nil) else { return false }
        let bounds = CGRect(x: 0, y: 0, width: cell, height: cell)
        // Every cell is its own laid stone: inset, rounded, with a soft drop shadow and a rim. The source and
        // the mouth are keycaps too; their faint carved rim, not a flush square, says they do not turn.
        let rect = bounds.insetBy(dx: 2.5, dy: 2.5)
        let radius = cell * 0.15
        let body = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
        do {
            context.saveGState()
            context.setShadow(offset: CGSize(width: 0, height: 2), blur: 3, color: FlowPalette.ink.withAlphaComponent(0.34).cgColor)
            context.setFillColor(FlowPalette.stoneShade.cgColor)
            context.addPath(body)
            context.fillPath()
            context.restoreGState()
        }
        context.saveGState()
        context.addPath(body)
        context.clip()
        context.saveGState()
        context.translateBy(x: cell / 2, y: cell / 2)
        context.rotate(by: CGFloat((hash / 2) % 4) * .pi / 2)
        context.translateBy(x: -cell / 2, y: -cell / 2)
        image.draw(in: bounds)
        context.restoreGState()
        context.setBlendMode(.multiply)
        context.setFillColor(Self.stoneTint.cgColor)
        context.fill(bounds)
        context.setBlendMode(.normal)
        // Fixed tiles keep a faint carved rim, so they read as not turnable.
        if !kind.isTurnable {
            context.setStrokeColor(FlowPalette.stoneEdge.withAlphaComponent(0.5).cgColor)
            context.setLineWidth(1.6)
            context.setLineDash(phase: 0, lengths: [5, 3])
            context.addPath(UIBezierPath(roundedRect: bounds.insetBy(dx: 9, dy: 9), cornerRadius: cell * 0.13).cgPath)
            context.strokePath()
            context.setLineDash(phase: 0, lengths: [])
        }
        // The carved channel: a soft shade around the bank, a light lip on the lower edge, a dark lip,
        // then the recessed floor with an inner shadow under its upper and left wall.
        let path = channelPath(openings)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.addPath(path)
        context.setStrokeColor(FlowPalette.ink.withAlphaComponent(0.14).cgColor)
        context.setLineWidth(grooveWidth + 9)
        context.strokePath()
        context.saveGState()
        context.translateBy(x: 1.6, y: 1.8)
        context.addPath(path)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.6).cgColor)
        context.setLineWidth(grooveWidth + 3)
        context.strokePath()
        context.restoreGState()
        context.addPath(path)
        context.setStrokeColor(FlowPalette.grooveDark.cgColor)
        context.setLineWidth(grooveWidth + 3)
        context.strokePath()
        context.saveGState()
        context.addPath(path)
        context.setLineWidth(grooveWidth)
        context.replacePathWithStrokedPath()
        context.clip()
        context.setFillColor(FlowPalette.grooveDark.cgColor)
        context.fill(bounds)
        context.translateBy(x: 2.4, y: 2.4)
        if let bed = art(FlowArtSlot.channelBed) {
            // The seamless channel bed fills the floor of the carved mask.
            context.addPath(path)
            context.setLineWidth(grooveWidth)
            context.replacePathWithStrokedPath()
            context.clip()
            // The bed is placed in cell space, not in the shifted frame, so a mirrored neighbour meets it exactly.
            drawSeamless(bed, crop: Self.bedCrop, flip: flip, in: bounds.insetBy(dx: -3, dy: -3).offsetBy(dx: -2.4, dy: -2.4), context)
        } else {
            context.addPath(path)
            context.setStrokeColor(FlowPalette.groove.cgColor)
            context.setLineWidth(grooveWidth)
            context.strokePath()
        }
        context.restoreGState()
        if kind == .source || kind == .mouth {
            let middle = CGPoint(x: cell / 2, y: cell / 2)
            if let spring = art(kind == .source ? FlowArtSlot.spring : FlowArtSlot.outlet) {
                // The painted spring or outlet sits on the keycap, centred on the channel's end.
                let side = cell * 0.9
                spring.draw(in: CGRect(x: middle.x - side / 2, y: middle.y - side / 2, width: side, height: side))
            } else {
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
        context.restoreGState()
        do {
            context.setStrokeColor(FlowPalette.stoneEdge.withAlphaComponent(0.85).cgColor)
            context.setLineWidth(1.2)
            context.addPath(body)
            context.strokePath()
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
            context.setLineWidth(1.2)
            context.addPath(UIBezierPath(roundedRect: rect.insetBy(dx: 1.6, dy: 1.6), cornerRadius: max(0, radius - 1.6)).cgPath)
            context.strokePath()
        }
        return true
    }

    private func drawWater(_ context: CGContext, kind: FlowTileKind, openings: FlowDirection, flip: Int) {
        let path = channelPath(openings)
        let middle = CGPoint(x: cell / 2, y: cell / 2)
        if let texture = art(FlowArtSlot.water) {
            // The painted water fills the carved channel from a seamless texture. A painted spring or outlet
            // is not covered by a drawn ball.
            let hasBall = (kind == .source || kind == .mouth) && art(kind == .source ? FlowArtSlot.spring : FlowArtSlot.outlet) == nil
            let body = CGMutablePath()
            body.addPath(path.copy(strokingWithWidth: grooveWidth * 0.92, lineCap: .round, lineJoin: .round, miterLimit: 10))
            if hasBall {
                let radius = grooveWidth * (kind == .source ? 0.95 : 1.0)
                body.addEllipse(in: CGRect(x: middle.x - radius, y: middle.y - radius, width: radius * 2, height: radius * 2))
            }
            context.saveGState()
            context.addPath(body)
            context.clip()
            drawSeamless(texture, crop: Self.waterCrop, flip: flip, in: CGRect(x: 0, y: 0, width: cell, height: cell).insetBy(dx: -3, dy: -3), context)
            context.restoreGState()
            context.setStrokeColor(FlowPalette.waterDeep.withAlphaComponent(0.35).cgColor)
            context.setLineWidth(1.2)
            context.addPath(body)
            context.strokePath()
            return
        }
        context.setLineCap(.round)
        context.setLineJoin(.round)
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
