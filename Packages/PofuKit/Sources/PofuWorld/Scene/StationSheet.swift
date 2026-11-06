#if os(iOS)
import PofuCore
import PofuDesignSystem
import SwiftUI

/// A station's sheet (experience v1 section 3.2, the template for every
/// sheet): the grabber, a painted header plate with the station's vignette
/// and drawn level pips, **the one thing** (the rate now and at the next
/// level, in monospaced digits), one primary action pinned at the bottom,
/// and one flavour line in Pofu's voice. While its build moment runs, the
/// sheet sits at its compact detent and says so (§2.6: the one refused
/// input explains itself).
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
    /// Where the next level's rate comes from.
    var catalog = ArchipelagoCatalog.standard

    var body: some View {
        Group {
            if isBuilding {
                VStack(alignment: .leading, spacing: PofuSpacing.l) {
                    plate(compact: true)
                    building
                }
                .padding(.horizontal, PofuSpacing.screen)
                .padding(.top, PofuSpacing.l)
                .padding(.bottom, PofuSpacing.l)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                PofuSheetScaffold {
                    plate(compact: false)
                } thing: {
                    theOneThing
                } action: {
                    actions
                } flavour: {
                    flavour
                }
            }
        }
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

    /// The station's painted art for the header plate (the `sheet-header-*`
    /// vignettes replace it by name when they exist).
    private var art: PofuPaint {
        switch station {
        case .garden: .potBloom
        case .teaStall: .iconTea
        case .workshop: .iconDecor
        case .pond: .iconIsland
        case .windmill: .iconBreath
        default: .iconCalm
        }
    }

    private func plate(compact: Bool) -> some View {
        PofuHeaderPlate(
            paint: art,
            title: WorldStrings.stationName(station),
            subtitle: WorldStrings.stationKeeper(station),
            pips: status.map { ($0.level, $0.maxLevel) },
            compact: compact,
            closeLabel: Text("Close", bundle: .module),
            onClose: onClose
        )
    }

    // MARK: The one thing

    @ViewBuilder
    private var theOneThing: some View {
        if let status {
            rate(status)
                .accessibilityElement(children: .combine)
        } else {
            Text("Not open yet", bundle: .module)
                .font(PofuFont.body)
                .foregroundStyle(PofuColor.textSecondary)
        }
    }

    /// Seeds a day now, and at the next level (a day reads better than the
    /// tiny hourly rate, which rounded to 0): live numbers with
    /// monospaced digits on one paper panel.
    private func rate(_ status: StationStatus) -> some View {
        let now = Self.format(status.seedsPerHour * 24)
        let next = status.nextCost == nil ? nil : catalog.station(station).map { Self.format($0.seedsPerHour(at: status.level + 1) * 24) }
        return VStack(alignment: .leading, spacing: PofuSpacing.xs) {
            if status.level == 0, let next {
                Text("\(next) seeds a day once built", bundle: .module)
                    .font(PofuFont.title3.monospacedDigit())
            } else if let next {
                Text("\(now) → \(next) seeds a day", bundle: .module)
                    .font(PofuFont.title3.monospacedDigit())
            } else {
                Text("\(now) seeds a day", bundle: .module)
                    .font(PofuFont.title3.monospacedDigit())
            }
            if status.level == 0 {
                Text("Build spot", bundle: .module)
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.textSecondary)
            } else {
                Text(verbatim: WorldStrings.level(status.level, of: status.maxLevel))
                    .font(PofuFont.footnote.monospacedDigit())
                    .foregroundStyle(PofuColor.textSecondary)
            }
        }
        .foregroundStyle(PofuColor.textPrimary)
        .padding(PofuSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { PofuPaperPanel() }
    }

    private static func format(_ rate: Double) -> String {
        rate.formatted(.number.precision(.fractionLength(0...1)))
    }

    // MARK: The primary action

    @ViewBuilder
    private var actions: some View {
        if let status {
            VStack(spacing: PofuSpacing.s) {
                buildButton(status)
                playButton(status)
            }
        }
    }

    /// The garden's door to the game once it is built: rounds are earned,
    /// two a day, so with none left it says so instead of disappearing. A
    /// text button: the build is the sheet's one primary action.
    @ViewBuilder
    private func playButton(_ status: StationStatus) -> some View {
        if station == .garden, status.level > 0, let onPlay {
            if playableRounds > 0 {
                Button {
                    PofuHaptics.shared.play(.tap)
                    onPlay()
                } label: {
                    Text("Play · \(playableRounds) left", bundle: .module)
                }
                .buttonStyle(PofuTextButtonStyle())
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
        if let liftsAt = status.capLiftsAtIslandLevel {
            // The island level holds the next level back: a quiet line,
            // no padlock, no red (home progression section 3, rule 4).
            Text(verbatim: WorldStrings.capReason(islandLevel: liftsAt))
                .font(PofuFont.callout)
                .foregroundStyle(PofuColor.textSecondary)
                .accessibilityIdentifier("station-cap-reason")
        } else if let cost = status.nextCost {
            let missing = max(cost.units - jar.units, 0)
            Button {
                if missing > 0 {
                    PofuHaptics.shared.play(.warning)
                } else {
                    PofuHaptics.shared.play(.tap)
                    onBuild?(station)
                }
            } label: {
                Group {
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
                .font(PofuFont.headline)
                .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch)
            }
            .pofuActionStyle(.primary)
            .opacity(missing > 0 ? 0.55 : 1)
            .disabled(onBuild == nil)
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

    // MARK: Flavour

    @ViewBuilder
    private var flavour: some View {
        if let flavour = WorldStrings.stationFlavour(station) {
            Text(verbatim: flavour)
                .font(PofuFont.footnote.italic())
                .foregroundStyle(PofuColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
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
#endif
