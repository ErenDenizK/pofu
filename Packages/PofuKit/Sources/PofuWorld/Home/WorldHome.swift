#if os(iOS)
import PofuCore
import PofuDesignSystem
import SwiftUI

/// Home: the island at its Home framing with the chrome of the app–game
/// boundary §6.3, and the visit's moments.
///
/// At most five chrome items: the wellbeing pill, the calm chip and the
/// gear in the top band; the Today card and one contextual primary action
/// in the bottom band. In the settled state the primary is gone and one
/// quiet line takes its place ("Ada sensiz de çalışıyor."). Away from the
/// Home framing, the Home chrome yields to the framing control.
///
/// Collect and build go through `actions`, which the app wires to
/// `WorldClock.collect` and `WorldClock.build`; the moments then play from
/// `home`.
public struct WorldHome: View {
    /// What Home's controls do. The app wires the model's commits here.
    public struct Actions {
        public var collect: @MainActor () -> SeedPouch?
        public var build: @MainActor (StationID) -> BuildReceipt?
        public var openSettings: @MainActor () -> Void
        public var repair: @MainActor () -> Void
        /// The Today sheet; `nil` until it exists.
        public var openToday: (@MainActor () -> Void)?

        public init(
            collect: @escaping @MainActor () -> SeedPouch?,
            build: @escaping @MainActor (StationID) -> BuildReceipt?,
            openSettings: @escaping @MainActor () -> Void,
            repair: @escaping @MainActor () -> Void,
            openToday: (@MainActor () -> Void)? = nil
        ) {
            self.collect = collect
            self.build = build
            self.openSettings = openSettings
            self.repair = repair
            self.openToday = openToday
        }
    }

    let world: WorldSnapshot
    let today: TodaySummary
    let scene: IslandSceneModel
    let home: WorldHomeModel
    let actions: Actions

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The action slot's centre on screen: where collected seeds land.
    @State private var slotCenter = CGPoint(x: 201, y: 790)

    public init(world: WorldSnapshot, today: TodaySummary, scene: IslandSceneModel, home: WorldHomeModel, actions: Actions) {
        self.world = world
        self.today = today
        self.scene = scene
        self.home = home
        self.actions = actions
    }

    public var body: some View {
        ZStack {
            IslandScene(
                world: world,
                model: scene,
                home: home,
                onPofuTap: { home.pofuTapped() },
                onBuild: { station in build(station) },
                bubble: { bubble }
            )

            chrome

            CollectFlight(home: home)
        }
        .onAppear {
            home.camera = scene
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: home.collectTaps)
        .sensoryFeedback(.selection, trigger: home.collectTicks)
        .sensoryFeedback(.success, trigger: home.collectSuccesses)
        .sensoryFeedback(.impact(weight: .medium), trigger: home.buildSwaps)
        .sensoryFeedback(.success, trigger: home.buildSettles)
        // TODO(haptics): the last level's three-transient celebration
        // (design language §11) needs Core Haptics; `.success` until then.
        .sensoryFeedback(.success, trigger: home.finalBuilds)
    }

    // MARK: - The bubble

    /// Pofu's line: the beat's, or in the settled state one line after a
    /// tap.
    private var line: String? {
        if let beat = home.currentBeat {
            return WorldStrings.beatLine(beat, calm: world.calm)
        }
        return home.settledLine.map(WorldStrings.settledLine)
    }

