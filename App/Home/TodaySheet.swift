import PofuCore
import PofuDesignSystem
import SwiftUI

/// The Today sheet as a day card (UI v3 section 2): the hour's island strip
/// on top (a sky band and a small island until the batch-59 strips land),
/// today's resists as wax seals, the seed jar, and one line from Pofu in a
/// speech bubble. Paper by the scene's light, never the system's.
struct TodaySheet: View {
    let model: AppModel
    /// The hour the card shows; `nil` is now. Screenshots set it.
    var hourOverride: Int?

    @Environment(\.dynamicTypeSize) private var typeSize

    private var hour: Int {
        hourOverride ?? Calendar.current.component(.hour, from: Date())
    }

    private var sky: DaySky { DaySky(hour: hour) }

    var body: some View {
        let palette: PofuKitPalette = sky.isNight ? .night : .day
        ScrollView {
            VStack(alignment: .leading, spacing: PofuSpacing.l) {
                DayCard(model: model, sky: sky, palette: palette)
                pofuLine(palette)
            }
            .padding(.horizontal, PofuSpacing.screen)
            .padding(.top, PofuSpacing.xl)
            .padding(.bottom, PofuSpacing.l)
        }
        .scrollBounceBehavior(.basedOnSize)
        .pofuNight(sky.isNight)
        .environment(\.colorScheme, sky.isNight ? .dark : .light)
        .background { PofuPaperSheetBackground().pofuNight(sky.isNight) }
    }

    /// One line from Pofu, in a bubble that grows from its mouth.
    @ViewBuilder
    private func pofuLine(_ palette: PofuKitPalette) -> some View {
        let sticker = StickerView(
            Sticker.dayMood(skipped: model.impulsesToday.resisted, reaches: model.impulsesToday.attempts),
            size: 64
        )
        let bubble = PofuPaperBubble(speaker: LocalizedStringKey(model.profile.companionName), tailPosition: 0.12) {
            Text("Each skip is a small win.")
        }
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: PofuSpacing.s) {
                bubble
                sticker
            }
        } else {
            HStack(alignment: .bottom, spacing: PofuSpacing.s) {
                sticker
                bubble
            }
        }
    }
}

/// The sky of an hour, for the card's strip: the world's palette (dawn
/// peach, day blue, golden apricot, night indigo).
struct DaySky {
    let hour: Int

    var isNight: Bool { hour < 5 || hour >= 21 }

    var colors: [Color] {
        switch hour {
        case 5..<8: [Color(red: 0.99, green: 0.80, blue: 0.66), Color(red: 0.99, green: 0.93, blue: 0.82)]
        case 8..<17: [Color(red: 0.56, green: 0.78, blue: 0.93), Color(red: 0.88, green: 0.95, blue: 0.97)]
        case 17..<21: [Color(red: 0.93, green: 0.58, blue: 0.40), Color(red: 0.99, green: 0.86, blue: 0.62)]
        default: [Color(red: 0.12, green: 0.11, blue: 0.27), Color(red: 0.30, green: 0.24, blue: 0.45)]
        }
    }

    /// The sun or the moon, by the hour.
    var orb: Color {
        isNight ? Color(red: 0.98, green: 0.93, blue: 0.78) : Color(red: 1, green: 0.90, blue: 0.55)
    }

    /// 0 at the left horizon, 1 at the right.
    var orbPosition: Double {
        let h = Double((hour + 24 - (isNight ? 21 : 5)) % 24)
        let span = isNight ? 8.0 : 16.0
        return min(max(h / span, 0.08), 0.92)
    }
}

/// The card: strip, seals, jar.
private struct DayCard: View {
    let model: AppModel
    let sky: DaySky
    let palette: PofuKitPalette

