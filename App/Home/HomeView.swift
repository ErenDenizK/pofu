import PofuCompanion
import PofuCore
import PofuDesignSystem
#if DEBUG
import PofuTuning
#endif
import PofuSound
import PofuWorld
import SwiftUI

/// Pofu's room: the single home of the app (information architecture,
/// option C). Pofu with its mood and cheeks, the seed pouch, today's beads,
/// one primary action, and everything else as sheets.
///
/// With `FeatureFlags.islandHome`, the room is Pofu's island
/// (`IslandScene`, iteration W2): the same chrome over one world in three
/// framings. The Today card and the actions show at the Home framing.
struct HomeView: View {
    @Bindable var model: AppModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    /// "glass" or "crafted" from the Prova panel or the launch argument
    /// `-PofuSkin crafted`; empty means the default skin.
    @AppStorage("PofuSkin") private var skinOverride = ""
    /// The companion's laid-out width, for tucking the bubble into its
    /// headroom.
    @State private var companionWidth: CGFloat = 300

    var body: some View {
        ZStack {
            if FeatureFlags.worldHome {
                worldHome
            } else if FeatureFlags.islandHome {
                island
            } else {
                PofuColor.dayWash.ignoresSafeArea()
            }

            if !FeatureFlags.worldHome {
                VStack(spacing: PofuSpacing.l) {
                    topBar
                        .opacity(model.island.focus == nil ? 1 : 0)
                        .allowsHitTesting(model.island.focus == nil)
                    Spacer(minLength: 0)
                    if !FeatureFlags.islandHome {
                        pofu
                        Spacer(minLength: 0)
                    }
                    Group {
                        TodayCard(model: model)
                        bottomActions
                    }
                    .opacity(showsHomeChrome ? 1 : 0)
                    .allowsHitTesting(showsHomeChrome)
                }
                .padding(.horizontal, PofuSpacing.screen)
                .padding(.bottom, PofuSpacing.s)
                .animation(PofuMotion.respecting(reduceMotion, PofuMotion.settle), value: showsHomeChrome)
                .animation(PofuMotion.respecting(reduceMotion, PofuMotion.settle), value: model.island.focus == nil)
            }

            if model.activeSession != nil || model.earningResult != nil {
                FocusSessionView(model: model)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        // The skin of the over-world chrome, once at the root: the
        // developer override (Prova panel or `-PofuSkin crafted`), else the
        // default. Reduce Transparency is resolved where the faces draw.
        .environment(\.pofuSkin, PofuSkinPolicy(developerOverride: PofuSkinPolicy.override(from: skinOverride)).skin)
        #if DEBUG
        .onChange(of: TuningLab.store.values.home, initial: true) { _, values in
            var timing = HomeTiming()
            timing.pawsPress = values.pawsPress
            timing.cheekRelease = values.cheekRelease
            timing.jarFill = values.jarFill
            timing.lanternGlow = values.lanternGlow
            timing.potBloom = values.potBloom
            timing.jarCapacity = values.jarCapacity
            model.worldHome.timing = timing
        }
        #endif
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.settle), value: model.activeSession != nil || model.earningResult != nil)
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.settle), value: model.canCollectQuietSeeds)
        .sensoryFeedback(.success, trigger: model.quietCollections)
        .onChange(of: scenePhase) { _, phase in
            // A new visit: residents may say their lines again.
            if phase == .active {
                model.island.beginVisit()
            }
        }
        .task {
            // Quiet time accrues while Pofu's room is on screen, too.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                model.tick()
            }
        }
        // Sheets and covers freeze the world's ambient layers while they
        // are up, so presenting and dismissing them never competes with a
        // live scene.
        .onChange(of: model.homeSheet != nil || model.isPlayingGarden, initial: true) { _, covered in
            model.island.isCovered = covered
        }
        .sheet(item: $model.homeSheet) { sheet in
            switch sheet {
            case .earn:
                // Tall enough for the activities, the lengths, and Start
                // together, with Pofu's room still showing above.
                EarnSheet(model: model)
                    .presentationDetents([.fraction(0.68), .large])
                    .pofuSheetBackground()
            case .passes:
                PassesSheet(model: model)
                    .presentationDetents([.medium, .large])
                    .pofuSheetBackground()
            case .settings:
                SettingsView(model: model)
                    .pofuSheetBackground()
            case .setup:
                NavigationStack {
                    SetupGuideView(model: model)
                        .pofuSheetChrome()
                }
                .pofuSheetBackground()
            case .today:
                TodaySheet(model: model)
                    .presentationDetents([.medium, .large])
                    .pofuSheetBackground()
            }
        }
        // The garden game takes the whole screen, like Hop!.
        .fullScreenCover(isPresented: $model.isPlayingGarden) {
            GardenPlayView(model: model)
        }
    }

    // MARK: Parts

    /// The island in the Home framing's chrome: Pofu, his bubble and the
    /// world live in the scene.
    private var island: some View {
        IslandScene(
            world: model.world,
            model: model.island,
            onPofuTap: {
                if model.canCollectQuietSeeds {
                    collect()
                }
            },
            bubble: { bubble }
        )
    }

    /// Home per the app–game boundary (`FeatureFlags.worldHome`): the
    /// island with its five chrome items and the visit, collecting and
    /// building through the game model.
    private var worldHome: some View {
        WorldHome(
            world: model.world,
            today: TodaySummary(
                beads: model.beadsToday.map { $0 == .skipped },
                guardedMinutes: model.world.guardedMinutesToday,
                dailyHourMinutes: model.world.dailyHourMinutes
            ),
            scene: model.island,
            home: model.worldHome,
            actions: WorldHome.Actions(
                collect: {
                    let pouch = model.collectWorldSeeds()
                    if pouch != nil { SoundEngine.shared.play(.collect) }
                    return pouch
                },
                build: { model.buildStation($0) },
                openSettings: { model.homeSheet = .settings },
                repair: { model.homeSheet = .setup },
                openToday: { model.homeSheet = .today },
                play: { model.playGarden() },
                playableRounds: model.playableRounds
            )
        )
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                model.beginWorldVisit()
            }
        }
    }

    /// The Today card and the actions belong to the Home framing.
    private var showsHomeChrome: Bool {
        !FeatureFlags.islandHome || (model.island.framing == .home && model.island.focus == nil)
    }

    private var topBar: some View {
        HStack {
            Button {
                model.homeSheet = .passes
            } label: {
                SeedPill(count: model.balance.units)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("\(model.balance.units) seeds in my cheeks"))
            Spacer()
            if FeatureFlags.islandHome {
                FramingPicker(model: model.island)
                Spacer()
            }
            Button {
                model.homeSheet = .settings
            } label: {
                // Exactly the seed pill's height and capsule shape: glass
                // drawn in the frame, not around it as `.glass` would.
                Image(systemName: "gearshape")
                    .font(PofuFont.title3)
                    .foregroundStyle(PofuColor.textPrimary)
                    .frame(width: PofuSize.minimumTouch, height: PofuSize.minimumTouch)
                    .glassEffect(.regular.interactive(), in: Capsule(style: .continuous))
                    .contentShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Settings"))
        }
        .padding(.top, PofuSpacing.s)
    }

    private var needsSetup: Bool {
        model.profile.protectedApps.isEmpty || model.profile.lastCheckIn.isEmpty
    }

    /// What tapping the speech bubble does.
    private enum BubbleAction {
        case nothing
        case setup
        case collect
    }

    private var bubbleAction: BubbleAction {
        if needsSetup || model.isAwaitingSignOfLife {
            return .setup
        }
        return model.canCollectQuietSeeds ? .collect : .nothing
    }

    /// Pofu's speech bubble: setup, collect, or the day's line.
    private var bubble: some View {
        Button {
            switch bubbleAction {
            case .setup: model.homeSheet = .setup
            case .collect: collect()
            case .nothing: break
            }
        } label: {
            SpeechBubble {
                bubbleText
            }
        }
        .buttonStyle(.plain)
        .disabled(bubbleAction == .nothing)
        .accessibilityAddTraits(bubbleAction == .nothing ? [] : .isButton)
    }

    private var pofu: some View {
        VStack(spacing: PofuSpacing.s) {
            bubble
            // The companion keeps empty room above the art for hops. Tuck
            // the bubble into most of it, so the tail ends just above
            // Pofu's head instead of pointing at air.
            .padding(.bottom, -CompanionView.restingHeadroom(forWidth: companionWidth) * 0.9)
            .zIndex(1)

            ZStack(alignment: .bottom) {
                CompanionView(
                    vitality: model.vitality,
                    energy: model.cheekFill,
                    celebrations: model.quietCollections,
                    onTap: {
                        if model.canCollectQuietSeeds {
                            collect()
                        }
                    }
                )
                .frame(maxWidth: 300)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { width in
                    companionWidth = width
                }
                .background {
                    // A glow, not a disc: no edge, so it never reads as a
                    // plate on the night room. It overflows the figure and
                    // centers on the body, below the hop headroom.
                    Circle()
                        .fill(PofuColor.haloGlow(radius: 170))
                        .frame(width: 340, height: 340)
                        .offset(y: 54)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .accessibilityLabel(Text(companionLabel))
                .accessibilityHint(model.canCollectQuietSeeds ? Text("Collects the seeds in my cheeks") : Text(verbatim: ""))

                if model.canCollectQuietSeeds {
                    CollectButton(seeds: model.state.quietTime.pending.units, action: collect)
                        .offset(y: PofuSpacing.l)
                        .transition(reduceMotion ? AnyTransition.opacity : AnyTransition.scale(scale: 0.6).combined(with: .opacity))
                }
            }
        }
    }

    /// Pofu's line: setup first, then held seeds, then the seeds quiet time
    /// saved, then the day so far.
    @ViewBuilder
    private var bubbleText: some View {
        if needsSetup {
            Text(PofuLines.home(skips: 0, attempts: 0, isBedtime: false, needsSetup: true))
        } else if model.isAwaitingSignOfLife {
            VStack(spacing: PofuSpacing.xs) {
                if model.state.quietTime.pending > .zero {
                    Text("I'm holding \(model.state.quietTime.pending.units) seeds for you.")
                }
                Text("I haven't heard from your apps in a while. Check on my setup?")
            }
        } else if model.canCollectQuietSeeds {
            let pending = model.pendingQuiet
            VStack(spacing: PofuSpacing.xs) {
                if pending.quietSeeds > .zero {
                    Text("You stayed away for \(QuietFormat.awayTime(seeds: pending.quietSeeds, rules: model.economy.configuration.quietTime)).")
                } else {
                    Text("Not a single open all night.")
                }
                Text("I saved \((pending.quietSeeds + pending.sleepBonus).units) seeds in my cheeks.")
            }
        } else {
            Text(
                PofuLines.home(
                    skips: model.impulsesToday.resisted,
                    attempts: model.impulsesToday.attempts,
                    isBedtime: model.isBedtime,
                    needsSetup: false
                )
            )
        }
    }

    /// Collects the quiet seeds: Pofu swallows the puff and hops, and the
    /// pill counts up.
    private func collect() {
        SoundEngine.shared.play(.collect)
        withAnimation(PofuMotion.respecting(reduceMotion, PofuMotion.settle)) {
            _ = model.collectQuietSeeds()
        }
    }

    private var companionLabel: String {
        let band = model.vitalityModel.band(for: model.vitality)
        let mood: String
        switch band {
        case .thriving: mood = String(localized: "thriving")
        case .content: mood = String(localized: "content")
        case .tired: mood = String(localized: "tired")
        case .wilting: mood = String(localized: "wilting")
        }
        return "\(model.profile.companionName), \(mood)"
    }

    private var bottomActions: some View {
        HStack(spacing: PofuSpacing.m) {
            Button {
                model.homeSheet = .earn
            } label: {
                Text("Fill my cheeks")
            }
            .buttonStyle(PofuPrimaryButtonStyle())

            Button {
                model.homeSheet = .passes
            } label: {
                Image(systemName: "ticket")
                    .font(PofuFont.title3)
                    .frame(width: PofuSize.buttonHeight, height: PofuSize.buttonHeight)
            }
            .buttonStyle(.glass)
            .tint(PofuColor.accent)
            .accessibilityLabel(Text("Passes"))
        }
    }
}

/// The Today sheet: the Today card on its own, opened from Home's glance.
private struct TodaySheet: View {
    let model: AppModel

    var body: some View {
        ScrollView {
            TodayCard(model: model)
                .padding(.horizontal, PofuSpacing.screen)
                .padding(.top, PofuSpacing.xl)
                .padding(.bottom, PofuSpacing.l)
        }
        .background(PofuColor.dayWash.ignoresSafeArea())
    }
}

/// Today's north star: reaches skipped, as raw counts first, beads second,
/// and the ratio last.
private struct TodayCard: View {
    let model: AppModel

    var body: some View {
        let metrics = model.impulsesToday
        VStack(alignment: .leading, spacing: PofuSpacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today")
                    .font(PofuFont.subheadline)
                    .foregroundStyle(PofuColor.textSecondary)
                Spacer(minLength: PofuSpacing.s)
                QuietStreak(model: model)
            }
            if metrics.attempts == 0 {
                Text("No reaches yet today.")
                    .font(PofuFont.title3)
                    .foregroundStyle(PofuColor.textPrimary)
            } else {
                Text("\(metrics.resisted) of \(metrics.attempts) skipped")
                    .font(PofuFont.title2)
                    .foregroundStyle(PofuColor.textPrimary)
                    .contentTransition(.numericText(value: Double(metrics.resisted)))
                BeadRow(skipped: model.beadsToday.map { $0 == .skipped })
                if let ratio = metrics.resistedRatio {
                    Text("Goal: half. You're at \(ratio.formatted(.percent.precision(.fractionLength(0)).locale(AppLanguage.locale))).")
                        .font(PofuFont.footnote)
                        .foregroundStyle(PofuColor.textSecondary)
                }
            }
            if let pass = model.activePasses.first {
                Label {
                    Text("\(ProtectedApp(rawValue: pass.target.rawValue)?.displayName ?? "") pass running")
                } icon: {
                    Image(systemName: "ticket")
                }
                .font(PofuFont.footnote)
                .foregroundStyle(PofuColor.accent)
            }
        }
        .pofuCard()
        .accessibilityElement(children: .combine)
    }
}