    @ViewBuilder
    private var bubble: some View {
        if let line {
            SpeechBubble {
                Text(verbatim: line)
            }
            .id(line)
            .transition(.scale(scale: 0.92, anchor: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - The chrome

    private var showsHomeChrome: Bool {
        scene.projectedFraming == .home && scene.focus == nil && !scene.hasSheet
    }

    private var showsFramingControl: Bool {
        scene.projectedFraming != .home && scene.focus == nil
    }

    private var chrome: some View {
        ZStack {
            VStack(spacing: 0) {
                topBand
                Spacer(minLength: 0)
                bottomBand
            }
            .padding(.horizontal, PofuSpacing.screen)
            .padding(.bottom, PofuSpacing.s)
            .opacity(showsHomeChrome ? 1 : 0)
            .allowsHitTesting(showsHomeChrome)

            VStack {
                FramingPicker(model: scene)
                    .padding(.top, PofuSpacing.s)
                Spacer(minLength: 0)
                if scene.projectedFraming == .island {
                    IslandNameChip(island: .aycicegi)
                        .padding(.bottom, PofuSpacing.l)
                }
            }
            .opacity(showsFramingControl ? 1 : 0)
            .allowsHitTesting(showsFramingControl)
        }
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: showsHomeChrome)
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: showsFramingControl)
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.settle), value: home.currentBeat)
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: home.collect == nil)
    }

    /// Wellbeing pill · calm chip · gear; a broken guard replaces the pill
    /// row with the repair banner.
    @ViewBuilder
    private var topBand: some View {
        if home.visit.plan.showsRepairBanner {
            RepairBanner(onRepair: actions.repair, onSettings: actions.openSettings)
                .padding(.top, PofuSpacing.s)
        } else {
            HStack(spacing: PofuSpacing.s) {
                WellbeingPill(band: world.band)
                CalmChip(calm: world.calm, isGrowing: world.activity == .away && !world.calmIsFull, isFull: world.calmIsFull)
                Spacer(minLength: 0)
                GearButton(action: actions.openSettings)
            }
            .padding(.top, PofuSpacing.s)
        }
    }

    private var bottomBand: some View {
        VStack(spacing: PofuSpacing.m) {
            TodayCard(today: today, onOpen: actions.openToday)
            actionSlot
                .frame(minHeight: PofuSize.buttonHeight)
                .onGeometryChange(for: CGPoint.self) { proxy in
                    let frame = proxy.frame(in: .global)
                    return CGPoint(x: frame.midX, y: frame.midY)
                } action: { center in
                    slotCenter = center
                }
        }
    }

    /// The beat's primary, the seed pill while seeds land, or the settled
    /// line.
    @ViewBuilder
    private var actionSlot: some View {
        if home.collect != nil {
            SeedCounterPill(home: home)
                .transition(.opacity)
        } else if let beat = home.currentBeat {
            Button {
                primary(beat)
            } label: {
                HStack(spacing: PofuSpacing.s) {
                    if case .collect = beat {
                        SeedGlyph()
                            .fill(PofuColor.onAccent)
                            .frame(width: 10, height: 16)
                            .rotationEffect(.degrees(18))
                            .accessibilityHidden(true)
                    }
                    Text(verbatim: WorldStrings.beatAction(beat))
                        .font(PofuFont.headline)
                }
                .frame(maxWidth: .infinity, minHeight: PofuSize.buttonHeight - 8)
            }
            .buttonStyle(.glassProminent)
            .tint(PofuColor.accent)
            .transition(.opacity)
        } else {
            Text(verbatim: WorldStrings.settled)
                .font(PofuFont.subheadline)
                .foregroundStyle(PofuColor.textSecondary)
                .padding(.horizontal, PofuSpacing.l)
                .frame(minHeight: 34)
                .background(PofuColor.card.opacity(0.82), in: Capsule(style: .continuous))
                .frame(maxWidth: .infinity)
                .transition(.opacity)
        }
    }

    // MARK: - Actions

    private func primary(_ beat: VisitBeat) {
        switch beat {
        case .collect:
            collect()
        case .care:
            home.acknowledgeCurrentBeat()
        case .news:
            home.acknowledgeCurrentBeat()
            scene.go(to: .island)
        case .build(let station, _):
            home.acknowledgeCurrentBeat()
            scene.focusStation(station)
        case .weeklyRecap:
            home.acknowledgeCurrentBeat()
            actions.openToday?()
        }
    }

    /// Seeds leave the built stations and Pofu and land in the pill.
    private func collect() {
        home.collectSeeds(
            jarBefore: world.jar.units,
            sources: seedSources(),
            target: MomentPoint(x: Double(slotCenter.x), y: Double(slotCenter.y)),
            commit: actions.collect
        )
    }

    private func build(_ station: StationID) {
        let maxLevel = world.stations.first { $0.id == station }?.maxLevel ?? 5
        home.buildStation(station, maxLevel: maxLevel, commit: actions.build)
    }

    /// Where seeds leave from: every built station on the home island and
    /// Pofu himself, kept on screen so they fly in from the edge.
    private func seedSources() -> [MomentPoint] {
        var points: [WorldPoint] = []
        for status in world.stations where status.island == .aycicegi && status.level > 0 {
            if let anchor = IslandLayout.stationAnchors[status.id] {
                points.append(WorldPoint(x: anchor.x, y: anchor.y - 24))
            }
        }
        points.append(WorldPoint(x: IslandLayout.pofu.x, y: IslandLayout.pofu.y - 30))
        let width = scene.engine.rig.rail.width
        return points.map { point in
            let p = scene.screenPoint(of: point)
            return MomentPoint(x: min(max(p.x, 16), width - 16), y: max(p.y, 140))
        }
    }
}

