#if os(iOS)
import SpriteKit
import SwiftUI
import UIKit

/// The garden's palette: the crafted layer's materials (ui-system-v2 §3.1:
/// clay, paper, wood for trays), sampled from the garden station's art so
/// the game sits beside the island without a seam.
@MainActor
enum GardenPalette {
    static func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> UIColor {
        UIColor(red: r, green: g, blue: b, alpha: a)
    }

    // Sky and paper.
    static let skyTop = rgb(1.00, 0.96, 0.88)
    static let skyBottom = rgb(0.97, 0.87, 0.68)
    static let sun = rgb(1.00, 0.92, 0.62)
    static let ink = rgb(0.36, 0.24, 0.16)

    // The bed: a rim of the garden's peach clay stones around warm soil.
    static let rimLight = rgb(0.96, 0.86, 0.76)
    static let rimShade = rgb(0.84, 0.67, 0.54)
    static let soilDeep = rgb(0.55, 0.35, 0.26)
    static let soil = rgb(0.68, 0.45, 0.34)
    static let soilLight = rgb(0.74, 0.52, 0.40)

    // The tray: honey wood.
    static let woodLight = rgb(0.86, 0.66, 0.45)
    static let woodShade = rgb(0.71, 0.50, 0.32)
    static let woodGrain = rgb(0.55, 0.36, 0.22, 0.22)

    /// Clay glazes for the plots, one per `PieceFamily.tint`: sage, honey,
    /// terracotta, lilac, mint, rose. Pastel but saturated enough to read
    /// against soil at 21 pt in the tray.
    static let glazes: [UIColor] = [
        rgb(0.58, 0.74, 0.46),
        rgb(0.97, 0.77, 0.36),
        rgb(0.93, 0.56, 0.43),
        rgb(0.69, 0.60, 0.88),
        rgb(0.44, 0.73, 0.68),
        rgb(0.93, 0.58, 0.67),
    ]

    static let glow = rgb(1.00, 0.86, 0.44)
    static let petal = rgb(0.99, 0.82, 0.42)
    static let seedDark = rgb(0.27, 0.23, 0.21)
    static let seedStripe = rgb(0.93, 0.90, 0.82)
    static let blush = rgb(0.98, 0.55, 0.58)

    /// Bloom words warm up with the combo: honey, coral, then violet glaze.
    static func comboInk(_ combo: Int) -> UIColor {
        switch combo {
        case ..<2: rgb(0.98, 0.78, 0.30)
        case 2: rgb(0.97, 0.56, 0.38)
        case 3: rgb(0.93, 0.44, 0.52)
        default: rgb(0.56, 0.44, 0.88)
        }
    }
}

extension UIColor {
    func adjusted(brightness factor: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        return UIColor(hue: h, saturation: s, brightness: min(1, b * factor), alpha: a)
    }
}

/// The garden's textures: the painted sprites from the bundle, and the
/// drawn ones (tiles, soil, tray, glows, seeds, petals) rendered once per
/// size with Core Graphics at 3x and cached.
@MainActor
final class GardenTextures {
    private var cache: [String: SKTexture] = [:]
    private let scale: CGFloat = 3

    // MARK: Painted art

    enum Art: String, CaseIterable {
        case pofu = "garden-pofu"
        case pofuPuff = "garden-pofu-puff"
        case mochi = "garden-mochi"
        case findik = "garden-findik"
        case bloom = "garden-bloom"
        case bloomSmall = "garden-bloom-small"
    }

    static func image(_ art: Art) -> UIImage? {
        if let image = UIImage(named: art.rawValue, in: .module, with: nil) {
            return image
        }
        guard let path = Bundle.module.path(forResource: art.rawValue, ofType: "png") else { return nil }
        return UIImage(contentsOfFile: path)
    }

    func art(_ art: Art) -> SKTexture {
        cached("art.\(art.rawValue)") {
            if let image = Self.image(art) {
                return SKTexture(image: image)
            }
            // Never a blank: a drawn stand-in if the bundle lacks the PNG.
            return SKTexture(image: Self.render(CGSize(width: 64, height: 64), scale: 2) { context, rect in
                context.setFillColor(GardenPalette.glow.cgColor)
                context.fillEllipse(in: rect.insetBy(dx: 4, dy: 4))
            })
        }
    }

    // MARK: Drawn sprites

