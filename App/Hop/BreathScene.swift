import PofuDesignSystem
import SwiftUI

/// The breathing room's world (UI v3 section 4), drawn in code until the
/// batch-62 art lands: sky by day or night tinted toward lavender, two cloud
/// bands that part on the in-breath, drifting petals (fireflies at night),
/// a halo and the breath ring; over the gate's postcard only the petals and the ring are drawn. Every layer
/// is a plain gradient or shape: nothing is blurred per frame.
enum BreathPalette {
    static func rgb(_ hex: UInt32) -> Color { PofuKitPalette.rgb(hex) }

    static func skyColors(night: Bool) -> [Color] {
        night
            ? [rgb(0x1E1A3C), rgb(0x2B2450), rgb(0x3A2F5E)]
            : [rgb(0xFBE4D2), rgb(0xF4DCE4), rgb(0xE2DCF6)]
    }

    static func ink(night: Bool) -> Color { night ? rgb(0xF6E7D2) : rgb(0x4A3326) }
    static func inkSoft(night: Bool) -> Color { night ? rgb(0xD9C3A0) : rgb(0x7A6150) }
}

/// The sky, clouds and drifting petals behind everything.
struct BreathSky: View {
    let isNight: Bool
    /// 0 (out) ... 1 (in): the clouds part as it rises.
    let lift: Double
    let reduceMotion: Bool
    var animatesPetals = true
    /// False over the gate's painted postcard: only the petals drift.
    var showsSky = true

    var body: some View {
        ZStack {
            if showsSky {
                LinearGradient(colors: BreathPalette.skyColors(night: isNight), startPoint: .top, endPoint: .bottom)
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    clouds(width: width, near: false)
                        .offset(x: reduceMotion ? 0 : -10 * lift, y: height * 0.16)
                    clouds(width: width, near: true)
                        .offset(x: reduceMotion ? 0 : 14 * lift, y: height * 0.78)
                }
            }
            if !reduceMotion && animatesPetals {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                    PetalCanvas(time: timeline.date.timeIntervalSinceReferenceDate, isNight: isNight)
                }
                .allowsHitTesting(false)
            }
        }
        .accessibilityHidden(true)
    }

    private func clouds(width: CGFloat, near: Bool) -> some View {
        let tint = isNight ? BreathPalette.rgb(0x6A5C8E) : Color.white
        let opacity = near ? (isNight ? 0.5 : 0.8) : (isNight ? 0.3 : 0.55)
        return ZStack {
            Capsule().frame(width: width * 0.55, height: near ? 54 : 34).offset(x: -width * 0.18, y: 0)
            Capsule().frame(width: width * 0.4, height: near ? 44 : 28).offset(x: width * 0.2, y: near ? 14 : 10)
            Capsule().frame(width: width * 0.3, height: near ? 40 : 24).offset(x: -width * 0.02, y: near ? -16 : -12)
        }
        .foregroundStyle(tint.opacity(opacity))
        .frame(width: width)
    }
}

/// Six petals falling slowly by day; six fireflies pulsing at night.
private struct PetalCanvas: View {
    let time: TimeInterval
    let isNight: Bool

    var body: some View {
        Canvas { context, size in
            for index in 0..<6 {
                let seed = Double(index)
                let speed = 0.025 + seed * 0.004
                let phase = (time * speed + seed * 0.37).truncatingRemainder(dividingBy: 1)
                let x = size.width * (0.12 + 0.15 * seed) + sin(time * 0.4 + seed) * 18
                if isNight {
                    let y = size.height * (0.25 + 0.09 * seed) + cos(time * 0.3 + seed) * 12
                    let glow = 0.35 + 0.35 * sin(time * 1.1 + seed * 2)
                    let rect = CGRect(x: x, y: y, width: 6, height: 6)
                    context.fill(Path(ellipseIn: rect), with: .color(BreathPalette.rgb(0xFFD27A).opacity(glow)))
                } else {
                    let y = size.height * phase
                    var petal = context
                    petal.translateBy(x: x, y: y)
                    petal.rotate(by: .degrees(sin(time + seed) * 30))
                    petal.fill(Path(ellipseIn: CGRect(x: -4.5, y: -2.5, width: 9, height: 5)), with: .color(BreathPalette.rgb(0xF2A7B8).opacity(0.7)))
                }
            }
        }
    }
}

/// The ring and the halo around Pofu, who stands on the postcard's lawn.
struct BreathScene<Pofu: View>: View {
    let inhale: Double
    let exhale: Double
    let start: Int
    /// Pins the ring (screenshots).
    var frozenRing: Double?
    let onPhase: (BreathRingPhase) -> Void
    /// 0 (out) ... 1 (in): drives the halo and the swell.
    let lift: Double
    let isNight: Bool
    let reduceMotion: Bool
    let pofu: Pofu

    var body: some View {
        let honey = PofuKitPalette.day.honey
        ZStack {
            // The halo: a soft glow that opens with the breath. Reduce
            // Motion fades it in and out instead of moving anything.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (isNight ? BreathPalette.rgb(0xFFC76A) : Color.white).opacity(isNight ? 0.5 : 0.9),
                            honey.opacity(0.18),
                            honey.opacity(0),
                        ],
                        center: .center, startRadius: 0, endRadius: 150
                    )
                )
                .scaleEffect(reduceMotion ? 1 : 0.9 + 0.12 * lift)
                .opacity(0.45 + 0.55 * lift)
            BreathRing(inhale: inhale, exhale: exhale, start: start, frozen: frozenRing, onPhase: onPhase)
                .padding(14)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack(alignment: .bottom) {
                    // Pofu stands on the postcard's lawn: a contact shadow,
                    // no drawn ground.
                    Ellipse()
                        .fill(Color(red: 0.165, green: 0.122, blue: 0.176).opacity(isNight ? 0.5 : 0.28))
                        .frame(width: 130, height: 22)
                        .blur(radius: 7)
                        .offset(y: 8)
                    pofu
                        .frame(maxWidth: 132)
                        .pofuBreathing(lift: lift)
                }
                .offset(y: reduceMotion ? 0 : -6 * lift)
                .padding(.bottom, Self.feetInset)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Pofu's feet stand this far above the scene's bottom edge.
    static var feetInset: CGFloat { 56 }
}
