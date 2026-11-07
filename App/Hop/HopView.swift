import PofuCompanion
import PofuCore
import PofuDesignSystem
import SwiftUI

/// Hop!: the soft gate's intervention (user flows, section 2).
///
/// Every rung shares one layout so the eye and thumb never re-learn it:
/// the app chip, "Hop!", the rung's question, Pofu, the rung's element,
/// then the quieter open action above the large **Skip it**. The skip is
/// live from the first frame. Leaving without choosing counts as skipping.
struct HopView: View {
    let model: AppModel
    /// Pins the postcard (a screenshot, the rain when there is weather);
    /// otherwise the hour's sky decides.
    var hourOverride: GateHour?

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let session = model.hop {
                let hour = hourOverride ?? GateHour(date: model.now, isBedtime: session.isNight, mist: model.isMistMorning)
                HopContent(model: model, session: session, hour: hour)
                    .environment(\.colorScheme, hour.isDark || session.isNight ? .dark : .light)
            } else {
                Color.clear
            }
        }
        .onAppear {
            if scenePhase == .active {
                model.markHopActive()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.markHopActive()
            }
        }
    }
}

private struct HopContent: View {
    let model: AppModel
    let session: HopSession
    let hour: GateHour

    var body: some View {
        ZStack {
            GatePostcard(hour: hour)
            GateScrim(hour: hour)
            if !(session.phase == .deciding && !session.isBreathing) {
                // Screens that are all text sit on the hour's sky, wholly.
                hour.scrim.opacity(0.82).ignoresSafeArea()
            }
            switch session.phase {
            case .deciding:
                if session.isBreathing, let plan = session.breath {
                    BreathRoom(model: model, session: session, plan: plan)
                        .transition(.opacity)
                } else {
                    HopDecision(model: model, session: session, hour: hour)
                        .transition(.opacity)
                }
            case .skipped(let skipsToday):
                HopSkipped(model: model, session: session, skipsToday: skipsToday)
                    .transition(.opacity)
            case .handoff(let pass):
                HopHandoff(model: model, session: session, pass: pass)
                    .transition(.opacity)
            case .handoffFailed(let refund):
                HopHandoffFailed(model: model, session: session, refund: refund)
                    .transition(.opacity)
            }
        }
        .animation(PofuMotion.settle, value: session.phase)
    }
}

// MARK: - Deciding

