#if os(iOS)
import SwiftUI

/// A minigame's goal in one short line under its HUD: what to do, so the
/// first round never starts on a guess.
struct GoalLine: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.system(.footnote, design: .rounded, weight: .semibold))
            .foregroundStyle(GardenInk.ink.opacity(0.78))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(false)
    }
}
#endif
