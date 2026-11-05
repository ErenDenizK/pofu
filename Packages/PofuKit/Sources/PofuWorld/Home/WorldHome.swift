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
/// waiting. The jar, the lantern and the pots stand in the world canvas at
/// `HomeSlots` (experience v1 §1.4), so they share the island's transform.
/// The chrome is the gear (top), the peeking Today glance (bottom) and one
/// contextual primary for the beats that are not Collect. In the settled
/// state one quiet line takes the primary's place ("Ada sensiz de
/// çalışıyor."). The one place control lives in the scene
/// (`PlaceControl`), the same spot in every framing.
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
        /// Opens the garden game; `nil` hides the play doors.
        public var play: (@MainActor () -> Void)?
        /// Garden rounds playable now.
        public var playableRounds: Int
        /// Sends the game event of a tap on today's visit (greeting, gift,
        /// help, invitation); `nil` leaves the visit decorative.
        public var visitor: (@MainActor (GameEvent.Kind) -> Void)?

        public init(
            collect: @escaping @MainActor () -> SeedPouch?,
            build: @escaping @MainActor (StationID) -> BuildReceipt?,
            openSettings: @escaping @MainActor () -> Void,
            repair: @escaping @MainActor () -> Void,
            openToday: (@MainActor () -> Void)? = nil,
            play: (@MainActor () -> Void)? = nil,
            playableRounds: Int = 0,
            visitor: (@MainActor (GameEvent.Kind) -> Void)? = nil
        ) {
            self.collect = collect
            self.build = build
            self.openSettings = openSettings
            self.repair = repair
            self.openToday = openToday
            self.play = play
            self.playableRounds = playableRounds
            self.visitor = visitor
        }
    }

    let world: WorldSnapshot
    let today: TodaySummary
    let scene: IslandSceneModel
    let home: WorldHomeModel
    let actions: Actions

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    public init(world: WorldSnapshot, today: TodaySummary, scene: IslandSceneModel, home: WorldHomeModel, actions: Actions) {
        self.world = world
        self.today = today
        self.scene = scene
        self.home = home
        self.actions = actions
    }

    public var body: some View {
        // The one resolver reports taps on the home objects here; set on
        // every pass so it never holds a stale world.
        let _ = scene.onPropTap = { prop in propTapped(prop) }
        ZStack {
            IslandScene(
                world: world,
                model: scene,
                home: home,
                onPofuTap: { home.pofuTapped() },
                onBuild: { station in build(station) },
                props: props,
                onVisitor: actions.visitor,
                bubble: { bubble }
            )

            chrome

            CollectFlight(home: home)
        }
        .onAppear {
            home.camera = scene
        }
        .onChange(of: actions.playableRounds, initial: true) { _, rounds in
            scene.playableRounds = rounds
        }
        .onAppear {
            scene.onPlay = actions.play
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

    private var showsIslandName: Bool {
        scene.projectedFraming == .island && scene.focus == nil
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
                Spacer(minLength: 0)
                if scene.projectedFraming == .island {
                    IslandNameChip(island: scene.island)
                        .padding(.bottom, PofuSpacing.l)
                }
            }
            .opacity(showsIslandName ? 1 : 0)
            .allowsHitTesting(false)
        }
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: showsHomeChrome)
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: showsIslandName)
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
    /// settled line, and the glance. The place control sits bottom trailing
    /// in the scene; the play door lives in the garden.
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

    private var isNight: Bool {
        world.isBedtime || WorldLight.resolve(world: world, calendar: .current).night > 0.5
    }

    /// The jar, the lantern and the pots in the world canvas (§1.4), and
    /// the jar's count tag and Collect action as screen overlays shown from
    /// z 1.6.
    private var props: WorldProps {
        WorldProps(
            world: { frame in AnyView(worldProps(frame)) },
            screen: { frame in AnyView(screenProps(frame)) }
        )
    }

    private func worldProps(_ frame: WorldPropsFrame) -> some View {
        let presence = frame.presence
        return ZStack(alignment: .topLeading) {
            placed(.pots, frame) {
                SkipPotsView(
                    pots: SkipPots(beads: today.beads, isAsleep: world.isBedtime),
                    today: today,
                    timing: home.timing,
                    isNight: isNight
                )
            }
            placed(.lantern, frame) {
                CalmLanternView(
                    calm: world.calm,
                    isGrowing: world.activity == .away && !world.calmIsFull,
                    isFull: world.calmIsFull,
                    isNight: isNight,
                    timing: home.timing
                )
            }
            placed(.jar, frame) {
                // The tag and the Collect action are screen overlays; the
                // jar itself is just art (the tap goes through the one
                // resolver).
                HomeJar(
                    jar: world.jar.units,
                    uncollected: world.pending.total.units,
                    canCollect: false,
                    isNight: isNight,
                    showsTag: false,
                    jarX: 0,
                    screenWidth: Double(frame.size.width),
                    leadingInset: 0,
                    trailingInset: 0,
                    home: home,
                    collect: {}
                )
            }
        }
        .frame(width: frame.size.width, height: frame.size.height, alignment: .topLeading)
        .opacity(presence)
        .allowsHitTesting(false)
    }

    /// One object at its slot: projected like Pofu, scaled with the world,
    /// squished when tapped.
    private func placed<Content: View>(_ prop: HomeSlots.Prop, _ frame: WorldPropsFrame, @ViewBuilder content: () -> Content) -> some View {
        let p = frame.point(of: prop.slot)
        let k = CGFloat(frame.homeFactor)
        return ZStack {
            content()
                .modifier(TapSquish(trigger: frame.pulse(of: prop), anchor: .bottom))
                .scaleEffect(k)
            // Where the slot was drawn, for the screenshot tests.
            Color.clear
                .frame(width: 1, height: 1)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame.report(prop, $0) }
                .allowsHitTesting(false)
        }
        .position(x: p.x, y: p.y)
    }

    private func screenProps(_ frame: WorldPropsFrame) -> some View {
        let opacity = frame.isFocused ? 0 : min(max((frame.z - 1.6) / 0.3, 0), 1)
        let jar = frame.point(of: HomeSlots.jar)
        let k = frame.homeFactor
        return JarOverlay(
            home: home,
            jar: world.jar.units,
            uncollected: world.pending.total.units,
            canCollect: collectBeatIsOpen,
            showsTag: showsJarTag,
            jarX: jar.x,
            screenWidth: Double(frame.size.width),
            collect: { collect() }
        )
        .offset(y: HomeObjectsLayout.jarSize.height * k / 2 + 4)
        .position(x: jar.x, y: jar.y)
        .opacity(opacity)
        .allowsHitTesting(opacity > 0.5)
        .frame(width: frame.size.width, height: frame.size.height, alignment: .topLeading)
    }

    /// What a tap on a home object does (the squish already played).
    private func propTapped(_ prop: HomeSlots.Prop) {
        switch prop {
        case .jar:
            if collectBeatIsOpen { collect() }
        case .pots:
            actions.openToday?()
        case .lantern:
            break
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
        home.collectSeeds(
            jarBefore: world.jar.units,
            sources: seedSources(),
            target: jarTarget(),
            commit: actions.collect
        )
    }

    /// The jar on screen now: where the seeds land.
    private func jarTarget() -> MomentPoint {
        let p = scene.screenPoint(of: HomeSlots.jar)
        return MomentPoint(x: p.x, y: p.y)
    }

    private func build(_ station: StationID) {
        let maxLevel = world.stations.first { $0.id == station }?.maxLevel ?? 5
        home.buildStation(station, maxLevel: maxLevel, commit: actions.build)
    }

    /// Where seeds leave from: every built station on the home island and
    /// Pofu himself, kept on screen so they fly in from the edge.
    private func seedSources() -> [MomentPoint] {
        var points: [WorldPoint] = []
        for status in world.stations where status.island == .home && status.level > 0 {
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

/// The jar's count tag and the "Topla" action under it, in screen points
/// (§1.4): the count rolls up with the collect moment like the jar's fill.
struct JarOverlay: View {
    let home: WorldHomeModel
    let jar: Int
    let uncollected: Int
    let canCollect: Bool
    let showsTag: Bool
    let jarX: Double
    let screenWidth: Double
    let collect: @MainActor () -> Void

    /// The action's measured width (it grows with the seed count).
    @State private var actionWidth = 140.0

    var body: some View {
        // A point at the jar's centre; the content hangs from its top.
        Color.clear
            .frame(width: 1, height: 1)
            .overlay(alignment: .top) { content }
    }

    private var content: some View {
        TimelineView(.animation(minimumInterval: nil, paused: home.collect == nil || home.frozenOffset != nil)) { context in
            let moment = home.collect?.moment
            let time = home.collectTime(at: context.date) ?? 0
            let count = moment?.counter(at: time) ?? jar
            VStack(spacing: PofuSpacing.xs) {
                if showsTag {
                    JarTag(count: count)
                        .scaleEffect(CGFloat(moment?.pillScale(at: time) ?? 1))
                        .accessibilityHidden(true)
                }
                if canCollect, home.collect == nil {
                    CollectAction(seeds: uncollected, action: collect)
                        .onGeometryChange(for: Double.self) { Double($0.size.width) } action: { actionWidth = $0 }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .fixedSize()
            .offset(x: HomeObjectsLayout.collectShift(jarX: jarX, actionWidth: actionWidth, screenWidth: screenWidth))
        }
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
