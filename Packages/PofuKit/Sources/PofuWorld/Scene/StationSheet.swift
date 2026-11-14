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
public struct StationSheet: View {
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

    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize

    public init(
        station: StationID,
        status: StationStatus?,
        jar: Energy,
        isBuilding: Bool = false,
        playableRounds: Int = 0,
        onPlay: (@MainActor () -> Void)? = nil,
        onBuild: (@MainActor (StationID) -> Void)?,
        onClose: @escaping @MainActor () -> Void,
        catalog: ArchipelagoCatalog = .standard
    ) {
        self.station = station
        self.status = status
        self.jar = jar
        self.isBuilding = isBuilding
        self.playableRounds = playableRounds
        self.onPlay = onPlay
        self.onBuild = onBuild
        self.onClose = onClose
        self.catalog = catalog
    }

    private var palette: PofuKitPalette {
        (night ?? (scheme == .dark)) ? .night : .day
    }

    private var inkSoft: Color {
        palette.isNight ? palette.onPaper.opacity(0.8) : palette.inkSoft
    }

    /// Paper at every detent. The header and the level scroll together
    /// with the facts, so nothing clips at the medium detent or at any
    /// text size; the primary plaque is pinned below, except at
    /// accessibility sizes where it joins the scroll (a pinned block
    /// would eat the sheet).
    public var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let compact = height < Self.compactBelow
            let short = height < Self.shortBelow
            Group {
                if typeSize.isAccessibilitySize {
                    ScrollView {
                        VStack(alignment: .leading, spacing: PofuSpacing.l) {
                            content(compact: compact, short: short)
                            footer(compact: compact)
                        }
                        .padding(PofuSpacing.screen)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                } else {
                    // The footer is its own row under the scroll, never over it: the
                    // content ends where the row starts, so no two texts share a line.
                    VStack(spacing: 0) {
                        ScrollView {
                            content(compact: compact, short: short)
                                .padding(.horizontal, PofuSpacing.screen)
                                .padding(.top, short ? PofuSpacing.m : PofuSpacing.screen)
                                .padding(.bottom, short ? PofuSpacing.s : PofuSpacing.screen)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        if !(compact && isBuilding) {
                            footer(compact: compact)
                                .padding(.horizontal, PofuSpacing.screen)
                                .padding(.top, short ? PofuSpacing.xs : PofuSpacing.s)
                                .padding(.bottom, short ? PofuSpacing.s : PofuSpacing.m)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .animation(.spring(duration: 0.25, bounce: 0), value: isBuilding)
        #if os(iOS)
        .presentationDragIndicator(.visible)
        #endif
    }

    /// Below this the sheet is the build's compact detent: the status sits in the pots' row.
    static let compactBelow: CGFloat = 240
    /// Below this the flavour line leaves: the facts and the plaque fill the sheet.
    static let shortBelow: CGFloat = 460

    private func content(compact: Bool, short: Bool) -> some View {
        VStack(alignment: .leading, spacing: short ? PofuSpacing.s : PofuSpacing.l) {
            header
            if let status {
                if compact && isBuilding {
                    HStack(alignment: .bottom, spacing: PofuSpacing.m) {
                        pots(status)
                        buildingStatus
                    }
                } else {
                    pots(status, showsLevel: short && !compact)
                    if !compact {
                        rate(status, showsLevel: !short)
                            .accessibilityElement(children: .combine)
                    }
                }
            } else {
                Text("Not open yet", bundle: .module)
                    .font(PofuFont.body)
                    .foregroundStyle(inkSoft)
            }
            if !short { flavour }
        }
        .padding(.top, short ? 0 : PofuSpacing.s)
    }

    private var buildingStatus: some View {
        Text("Building…", bundle: .module)
            .font(PofuFont.headline)
            .foregroundStyle(inkSoft)
            .accessibilityIdentifier("station-building")
    }

    /// The pinned part: the build plaque with its cost and reason, then
    /// the garden's door.
    @ViewBuilder
    private func footer(compact: Bool) -> some View {
        if isBuilding {
            // At the compact detent the status already sits in the pots' row.
            if !compact {
                buildingStatus.frame(maxWidth: .infinity)
            }
        } else if let status {
            VStack(spacing: PofuSpacing.s) {
                buildButton(status)
                playButton(status)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: PofuSpacing.m) {
            VStack(alignment: .leading, spacing: PofuSpacing.xs) {
                Text(verbatim: WorldStrings.stationName(station))
                    .font(PofuFont.title)
                    .foregroundStyle(palette.onPaper)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let keeper = WorldStrings.stationKeeper(station) {
                    Text(verbatim: keeper)
                        .font(PofuFont.subheadline)
                        .foregroundStyle(inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            Button(action: onClose) {
                // A plain glyph: the duotone close art carried a stray mark above its cross.
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(PofuKitPalette.day.ink)
                    .frame(width: PofuSize.minimumTouch, height: PofuSize.minimumTouch)
                    .background { Circle().fill(palette.isNight ? palette.honey : palette.felt) }
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Close", bundle: .module))
        }
    }

    /// `showsLevel` puts "Level n / m" beside the pots, for the medium
    /// detent where the rate card has no room for its own footnote.
    private func pots(_ status: StationStatus, showsLevel: Bool = false) -> some View {
        HStack(alignment: .bottom, spacing: PofuSpacing.m) {
            PotPips(level: status.level, maxLevel: status.maxLevel, palette: palette)
            Spacer(minLength: 0)
            if showsLevel, status.level > 0 {
                Text(verbatim: WorldStrings.level(status.level, of: status.maxLevel))
                    .font(PofuFont.footnote.monospacedDigit())
                    .foregroundStyle(inkSoft)
            }
        }
    }

    // MARK: The one thing

    /// Seeds a day now, and at the next level: live numbers with
    /// monospaced digits on one paper card.
    private func rate(_ status: StationStatus, showsLevel: Bool = true) -> some View {
        let now = Self.format(status.seedsPerHour * 24)
        let next = status.nextCost == nil ? nil : catalog.station(station).map { Self.format($0.seedsPerHour(at: status.level + 1) * 24) }
        return VStack(alignment: .leading, spacing: PofuSpacing.xs) {
            if status.level == 0, let next {
                Text("\(next) seeds a day once built", bundle: .module)
                    .font(PofuFont.title3.monospacedDigit())
            } else if let next {
                Text("\(now) seeds a day · \(next) once built", bundle: .module)
                    .font(PofuFont.title3.monospacedDigit())
            } else {
                Text("\(now) seeds a day", bundle: .module)
                    .font(PofuFont.title3.monospacedDigit())
            }
            if !showsLevel && status.level > 0 {
                EmptyView()
            } else if status.level == 0 {
                Text("Build spot", bundle: .module)
                    .font(PofuFont.footnote)
                    .foregroundStyle(inkSoft)
            } else {
                Text(verbatim: WorldStrings.level(status.level, of: status.maxLevel))
                    .font(PofuFont.footnote.monospacedDigit())
                    .foregroundStyle(inkSoft)
            }
        }
        .foregroundStyle(palette.onPaper)
        .fixedSize(horizontal: false, vertical: true)
        .pofuKitCard(.linen)
    }

    private static func format(_ rate: Double) -> String {
        rate.formatted(.number.precision(.fractionLength(0...1)))
    }

    // MARK: The primary action

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
                        .foregroundStyle(palette.onPaper)
                        .frame(minHeight: PofuSize.minimumTouch)
                }
                .buttonStyle(PofuTextButtonStyle())
            } else {
                Text("No rounds left today.", bundle: .module)
                    .font(PofuFont.footnote)
                    .foregroundStyle(inkSoft)
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
                .foregroundStyle(inkSoft)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .pofuKitCard(.linen)
                .accessibilityIdentifier("station-cap-reason")
        } else if let cost = status.nextCost {
            let missing = max(cost.units - jar.units, 0)
            VStack(spacing: PofuSpacing.xs) {
                if missing > 0, onBuild != nil {
                    // Not enough seeds yet: a readable note on linen, not a greyed plaque.
                    Text("\(missing) more seeds", bundle: .module)
                        .font(PofuFont.headline.monospacedDigit())
                        .foregroundStyle(palette.onPaper)
                        .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch - 8)
                        .pofuKitCard(.linen)
                        .accessibilityIdentifier("station-missing-seeds")
                } else {
                    Button {
                        PofuHaptics.shared.play(.tap)
                        onBuild?(station)
                    } label: {
                        if missing > 0 {
                            Text("\(missing) more seeds", bundle: .module)
                        } else {
                            HStack(spacing: PofuSpacing.s) {
                                Text("Build · \(cost.units)", bundle: .module)
                                SeedGlyph()
                                    .fill(PofuKitPalette.day.ink)
                                    .frame(width: 9, height: 14)
                                    .rotationEffect(.degrees(18))
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .buttonStyle(PofuPlaqueStyle(.primary, haptic: nil))
                    .disabled(missing > 0 || onBuild == nil)
                }
                // The reason lives under the plaque: never a dead state.
                if onBuild == nil {
                    reasonLine { Text("Building opens soon.", bundle: .module) }
                } else if missing > 0 {
                    reasonLine { Text("Your cheeks hold \(jar.units) of \(cost.units) seeds.", bundle: .module) }
                } else {
                    reasonLine { Text("It uses \(cost.units) seeds from the jar.", bundle: .module) }
                }
            }
        } else {
            Text("Every level is built.", bundle: .module)
                .font(PofuFont.callout)
                .foregroundStyle(inkSoft)
                .frame(maxWidth: .infinity)
        }
    }

    private func reasonLine<Line: View>(@ViewBuilder _ line: () -> Line) -> some View {
        line()
            .font(PofuFont.footnote.monospacedDigit())
            .foregroundStyle(inkSoft)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }

    // MARK: Flavour

    @ViewBuilder
    private var flavour: some View {
        if let flavour = WorldStrings.stationFlavour(station) {
            Text(verbatim: flavour)
                .font(PofuFont.footnote.italic())
                .foregroundStyle(inkSoft)
                .fixedSize(horizontal: false, vertical: true)
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