    /// A clay plot tile: glaze gradient, a top light, a darker lip at the
    /// bottom and a small embossed sprout.
    func tile(tint: Int, side: CGFloat) -> SKTexture {
        cached("tile.\(tint).\(side)") {
            let base = GardenPalette.glazes[tint % GardenPalette.glazes.count]
            return SKTexture(image: Self.render(CGSize(width: side, height: side), scale: scale) { context, rect in
                let radius = side * 0.24
                let body = UIBezierPath(roundedRect: rect, cornerRadius: radius)
                // The lip: the whole tile in a darker glaze, then the face
                // above it, shorter by the lip's height.
                context.setFillColor(base.adjusted(brightness: 0.78).cgColor)
                context.addPath(body.cgPath)
                context.fillPath()
                let lip = max(2, side * 0.09)
                let faceRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - lip)
                let face = UIBezierPath(roundedRect: faceRect, cornerRadius: radius)
                context.saveGState()
                context.addPath(face.cgPath)
                context.clip()
                Self.linearGradient(
                    context,
                    colors: [base.adjusted(brightness: 1.12), base, base.adjusted(brightness: 0.94)],
                    from: CGPoint(x: rect.midX, y: rect.minY),
                    to: CGPoint(x: rect.midX, y: faceRect.maxY)
                )
                // The top light: a soft ellipse, like glaze catching the sun.
                context.setFillColor(UIColor.white.withAlphaComponent(0.32).cgColor)
                context.fillEllipse(in: CGRect(x: side * 0.16, y: side * 0.08, width: side * 0.5, height: side * 0.22))
                context.restoreGState()

                // The sprout, embossed: a darker glaze with a light edge.
                let sprout = Self.sproutPath(in: CGRect(x: side * 0.3, y: side * 0.26, width: side * 0.4, height: side * 0.42))
                context.saveGState()
                context.translateBy(x: 0, y: 1)
                context.setFillColor(UIColor.white.withAlphaComponent(0.35).cgColor)
                context.addPath(sprout)
                context.fillPath()
                context.restoreGState()
                context.setFillColor(base.adjusted(brightness: 0.8).withAlphaComponent(0.85).cgColor)
                context.addPath(sprout)
                context.fillPath()
            })
        }
    }

    /// An empty cell: a soft soil mound with two crumbs.
    func soilCell(side: CGFloat) -> SKTexture {
        cached("soil.\(side)") {
            SKTexture(image: Self.render(CGSize(width: side, height: side), scale: scale) { context, rect in
                let body = UIBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerRadius: side * 0.22)
                context.saveGState()
                context.addPath(body.cgPath)
                context.clip()
                Self.linearGradient(
                    context,
                    colors: [GardenPalette.soilLight, GardenPalette.soil],
                    from: CGPoint(x: rect.midX, y: rect.minY),
                    to: CGPoint(x: rect.midX, y: rect.maxY)
                )
                context.setFillColor(GardenPalette.soilDeep.withAlphaComponent(0.35).cgColor)
                context.fillEllipse(in: CGRect(x: side * 0.24, y: side * 0.58, width: side * 0.1, height: side * 0.08))
                context.fillEllipse(in: CGRect(x: side * 0.62, y: side * 0.3, width: side * 0.08, height: side * 0.06))
                context.restoreGState()
            })
        }
    }

    /// The bed: a clay rim around a sunken soil floor, with a soft inner
    /// shadow under the back rim.
    func bed(size: CGSize, padding: CGFloat) -> SKTexture {
        cached("bed.\(size.width)x\(size.height)") {
            SKTexture(image: Self.render(size, scale: scale) { context, rect in
                let outer = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: padding * 2.4)
                context.saveGState()
                context.setShadow(offset: CGSize(width: 0, height: 4), blur: 6, color: GardenPalette.ink.withAlphaComponent(0.25).cgColor)
                context.setFillColor(GardenPalette.rimShade.cgColor)
                context.addPath(outer.cgPath)
                context.fillPath()
                context.restoreGState()

                context.saveGState()
                context.addPath(outer.cgPath)
                context.clip()
                Self.linearGradient(
                    context,
                    colors: [GardenPalette.rimLight, GardenPalette.rimShade],
                    from: CGPoint(x: rect.midX, y: rect.minY),
                    to: CGPoint(x: rect.midX, y: rect.maxY)
                )
                context.restoreGState()

                let floorRect = rect.insetBy(dx: padding - 3, dy: padding - 3)
                let floor = UIBezierPath(roundedRect: floorRect, cornerRadius: padding * 1.3)
                context.saveGState()
                context.addPath(floor.cgPath)
                context.clip()
                context.setFillColor(GardenPalette.soilDeep.cgColor)
                context.fill(floorRect)
                // Inner shadow from the back rim.
                Self.linearGradient(
                    context,
                    colors: [GardenPalette.ink.withAlphaComponent(0.35), GardenPalette.ink.withAlphaComponent(0)],
                    from: CGPoint(x: rect.midX, y: floorRect.minY),
                    to: CGPoint(x: rect.midX, y: floorRect.minY + padding * 1.6)
                )
                context.restoreGState()
                // A light line on the rim's top edge.
                context.setStrokeColor(UIColor.white.withAlphaComponent(0.45).cgColor)
                context.setLineWidth(1.2)
                context.addPath(UIBezierPath(roundedRect: rect.insetBy(dx: 2.5, dy: 2.5), cornerRadius: padding * 2.3).cgPath)
                context.strokePath()
            })
        }
    }

    /// The wooden tray: honey planks with grain and a recessed floor.
    func tray(size: CGSize) -> SKTexture {
        cached("tray.\(size.width)x\(size.height)") {
            SKTexture(image: Self.render(size, scale: scale) { context, rect in
                let body = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: 26)
                context.saveGState()
                context.setShadow(offset: CGSize(width: 0, height: 5), blur: 8, color: GardenPalette.ink.withAlphaComponent(0.28).cgColor)
                context.setFillColor(GardenPalette.woodShade.cgColor)
                context.addPath(body.cgPath)
                context.fillPath()
                context.restoreGState()

                context.saveGState()
                context.addPath(body.cgPath)
                context.clip()
                Self.linearGradient(
                    context,
                    colors: [GardenPalette.woodLight, GardenPalette.woodShade],
                    from: CGPoint(x: rect.midX, y: rect.minY),
                    to: CGPoint(x: rect.midX, y: rect.maxY)
                )
                // Grain: long, gently wavy lines, deterministic.
                context.setStrokeColor(GardenPalette.woodGrain.cgColor)
                context.setLineWidth(1)
                for line in 0..<9 {
                    let y = rect.minY + rect.height * (CGFloat(line) + 0.5) / 9
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: rect.minX, y: y))
                    var x = rect.minX
                    while x < rect.maxX {
                        x += 6
                        let wobble = sin(x * 0.021 + CGFloat(line) * 1.7) * 2.2 + sin(x * 0.067 + CGFloat(line)) * 0.8
                        path.addLine(to: CGPoint(x: x, y: y + wobble))
                    }
                    context.addPath(path.cgPath)
                    context.strokePath()
                }
                context.restoreGState()

                // The recessed floor.
                let floorRect = rect.insetBy(dx: 12, dy: 12)
                let floor = UIBezierPath(roundedRect: floorRect, cornerRadius: 18)
                context.saveGState()
                context.addPath(floor.cgPath)
                context.clip()
                context.setFillColor(GardenPalette.woodShade.withAlphaComponent(0.55).cgColor)
                context.fill(floorRect)
                Self.linearGradient(
                    context,
                    colors: [GardenPalette.ink.withAlphaComponent(0.22), GardenPalette.ink.withAlphaComponent(0)],
                    from: CGPoint(x: rect.midX, y: floorRect.minY),
                    to: CGPoint(x: rect.midX, y: floorRect.minY + 14)
                )
                context.restoreGState()
                context.setStrokeColor(UIColor.white.withAlphaComponent(0.35).cgColor)
                context.setLineWidth(1.2)
                context.addPath(UIBezierPath(roundedRect: rect.insetBy(dx: 2.5, dy: 2.5), cornerRadius: 24).cgPath)
                context.strokePath()
            })
        }
    }

    /// The sky behind the garden: warm cream to honey, a soft sun behind
    /// Pofu, and a faint vignette.
    func sky(size: CGSize, sunAt sun: CGPoint) -> SKTexture {
        cached("sky.\(size.width)x\(size.height)") {
            SKTexture(image: Self.render(size, scale: 2) { context, rect in
                Self.linearGradient(
                    context,
                    colors: [GardenPalette.skyTop, GardenPalette.skyBottom],
                    from: CGPoint(x: rect.midX, y: rect.minY),
                    to: CGPoint(x: rect.midX, y: rect.maxY)
                )
                // `sun` is in SpriteKit points (y up); flip for UIKit.
                let center = CGPoint(x: sun.x, y: rect.height - sun.y)
                Self.radialGradient(context, colors: [GardenPalette.sun.withAlphaComponent(0.85), GardenPalette.sun.withAlphaComponent(0)], center: center, radius: rect.width * 0.62)
                Self.radialGradient(
                    context,
                    colors: [GardenPalette.ink.withAlphaComponent(0), GardenPalette.ink.withAlphaComponent(0.10)],
                    center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: max(rect.width, rect.height) * 0.75,
                    startRadius: max(rect.width, rect.height) * 0.4
                )
            })
        }
    }

    /// A soft honey glow for a cell in a line about to bloom.
    func glow(side: CGFloat) -> SKTexture {
        cached("glow.\(side)") {
            SKTexture(image: Self.render(CGSize(width: side, height: side), scale: scale) { context, rect in
                let body = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: side * 0.26)
                context.addPath(body.cgPath)
                context.clip()
                Self.radialGradient(
                    context,
                    colors: [GardenPalette.glow.withAlphaComponent(0.95), GardenPalette.glow.withAlphaComponent(0.45)],
                    center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: side * 0.72
                )
            })
        }
    }

    /// A soft drop shadow under a lifted plot.
    func shadow(side: CGFloat) -> SKTexture {
        cached("shadow.\(side)") {
            SKTexture(image: Self.render(CGSize(width: side, height: side), scale: 2) { context, rect in
                context.setFillColor(GardenPalette.ink.withAlphaComponent(0.22).cgColor)
                context.addPath(UIBezierPath(roundedRect: rect.insetBy(dx: side * 0.08, dy: side * 0.08), cornerRadius: side * 0.26).cgPath)
                context.fillPath()
            })
        }
    }

    /// A ground shadow under a resident's feet.
    func groundShadow() -> SKTexture {
        cached("ground") {
            SKTexture(image: Self.render(CGSize(width: 80, height: 20), scale: 2) { context, rect in
                Self.radialGradient(
                    context,
                    colors: [GardenPalette.ink.withAlphaComponent(0.30), GardenPalette.ink.withAlphaComponent(0)],
                    center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: rect.width / 2,
                    verticalScale: rect.height / rect.width
                )
            })
        }
    }

    /// A sunflower seed: a dark teardrop with cream stripes.
    func seed() -> SKTexture {
        cached("seed") {
            SKTexture(image: Self.render(CGSize(width: 13, height: 19), scale: scale) { context, outer in
                // A cream halo first, so a dark seed reads over dark soil.
                let rect = outer.insetBy(dx: 1.5, dy: 1.5)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: rect.midX, y: rect.minY + 0.5))
                path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY - 0.5), controlPoint1: CGPoint(x: rect.maxX + 1.5, y: rect.minY + 5), controlPoint2: CGPoint(x: rect.maxX, y: rect.maxY - 1))
                path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + 0.5), controlPoint1: CGPoint(x: rect.minX, y: rect.maxY - 1), controlPoint2: CGPoint(x: rect.minX - 1.5, y: rect.minY + 5))
                context.addPath(path.cgPath)
                context.setStrokeColor(GardenPalette.seedStripe.withAlphaComponent(0.9).cgColor)
                context.setLineWidth(2.4)
                context.strokePath()
                context.addPath(path.cgPath)
                context.setFillColor(GardenPalette.seedDark.cgColor)
                context.fillPath()
                context.addPath(path.cgPath)
                context.clip()
                context.setStrokeColor(GardenPalette.seedStripe.cgColor)
                context.setLineWidth(0.9)
                for x in [rect.midX - 2.4, rect.midX, rect.midX + 2.4] {
                    context.move(to: CGPoint(x: x, y: rect.minY + 3))
                    context.addLine(to: CGPoint(x: x, y: rect.maxY - 2))
                }
                context.strokePath()
            })
        }
    }

    /// A single sunflower petal.
    func petal() -> SKTexture {
        cached("petal") {
            SKTexture(image: Self.render(CGSize(width: 8, height: 14), scale: scale) { context, rect in
                context.setFillColor(GardenPalette.petal.cgColor)
                context.fillEllipse(in: rect.insetBy(dx: 0.5, dy: 0.5))
                context.setFillColor(UIColor.white.withAlphaComponent(0.35).cgColor)
                context.fillEllipse(in: CGRect(x: 2, y: 2, width: 3, height: 6))
            })
        }
    }

    /// A four-pointed sparkle.
    func sparkle() -> SKTexture {
        cached("sparkle") {
            SKTexture(image: Self.render(CGSize(width: 16, height: 16), scale: scale) { context, rect in
                let c = CGPoint(x: rect.midX, y: rect.midY)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: c.x, y: rect.minY))
                path.addQuadCurve(to: CGPoint(x: rect.maxX, y: c.y), controlPoint: c)
                path.addQuadCurve(to: CGPoint(x: c.x, y: rect.maxY), controlPoint: c)
                path.addQuadCurve(to: CGPoint(x: rect.minX, y: c.y), controlPoint: c)
                path.addQuadCurve(to: CGPoint(x: c.x, y: rect.minY), controlPoint: c)
                context.setFillColor(UIColor(red: 1, green: 0.97, blue: 0.84, alpha: 1).cgColor)
                context.addPath(path.cgPath)
                context.fillPath()
            })
        }
    }

    /// A soil crumb kicked up by a planting.
    func crumb() -> SKTexture {
        cached("crumb") {
            SKTexture(image: Self.render(CGSize(width: 6, height: 6), scale: scale) { context, rect in
                context.setFillColor(GardenPalette.soil.cgColor)
                context.fillEllipse(in: rect)
            })
        }
    }

    /// A soft round blush for Pofu's cheeks.
    func blush() -> SKTexture {
        cached("blush") {
            SKTexture(image: Self.render(CGSize(width: 40, height: 28), scale: 2) { context, rect in
                Self.radialGradient(
                    context,
                    colors: [GardenPalette.blush.withAlphaComponent(0.9), GardenPalette.blush.withAlphaComponent(0)],
                    center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: rect.width / 2,
                    verticalScale: rect.height / rect.width
                )
            })
        }
    }

    // MARK: Helpers

    private func cached(_ key: String, make: () -> SKTexture) -> SKTexture {
        if let texture = cache[key] { return texture }
        let texture = make()
        cache[key] = texture
        return texture
    }

    static func render(_ size: CGSize, scale: CGFloat, draw: (CGContext, CGRect) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let rect = CGRect(origin: .zero, size: CGSize(width: max(1, size.width), height: max(1, size.height)))
        return UIGraphicsImageRenderer(size: rect.size, format: format).image { renderer in
            draw(renderer.cgContext, rect)
        }
    }

    static func linearGradient(_ context: CGContext, colors: [UIColor], from start: CGPoint, to end: CGPoint) {
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map(\.cgColor) as CFArray, locations: nil) else { return }
        context.drawLinearGradient(gradient, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }

    static func radialGradient(
        _ context: CGContext,
        colors: [UIColor],
        center: CGPoint,
        radius: CGFloat,
        startRadius: CGFloat = 0,
        verticalScale: CGFloat = 1
    ) {
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map(\.cgColor) as CFArray, locations: nil) else { return }
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.scaleBy(x: 1, y: verticalScale)
        context.drawRadialGradient(gradient, startCenter: .zero, startRadius: startRadius, endCenter: .zero, endRadius: radius, options: [.drawsAfterEndLocation])
        context.restoreGState()
    }

    /// A two-leaf sprout fitted in `rect` (UIKit coordinates, y down).
    static func sproutPath(in rect: CGRect) -> CGPath {
        let path = UIBezierPath()
        let stemBottom = CGPoint(x: rect.midX, y: rect.maxY)
        let stemTop = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.42)
        // Stem.
        path.append(UIBezierPath(roundedRect: CGRect(x: rect.midX - rect.width * 0.06, y: stemTop.y, width: rect.width * 0.12, height: stemBottom.y - stemTop.y), cornerRadius: rect.width * 0.06))
        // Left leaf.
        let left = UIBezierPath()
        left.move(to: stemTop)
        left.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.12), controlPoint: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.minY + rect.height * 0.55))
        left.addQuadCurve(to: stemTop, controlPoint: CGPoint(x: rect.midX - rect.width * 0.02, y: rect.minY + rect.height * 0.02))
        path.append(left)
        // Right leaf.
        let right = UIBezierPath()
        right.move(to: stemTop)
        right.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), controlPoint: CGPoint(x: rect.maxX - rect.width * 0.02, y: rect.minY + rect.height * 0.5))
        right.addQuadCurve(to: stemTop, controlPoint: CGPoint(x: rect.midX + rect.width * 0.04, y: rect.minY - rect.height * 0.02))
        path.append(right)
        return path.cgPath
    }
}
#endif
