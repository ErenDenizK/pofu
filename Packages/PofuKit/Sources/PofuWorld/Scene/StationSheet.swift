#if os(iOS)
import PofuCore
import PofuDesignSystem
import SwiftUI

/// A station's sheet (interaction spec §2.3): the name and keeper, five
/// level dots, the rate, and the build button. While its build moment
/// runs, the sheet sits at its compact detent and says so (§2.6: the one
/// refused input explains itself).
struct StationSheet: View {
    let station: StationID
    let status: StationStatus?
    let jar: Energy
    var isBuilding = false
    /// The garden's rounds left today, and the door to play them.
    var playableRounds = 0
    var onPlay: (@MainActor () -> Void)?
    let onBuild: (@MainActor (StationID) -> Void)?
    let onClose: @MainActor () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.l) {
            header
            if isBuilding {
                building
            } else if let status {
                levelDots(status)
                details(status)
                Spacer(minLength: 0)
                playButton(status)
                buildButton(status)
            } else {
                Text("Not open yet", bundle: .module)
                    .font(PofuFont.body)
                    .foregroundStyle(PofuColor.textSecondary)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, PofuSpacing.screen)
        .padding(.top, isBuilding ? PofuSpacing.l : PofuSpacing.xl)
        .padding(.bottom, PofuSpacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .animation(.spring(duration: 0.25, bounce: 0), value: isBuilding)
    }

    /// The compact sheet during a build: the button's place says what is
    /// happening.
    private var building: some View {
        HStack(spacing: PofuSpacing.s) {
            ProgressView()
                .controlSize(.small)
            Text("Building…", bundle: .module)
                .font(PofuFont.headline)
                .foregroundStyle(PofuColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: PofuSpacing.m) {
            VStack(alignment: .leading, spacing: PofuSpacing.xs) {
                Text(verbatim: WorldStrings.stationName(station))
                    .font(PofuFont.title2)
                    .foregroundStyle(PofuColor.textPrimary)
                if let keeper = WorldStrings.stationKeeper(station) {
                    Text(verbatim: keeper)
                        .font(PofuFont.subheadline)
                        .foregroundStyle(PofuColor.textSecondary)
                }
            }
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PofuColor.textPrimary)
                    .frame(width: PofuSize.minimumTouch, height: PofuSize.minimumTouch)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Close", bundle: .module))
        }
    }

    private func levelDots(_ status: StationStatus) -> some View {
        HStack(spacing: PofuSpacing.s) {
            HStack(spacing: 6) {
                ForEach(1...max(status.maxLevel, 1), id: \.self) { level in
                    Circle()
                        .fill(level <= status.level ? PofuColor.accent : PofuColor.hairline)
                        .frame(width: 10, height: 10)
                }
            }
            Text(verbatim: status.level > 0 ? WorldStrings.level(status.level, of: status.maxLevel) : String(localized: "Build spot", bundle: .module))
                .font(PofuFont.footnote.monospacedDigit())
                .foregroundStyle(PofuColor.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func details(_ status: StationStatus) -> some View {
        HStack(spacing: PofuSpacing.s) {
            Image(systemName: "leaf")
                .foregroundStyle(PofuColor.success)
            Text("\(status.seedsPerHour.formatted(.number.precision(.fractionLength(0...1)))) seeds an hour", bundle: .module)
                .font(PofuFont.callout)
                .foregroundStyle(PofuColor.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    /// The garden's door to the game once it is built: rounds are earned,
    /// two a day, so with none left it says so instead of disappearing.
    @ViewBuilder
    private func playButton(_ status: StationStatus) -> some View {
        if station == .garden, status.level > 0, let onPlay {
            if playableRounds > 0 {
                Button {
                    onPlay()
                } label: {
                    Text("Play · \(playableRounds) left", bundle: .module)
                        .font(PofuFont.headline)
                        .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch)
                }
                .buttonStyle(.glass)
                .tint(PofuColor.accent)
            } else {
                Text("No rounds left today.", bundle: .module)
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func buildButton(_ status: StationStatus) -> some View {
        if let cost = status.nextCost {
            let missing = max(cost.units - jar.units, 0)
            Button {
                onBuild?(station)
            } label: {
                if missing > 0 {
                    Text("\(missing) more seeds", bundle: .module)
                } else {
                    HStack(spacing: PofuSpacing.s) {
                        Text("Build · \(cost.units)", bundle: .module)
                        SeedGlyph()
                            .fill(PofuColor.onAccent)
                            .frame(width: 9, height: 14)
                            .rotationEffect(.degrees(18))
                            .accessibilityHidden(true)
                    }
                }
            }
            .buttonStyle(PofuPrimaryButtonStyle())
            .disabled(missing > 0 || onBuild == nil)
            if onBuild == nil {
                Text("Building opens soon.", bundle: .module)
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        } else {
            Text("Every level is built.", bundle: .module)
                .font(PofuFont.callout)
                .foregroundStyle(PofuColor.textSecondary)
        }
    }
}

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
            Text(verbatim: WorldStrings.residentName(resident.id))
                .font(PofuFont.headline)
                .foregroundStyle(PofuColor.textPrimary)
            Text(verbatim: WorldStrings.stationAndLevel(WorldStrings.stationName(resident.station), level: status?.level ?? 0))
                .font(PofuFont.footnote)
                .foregroundStyle(PofuColor.textSecondary)
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
            .buttonStyle(.glass)
            .tint(PofuColor.accent)
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

private struct CardTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The framing control: three framings in a glass capsule whose pill
/// follows where a pinch would land (§1.6).
public struct FramingPicker: View {
    let model: IslandSceneModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var pill

    public init(model: IslandSceneModel) {
        self.model = model
    }

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(WorldFraming.allCases.reversed(), id: \.self) { framing in
                let selected = model.projectedFraming == framing
                Button {
                    model.go(to: framing)
                } label: {
                    Text(verbatim: WorldStrings.framingName(framing))
                        .font(PofuFont.subheadline)
                        .foregroundStyle(selected ? PofuColor.onAccent : PofuColor.textPrimary)
                        .padding(.horizontal, 14)
                        .frame(minHeight: PofuSize.minimumTouch)
                        .background {
                            if selected {
                                Capsule(style: .continuous)
                                    .fill(PofuColor.accent)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(4)
        .glassEffect(.regular, in: Capsule(style: .continuous))
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.settle), value: model.projectedFraming)
    }
}
#endif
