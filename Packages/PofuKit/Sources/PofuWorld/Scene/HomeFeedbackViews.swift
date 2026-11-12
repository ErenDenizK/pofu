#if os(iOS)
import PofuDesignSystem
import SwiftUI

/// The greeting's answer over a greeted visitor: one small heart on a
/// paper disc, drawn in screen space so it reads however small the visitor
/// stands. It pops in once (Reduce Motion: a fade) and stays for the visit.
struct GreetingHeart: View {
    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color(red: 0.89, green: 0.42, blue: 0.50))
            .frame(width: 28, height: 28)
            .paintedPaper(cornerSeed: 9)
            .fixedSize()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The paper tag over a wonder island's gift on the day it reaches home:
/// who it is from, small, in the build tag's paper.
struct GiftTag: View {
    let gift: HomeGifts.Gift

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: gift == .kokeMoss ? "leaf.fill" : "drop.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(gift == .kokeMoss ? Color(red: 0.36, green: 0.58, blue: 0.30) : Color(red: 0.27, green: 0.58, blue: 0.84))
            Text(verbatim: WorldStrings.giftTag(gift))
                .font(PofuFont.caption)
                .foregroundStyle(Color.paperInk)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 30)
        .paintedPaper(cornerSeed: gift == .kokeMoss ? 3 : 7)
        .fixedSize()
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: WorldStrings.giftTag(gift)))
    }
}
#endif
