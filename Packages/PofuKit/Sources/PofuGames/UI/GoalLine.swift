#if os(iOS)
import PofuDesignSystem
import SwiftUI

/// A minigame's goal in one short line under its HUD: what to do, so the
/// first round never starts on a guess. It sits on the screen plane like
/// the rest of the HUD (a glass tag, UI grammar G3), and the caller takes
/// it away after the player's first move: a rule read once is not chrome.
struct GoalLine: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.system(.footnote, design: .rounded, weight: .semibold))
            .foregroundStyle(GardenInk.ink)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .pofuChrome(.worldTag)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(false)
    }
}
#endif
