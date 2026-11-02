#if os(iOS)
import SwiftUI

/// A celebration moment (a station's new level, a new island) on a
/// painted, craft-style card: warm paper with a torn edge, a painted
/// border and a ribbon. The rule (look-dev C): **system UI is glass,
/// celebration is painted.** Glass frames the terrarium and carries the
/// controls; the world's own moments are drawn in the world's medium.
public struct CelebrationCard: View {
    let kicker: String
    let title: String
    let detail: String?

    public init(kicker: String, title: String, detail: String? = nil) {
        self.kicker = kicker
        self.title = title
        self.detail = detail
    }

    public var body: some View {
        VStack(spacing: 6) {
            Text(verbatim: kicker.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(Color.paperInk.opacity(0.65))
            Text(verbatim: title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.paperInk)
                .multilineTextAlignment(.center)
            if let detail {
                Text(verbatim: detail)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.paperInk.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 30)
        .padding(.bottom, 24)
        .frame(minWidth: 220)
        // The paper: warm cream, lighter where the key light falls, with a
        // painted border, a little uneven.
        .paperBackground(seed: 3)
        .overlay(alignment: .top) {
            Ribbon()
                .fill(Color(red: 0.89, green: 0.50, blue: 0.40))
                .frame(width: 64, height: 20)
                .overlay {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(red: 1, green: 0.95, blue: 0.86))
                }
                .offset(y: -8)
        }
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// The painted paper behind a celebration: warm cream with a torn edge,
    /// a painted dashed border and a soft shadow.
    func paperBackground(seed: Double, borderInset: CGFloat = 9) -> some View {
        background {
            ZStack {
                DeckledRectangle(seed: seed)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1, green: 0.97, blue: 0.90), Color(red: 0.96, green: 0.89, blue: 0.76)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.paperInk.opacity(0.22), radius: 10, y: 5)
                DeckledRectangle(seed: seed + 6, wobble: 1.2)
                    .inset(by: borderInset)
                    .stroke(
                        Color(red: 0.84, green: 0.55, blue: 0.36).opacity(0.55),
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round, dash: [9, 3.5])
                    )
            }
        }
    }

    /// A small painted tag (the build's level-up tag).
    func paintedPaper(cornerSeed: Double) -> some View {
        paperBackground(seed: cornerSeed, borderInset: 4)
    }
}

extension Color {
    /// Warm brown ink for painted surfaces (never black).
    static let paperInk = Color(red: 0.36, green: 0.24, blue: 0.16)
}

/// A rectangle whose edges wobble like torn paper; deterministic per seed.
struct DeckledRectangle: InsettableShape {
    var seed: Double
    var wobble: Double = 2.0
    var insetAmount: Double = 0

    func inset(by amount: CGFloat) -> DeckledRectangle {
        var copy = self
        copy.insetAmount += Double(amount)
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let corner = 14.0
        var path = Path()
        func jitter(_ t: Double, _ side: Double) -> Double {
            (sin(t * 0.21 + seed * 3.1 + side) * 0.6 + sin(t * 0.57 + seed + side * 2) * 0.4) * wobble
        }
        let step = 6.0
        // Top, right, bottom, left, each nudged along its normal.
        var points: [CGPoint] = []
        var x = r.minX + corner
        while x <= r.maxX - corner { points.append(CGPoint(x: x, y: r.minY + jitter(x, 0))); x += step }
        var y = r.minY + corner
        while y <= r.maxY - corner { points.append(CGPoint(x: r.maxX + jitter(y, 1), y: y)); y += step }
        x = r.maxX - corner
        while x >= r.minX + corner { points.append(CGPoint(x: x, y: r.maxY + jitter(x, 2))); x -= step }
        y = r.maxY - corner
        while y >= r.minY + corner { points.append(CGPoint(x: r.minX + jitter(y, 3), y: y)); y -= step }
        guard let first = points.first else { return Path(r) }
        path.move(to: first)
        for (i, p) in points.enumerated().dropFirst() {
            let prev = points[i - 1]
            if abs(p.x - prev.x) > step * 1.5 || abs(p.y - prev.y) > step * 1.5 {
                // Round the corner between two sides, through the rect's corner.
                let control = CGPoint(
                    x: (p.x + prev.x) / 2 < r.midX ? r.minX : r.maxX,
                    y: (p.y + prev.y) / 2 < r.midY ? r.minY : r.maxY
                )
                path.addQuadCurve(to: p, control: control)
            } else {
                path.addLine(to: p)
            }
        }
        path.addQuadCurve(to: first, control: CGPoint(x: r.minX, y: r.minY))
        path.closeSubpath()
        return path
    }
}

/// A small swallow-tailed ribbon.
struct Ribbon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let notch = rect.height * 0.35
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + notch, y: rect.midY))
        p.closeSubpath()
        return p
    }
}
#endif