// MARK: - Chrome components

/// Pofu's wellbeing band in the art's warm palette (gate v2 §8): a glass
/// capsule tinted by the band, a heart and the band's words.
struct WellbeingPill: View {
    let band: WellbeingBand

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(heart)
            Text(verbatim: WorldStrings.wellbeing(band))
                .font(PofuFont.subheadline)
                .foregroundStyle(PofuColor.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, PofuSpacing.m)
        .frame(minHeight: PofuSize.minimumTouch - 6)
        .glassEffect(.regular.tint(tint.opacity(0.45)), in: Capsule(style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: WorldStrings.wellbeingLabel(band)))
    }

    private var tint: Color {
        switch band {
        case .cozy: PofuPrimitive.honey300.rgb.color
        case .content: PofuPrimitive.peach300.rgb.color
        case .tired: PofuPrimitive.cream300.rgb.color
        case .unwell: PofuPrimitive.blush200.rgb.color
        case .curledUp: PofuPrimitive.ink300.rgb.color
        }
    }

    private var heart: Color {
        switch band {
        case .cozy: PofuPrimitive.blush500.rgb.color
        case .content: PofuPrimitive.peach600.rgb.color
        case .tired: PofuPrimitive.peach400.rgb.color
        case .unwell, .curledUp: PofuPrimitive.ink400.rgb.color
        }
    }
}

/// Calm, the stake (§6.3): "Huzur ×1,6" with a green dot that breathes
/// while calm grows, the only animated chrome (home directions §6).
struct CalmChip: View {
    let calm: Double
    let isGrowing: Bool
    let isFull: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.worldStillFrame) private var still
    @State private var breathe = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isGrowing || isFull ? PofuPrimitive.meadow400.rgb.color : PofuColor.textTertiary)
                .frame(width: 8, height: 8)
                .scaleEffect(breathe ? 1.3 : 0.85)
                .opacity(breathe ? 1 : 0.75)
            Text(verbatim: WorldStrings.calmChip(calm))
                .font(PofuFont.subheadline.monospacedDigit())
                .foregroundStyle(PofuColor.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, PofuSpacing.m)
        .frame(minHeight: PofuSize.minimumTouch - 6)
        .glassEffect(.regular, in: Capsule(style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: WorldStrings.calmLabel(calm, growing: isGrowing, full: isFull)))
        .onAppear {
            guard isGrowing, !reduceMotion, !still else { return }
            // 4 s in, 4 s out: the breathing rate.
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}

/// Settings, a system action: SF Symbol in a 44 pt glass circle.
struct GearButton: View {
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape")
                .font(PofuFont.title3)
                .foregroundStyle(PofuColor.textPrimary)
                .frame(width: PofuSize.minimumTouch, height: PofuSize.minimumTouch)
                .glassEffect(.regular.interactive(), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: WorldStrings.settings))
    }
}

/// A broken guard, natively and first (§6.1): one line and "Onar".
struct RepairBanner: View {
    let onRepair: @MainActor () -> Void
    let onSettings: @MainActor () -> Void

    var body: some View {
        HStack(spacing: PofuSpacing.s) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundStyle(PofuColor.warning)
            Text(verbatim: WorldStrings.repairBanner)
                .font(PofuFont.subheadline)
                .foregroundStyle(PofuColor.textPrimary)
                .lineLimit(2)
            Spacer(minLength: 0)
            Button(action: onRepair) {
                Text(verbatim: WorldStrings.repairAction)
                    .font(PofuFont.headline)
                    .padding(.horizontal, PofuSpacing.s)
            }
            .buttonStyle(.glassProminent)
            .tint(PofuColor.accent)
            GearButton(action: onSettings)
        }
        .padding(.leading, PofuSpacing.m)
        .padding(.vertical, 2)
        .glassEffect(.regular, in: Capsule(style: .continuous))
    }
}

