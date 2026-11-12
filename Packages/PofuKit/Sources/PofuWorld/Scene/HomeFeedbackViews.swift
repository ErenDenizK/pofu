#if os(iOS)
import PofuDesignSystem
import SwiftUI

/// A rounded bubble with a small tail on its bottom edge, `tailOffset`
/// from its middle; the tail's tip is the shape's bottom.
struct TailedBubble: Shape {
    var radius: CGFloat
    var tailOffset: CGFloat = 0
    var tailWidth: CGFloat = 10
    var tailHeight: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        let body = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailHeight)
        let r = min(radius, body.height / 2, body.width / 2)
        let tip = min(max(body.midX + tailOffset, body.minX + r + tailWidth / 2), body.maxX - r - tailWidth / 2)
        var path = Path()
        path.move(to: CGPoint(x: body.minX + r, y: body.minY))
        path.addArc(tangent1End: CGPoint(x: body.maxX, y: body.minY), tangent2End: CGPoint(x: body.maxX, y: body.maxY), radius: r)
        path.addArc(tangent1End: CGPoint(x: body.maxX, y: body.maxY), tangent2End: CGPoint(x: body.minX, y: body.maxY), radius: r)
        path.addLine(to: CGPoint(x: tip + tailWidth / 2, y: body.maxY))
        path.addLine(to: CGPoint(x: tip, y: rect.maxY))
        path.addLine(to: CGPoint(x: tip - tailWidth / 2, y: body.maxY))
        path.addArc(tangent1End: CGPoint(x: body.minX, y: body.maxY), tangent2End: CGPoint(x: body.minX, y: body.minY), radius: r)
        path.addArc(tangent1End: CGPoint(x: body.minX, y: body.minY), tangent2End: CGPoint(x: body.maxX, y: body.minY), radius: r)
        path.closeSubpath()
        return path
    }
}

private extension View {
    /// The bubbles' warm paper: cream, a thin ink rim, a soft lift.
    func bubblePaper(_ shape: TailedBubble) -> some View {
        background {
            shape.fill(Color(red: 1.0, green: 0.98, blue: 0.94))
                .shadow(color: .black.opacity(0.14), radius: 3, y: 1)
        }
        .overlay { shape.stroke(Color.paperInk.opacity(0.28), lineWidth: 1) }
    }
}

/// The greeting's answer over a greeted visitor: a heart in a small speech
/// bubble whose tail points at them, drawn in screen space so it reads
/// however small the visitor stands. It pops in once (Reduce Motion: a
/// fade) and stays for the visit.
struct GreetingHeart: View {
    /// Where the tail's tip points, just over the visitor's head.
    let tip: CGPoint
    let screenWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    static let size: CGFloat = 30
    static let tail: CGFloat = 5

    var body: some View {
        let place = TailedBubblePlacement.place(tipX: Double(tip.x), width: Double(Self.size), screenWidth: Double(screenWidth), corner: Double(Self.size / 2), tailWidth: 8)
        Image(systemName: "heart.fill")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color(red: 0.89, green: 0.42, blue: 0.50))
            .frame(width: Self.size, height: Self.size)
            .padding(.bottom, Self.tail)
            .bubblePaper(TailedBubble(radius: Self.size / 2, tailOffset: CGFloat(place.tailOffset), tailWidth: 8, tailHeight: Self.tail))
            // The pop: up from the tail's tip, once.
            .scaleEffect(shown || reduceMotion ? 1 : 0.3, anchor: .bottom)
            .opacity(shown ? 1 : 0)
            .onAppear {
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0.4)) { shown = true }
            }
            .position(x: CGFloat(place.centreX), y: tip.y - (Self.size + Self.tail) / 2)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The small tag over a wonder island's gift on the day it reaches home:
/// who it is from, its tail pointing at the gift.
struct GiftTag: View {
    let gift: HomeGifts.Gift
    /// Where the tail's tip points, just over the gift.
    let tip: CGPoint
    let screenWidth: CGFloat
    @State private var width: CGFloat = 150

    static let height: CGFloat = 26
    static let tail: CGFloat = 6

    var body: some View {
        let place = TailedBubblePlacement.place(tipX: Double(tip.x), width: Double(width), screenWidth: Double(screenWidth))
        HStack(spacing: 5) {
            Image(systemName: gift == .kokeMoss ? "leaf.fill" : "drop.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(gift == .kokeMoss ? Color(red: 0.36, green: 0.58, blue: 0.30) : Color(red: 0.27, green: 0.58, blue: 0.84))
            Text(verbatim: WorldStrings.giftTag(gift))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.paperInk)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(height: Self.height)
        .padding(.bottom, Self.tail)
        .bubblePaper(TailedBubble(radius: Self.height / 2, tailOffset: CGFloat(place.tailOffset), tailHeight: Self.tail))
        .fixedSize()
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .position(x: CGFloat(place.centreX), y: tip.y - (Self.height + Self.tail) / 2)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: WorldStrings.giftTag(gift)))
    }
}
#endif
