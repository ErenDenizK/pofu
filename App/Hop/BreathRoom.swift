import PofuCompanion
import PofuCore
import PofuDesignSystem
import SwiftUI
import UIKit

/// The breathing room (ADR-0015, gate v2 section 6.5): past the daily
/// hour, every open starts here. Pofu waits in a calm orb; the user starts
/// the breath, and after it chooses: skip, or go on to the ways in.
///
/// The breath is a clock, not a motion of the world: the orb grows over
/// the in-breath and shrinks over the out-breath on a sine ease. With
/// Reduce Motion it keeps its size and glows instead. "Şimdi değil" is a
/// skip at any moment.
struct BreathRoom: View {
    let model: AppModel
    let session: HopSession
    let plan: BreathPlan

    private enum Phase: Equatable {
        case waiting
        case breathingIn
        case breathingOut
        case done
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Phase = .waiting
    @State private var started = 0
    @State private var finished = 0

    var body: some View {
        VStack(spacing: PofuSpacing.l) {
            HopAppChip(app: session.app, reachOrdinal: session.reachOrdinal)
                .padding(.top, PofuSpacing.s)
            Spacer(minLength: 0)
            Text(title)
                .font(PofuFont.title2)
                .foregroundStyle(PofuColor.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            orb
            Text(line)
                .font(PofuFont.title3)
                .foregroundStyle(PofuColor.textSecondary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
            Spacer(minLength: 0)
            actions
            if plan.explains && phase == .waiting {
                Text("Past \(plan.dailyHourMinutes) minutes a day, every open starts with a breath. Change it in Settings.")
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, PofuSpacing.screen)
        .padding(.bottom, PofuSpacing.xs)
        .background(lavender.ignoresSafeArea())
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: started)
        .sensoryFeedback(.success, trigger: finished)
    }

    private var lavender: Color {
        // Lavender by day, its night tint after dark (gate v2, 5.2).
        session.isNight ? Color(red: 0x1E / 255, green: 0x18 / 255, blue: 0x28 / 255) : Color(red: 0xF1 / 255, green: 0xEC / 255, blue: 0xFF / 255)
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

    private var isExpanded: Bool { phase == .breathingIn }

    private var orb: some View {
        ZStack {
            Circle()
                .fill(PofuColor.accentTint)
                .opacity(reduceMotion && isExpanded ? 1 : 0.7)
                .scaleEffect(reduceMotion ? 1 : (isExpanded ? 1.18 : 0.88))
            CompanionView(vitality: model.vitality, energy: model.cheekFill)
                .frame(maxWidth: 150)
                .accessibilityLabel(Text(verbatim: model.profile.companionName))
        }
        .frame(width: 240, height: 240)
    }

    @ViewBuilder private var actions: some View {
        VStack(spacing: PofuSpacing.s) {
            switch phase {
            case .waiting:
                Button("Breathe with Pofu") { breathe() }
                    .buttonStyle(PofuPrimaryButtonStyle())
                Button("Not now") { model.skipHop() }
                    .buttonStyle(PofuQuietButtonStyle())
            case .breathingIn, .breathingOut:
                Button("Not now") { model.skipHop() }
                    .buttonStyle(PofuQuietButtonStyle())
            case .done:
                Button("I'm good, skip it") { model.skipHop() }
                    .buttonStyle(PofuPrimaryButtonStyle())
                Button("I'll still open it") { model.finishBreath() }
                    .buttonStyle(PofuQuietButtonStyle())
            }
        }
    }

    private func breathe() {
        started += 1
        Task { @MainActor in
            announce("Breathe in…")
            withAnimation(.easeInOut(duration: plan.inhale)) { phase = .breathingIn }
            try? await Task.sleep(for: .seconds(plan.inhale))
            guard phase == .breathingIn else { return }
            announce("…and out.")
            withAnimation(.easeInOut(duration: plan.exhale)) { phase = .breathingOut }
            try? await Task.sleep(for: .seconds(plan.exhale))
            guard phase == .breathingOut else { return }
            withAnimation(PofuMotion.settle) { phase = .done }
            finished += 1
        }
    }

    private func announce(_ key: String.LocalizationValue) {
        UIAccessibility.post(notification: .announcement, argument: String(localized: key))
    }
}
