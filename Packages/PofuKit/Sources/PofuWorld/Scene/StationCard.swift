#if os(iOS)
import PofuCore
import PofuDesignSystem
import SwiftUI

/// The two station cards the founder tries on his phone (brief 2026-11-24-1):
/// Etiket, a small glass card by the station with everything on it, and Hap,
/// a glass pill that opens in place into the same card. Settings holds the
/// switch; it and the losing variant go when he has picked.
public enum StationCardVariant: String, CaseIterable, Sendable {
    case tag
    case pill

    /// The `UserDefaults` key Settings and the scene share.
    public static let storageKey = "stationCardVariant"
    public static let standard = StationCardVariant.tag
}

/// A rounded card with a small tail on one edge, as one shape so the glass is
/// one piece. The tail sits `tailX` points from the card's centre.
struct StationCardShape: Shape {
    var cornerRadius: CGFloat
    /// The tail's offset from the centre, or `nil` for no tail.
    var tailX: CGFloat?
    /// The tail on the top edge (the card hangs under its station) or the bottom.
    var tailUp: Bool

    static let tailHeight: CGFloat = 9
    static let tailWidth: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        var body = rect
        if tailX != nil {
            if tailUp { body.origin.y += Self.tailHeight }
            body.size.height -= Self.tailHeight
        }
        var path = Path(roundedRect: body, cornerRadius: cornerRadius, style: .continuous)
        if let tailX {
            let centre = rect.midX + tailX
            let baseY = tailUp ? body.minY : body.maxY
            let tipY = tailUp ? rect.minY : rect.maxY
            let half = Self.tailWidth / 2
            var tail = Path()
            tail.move(to: CGPoint(x: centre - half, y: baseY))
            tail.addQuadCurve(to: CGPoint(x: centre, y: tipY), control: CGPoint(x: centre - Self.tailWidth * 0.18, y: baseY))
            tail.addQuadCurve(to: CGPoint(x: centre + half, y: baseY), control: CGPoint(x: centre + Self.tailWidth * 0.18, y: baseY))
            tail.closeSubpath()
            path.addPath(tail)
        }
        return path
    }
}

/// The level as a row of small marks, `level` of `maxLevel`, drawn in code until
/// the painted mark of pofu-art batch 159 drops into `LevelMark`'s slot.
struct LevelMarks: View {
    let level: Int
    let maxLevel: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...max(maxLevel, 1), id: \.self) { index in
                LevelMark(isBuilt: index <= level, isNext: index == level + 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: WorldStrings.level(level, of: maxLevel)))
    }
}

/// One mark. The slot for the painted art.
struct LevelMark: View {
    let isBuilt: Bool
    let isNext: Bool

    var body: some View {
        Circle()
            .fill(isBuilt ? Color.primary : Color.clear)
            .overlay { Circle().stroke(Color.primary.opacity(isBuilt ? 0 : (isNext ? 0.7 : 0.35)), lineWidth: 1.5) }
            .frame(width: 10, height: 10)
    }
}

/// What the card shows, in one place for both variants: name and level
/// marks; then the rate now and at the next level; then the one action, or
/// the reason it is refused where the action would be.
struct StationCard: View {
    let station: StationID
    let status: StationStatus?
    let jar: Energy
    let playableRounds: Int
    let onPlay: (@MainActor () -> Void)?
    let onBuild: (@MainActor (StationID) -> Void)?
    var catalog = ArchipelagoCatalog.standard
    let variant: StationCardVariant
    let expanded: Bool
    /// The card's width, or `nil` for the collapsed pill, which fits its content.
    let width: CGFloat?
    /// The tail's offset from the centre; `nil` while the pill is closed.
    let tailX: CGFloat?
    let tailUp: Bool
    let onTogglePill: () -> Void

    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme

    private var showsFacts: Bool {
        variant == .tag || expanded
    }

