import PofuDesignSystem
import SwiftUI

/// The hour the gate is painted in (gate v2 section 5.1): one postcard per
/// sky of the colour script, and the rain one when there is rain. The sky
/// colours the scrim behind the text and the ring of light behind Pofu.
enum GateHour: String, CaseIterable {
    case dawn, day, golden, night, rain

    /// The colour script's schedule: night until 05:30, dawn to 07:45, day
    /// to 17:30, golden hour to 20:30, then night. `isBedtime` is always
    /// night. Rain is never inferred from the clock.
    init(date: Date, isBedtime: Bool = false, calendar: Calendar = .autoupdatingCurrent) {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let minute = (parts.hour ?? 12) * 60 + (parts.minute ?? 0)
        switch minute {
        case _ where isBedtime: self = .night
        case 330..<465: self = .dawn
        case 465..<1050: self = .day
        case 1050..<1230: self = .golden
        default: self = .night
        }
    }

    var assetName: String { "gate-postcard-\(rawValue)" }
    var isDark: Bool { self == .night }

    /// Where the painted ground ends, as a fraction of the screen's height.
    var groundLine: Double {
        switch self {
        case .dawn: 0.6
        case .day: 0.62
        case .golden, .rain: 0.58
        case .night: 0.64
        }
    }

    /// The sky's colour at the text: the scrim fades from it.
    var scrim: Color {
        switch self {
        case .dawn: Color(hex: 0xFBE4D8)
        case .day: Color(hex: 0xFFF1DE)
        case .golden: Color(hex: 0xFFE0C0)
        case .night: Color(hex: 0x1E1A3C)
        case .rain: Color(hex: 0xE4EAF2)
        }
    }

    /// The hour's light: the ring behind Pofu.
    var glow: Color {
        switch self {
        case .dawn: Color(hex: 0xFFC9A8)
        case .day: Color(hex: 0xFFE9A8)
        case .golden: Color(hex: 0xFFC46B)
        case .night: Color(hex: 0xFFC766)
        case .rain: Color(hex: 0xFFFFFF)
        }
    }

    /// The title's colour, at least 4.5:1 on the scrim.
    var title: Color {
        switch self {
        case .dawn: Color(hex: 0xA8431F)
        case .day: Color(hex: 0x8A4B12)
        case .golden: Color(hex: 0x9C3F1B)
        case .night: Color(hex: 0xFFC766)
        case .rain: Color(hex: 0x2F5F8A)
        }
    }

    var ink: Color { isDark ? Color(hex: 0xFFF6EC) : Color(hex: 0x2A1F2D) }
    var inkSoft: Color { isDark ? Color(hex: 0xD9CCE0) : Color(hex: 0x4F3F49) }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// The postcard of the hour, full-bleed, drifting by a few points (never
/// more than 6) at 30 Hz while it is on screen; still with Reduce Motion.
struct GatePostcard: View {
    static let driftPoints: Double = 6

    let hour: GateHour

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || scenePhase != .active)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let drift = reduceMotion ? CGSize.zero : CGSize(
                    width: sin(t * 2 * .pi / 26) * Self.driftPoints,
                    height: cos(t * 2 * .pi / 34) * Self.driftPoints * 0.6
                )
                Image(hour.assetName)
                    .resizable()
                    .scaledToFill()
                    // Enough bleed that a 6 pt drift never shows an edge.
                    .scaleEffect(1 + 2.2 * Self.driftPoints / max(min(proxy.size.width, proxy.size.height), 1))
                    .offset(drift)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// The soft gradient behind text only: the top ~30 % and the bottom ~35 %,
/// coloured from the hour's sky. `strength` rises for screens that sit all
/// text (the skip and handoff phases).
struct GateScrim: View {
    let hour: GateHour
    var strength: Double = 1

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                LinearGradient(
                    stops: [
                        .init(color: hour.scrim.opacity(0.92 * strength), location: 0),
                        .init(color: hour.scrim.opacity(0.7 * strength), location: 0.55),
                        .init(color: hour.scrim.opacity(0), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: proxy.size.height * 0.3)
                Spacer(minLength: 0)
                LinearGradient(
                    stops: [
                        .init(color: hour.scrim.opacity(0), location: 0),
                        .init(color: hour.scrim.opacity(0.75 * strength), location: 0.5),
                        .init(color: hour.scrim.opacity(0.94 * strength), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: proxy.size.height * 0.35)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Pofu's soft ring of the hour's light, breathing with him.
struct GateGlow: View {
    let hour: GateHour
    let breathe: Bool

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [hour.glow.opacity(0.55), hour.glow.opacity(0.22), hour.glow.opacity(0)],
                    center: .center,
                    startRadius: 20,
                    endRadius: 150
                )
            )
            .frame(width: 300, height: 300)
            .scaleEffect(breathe ? 1.04 : 1)
            .accessibilityHidden(true)
    }
}
