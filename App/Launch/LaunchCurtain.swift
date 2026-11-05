import os
import PofuDesignSystem
import SwiftUI
import UIKit

/// The honest loading screen (experience v1 section 3.5).
///
/// The system launch screen is a painted dawn sky (`launch-sky`). This view
/// carries on from it over the first frames: if the world is ready within
/// 150 ms the sky crossfades to it in 0.2 s; otherwise a cloud curtain of
/// three drifting layers stays only while loading actually runs, then parts
/// in 0.6 s. There is no minimum duration and no fake progress; after two
/// seconds one honest line appears.
///
/// Art: `launch-sky` (asset catalog) and `cloud-curtain-1...3` (asset
/// catalog) are code-drawn placeholders until the Codex plates exist; a
/// plate added under the same name replaces the placeholder with no code
/// change.
struct LaunchCurtain: View {
    /// The world has its first frame.
    let isReady: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Phase: Equatable {
        case loading
        /// Ready: the reveal began at `Date`, of this kind and length.
        case revealing(PofuLaunchTiming.Reveal, since: Date, length: TimeInterval)
        case done
    }

    @State private var phase: Phase = .loading
    @State private var start = Date()

    var body: some View {
        if phase != .done {
            TimelineView(.animation(minimumInterval: phase == .loading ? 1.0 / 30.0 : nil)) { context in
                let elapsed = context.date.timeIntervalSince(start)
                let progress = revealProgress(at: context.date)
                let kind = revealKind
                let showsCurtain = PofuLaunchTiming.showsCurtain(after: elapsed, isReady: isReady) || kind == .curtain
                ZStack {
                    LaunchSky()
                        .opacity(kind == .curtain ? 1 - progress : 1)
                    if showsCurtain {
                        CloudCurtain(time: elapsed, parted: kind == .curtain ? progress : 0, reduceMotion: reduceMotion)
                    }
                    if PofuLaunchTiming.showsLine(after: elapsed, isReady: isReady) {
                        Text("Pofu is waking up…")
                            .font(.system(.title2, design: .rounded, weight: .heavy))
                            .foregroundStyle(Color(red: 0.24, green: 0.18, blue: 0.14))
                    }
                }
                .opacity(kind == .crossfade ? 1 - progress : 1)
            }
            .ignoresSafeArea()
            .allowsHitTesting(phase == .loading)
            .accessibilityHidden(true)
            .onChange(of: isReady, initial: true) { _, ready in
                if ready { begin() }
            }
        }
    }

    private var revealKind: PofuLaunchTiming.Reveal? {
        if case .revealing(let kind, _, _) = phase { return kind }
        return nil
    }

    /// The reveal's eased progress, `0...1`.
    private func revealProgress(at date: Date) -> Double {
        guard case .revealing(_, let since, let length) = phase else { return 0 }
        let t = min(max(date.timeIntervalSince(since) / length, 0), 1)
        return t * t * (3 - 2 * t)
    }

    private func begin() {
        guard phase == .loading else { return }
        let elapsed = Date().timeIntervalSince(start)
        // Reduce Motion gets the plain crossfade.
        let kind = reduceMotion ? PofuLaunchTiming.Reveal.crossfade : PofuLaunchTiming.reveal(readyAfter: elapsed)
        let length = PofuLaunchTiming.revealDuration(kind)
        phase = .revealing(kind, since: Date(), length: length)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(length + 0.05))
            phase = .done
        }
    }
}

/// The world is ready: Home's first frame is up (or a later signal from
/// the world, once the plates are prepared). Marking it twice is harmless.
@MainActor
@Observable
final class LaunchGate {
    static let shared = LaunchGate()

    private(set) var isReady = false
    private let signposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier ?? "pofu", category: "launch")
    private let launched = Date()

    private init() {}

    func markWorldReady() {
        guard !isReady else { return }
        isReady = true
        // `firstWorldFrame`: the cold-launch target is 600 ms on iPhone 17.
        let milliseconds = Int(Date().timeIntervalSince(launched) * 1000)
        signposter.emitEvent("firstWorldFrame", "\(milliseconds) ms after the gate was made")
    }
}

/// The dawn sky: the painted `launch-sky` plate, or a code-drawn dawn
/// gradient (the colour script's dawn zenith over its horizon) until the
/// plate lands.
private struct LaunchSky: View {
    var body: some View {
        if UIImage(named: "launch-sky") != nil {
            GeometryReader { proxy in
                Image("launch-sky")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
        } else {
            LinearGradient(
                colors: [Color(red: 0.643, green: 0.776, blue: 0.933), Color(red: 0.980, green: 0.784, blue: 0.690)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

/// Three painted cloud layers drifting at 30 Hz, then parting. Each layer
/// is `cloud-curtain-N` when the plate exists and a soft code-drawn bank
/// until then.
private struct CloudCurtain: View {
    let time: TimeInterval
    /// 0 closed, 1 parted.
    let parted: Double
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(1...3, id: \.self) { index in
                    layer(index, size: proxy.size)
                }
            }
        }
    }

    private func layer(_ index: Int, size: CGSize) -> some View {
        let drift = reduceMotion ? 0 : sin(time * (0.35 + 0.12 * Double(index)) + Double(index)) * 14
        // Front banks part first and widest; alternate sides.
        let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
        let apart = CGFloat(parted) * size.width * (0.9 - 0.15 * CGFloat(index)) * direction
        return Group {
            if UIImage(named: "cloud-curtain-\(index)") != nil {
                Image("cloud-curtain-\(index)")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width * 1.2, height: size.height)
            } else {
                CloudBank(seed: index)
                    .frame(width: size.width * 1.2, height: size.height)
            }
        }
        .offset(x: CGFloat(drift) + apart, y: CGFloat(index - 2) * 16)
        .opacity(1 - parted * 0.8)
        .allowsHitTesting(false)
    }
}

/// A soft bank of clouds drawn in code: overlapping ellipses, blurred.
private struct CloudBank: View {
    let seed: Int

    var body: some View {
        Canvas { context, size in
            let tint = Color(red: 1.0, green: 0.957, blue: 0.933).opacity(0.5 + 0.12 * Double(seed))
            let shade = Color(red: 0.902, green: 0.773, blue: 0.776).opacity(0.28)
            let rows = 3 + seed
            for row in 0..<rows {
                let y = size.height * (0.12 + 0.76 * Double(row) / Double(rows))
                for column in 0..<4 {
                    let phase = Double(row * 7 + column * 3 + seed * 5)
                    let x = size.width * (0.05 + 0.3 * Double(column)) + sin(phase) * 30
                    let width = 150.0 + 70.0 * (sin(phase * 1.3) + 1)
                    let height = 54.0 + 20.0 * (cos(phase) + 1)
                    let rect = CGRect(x: x, y: y, width: width, height: height)
                    context.fill(Path(ellipseIn: rect.offsetBy(dx: 0, dy: 10)), with: .color(shade))
                    context.fill(Path(ellipseIn: rect), with: .color(tint))
                }
            }
        }
        .blur(radius: 16)
    }
}