    var body: some View {
        let shape = StationCardShape(cornerRadius: showsFacts ? 22 : 20, tailX: tailX, tailUp: tailUp)
        VStack(alignment: .leading, spacing: PofuSpacing.s) {
            header
            if showsFacts, let status {
                facts(status)
            } else if showsFacts {
                Text("Not open yet", bundle: .module)
                    .font(PofuFont.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, showsFacts ? PofuSpacing.m : PofuSpacing.m)
        .padding(.vertical, showsFacts ? PofuSpacing.m : PofuSpacing.s)
        .padding(tailUp ? .top : .bottom, tailX == nil ? 0 : StationCardShape.tailHeight)
        .frame(width: width, alignment: .leading)
        .fixedSize(horizontal: width == nil, vertical: true)
        .glassEffect(.regular, in: shape)
        .contentShape(shape)
        // Glass and its text follow the plate: a night plate under a day system gets a dark card.
        .environment(\.colorScheme, night.map { $0 ? ColorScheme.dark : ColorScheme.light } ?? scheme)
        .accessibilityElement(children: .contain)
    }

    // MARK: Header

    @ViewBuilder
    private var header: some View {
        if variant == .pill {
            Button(action: onTogglePill) { headerRow }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isHeader)
        } else {
            headerRow.accessibilityAddTraits(.isHeader)
        }
    }

    private var headerRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PofuSpacing.m) {
                name
                if showsFacts { Spacer(minLength: 0) }
                marks
            }
            VStack(alignment: .leading, spacing: PofuSpacing.xs) {
                name
                marks
            }
        }
        .frame(minHeight: variant == .pill && !expanded ? PofuSize.minimumTouch - 16 : 0)
        .contentShape(Rectangle())
    }

    private var name: some View {
        Text(verbatim: WorldStrings.stationName(station))
            .font(PofuFont.headline)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var marks: some View {
        if let status {
            LevelMarks(level: status.level, maxLevel: status.maxLevel)
        }
    }

    // MARK: Facts and the one action

    private func facts(_ status: StationStatus) -> some View {
        VStack(alignment: .leading, spacing: PofuSpacing.s) {
            rate(status)
                .accessibilityElement(children: .combine)
            action(status)
        }
    }

    /// Seeds a day now, and at the next level, in monospaced digits.
    private func rate(_ status: StationStatus) -> some View {
        let now = Self.format(status.seedsPerHour * 24)
        let next = status.nextCost == nil ? nil : catalog.station(station).map { Self.format($0.seedsPerHour(at: status.level + 1) * 24) }
        return Group {
            if status.level == 0, let next {
                Text("\(next) seeds a day once built", bundle: .module)
            } else if let next {
                Text("\(now) seeds a day · \(next) once built", bundle: .module)
            } else {
                Text("\(now) seeds a day", bundle: .module)
            }
        }
        .font(PofuFont.subheadline.monospacedDigit())
        .foregroundStyle(.primary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private static func format(_ rate: Double) -> String {
        rate.formatted(.number.precision(.fractionLength(0...1)))
    }

    /// The garden's door to the game comes first while rounds are left; the
    /// build or its reason follows. Every other station has the build alone.
    @ViewBuilder
    private func action(_ status: StationStatus) -> some View {
        if station == .garden, status.level > 0, playableRounds > 0, let onPlay {
            VStack(spacing: PofuSpacing.xs) {
                Button {
                    PofuHaptics.shared.play(.tap)
                    onPlay()
                } label: {
                    Text("Play · \(playableRounds) left", bundle: .module)
                        .font(PofuFont.headline)
                        .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch - 8)
                }
                .buttonStyle(.glassProminent)
                .tint(PofuKitPalette.day.honey)
                .foregroundStyle(PofuKitPalette.day.ink)
                if status.nextCost != nil, status.capLiftsAtIslandLevel == nil {
                    buildAction(status, prominent: false)
                }
            }
        } else {
            buildAction(status, prominent: true)
        }
    }

    @ViewBuilder
    private func buildAction(_ status: StationStatus, prominent: Bool) -> some View {
        if let liftsAt = status.capLiftsAtIslandLevel {
            // The island level holds the next level back: a quiet line, no padlock, no red.
            reason { Text(verbatim: WorldStrings.capReason(islandLevel: liftsAt)) }
                .accessibilityIdentifier("station-cap-reason")
        } else if let cost = status.nextCost {
            let missing = max(cost.units - jar.units, 0)
            if onBuild == nil {
                reason { Text("Building opens soon.", bundle: .module) }
            } else if missing > 0 {
                // Not enough seeds yet: the reason stands where the button would.
                reason { Text("\(missing) more seeds", bundle: .module) }
                    .accessibilityIdentifier("station-missing-seeds")
            } else {
                let button = Button {
                    PofuHaptics.shared.play(.tap)
                    onBuild?(station)
                } label: {
                    HStack(spacing: PofuSpacing.s) {
                        Text("Build · \(cost.units)", bundle: .module)
                            .font(PofuFont.headline.monospacedDigit())
                        SeedGlyph()
                            .fill(prominent ? PofuKitPalette.day.ink : Color.primary)
                            .frame(width: 9, height: 14)
                            .rotationEffect(.degrees(18))
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch - 8)
                }
                if prominent {
                    button
                        .buttonStyle(.glassProminent)
                        .tint(PofuKitPalette.day.honey)
                        .foregroundStyle(PofuKitPalette.day.ink)
                } else {
                    button.buttonStyle(.glass)
                }
            }
        } else if station == .garden, status.level > 0, onPlay != nil {
            // Fully built garden with no rounds left today.
            reason { Text("No rounds left today.", bundle: .module) }
        } else {
            reason { Text("Every level is built.", bundle: .module) }
        }
    }

    private func reason<Line: View>(@ViewBuilder _ line: () -> Line) -> some View {
        line()
            .font(PofuFont.callout.monospacedDigit())
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch - 8, alignment: .leading)
    }
}