/// Today's honest readout (gate v2 §8): skips of reaches, one bead per
/// reach (filled = skipped, a ring = opened; shape, not only color), and
/// guarded time in 15-minute steps against the daily hour.
struct TodayCard: View {
    let today: TodaySummary
    let onOpen: (@MainActor () -> Void)?

    var body: some View {
        let card = VStack(alignment: .leading, spacing: PofuSpacing.s) {
            HStack(alignment: .firstTextBaseline, spacing: PofuSpacing.s) {
                Text(verbatim: WorldStrings.todayLine(today))
                    .font(PofuFont.headline)
                    .foregroundStyle(PofuColor.textPrimary)
                    .lineLimit(2)
                Spacer(minLength: PofuSpacing.s)
                GuardedSteps(today: today)
            }
            HStack(alignment: .center, spacing: PofuSpacing.s) {
                if today.reaches > 0 {
                    BeadRow(skipped: today.beads, beadSize: 12)
                }
                Spacer(minLength: PofuSpacing.s)
                Text(verbatim: WorldStrings.guarded(today))
                    .font(PofuFont.footnote.monospacedDigit())
                    .foregroundStyle(PofuColor.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, PofuSpacing.l)
        .padding(.vertical, PofuSpacing.m + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PofuColor.card.opacity(0.96), in: RoundedRectangle(cornerRadius: PofuRadius.large, style: .continuous))
        .shadow(color: PofuColor.shadow.opacity(0.08), radius: 10, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(WorldStrings.todayLine(today)). \(WorldStrings.guardedLabel(today))"))

        if let onOpen {
            Button(action: onOpen) { card }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
        } else {
            card
        }
    }
}

/// The daily hour as four 15-minute segments; the used ones filled.
struct GuardedSteps: View {
    let today: TodaySummary

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<today.segments, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index < today.filledSegments ? PofuColor.textSecondary : PofuColor.hairline)
                    .frame(width: 14, height: 6)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The island's name at the Island framing (§1.6).
struct IslandNameChip: View {
    let island: IslandID

    var body: some View {
        Text(verbatim: WorldStrings.islandName(island))
            .font(PofuFont.subheadline)
            .foregroundStyle(PofuColor.textPrimary)
            .padding(.horizontal, PofuSpacing.l)
            .frame(minHeight: 34)
            .glassEffect(.regular, in: Capsule(style: .continuous))
            .accessibilityAddTraits(.isHeader)
    }
}

/// The seed pill that takes the primary's place while seeds land: its
/// counter rolls up to the jar's new total and pops (the jar itself is
/// deferred, ADR-0018 amendment; this is the native readout).
struct SeedCounterPill: View {
    let home: WorldHomeModel

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: home.collect == nil || home.frozenOffset != nil)) { context in
            let time = home.collectTime(at: context.date) ?? 0
            let moment = home.collect?.moment
            let count = moment?.counter(at: time) ?? 0
            HStack(spacing: PofuSpacing.s) {
                SeedIcon(size: 18)
                Text(count, format: .number)
                    .font(PofuFont.title3.monospacedDigit())
                    .foregroundStyle(PofuColor.energyOnFill)
            }
            .padding(.horizontal, PofuSpacing.l)
            .frame(minHeight: PofuSize.buttonHeight - 8)
            .glassEffect(.regular.tint(PofuColor.energyFill.opacity(0.75)), in: Capsule(style: .continuous))
            .scaleEffect(CGFloat(moment?.pillScale(at: time) ?? 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: WorldStrings.seeds(moment?.jarAfter ?? count)))
        }
        .frame(maxWidth: .infinity)
    }
}

/// The seeds in flight, over everything, in screen points.
struct CollectFlight: View {
    let home: WorldHomeModel

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: home.collect == nil || home.frozenOffset != nil)) { context in
            if let moment = home.collect?.moment, let time = home.collectTime(at: context.date) {
                ZStack(alignment: .topLeading) {
                    ForEach(0..<moment.seedCount, id: \.self) { index in
                        if let seed = moment.seed(index, at: time) {
                            SeedIcon(size: 18)
                                .shadow(color: Color.shadowInk.opacity(0.25), radius: 2, y: 1)
                                .scaleEffect(CGFloat(seed.scale))
                                .rotationEffect(.degrees(seed.rotation))
                                .opacity(seed.opacity)
                                .position(x: CGFloat(seed.x), y: CGFloat(seed.y))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
