#if os(iOS)
import PofuCore
import PofuDesignSystem
import SwiftUI

/// A resident's small card (§12.2): their name, station and level, one
/// line said once a visit, and "Go to the stall".
struct ResidentCard: View {
    let resident: IslandLayout.Resident
    let status: StationStatus?
    let line: String?
    /// Where the resident stands relative to the card's centre, for the tail.
    let tailOffset: CGFloat
    let onGoToStall: @MainActor () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.s) {
            HStack(alignment: .center, spacing: PofuSpacing.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: WorldStrings.residentName(resident.id))
                        .font(PofuFont.headline)
                        .foregroundStyle(PofuColor.textPrimary)
                    Text(verbatim: WorldStrings.stationAndLevel(WorldStrings.stationName(resident.station), level: status?.level ?? 0))
                        .font(PofuFont.footnote)
                        .foregroundStyle(PofuColor.textSecondary)
                }
                Spacer(minLength: 0)
                // The resident's reaction sticker, when they have one.
                if let sticker = Sticker.reaction(forResident: resident.id.rawValue) {
                    StickerView(sticker, size: 44)
                }
            }
            if let line {
                Text(verbatim: line)
                    .font(PofuFont.callout)
                    .foregroundStyle(PofuColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: onGoToStall) {
                Text("Go to the stall", bundle: .module)
                    .font(PofuFont.headline)
                    .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch)
            }
            .pofuActionStyle(.secondary)
        }
        .padding(PofuSpacing.l)
        .background(PofuColor.card.opacity(0.95), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .top) {
            CardTail()
                .fill(PofuColor.card.opacity(0.95))
                .frame(width: 18, height: 9)
                .offset(x: tailOffset, y: -8)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
    }
}

struct CardTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
#endif
