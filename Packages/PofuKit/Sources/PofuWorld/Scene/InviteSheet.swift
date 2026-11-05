#if os(iOS)
import PofuCore
import PofuDesignSystem
import SwiftUI

/// A quiet day's letter (experience v1 §5.1): Pofu hands it over and the
/// player picks a resident they have met. That resident comes tomorrow as an
/// invited visitor. An invitation never expires and never costs anything, so
/// the sheet has nothing to confirm and nothing to lose: one tap picks, the
/// close button leaves the letter on the lawn.
struct InviteSheet: View {
    /// The residents the player has met who can visit, in story order.
    let choices: [ResidentID]
    let onPick: (ResidentID) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.m) {
            VStack(alignment: .leading, spacing: PofuSpacing.xs) {
                Text(verbatim: WorldStrings.inviteTitle)
                    .font(PofuFont.title3)
                    .foregroundStyle(PofuColor.textPrimary)
                Text(verbatim: choices.isEmpty ? WorldStrings.inviteEmpty : WorldStrings.inviteSubtitle)
                    .font(PofuFont.callout)
                    .foregroundStyle(PofuColor.textSecondary)
            }
            ForEach(choices, id: \.self) { resident in
                Button {
                    PofuHaptics.shared.play(.tap)
                    onPick(resident)
                } label: {
                    HStack(spacing: PofuSpacing.m) {
                        Canvas { context, size in
                            LifeArt.drawVisitor(resident, in: &context, size: size)
                        }
                        .frame(width: LifeArt.visitorSize.width, height: LifeArt.visitorSize.height)
                        .accessibilityHidden(true)
                        Text(verbatim: WorldStrings.residentName(resident))
                            .font(PofuFont.headline)
                            .foregroundStyle(PofuColor.textPrimary)
                        Spacer(minLength: 0)
                        Image(systemName: "paperplane")
                            .font(PofuFont.body)
                            .foregroundStyle(PofuColor.accent)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, PofuSpacing.l)
                    .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch + 8, alignment: .leading)
                    .background { PofuPaperPanel() }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: WorldStrings.invite(WorldStrings.residentName(resident))))
            }
            Button {
                onClose()
            } label: {
                Text(verbatim: WorldStrings.inviteClose)
                    .font(PofuFont.headline)
                    .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch)
            }
            .buttonStyle(.plain)
            .foregroundStyle(PofuColor.accent)
        }
        .padding(.horizontal, PofuSpacing.screen)
        .padding(.top, PofuSpacing.xl)
        .padding(.bottom, PofuSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("invite-sheet")
    }
}
#endif
