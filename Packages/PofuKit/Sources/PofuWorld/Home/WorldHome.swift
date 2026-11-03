#if os(iOS)
import PofuCore
import PofuDesignSystem
import SwiftUI

/// Home: the island at its Home framing with the chrome of the app–game
/// boundary §6.3, and the visit's moments.
///
/// "Living Diorama" (UI direction B): state lives in the world, glass is for
/// what you do. The seed jar by Pofu carries the balance on its tag and
/// the Collect action, the calm lantern is the multiplier, today's skips
/// are clay pots on the island's lip and Pofu's cheeks show the seeds
/// waiting. The chrome is the gear (top), the peeking Today glance and the
/// map button (bottom), and one contextual primary for the beats that are
/// not Collect. In the settled state one quiet line takes the primary's
/// place ("Ada sensiz de çalışıyor."). Away from the Home framing, the Home
/// chrome yields to the framing control.
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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The left safe-area inset the objects layer last measured, for the
    /// collect flight's target (the jar keeps clear of it).
    @State private var leadingInset = 0.0

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

            objects

            chrome

            CollectFlight(home: home)
        }
        .onAppear {
            home.camera = scene
        }
        .onChange(of: home.collectSuccesses) { _, _ in
            if let moment = home.collect?.moment {
                AccessibilityNotification.Announcement(WorldStrings.collected(moment.total, jar: moment.jarAfter)).post()
            }
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
            // At the top cheek step, once a day, Pofu says the one line.
            if case .collect = beat, home.saysCheeksHuge {
                return WorldStrings.cheeksHuge
            }
            return WorldStrings.beatLine(beat)
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

    /// The gear alone; a broken guard replaces it with the repair banner.
    @ViewBuilder
    private var topBand: some View {
        if home.visit.plan.showsRepairBanner {
            RepairBanner(onRepair: actions.repair, onSettings: actions.openSettings)
                .padding(.top, PofuSpacing.s)
        } else {
            HStack(spacing: PofuSpacing.s) {
                Spacer(minLength: 0)
                PofuIconButton(systemName: "gearshape", label: WorldStrings.settings, action: actions.openSettings)
            }
            .padding(.top, PofuSpacing.s)
        }
    }

    /// The beat's primary (never Collect: that lives at the jar), the
    /// settled line, and the glance with the map button.
    private var bottomBand: some View {
        VStack(spacing: PofuSpacing.m) {
            actionSlot
            HStack(alignment: .bottom, spacing: PofuSpacing.m) {
                HomeGlance(
                    today: today,
                    seedsInGlance: showsJarTag ? nil : world.jar.units,
                    onOpen: actions.openToday
                )
                .frame(maxWidth: typeSize.isAccessibilitySize ? CGFloat.infinity : 280, alignment: .leading)
                Spacer(minLength: 0)
                PofuIconButton(systemName: "map", label: WorldStrings.framingName(.map)) {
                    scene.go(to: .map)
                }
            }
        }
    }

    /// Past the first accessibility size the jar's tag hides and the glance
    /// carries the number.
    private var showsJarTag: Bool {
        typeSize <= .accessibility1
    }

    @ViewBuilder
    private var actionSlot: some View {
        if let beat = home.currentBeat {
            if case .collect = beat {
                EmptyView()
            } else {
                Button {
                    primary(beat)
                } label: {
                    Text(verbatim: WorldStrings.beatAction(beat))
                        .font(PofuFont.headline)
                        .frame(maxWidth: .infinity, minHeight: PofuSize.buttonHeight - 8)
                }
                .pofuActionStyle(.primary)
                .transition(.opacity)
            }
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

    // MARK: - The objects

    /// Pofu's feet on screen: the objects stand relative to them.
    private func pofuFeet() -> MomentPoint {
        let p = scene.screenPoint(of: IslandLayout.pofu)
        return MomentPoint(x: p.x, y: p.y)
    }

    private var isNight: Bool {
        world.isBedtime || colorScheme == .dark
    }

    /// The jar, the lantern and the pots, glued to the world at the Home
    /// framing (they follow the camera at 15 Hz while it settles).
    private var objects: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 15.0)) { _ in
            GeometryReader { proxy in
                objectsBody(
                    width: Double(proxy.size.width),
                    leadingInset: Double(proxy.safeAreaInsets.leading),
                    trailingInset: Double(proxy.safeAreaInsets.trailing)
                )
                .onGeometryChange(for: Double.self) { Double($0.safeAreaInsets.leading) } action: { leadingInset = $0 }
            }
        }
        .ignoresSafeArea()
        .opacity(showsHomeChrome ? 1 : 0)
        .allowsHitTesting(showsHomeChrome)
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: showsHomeChrome)
    }

    private func objectsBody(width: Double, leadingInset: Double, trailingInset: Double) -> some View {
        let feet = pofuFeet()
        let jar = HomeObjectsLayout.jarCenter(feet: feet, screenWidth: width, leadingInset: leadingInset)
        let lantern = HomeObjectsLayout.lanternCenter(feet: feet, screenWidth: width)
        let pots = HomeObjectsLayout.potsCenter(feet: feet)
        return ZStack {
            SkipPotsView(
                pots: SkipPots(beads: today.beads, isAsleep: world.isBedtime),
                today: today,
                timing: home.timing,
                isNight: isNight
            )
            .position(x: pots.x, y: pots.y)

            CalmLanternView(
                calm: world.calm,
                isGrowing: world.activity == .away && !world.calmIsFull,
                isFull: world.calmIsFull,
                isNight: isNight,
                timing: home.timing
            )
            .position(x: lantern.x, y: lantern.y)

            HomeJar(
                jar: world.jar.units,
                uncollected: world.pending.total.units,
                canCollect: collectBeatIsOpen,
                isNight: isNight,
                showsTag: showsJarTag,
                jarX: jar.x,
                screenWidth: width,
                leadingInset: leadingInset,
                trailingInset: trailingInset,
                home: home,
                collect: { collect() }
            )
            .position(x: jar.x, y: jar.y)
        }
    }

    /// Seeds wait and the visit is on its Collect beat.
    private var collectBeatIsOpen: Bool {
        if case .collect? = home.currentBeat {
            return home.collect == nil
        }
        return false
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

    /// Seeds leave the built stations and Pofu, arc into the jar, and the
    /// cheeks step down.
    private func collect() {
        let width = Double(scene.engine.rig.rail.width)
        home.collectSeeds(
            jarBefore: world.jar.units,
            sources: seedSources(),
            target: HomeObjectsLayout.jarCenter(feet: pofuFeet(), screenWidth: width, leadingInset: leadingInset),
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
            PofuIconButton(systemName: "gearshape", label: WorldStrings.settings, action: onSettings)
        }
        .padding(.leading, PofuSpacing.m)
        .padding(.vertical, 2)
        .glassEffect(.regular, in: Capsule(style: .continuous))
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
            .pofuChrome(.worldTag)
            .accessibilityAddTraits(.isHeader)
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