/// "Quiet for 1 hr, 40 min": time since the last open, ticking every
/// minute. Hidden while a pass runs or when Pofu cannot vouch for the quiet.
private struct QuietStreak: View {
    let model: AppModel

    var body: some View {
        TimelineView(.everyMinute) { context in
            if let stretch = model.quietStretch(at: context.date), stretch >= 60 {
                Label {
                    Text("Quiet for \(QuietFormat.stretch(stretch))")
                } icon: {
                    Image(systemName: "leaf")
                }
                .font(PofuFont.footnote.monospacedDigit())
                .foregroundStyle(PofuColor.success)
                .lineLimit(1)
            }
        }
    }
}

/// The "Collect" affordance under Pofu when quiet time filled its cheeks.
private struct CollectButton: View {
    let seeds: Int
    let action: @MainActor () -> Void

    @ScaledMetric(relativeTo: .headline) private var glyphSize: CGFloat = 16

    var body: some View {
        Button(action: action) {
            HStack(spacing: PofuSpacing.s) {
                SeedIcon(size: glyphSize)
                Text("Collect \(seeds) seeds")
                    .font(PofuFont.headline)
            }
            .padding(.horizontal, PofuSpacing.m)
            .frame(minHeight: PofuSize.minimumTouch)
        }
        .buttonStyle(.glass)
        .tint(PofuColor.energyOnFill)
    }
}

/// Durations for quiet time, in the app's language.
enum QuietFormat {
    /// The quiet time behind `seeds` quiet-block seeds: "2 hours".
    static func awayTime(seeds: Energy, rules: QuietTimeRules) -> String {
        let blocks = max(0, seeds.units / max(1, rules.seedsPerBlock.units))
        let seconds = blocks * max(0, rules.blockMinutes) * 60
        return Duration.seconds(seconds)
            .formatted(.units(allowed: [.days, .hours, .minutes], width: .wide, maximumUnitCount: 2).locale(AppLanguage.locale))
    }

    /// The current stretch, compact and in whole minutes: "1 hr, 40 min".
    static func stretch(_ interval: TimeInterval) -> String {
        let minutes = Int(max(0, interval) / 60)
        return Duration.seconds(minutes * 60)
            .formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated, maximumUnitCount: 2).locale(AppLanguage.locale))
    }
}
