#if os(iOS)
import PofuCore
import SwiftUI

/// Code-drawn stand-ins for the art the Codex queue has not painted yet
/// (`dressing-meadow`, `dressing-garden`, `dressing-harbor`,
/// `critter-butterfly`, `critter-snail`, `critter-bird`, `critter-ladybug`,
/// `visitor-dandelion`, `gift-parcel`, `guest-letter`). Each is looked up by
/// its sprite name first: the day a baked sprite of that name exists, the
/// scene draws it and the stand-in goes unused. All coordinates are world
/// units; every stand-in is drawn in a small box whose bottom centre sits on
/// the object's feet.
enum LifeArt {
    private static func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(red: r, green: g, blue: b)
    }

    // Shared inks.
    private static let leaf = rgb(0.40, 0.62, 0.30)
    private static let leafDark = rgb(0.30, 0.50, 0.24)
    private static let wood = rgb(0.66, 0.46, 0.28)
    private static let woodDark = rgb(0.50, 0.34, 0.20)
    private static let paper = rgb(0.97, 0.93, 0.82)
    private static let outline = rgb(0.30, 0.22, 0.16)

    // MARK: Dressing

    static func size(of kind: DressingKind) -> CGSize {
        switch kind {
        case .grassTuft: CGSize(width: 18, height: 12)
        case .wildflowers: CGSize(width: 26, height: 20)
        case .pebbles: CGSize(width: 20, height: 8)
        case .mushroomRing: CGSize(width: 36, height: 14)
        case .wateringCan: CGSize(width: 24, height: 18)
        case .seedSack: CGSize(width: 18, height: 20)
        case .twine: CGSize(width: 16, height: 12)
        case .crate: CGSize(width: 22, height: 18)
        case .trowel: CGSize(width: 18, height: 8)
        case .rope: CGSize(width: 22, height: 10)
        case .barrel: CGSize(width: 16, height: 20)
        }
    }

    static func drawDressing(_ kind: DressingKind, in context: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        switch kind {
        case .grassTuft:
            var blades = Path()
            for i in 0..<5 {
                let x = w * (0.16 + 0.17 * Double(i))
                let lift = h * (0.45 + 0.4 * (1 - abs(Double(i) - 2) / 2))
                blades.move(to: CGPoint(x: x, y: h))
                blades.addQuadCurve(to: CGPoint(x: x + (Double(i) - 2) * 1.6, y: h - lift), control: CGPoint(x: x, y: h - lift * 0.5))
            }
            context.stroke(blades, with: .color(leaf), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        case .wildflowers:
            let blooms: [(Double, Double, Color)] = [
                (0.2, 0.30, rgb(0.95, 0.62, 0.72)), (0.42, 0.14, rgb(0.98, 0.86, 0.34)),
                (0.64, 0.34, rgb(0.97, 0.97, 0.94)), (0.84, 0.18, rgb(0.74, 0.62, 0.90)),
            ]
            var stems = Path()
            for (x, top, _) in blooms {
                stems.move(to: CGPoint(x: w * (x * 0.8 + 0.1), y: h))
                stems.addLine(to: CGPoint(x: w * x, y: h * top + 2))
            }
            context.stroke(stems, with: .color(leafDark), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
            for (x, top, colour) in blooms {
                let centre = CGPoint(x: w * x, y: h * top)
                context.fill(Path(ellipseIn: CGRect(x: centre.x - 3, y: centre.y - 3, width: 6, height: 6)), with: .color(colour))
                context.fill(Path(ellipseIn: CGRect(x: centre.x - 1, y: centre.y - 1, width: 2, height: 2)), with: .color(rgb(0.95, 0.75, 0.25)))
            }
            context.fill(Path(ellipseIn: CGRect(x: w * 0.30, y: h * 0.78, width: 6, height: 3)), with: .color(leaf))
            context.fill(Path(ellipseIn: CGRect(x: w * 0.55, y: h * 0.80, width: 6, height: 3)), with: .color(leaf))
        case .pebbles:
            for (x, y, pw, ph, tone) in [(0.05, 0.35, 0.42, 0.65, 0.55), (0.42, 0.20, 0.34, 0.6, 0.62), (0.68, 0.45, 0.28, 0.5, 0.5)] {
                let rect = CGRect(x: w * x, y: h * y, width: w * pw, height: h * ph)
                context.fill(Path(ellipseIn: rect), with: .color(rgb(tone, tone - 0.03, tone - 0.08)))
                context.fill(Path(ellipseIn: rect.insetBy(dx: rect.width * 0.28, dy: rect.height * 0.3).offsetBy(dx: -1, dy: -1)), with: .color(Color.white.opacity(0.35)))
            }
        case .mushroomRing:
            for i in 0..<5 {
                let angle = Double(i) * 2 * .pi / 5 + 0.4
                let cx = w / 2 + cos(angle) * w * 0.38
                let cy = h * 0.62 + sin(angle) * h * 0.3
                context.fill(Path(CGRect(x: cx - 1, y: cy - 2, width: 2, height: 4)), with: .color(paper))
                let cap = Path(ellipseIn: CGRect(x: cx - 3.5, y: cy - 5, width: 7, height: 4.4))
                context.fill(cap, with: .color(rgb(0.84, 0.28, 0.24)))
                context.fill(Path(ellipseIn: CGRect(x: cx - 1.4, y: cy - 4.2, width: 1.4, height: 1.4)), with: .color(Color.white))
            }
        case .wateringCan:
            var handle = Path()
            handle.addArc(center: CGPoint(x: w * 0.16, y: h * 0.58), radius: h * 0.24, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
            context.stroke(handle, with: .color(rgb(0.30, 0.56, 0.58)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            var spout = Path()
            spout.move(to: CGPoint(x: w * 0.66, y: h * 0.62))
            spout.addLine(to: CGPoint(x: w * 0.96, y: h * 0.26))
            context.stroke(spout, with: .color(rgb(0.36, 0.64, 0.66)), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            let body = Path(roundedRect: CGRect(x: w * 0.12, y: h * 0.36, width: w * 0.56, height: h * 0.62), cornerRadius: 3)
            context.fill(body, with: .color(rgb(0.42, 0.72, 0.72)))
            context.fill(Path(CGRect(x: w * 0.12, y: h * 0.42, width: w * 0.56, height: 1.4)), with: .color(Color.white.opacity(0.5)))
        case .seedSack:
            let sack = Path(ellipseIn: CGRect(x: w * 0.06, y: h * 0.34, width: w * 0.88, height: h * 0.66))
            context.fill(sack, with: .color(rgb(0.88, 0.76, 0.52)))
            let neck = Path(roundedRect: CGRect(x: w * 0.30, y: h * 0.10, width: w * 0.40, height: h * 0.34), cornerRadius: 2.5)
            context.fill(neck, with: .color(rgb(0.82, 0.69, 0.44)))
            context.fill(Path(CGRect(x: w * 0.28, y: h * 0.30, width: w * 0.44, height: 1.6)), with: .color(woodDark))
            for (x, y) in [(0.34, 0.68), (0.56, 0.74), (0.46, 0.58)] {
                context.fill(Path(ellipseIn: CGRect(x: w * x, y: h * y, width: 2, height: 1.4)), with: .color(rgb(0.45, 0.34, 0.20)))
            }
        case .twine:
            let ball = CGRect(x: 1, y: 1, width: w - 2, height: h - 2)
            context.fill(Path(ellipseIn: ball), with: .color(rgb(0.84, 0.70, 0.46)))
            for inset in [2.5, 4.5] {
                context.stroke(Path(ellipseIn: ball.insetBy(dx: inset, dy: inset * 0.7)), with: .color(rgb(0.62, 0.48, 0.28)), lineWidth: 0.8)
            }
        case .crate:
            context.fill(Path(CGRect(x: 1, y: h * 0.22, width: w - 2, height: h * 0.78)), with: .color(wood))
            context.fill(Path(CGRect(x: 1, y: h * 0.22, width: w - 2, height: 2.4)), with: .color(rgb(0.78, 0.58, 0.38)))
            for y in [0.5, 0.74] {
                context.fill(Path(CGRect(x: 1, y: h * y, width: w - 2, height: 1)), with: .color(woodDark))
            }
            context.stroke(Path(CGRect(x: 1, y: h * 0.22, width: w - 2, height: h * 0.78)), with: .color(woodDark), lineWidth: 1)
        case .trowel:
            context.fill(Path(roundedRect: CGRect(x: 0, y: h * 0.28, width: w * 0.38, height: h * 0.46), cornerRadius: 2), with: .color(woodDark))
            var blade = Path()
            blade.move(to: CGPoint(x: w * 0.36, y: h * 0.2))
            blade.addQuadCurve(to: CGPoint(x: w, y: h * 0.52), control: CGPoint(x: w * 0.78, y: h * 0.1))
            blade.addQuadCurve(to: CGPoint(x: w * 0.36, y: h * 0.84), control: CGPoint(x: w * 0.78, y: h * 0.94))
            blade.closeSubpath()
            context.fill(blade, with: .color(rgb(0.72, 0.74, 0.76)))
        case .rope:
            let coil = CGRect(x: 1, y: 1, width: w - 2, height: h - 2)
            for inset in [0.0, 2.2, 4.4] {
                context.stroke(Path(ellipseIn: coil.insetBy(dx: inset * 1.4, dy: inset * 0.55)), with: .color(rgb(0.82, 0.68, 0.44)), lineWidth: 1.8)
            }
        case .barrel:
            let body = Path(roundedRect: CGRect(x: 1, y: h * 0.12, width: w - 2, height: h * 0.86), cornerRadius: 4)
            context.fill(body, with: .color(wood))
            context.fill(Path(ellipseIn: CGRect(x: 1, y: 1, width: w - 2, height: h * 0.26)), with: .color(rgb(0.80, 0.62, 0.42)))
            for y in [0.38, 0.72] {
                context.fill(Path(CGRect(x: 1, y: h * y, width: w - 2, height: 1.6)), with: .color(woodDark))
            }
        }
    }

    // MARK: Critters

    static func size(of kind: CritterKind) -> CGSize {
        switch kind {
        case .butterfly: CGSize(width: 16, height: 12)
        case .snail: CGSize(width: 14, height: 10)
        case .bird: CGSize(width: 14, height: 14)
        case .frog: CGSize(width: 14, height: 9)
        case .ladybug: CGSize(width: 9, height: 7)
        }
    }

    static func drawCritter(_ kind: CritterKind, frame: Int, in context: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        switch kind {
        case .butterfly:
            // The wings beat: full, narrower, thin, narrower.
            let spread = [1.0, 0.7, 0.4, 0.7][frame & 3]
            let half = w * 0.5 * spread
            for side in [-1.0, 1.0] {
                let wing = CGRect(x: w / 2 + (side < 0 ? -half : 0), y: h * 0.05, width: half, height: h * 0.7)
                context.fill(Path(ellipseIn: wing), with: .color(rgb(0.98, 0.66, 0.26)))
                context.fill(Path(ellipseIn: wing.insetBy(dx: wing.width * 0.3, dy: wing.height * 0.32)), with: .color(Color.white.opacity(0.85)))
            }
            context.fill(Path(roundedRect: CGRect(x: w / 2 - 0.9, y: h * 0.2, width: 1.8, height: h * 0.7), cornerRadius: 0.9), with: .color(outline))
        case .snail:
            context.fill(Path(ellipseIn: CGRect(x: 0, y: h * 0.62, width: w * 0.86, height: h * 0.38)), with: .color(rgb(0.90, 0.82, 0.66)))
            let shell = CGRect(x: w * 0.22, y: 0, width: w * 0.52, height: h * 0.84)
            context.fill(Path(ellipseIn: shell), with: .color(rgb(0.80, 0.52, 0.32)))
            context.stroke(Path(ellipseIn: shell.insetBy(dx: shell.width * 0.28, dy: shell.height * 0.28)), with: .color(rgb(0.58, 0.34, 0.20)), lineWidth: 0.8)
            var feelers = Path()
            for dx in [0.74, 0.86] {
                feelers.move(to: CGPoint(x: w * dx, y: h * 0.7))
                feelers.addLine(to: CGPoint(x: w * (dx + 0.06), y: h * 0.36))
            }
            context.stroke(feelers, with: .color(rgb(0.78, 0.68, 0.52)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
        case .bird:
            context.fill(Path(ellipseIn: CGRect(x: w * 0.06, y: h * 0.24, width: w * 0.78, height: h * 0.7)), with: .color(rgb(0.50, 0.66, 0.84)))
            context.fill(Path(ellipseIn: CGRect(x: w * 0.22, y: h * 0.46, width: w * 0.46, height: h * 0.42)), with: .color(rgb(0.96, 0.92, 0.84)))
            var beak = Path()
            beak.move(to: CGPoint(x: w * 0.84, y: h * 0.42))
            beak.addLine(to: CGPoint(x: w, y: h * 0.5))
            beak.addLine(to: CGPoint(x: w * 0.84, y: h * 0.58))
            beak.closeSubpath()
            context.fill(beak, with: .color(rgb(0.95, 0.62, 0.24)))
            context.fill(Path(ellipseIn: CGRect(x: w * 0.62, y: h * 0.38, width: 1.8, height: 1.8)), with: .color(outline))
        case .frog:
            context.fill(Path(ellipseIn: CGRect(x: 0, y: h * 0.28, width: w, height: h * 0.72)), with: .color(rgb(0.46, 0.72, 0.38)))
            context.fill(Path(ellipseIn: CGRect(x: w * 0.2, y: h * 0.6, width: w * 0.6, height: h * 0.36)), with: .color(rgb(0.80, 0.90, 0.62)))
            for x in [0.2, 0.62] {
                context.fill(Path(ellipseIn: CGRect(x: w * x, y: 0, width: w * 0.2, height: h * 0.36)), with: .color(rgb(0.46, 0.72, 0.38)))
                context.fill(Path(ellipseIn: CGRect(x: w * (x + 0.05), y: h * 0.08, width: w * 0.1, height: h * 0.2)), with: .color(outline))
            }
        case .ladybug:
            context.fill(Path(ellipseIn: CGRect(x: w * 0.12, y: h * 0.1, width: w * 0.76, height: h * 0.9)), with: .color(rgb(0.88, 0.22, 0.20)))
            context.fill(Path(ellipseIn: CGRect(x: w * 0.3, y: 0, width: w * 0.4, height: h * 0.34)), with: .color(outline))
            context.fill(Path(CGRect(x: w / 2 - 0.3, y: h * 0.3, width: 0.6, height: h * 0.66)), with: .color(outline))
            for (x, y) in [(0.28, 0.5), (0.62, 0.5), (0.42, 0.74)] {
                context.fill(Path(ellipseIn: CGRect(x: w * x, y: h * y, width: 1.4, height: 1.4)), with: .color(outline))
            }
        }
    }

    // MARK: The visit

    static let visitorSize = CGSize(width: 26, height: 30)
    static let dandelionSize = CGSize(width: 30, height: 40)
    static let parcelSize = CGSize(width: 18, height: 16)
    static let letterSize = CGSize(width: 20, height: 14)
    static let kiteSize = CGSize(width: 24, height: 34)

    /// A visitor's coat: each resident has a colour until their sprite is
    /// painted.
    static func coat(of resident: ResidentID) -> Color {
        switch resident {
        case .sumi: rgb(0.50, 0.66, 0.42)
        case .damla: rgb(0.45, 0.65, 0.86)
        case .boncuk: rgb(0.82, 0.54, 0.36)
        case .yosun: rgb(0.32, 0.68, 0.64)
        case .tuli: rgb(0.62, 0.52, 0.82)
        case .keeper: rgb(0.96, 0.76, 0.32)
        case .nane: rgb(0.78, 0.74, 0.90)
        case .gezgin: rgb(0.38, 0.54, 0.74)
        default: rgb(0.72, 0.66, 0.60)
        }
    }

    static func drawVisitor(_ resident: ResidentID, in context: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        let coat = Self.coat(of: resident)
        context.fill(Path(ellipseIn: CGRect(x: w * 0.12, y: h * 0.18, width: w * 0.76, height: h * 0.8)), with: .color(coat))
        context.fill(Path(ellipseIn: CGRect(x: w * 0.28, y: h * 0.52, width: w * 0.44, height: h * 0.4)), with: .color(Color.white.opacity(0.4)))
        for x in [0.28, 0.6] {
            context.fill(Path(ellipseIn: CGRect(x: w * x, y: h * 0.34, width: 2.6, height: 3.4)), with: .color(outline))
        }
        context.fill(Path(ellipseIn: CGRect(x: w * 0.44, y: h * 0.46, width: 3, height: 1.8)), with: .color(rgb(0.90, 0.58, 0.56)))
        for x in [0.24, 0.58] {
            context.fill(Path(ellipseIn: CGRect(x: w * x, y: h * 0.9, width: w * 0.2, height: h * 0.1)), with: .color(outline.opacity(0.8)))
        }
    }

    static func drawDandelion(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let centre = CGPoint(x: w / 2, y: size.height * 0.3)
        var rays = Path()
        for i in 0..<12 {
            let angle = Double(i) * .pi / 6
            rays.move(to: centre)
            rays.addLine(to: CGPoint(x: centre.x + cos(angle) * w * 0.4, y: centre.y + sin(angle) * w * 0.4))
        }
        context.stroke(rays, with: .color(Color.white.opacity(0.9)), lineWidth: 0.8)
        for i in 0..<12 {
            let angle = Double(i) * .pi / 6
            let tip = CGPoint(x: centre.x + cos(angle) * w * 0.4, y: centre.y + sin(angle) * w * 0.4)
            context.fill(Path(ellipseIn: CGRect(x: tip.x - 1.3, y: tip.y - 1.3, width: 2.6, height: 2.6)), with: .color(Color.white))
        }
        var stalk = Path()
        stalk.move(to: centre)
        stalk.addLine(to: CGPoint(x: w / 2, y: size.height))
        context.stroke(stalk, with: .color(Color.white.opacity(0.85)), lineWidth: 0.9)
    }

    static func drawParcel(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        context.fill(Path(roundedRect: CGRect(x: 1, y: h * 0.3, width: w - 2, height: h * 0.7), cornerRadius: 2), with: .color(rgb(0.86, 0.50, 0.38)))
        context.fill(Path(roundedRect: CGRect(x: 0, y: h * 0.22, width: w, height: h * 0.2), cornerRadius: 1.5), with: .color(rgb(0.92, 0.58, 0.44)))
        let gold = rgb(0.96, 0.82, 0.38)
        context.fill(Path(CGRect(x: w / 2 - 1.2, y: h * 0.22, width: 2.4, height: h * 0.78)), with: .color(gold))
        for side in [-1.0, 1.0] {
            context.fill(Path(ellipseIn: CGRect(x: w / 2 + (side < 0 ? -5.4 : 0.6), y: 0, width: 4.8, height: 4.2)), with: .color(gold))
        }
    }

    static func drawLetter(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        context.fill(Path(roundedRect: CGRect(x: 1, y: 1, width: w - 2, height: h - 2), cornerRadius: 1.5), with: .color(paper))
        context.stroke(Path(roundedRect: CGRect(x: 1, y: 1, width: w - 2, height: h - 2), cornerRadius: 1.5), with: .color(woodDark.opacity(0.6)), lineWidth: 0.8)
        var flap = Path()
        flap.move(to: CGPoint(x: 1.5, y: 1.5))
        flap.addLine(to: CGPoint(x: w / 2, y: h * 0.58))
        flap.addLine(to: CGPoint(x: w - 1.5, y: 1.5))
        context.stroke(flap, with: .color(woodDark.opacity(0.6)), lineWidth: 0.8)
        context.fill(Path(ellipseIn: CGRect(x: w / 2 - 2.4, y: h * 0.5, width: 4.8, height: 4.8)), with: .color(rgb(0.84, 0.28, 0.28)))
    }

    static func drawKite(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        var pole = Path()
        pole.move(to: CGPoint(x: w / 2, y: h * 0.3))
        pole.addLine(to: CGPoint(x: w / 2, y: h))
        context.stroke(pole, with: .color(woodDark), lineWidth: 1.4)
        context.fill(Path(ellipseIn: CGRect(x: w * 0.12, y: h * 0.82, width: w * 0.76, height: h * 0.18)), with: .color(leaf))
        var left = Path()
        left.move(to: CGPoint(x: w / 2, y: 0))
        left.addLine(to: CGPoint(x: w * 0.06, y: h * 0.3))
        left.addLine(to: CGPoint(x: w / 2, y: h * 0.62))
        left.closeSubpath()
        var right = Path()
        right.move(to: CGPoint(x: w / 2, y: 0))
        right.addLine(to: CGPoint(x: w * 0.94, y: h * 0.3))
        right.addLine(to: CGPoint(x: w / 2, y: h * 0.62))
        right.closeSubpath()
        context.fill(left, with: .color(rgb(0.90, 0.36, 0.34)))
        context.fill(right, with: .color(rgb(0.98, 0.82, 0.36)))
        var tail = Path()
        tail.move(to: CGPoint(x: w / 2, y: h * 0.62))
        tail.addCurve(to: CGPoint(x: w * 0.7, y: h * 0.9), control1: CGPoint(x: w * 0.3, y: h * 0.7), control2: CGPoint(x: w * 0.8, y: h * 0.78))
        context.stroke(tail, with: .color(rgb(0.90, 0.36, 0.34)), lineWidth: 1)
    }
}

// MARK: - Placing a stand-in

extension View {
    /// Lays a stand-in out in `width` × `height` world units with its bottom
    /// centre on `point`, graded in its own small rect (a character's light)
    /// when `grade` changes something.
    func standing(on point: CGPoint, width: CGFloat, height: CGFloat, grade: WorldGrade = .neutral) -> some View {
        frame(width: width, height: height)
            .gradedIfNeeded(grade)
            .position(x: point.x, y: point.y - height / 2)
            .allowsHitTesting(false)
    }
}
#endif