    var body: some View {
        let metrics = model.impulsesToday
        VStack(alignment: .leading, spacing: 0) {
            IslandStrip(sky: sky, palette: palette)
                .frame(height: 112)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: PofuRadius.large, topTrailingRadius: PofuRadius.large, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PofuSpacing.m) {
                Text("Today")
                    .font(PofuFont.title2)
                    .foregroundStyle(palette.onPaper)
                    .accessibilityAddTraits(.isHeader)
                if metrics.attempts == 0 {
                    Text("No reaches yet today.")
                        .font(PofuFont.callout)
                        .foregroundStyle(inkSoft)
                } else {
                    Text("\(metrics.resisted) of \(metrics.attempts) skipped")
                        .font(PofuFont.title3)
                        .foregroundStyle(palette.onPaper)
                        .contentTransition(.numericText(value: Double(metrics.resisted)))
                    SealRow(beads: model.beadsToday, palette: palette)
                    if let ratio = metrics.resistedRatio {
                        Text("Goal: half. You're at \(ratio.formatted(.percent.precision(.fractionLength(0)).locale(AppLanguage.locale))).")
                            .font(PofuFont.footnote)
                            .foregroundStyle(inkSoft)
                    }
                }
                Divider().overlay(palette.stitch.opacity(0.5))
                HStack(spacing: PofuSpacing.s) {
                    SeedIcon(size: 26)
                    Text("\(model.world.jar.units) seeds in the jar")
                        .font(PofuFont.headline.monospacedDigit())
                        .foregroundStyle(palette.onPaper)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
            .padding(PofuSpacing.l)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { PofuPaperSurface(kind: .stitched) }
        .accessibilityElement(children: .contain)
    }

    private var inkSoft: Color {
        palette.isNight ? palette.onPaper.opacity(0.8) : palette.inkSoft
    }
}

/// A sky band with the sun or moon and a small island silhouette.
private struct IslandStrip: View {
    let sky: DaySky
    let palette: PofuKitPalette

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack(alignment: .bottom) {
                LinearGradient(colors: sky.colors, startPoint: .top, endPoint: .bottom)
                Circle()
                    .fill(sky.orb)
                    .frame(width: 30, height: 30)
                    .shadow(color: sky.orb.opacity(0.7), radius: 12)
                    .position(x: w * sky.orbPosition, y: h * 0.32)
                if sky.isNight {
                    ForEach(0..<7, id: \.self) { i in
                        Circle().fill(sky.orb.opacity(0.8))
                            .frame(width: 2.5, height: 2.5)
                            .position(x: w * (0.1 + 0.13 * Double(i)), y: h * (0.14 + 0.1 * Double((i * 5) % 4)))
                    }
                }
                // The island: a grass mound on a rock underside, one tree.
                ZStack(alignment: .bottom) {
                    Ellipse().fill(PofuKitPalette.rgb(sky.isNight ? 0x4A3F5C : 0xB08A63))
                        .frame(width: 150, height: 34)
                        .offset(y: 12)
                    Ellipse().fill(PofuKitPalette.rgb(sky.isNight ? 0x4E6A55 : 0x8FB574))
                        .frame(width: 170, height: 36)
                        .offset(y: -6)
                    Circle().fill(PofuKitPalette.rgb(sky.isNight ? 0x3E5A48 : 0x6E9A5C))
                        .frame(width: 30, height: 30)
                        .offset(x: 30, y: -34)
                    Capsule().fill(PofuKitPalette.rgb(0x7A5A40))
                        .frame(width: 5, height: 16)
                        .offset(x: 30, y: -22)
                }
                .frame(width: 170, height: 70)
                .offset(y: 4)
            }
            .frame(width: w, height: h)
            .clipped()
        }
    }
}

/// Today's reaches as wax seals in a row: resisted ones stamped, opened
/// ones an empty impression. Code-drawn until batch-60's `seal-resist`.
private struct SealRow: View {
    let beads: [ImpulseBead]
    let palette: PofuKitPalette
    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 32

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: side), spacing: PofuSpacing.s)], alignment: .leading, spacing: PofuSpacing.s) {
            ForEach(Array(beads.enumerated()), id: \.offset) { _, bead in
                WaxSeal(stamped: bead == .skipped, palette: palette)
                    .frame(width: side, height: side)
            }
        }
        .accessibilityHidden(true)
    }
}

struct WaxSeal: View {
    let stamped: Bool
    let palette: PofuKitPalette

    private static let wax = PofuKitPalette.rgb(0xB5483B)
    private static let waxDark = PofuKitPalette.rgb(0x8E3329)

    var body: some View {
        ZStack {
            if stamped {
                Circle()
                    .fill(RadialGradient(colors: [Self.wax, Self.waxDark], center: .topLeading, startRadius: 1, endRadius: 28))
                Circle().strokeBorder(Color.white.opacity(0.28), lineWidth: 1.4).padding(4)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.85))
            } else {
                Circle().strokeBorder(palette.stitch, style: StrokeStyle(lineWidth: 1.4, dash: [3, 3]))
            }
        }
        .shadow(color: palette.edge.opacity(stamped ? 0.3 : 0), radius: 2, y: 1)
    }
}
