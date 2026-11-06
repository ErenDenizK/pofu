import PofuCompanion
import PofuCore
import PofuDesignSystem
import SwiftUI
import UIKit

/// Where the breath is, for screens and screenshots.
enum BreathPhase: Equatable {
    case waiting
    case breathingIn
    case breathingOut
    case done
}

/// A breath held still at one moment (screenshots).
struct BreathFreeze: Equatable {
    var phase: BreathPhase
    var ring: Double
    var lift: Double
}

/// The breathing room (ADR-0015, gate v2 section 6.5, UI v3 section 4):
/// past the daily hour, every open starts here. Pofu waits on a small
/// mossy isle in a halo; the user starts the breath, and after it chooses:
/// skip, or go on to the ways in.
///
/// The breath is a clock, not a motion of the world: the ring fills over
/// the in-breath and unwinds over the out-breath on a sine ease, Pofu
/// swells 4 %, and a Core Haptics swell follows the same curve (Settings,
/// "Nefeste titreşim"). With Reduce Motion the ring still fills and
/// nothing moves; the halo fades in and out. "Şimdi değil" is a skip at
/// any moment. The timings are `BreathPlan`'s, unchanged.
struct BreathRoom: View {
    let model: AppModel
    let session: HopSession
    let plan: BreathPlan
    var frozen: BreathFreeze?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: BreathPhase
    @State private var lift: Double
    @State private var started = 0
    @State private var finished = 0

    init(model: AppModel, session: HopSession, plan: BreathPlan, frozen: BreathFreeze? = nil) {
        self.model = model
        self.session = session
        self.plan = plan
        self.frozen = frozen
        _phase = State(initialValue: frozen?.phase ?? .waiting)
        _lift = State(initialValue: frozen?.lift ?? 0)
    }

    private var isNight: Bool { session.isNight }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: PofuSpacing.l) {
                    HopAppChip(app: session.app, reachOrdinal: session.reachOrdinal)
                        .padding(.top, PofuSpacing.s)
                    Text(title)
                        .font(PofuFont.title2)
                        .foregroundStyle(BreathPalette.ink(night: isNight))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 0)
                    BreathScene(
                        inhale: plan.inhale,
                        exhale: plan.exhale,
                        start: started,
                        frozenRing: frozen?.ring,
                        onPhase: handle,
                        lift: lift,
                        isNight: isNight,
                        reduceMotion: reduceMotion,
                        pofu: CompanionView(vitality: model.vitality, energy: PofuBreathing.cheekEnergy(base: model.cheekFill, lift: lift))
                            .accessibilityLabel(Text(verbatim: model.profile.companionName))
                    )
                    .frame(maxWidth: 320)
                    Text(line)
                        .font(PofuFont.title3)
                        .foregroundStyle(BreathPalette.inkSoft(night: isNight))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                    Spacer(minLength: 0)
                    actions
                    if plan.explains && phase == .waiting {
                        Text("Past \(plan.dailyHourMinutes) minutes a day, every open starts with a breath. Change it in Settings.")
                            .font(PofuFont.footnote)
                            .foregroundStyle(BreathPalette.inkSoft(night: isNight))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, PofuSpacing.screen)
                .padding(.bottom, PofuSpacing.xs)
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background {
            BreathSky(isNight: isNight, lift: lift, reduceMotion: reduceMotion, animatesPetals: frozen == nil)
                .ignoresSafeArea()
        }
        .pofuNight(isNight)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: started)
        .sensoryFeedback(.success, trigger: finished)
        .onDisappear { BreathHaptics.shared.cancel() }
    }

    private var title: LocalizedStringKey {
        phase == .done ? "Nicely done." : "We've had our hour today."
    }

    private var line: LocalizedStringKey {
        switch phase {
        case .waiting: "Breathe with me first?"
        case .breathingIn: "Breathe in…"
        case .breathingOut: "…and out."
        case .done: "Skip it, or go on?"
        }
    }

    @ViewBuilder private var actions: some View {
        VStack(spacing: PofuSpacing.s) {
            switch phase {
            case .waiting:
                Button("Breathe with Pofu") { breathe() }
                    .buttonStyle(PofuPlaqueStyle(.primary))
                Button("Not now") { skip() }
                    .buttonStyle(PofuPlaqueStyle(.quiet))
            case .breathingIn, .breathingOut:
                Button("Not now") { skip() }
                    .buttonStyle(PofuPlaqueStyle(.quiet))
            case .done:
                Button("I'm good, skip it") { skip() }
                    .buttonStyle(PofuPlaqueStyle(.primary, haptic: nil))
                Button("I'll still open it") { model.finishBreath() }
                    .buttonStyle(PofuPlaqueStyle(.quiet))
            }
        }
    }

    private func skip() {
        BreathHaptics.shared.cancel()
        model.skipHop()
    }

    private func breathe() {
        started += 1
        BreathHaptics.shared.swell(inhale: plan.inhale, exhale: plan.exhale)
        BreathSound.plan = (plan.inhale, plan.exhale)
        BreathSound.play(.airOpens)
    }

    /// The ring's turns drive the room: the same inhale and exhale
    /// seconds as `BreathPlan`, then the choices.
    private func handle(_ ringPhase: BreathRingPhase) {
        switch ringPhase {
        case .inhale:
            announce("Breathe in…")
            withAnimation(.easeInOut(duration: plan.inhale)) {
                phase = .breathingIn
                lift = 1
            }
        case .exhale:
            announce("…and out.")
            BreathSound.play(.airCloses)
            withAnimation(.easeInOut(duration: plan.exhale)) {
                phase = .breathingOut
                lift = 0
            }
        case .finished:
            withAnimation(PofuMotion.settle) { phase = .done }
            BreathSound.play(.chime)
            finished += 1
        }
    }

    private func announce(_ key: String.LocalizationValue) {
        UIAccessibility.post(notification: .announcement, argument: String(localized: key))
    }
}