/// Places a station's card by its station: under it, or above it when the
/// screen's foot is too near; its side by where the station sits, kept whole on
/// screen with the tail still pointing at the station.
struct StationCardPlacement: View {
    let station: StationID
    /// The station's painted object on screen.
    let anchor: CGRect
    let size: CGSize
    let status: StationStatus?
    let jar: Energy
    let playableRounds: Int
    let onPlay: (@MainActor () -> Void)?
    let onBuild: (@MainActor (StationID) -> Void)?
    let variant: StationCardVariant
    let expanded: Bool
    let onTogglePill: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var measured = CGSize(width: 232, height: 170)

    static let margin: CGFloat = 12
    static let gap: CGFloat = 4

    var body: some View {
        let collapsed = variant == .pill && !expanded
        let available = max(size.width - 2 * Self.margin, 0)
        let cardWidth = typeSize.isAccessibilitySize ? available : min(232, available)
        let shownWidth = collapsed ? min(measured.width, available) : cardWidth
        let centreX = min(max(anchor.midX, Self.margin + shownWidth / 2), size.width - Self.margin - shownWidth / 2)
        let height = measured.height
        let below = anchor.maxY + Self.gap
        let above = anchor.minY - Self.gap - height
        let top = 110.0
        let bottom = size.height - 16
        // Under the station when it fits; above when only that clears the foot of the screen.
        let tailUp = below + height <= bottom || above < top
        let y = min(max(tailUp ? below : above, top), max(bottom - height, top))
        let reach = max(shownWidth / 2 - 26, 0)
        let tailX: CGFloat? = collapsed ? nil : min(max(anchor.midX - centreX, -reach), reach)
        StationCard(
            station: station,
            status: status,
            jar: jar,
            playableRounds: playableRounds,
            onPlay: onPlay,
            onBuild: onBuild,
            variant: variant,
            expanded: expanded,
            width: collapsed ? nil : cardWidth,
            tailX: tailX,
            tailUp: tailUp,
            onTogglePill: onTogglePill
        )
        .onGeometryChange(for: CGSize.self) { $0.size } action: { measured = $0 }
        .position(x: centreX, y: y + height / 2)
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: expanded)
        .transition(.scale(scale: 0.92, anchor: tailUp ? .top : .bottom).combined(with: .opacity))
    }
}
#endif