private struct HopDecision: View {
    let model: AppModel
    let session: HopSession
    let hour: GateHour

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var skipFocused: Bool
    @State private var appeared = false

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                // Spacers on both sides of Pofu put him lower-middle on the
                // postcard's ground whenever the rung has no element.
                VStack(spacing: PofuSpacing.l) {
                    HopAppChip(app: session.app, reachOrdinal: session.reachOrdinal)
                        .padding(.top, PofuSpacing.s)
                    header
                    Spacer(minLength: PofuSpacing.s)
                    stage
                    rungElement
                    Spacer(minLength: PofuSpacing.s)
                }
                .padding(.horizontal, PofuSpacing.screen)
                .padding(.bottom, PofuSpacing.l)
                .frame(maxWidth: .infinity, minHeight: max(proxy.size.height - 190, 0))
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .safeAreaInset(edge: .bottom) {
            actions
                .padding(.horizontal, PofuSpacing.screen)
                .padding(.top, PofuSpacing.s)
                .padding(.bottom, PofuSpacing.xs)
        }
        .onAppear {
            appeared = true
            skipFocused = true
        }
        // The palette's `nudge` by day; at night the check-in is softer.
        .onChange(of: appeared) {
            if !session.isNight {
                PofuHaptics.shared.play(.nudge)
            }
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.35), trigger: appeared) { _, _ in session.isNight }
    }

    // MARK: Header and stage

    private var header: some View {
        VStack(spacing: PofuSpacing.xs) {
            Text(verbatim: "Hop!")
                .pofuDisplayFont()
                .foregroundStyle(hour.title)
                .shadow(color: hour.scrim.opacity(0.7), radius: 6)
                .accessibilityAddTraits(.isHeader)
            Text(question)
                .font(PofuFont.title2)
                .foregroundStyle(hour.ink)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private var question: LocalizedStringKey {
        if session.isNight {
            return "Shh, it's late."
        }
        switch session.rung {
        case .pause: return model.isPastDailyHour ? "One breath first." : "Quick check-in."
        case .intent: return "What's this one for?"
        }
    }

    private var stage: some View {
        VStack(spacing: PofuSpacing.s) {
            if let line = pofuLine {
                SpeechBubble { Text(line) }
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
            HopCompanion(model: model, session: session, hour: hour, breathes: session.rung == .pause && model.isPastDailyHour)
        }
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.hop), value: session.reason)
    }

    /// What Pofu says above itself, if anything.
    private var pofuLine: LocalizedStringKey? {
        if let reason = session.reason, session.rung == .intent {
            return PofuLines.answer(to: reason)
        }
        if let running = model.activeSession {
            let minutes = Int((running.remaining(at: model.now) / 60).rounded(.up))
            if minutes > 0 {
                return "We're focusing. \(minutes) minutes left."
            }
        }
        if session.isNight {
            return "The feed will still be there tomorrow. I promise."
        }
        return nil
    }

    // MARK: Rung elements

    @ViewBuilder private var rungElement: some View {
        switch session.rung {
        case .pause:
            EmptyView()
        case .intent:
            ReasonGrid(selected: session.reason) { model.chooseReason($0) }
        }
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: PofuSpacing.s) {
            openAction
            Button {
                model.skipHop()
            } label: {
                Text(skipLabel)
            }
            .buttonStyle(PofuPlaqueButtonStyle(isProminent: true))
            .accessibilityFocused($skipFocused)
            Text("Swiping away counts as skipping.")
                .font(PofuFont.footnote)
                .foregroundStyle(hour.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private var skipLabel: LocalizedStringKey {
        session.isNight ? "Goodnight, \(model.profile.companionName)" : "Skip it"
    }

    @ViewBuilder private var openAction: some View {
        switch session.rung {
        case .pause:
            // The 5 s breath is for reaches past the daily hour only
            // (ADR-0015, gate v2 section 6.5); under it, opening is
            // immediate.
            if model.isPastDailyHour {
                BreathOpenButton(model: model)
            } else {
                Button {
                    model.openFromHop(with: .proceed)
                } label: {
                    Text("Open for \(model.economy.configuration.friction.freePassMinutes) min")
                }
                .buttonStyle(PofuPlaqueButtonStyle())
            }
        case .intent:
            Button {
                model.openFromHop(with: .proceed)
            } label: {
                Text("Open for \(model.economy.configuration.friction.freePassMinutes) min")
            }
            .buttonStyle(PofuPlaqueButtonStyle())
            .disabled(session.reason == nil)
        }
    }
}

/// The app being reached for, and how often this hour.
struct HopAppChip: View {
    let app: ProtectedApp
    let reachOrdinal: Int

    var body: some View {
        HStack(spacing: PofuSpacing.s) {
            Image(systemName: app.symbolName)
                .font(PofuFont.subheadline)
                .foregroundStyle(PofuColor.accent)
                .frame(width: 28, height: 28)
                .background(Circle().fill(PofuColor.accentTint))
            if reachOrdinal > 1 {
                Text("\(app.displayName) · \(AppLanguage.ordinal(reachOrdinal)) reach this hour")
            } else {
                Text(verbatim: app.displayName)
            }
        }
        .font(PofuFont.headline)
        .foregroundStyle(PofuColor.textSecondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.leading, PofuSpacing.xs)
        .padding(.trailing, PofuSpacing.l)
        .padding(.vertical, PofuSpacing.xs)
        .background(Capsule(style: .continuous).fill(PofuColor.raised.opacity(0.8)))
        .accessibilityElement(children: .combine)
    }
}

/// Pofu on the Hop! stage. On the pause rung Pofu breathes with the user:
/// it swells while they breathe in and settles as they breathe out.
private struct HopCompanion: View {
    let model: AppModel
    let session: HopSession
    let hour: GateHour
    let breathes: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var inhale = false
    @State private var idle = false

    var body: some View {
        let still = reduceMotion || scenePhase != .active
        CompanionView(vitality: model.vitality, energy: model.cheekFill)
            .frame(maxWidth: 170)
            .background { GateGlow(hour: hour, breathe: idle && !still) }
            .scaleEffect(breathes && inhale && !reduceMotion ? 1.07 : (idle && !still ? 1.015 : 1), anchor: .bottom)
            .background(alignment: .bottom) {
                // The contact shadow on the ground.
                Ellipse()
                    .fill(Color(hex: 0x2A1F2D).opacity(hour.isDark ? 0.5 : 0.28))
                    .frame(width: 130, height: 22)
                    .blur(radius: 7)
                    .offset(y: 8)
            }
            .task {
                guard !reduceMotion else { return }
                // A 4 s idle breath: 2 s in, 2 s out.
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { idle = true }
                guard breathes else { return }
                withAnimation(.easeInOut(duration: BreathOpenButton.halfBreath)) { inhale = true }
                try? await Task.sleep(for: .seconds(BreathOpenButton.halfBreath))
                withAnimation(.easeInOut(duration: BreathOpenButton.halfBreath)) { inhale = false }
            }
            .accessibilityLabel(Text(verbatim: model.profile.companionName))
    }
}

/// The pause rung's open action past the daily hour. It fills like a progress bar while the
/// user breathes, and opens only once the breath is done.
private struct BreathOpenButton: View {
    static let halfBreath: Double = 2.5

    let model: AppModel

    @State private var progress: Double = 0
    @State private var breathingOut = false
    @State private var isReady = false

    var body: some View {
        VStack(spacing: PofuSpacing.s) {
            Text(breathingOut ? LocalizedStringKey("…and out.") : LocalizedStringKey("Breathe in…"))
                .font(PofuFont.title3)
                .foregroundStyle(PofuColor.textSecondary)
                .contentTransition(.opacity)
                .accessibilityHidden(isReady)
            Button {
                model.openFromHop(with: .proceed)
            } label: {
                Text("Open for \(model.economy.configuration.friction.freePassMinutes) min")
            }
            .buttonStyle(PofuPlaqueButtonStyle(progress: isReady ? nil : progress))
            .disabled(!isReady)
        }
        .task {
            // Time-based, so it is linear on purpose: it is a clock, not a
            // motion of the world.
            withAnimation(.linear(duration: Self.halfBreath * 2)) { progress = 1 }
            try? await Task.sleep(for: .seconds(Self.halfBreath))
            withAnimation(PofuMotion.snappy) { breathingOut = true }
            try? await Task.sleep(for: .seconds(Self.halfBreath))
            withAnimation(PofuMotion.snappy) { isReady = true }
        }
    }
}

/// The six reasons of the intent rung.
private struct ReasonGrid: View {
    let selected: IntentReason?
    let onSelect: (IntentReason) -> Void

    private let columns = [GridItem(.flexible(), spacing: PofuSpacing.s), GridItem(.flexible(), spacing: PofuSpacing.s)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: PofuSpacing.s) {
            ForEach(IntentReason.allCases, id: \.self) { reason in
                Button {
                    onSelect(reason)
                } label: {
                    HStack(spacing: PofuSpacing.xs) {
                        if selected == reason {
                            Image(systemName: "checkmark")
                                .font(PofuFont.caption)
                        }
                        Text(PofuLines.label(for: reason))
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }
                .buttonStyle(PofuChoiceStyle(isSelected: selected == reason, cornerRadius: PofuRadius.large))
                .accessibilityAddTraits(selected == reason ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selected)
    }
}
