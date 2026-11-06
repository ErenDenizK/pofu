#if canImport(SwiftUI)
import SwiftUI

/// Where a breath cycle is (reported by `BreathRing`).
public enum BreathRingPhase: Equatable, Sendable {
    case inhale
    case exhale
    case finished
}

/// The drawn breath ring (UI v3 section 4): a 3 pt honey-to-cream stroke
/// that fills clockwise over the in-breath and unwinds over the out-breath,
/// no numbers. A reusable piece: the Door and the breath room both host it.
///
/// Raise `start` to begin a cycle with `inhale` and `exhale` seconds; the
/// ring calls `onPhase` at each turn and when the cycle ends. Leaving the
/// view cancels the cycle. `frozen` pins the ring (screenshots). With
/// Reduce Motion the ring still fills; it is only a stroke.
public struct BreathRing: View {
    let inhale: Double
    let exhale: Double
    let start: Int
    let frozen: Double?
    let onPhase: (BreathRingPhase) -> Void

    @State private var progress = 0.0
    @State private var cycle: Task<Void, Never>?

    public init(inhale: Double, exhale: Double, start: Int, frozen: Double? = nil, onPhase: @escaping (BreathRingPhase) -> Void = { _ in }) {
        self.inhale = inhale
        self.exhale = exhale
        self.start = start
        self.frozen = frozen
        self.onPhase = onPhase
    }

    public var body: some View {
        let honey = PofuKitPalette.day.honey
        let cream = PofuKitPalette.day.cream
        ZStack {
            Circle().stroke(cream.opacity(0.4), lineWidth: 3)
            Circle()
                .trim(from: 0, to: frozen ?? progress)
                .stroke(
                    AngularGradient(colors: [honey, cream, honey], center: .center, startAngle: .degrees(0), endAngle: .degrees(360)),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .accessibilityHidden(true)
        .onChange(of: start) { _, _ in run() }
        .onDisappear { cycle?.cancel() }
    }

    private func run() {
        cycle?.cancel()
        cycle = Task { @MainActor in
            onPhase(.inhale)
            withAnimation(.easeInOut(duration: inhale)) { progress = 1 }
            try? await Task.sleep(for: .seconds(inhale))
            guard !Task.isCancelled else { return }
            onPhase(.exhale)
            withAnimation(.easeInOut(duration: exhale)) { progress = 0 }
            try? await Task.sleep(for: .seconds(exhale))
            guard !Task.isCancelled else { return }
            onPhase(.finished)
        }
    }
}

/// Pofu's breathe: a 4 % swell from the feet and a little more in the
/// cheeks as `lift` (0 out, 1 in) rises. Reduce Motion keeps the size.
public struct PofuBreathing: ViewModifier {
    let lift: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(lift: Double) {
        self.lift = lift
    }

    /// The cheek fill to hand the companion: `base` plus the swell.
    public static func cheekEnergy(base: Double, lift: Double) -> Double {
        min(1, base + 0.1 * lift)
    }

    public func body(content: Content) -> some View {
        content.scaleEffect(reduceMotion ? 1 : 1 + 0.04 * lift, anchor: .bottom)
    }
}

extension View {
    /// Pofu breathes with `lift` (0 out ... 1 in).
    public func pofuBreathing(lift: Double) -> some View {
        modifier(PofuBreathing(lift: lift))
    }
}
#endif
