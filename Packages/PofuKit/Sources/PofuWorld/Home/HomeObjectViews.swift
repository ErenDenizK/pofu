#if os(iOS)
import PofuCore
import PofuDesignSystem
import SwiftUI

// The Living Diorama's world objects (UI direction B): the seed jar, the
// calm lantern, today's skip pots and Pofu's paws. Each is a painted master
// from `design/art/ui` with a drawn state on top (a fill mask, a glow, a
// bloom or a bud); a vector stand-in draws when its switch in `HomeArt` is
// off. Every object is one VoiceOver element with a native twin.

/// One switch per asset: the painted master in `World.xcassets`, or the
/// clean vector stand-in.
enum HomeArt {
    static let paintedJar = true
    static let paintedLantern = true
    static let paintedPot = true
    /// The painted "collect push" pose is not made yet. The pofu-paws-*
    /// masters are whole-body rig poses (a seed held at the chest), not
    /// cheek-press layers, and the vector stand-in paws read as a dark blob
    /// on his face, so the cheek squeeze plays alone. Flip when the pose
    /// lands.
    static let paintedPaws = false
}

/// Night, for the objects that sit over the graded world: a gentle code
/// grade (UI system v2: "code grade").
private struct NightGrade: ViewModifier {
    let isNight: Bool

    func body(content: Content) -> some View {
        content
            .brightness(isNight ? -0.2 : 0)
            .saturation(isNight ? 0.9 : 1)
    }
}

// MARK: - Seed jar

/// The painted jar with its fill: a wavy-topped heap of seeds revealed
/// bottom-up inside the jar's window.
struct SeedJarArt: View {
    let fraction: Double

    var body: some View {
        ZStack {
            if HomeArt.paintedJar {
                Image("ui-jar-empty", bundle: .module)
                    .resizable()
                    .scaledToFit()
            } else {
                VectorJar()
            }
            JarWindowFill(fraction: fraction)
        }
        .frame(width: HomeObjectsLayout.jarSize.width, height: HomeObjectsLayout.jarSize.height)
    }
}

/// A flat jar for when the painted master is switched off.
private struct VectorJar: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(PofuPrimitive.cream300.rgb.color)
                .padding(.top, 20)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(PofuPrimitive.peach300.rgb.color)
                .frame(height: 24)
                .frame(maxHeight: .infinity, alignment: .top)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(PofuPrimitive.peach400.rgb.color.opacity(0.55))
                .padding(.horizontal, 9)
                .padding(.top, 38)
                .padding(.bottom, 10)
        }
    }
}

private struct JarWindowFill: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let window = CGRect(x: w * 0.14, y: h * 0.49, width: w * 0.72, height: h * 0.35)
            SeedHeap(level: fraction)
                .frame(width: window.width, height: window.height)
                .clipShape(RoundedRectangle(cornerRadius: window.height * 0.42, style: .continuous))
                .position(x: window.midX, y: window.midY)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Seeds heaped to `level` (`0...1`): a honey fill with seed marks, masked
/// by a gently wavy top.
private struct SeedHeap: View {
    let level: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [PofuPrimitive.honey400.rgb.color, PofuPrimitive.peach600.rgb.color],
                    startPoint: .top,
                    endPoint: .bottom
                )
                ForEach(0..<14, id: \.self) { index in
                    seed(index, in: proxy.size)
                }
            }
            .mask { WavyTop(level: level) }
        }
    }
}

extension SeedHeap {
    /// One seed mark at a fixed, scattered place.
    fileprivate func seed(_ index: Int, in size: CGSize) -> some View {
        let fx = 0.08 + 0.84 * Double(index * 37 % 100) / 100
        let fy = 0.15 + 0.8 * Double(index * 59 % 100) / 100
        let tilt = Double(index * 47 % 90) - 45
        return SeedGlyph()
            .fill(PofuPrimitive.peach800.rgb.color.opacity(0.55))
            .frame(width: 5, height: 8)
            .rotationEffect(.degrees(tilt))
            .position(x: size.width * fx, y: size.height * fy)
    }
}

/// A fill from the bottom up to `level`, with a soft wave on top while the
/// jar is neither empty nor full.
private struct WavyTop: Shape {
    var level: Double

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clamped = min(max(level, 0), 1)
        var path = Path()
        guard clamped > 0 else { return path }
        let top = rect.maxY - rect.height * clamped
        let amplitude = (clamped < 1 ? 1.6 : 0)
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: top))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: top),
            control: CGPoint(x: rect.minX + rect.width * 0.25, y: top - amplitude * 2)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: top),
            control: CGPoint(x: rect.minX + rect.width * 0.75, y: top + amplitude * 2)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The jar's native twin: the live count on a world tag (glass or paper).
struct JarTag: View {
    let count: Int

    @ScaledMetric(relativeTo: .subheadline) private var height: CGFloat = 26

    var body: some View {
        HStack(spacing: 4) {
            SeedIcon(size: 13)
            Text(count, format: .number)
                .font(.system(.subheadline, design: .rounded, weight: .heavy).monospacedDigit())
        }
        .foregroundStyle(PofuColor.textPrimary)
        .padding(.horizontal, 10)
        .frame(minHeight: height)
        // Past the first accessibility size the tag hands the number to the
        // glance (the caller hides it).
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .pofuChrome(.worldTag)
    }
}

/// The jar with its tag and, while seeds wait, the "Topla · N" action. The
/// count and fill roll up with the collect moment's counter.
struct HomeJar: View {
    let jar: Int
    let uncollected: Int
    let canCollect: Bool
    let isNight: Bool
    let showsTag: Bool
    /// The jar's centre and the screen's width and safe-area insets, in
    /// points: the action keeps the gutter plus the inset from both edges.
    let jarX: Double
    let screenWidth: Double
    let leadingInset: Double
    let trailingInset: Double
    let home: WorldHomeModel
    let collect: @MainActor () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The action's measured width (it grows with the seed count).
    @State private var actionWidth = 140.0

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: home.collect == nil || home.frozenOffset != nil)) { context in
            let moment = home.collect?.moment
            let time = home.collectTime(at: context.date) ?? 0
            let count = moment?.counter(at: time) ?? jar
            let pop = moment?.pillScale(at: time) ?? 1
            content(count: count, pop: pop)
        }
    }

    private func content(count: Int, pop: Double) -> some View {
        let fraction = SeedJarFill.fraction(seeds: count, capacity: Int(home.timing.jarCapacity))
        return jarArt(count: count, fraction: fraction)
            .scaleEffect(CGFloat(pop))
            .modifier(NightGrade(isNight: isNight))
            .overlay(alignment: .top) {
                VStack(spacing: PofuSpacing.xs) {
                    if showsTag {
                        JarTag(count: count)
                            .accessibilityHidden(true)
                    }
                    if canCollect, home.collect == nil {
                        CollectAction(seeds: uncollected, action: collect)
                            .onGeometryChange(for: Double.self) { Double($0.size.width) } action: { actionWidth = $0 }
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .fixedSize()
                .offset(
                    x: HomeObjectsLayout.collectShift(
                        jarX: jarX,
                        actionWidth: actionWidth,
                        screenWidth: screenWidth,
                        leadingInset: leadingInset,
                        trailingInset: trailingInset
                    ),
                    y: HomeObjectsLayout.jarSize.height + 4
                )
            }
    }

    @ViewBuilder
    private func jarArt(count: Int, fraction: Double) -> some View {
        let art = SeedJarArt(fraction: fraction)
            .animation(PofuMotion.respecting(reduceMotion, .smooth(duration: home.timing.jarFill)), value: fraction)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: WorldStrings.jarLabel))
            .accessibilityValue(Text(verbatim: WorldStrings.jarValue(count)))
        if canCollect {
            // Tapping the jar is the shortcut for the visible Collect.
            Button(action: collect) { art }
                .buttonStyle(.plain)
                .accessibilityHint(Text(verbatim: WorldStrings.jarHint))
        } else {
            art
        }
    }
}

/// "Topla · 12": the one primary over the world, pinned to the jar.
struct CollectAction: View {
    let seeds: Int
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PofuSpacing.s) {
                SeedGlyph()
                    .frame(width: 10, height: 16)
                    .rotationEffect(.degrees(18))
                    .accessibilityHidden(true)
                Text(verbatim: WorldStrings.collectAction(seeds))
                    .font(PofuFont.headline.monospacedDigit())
            }
            .foregroundStyle(PofuKitPalette.day.ink)
            .frame(minHeight: PofuSize.minimumTouch)
            .padding(.horizontal, PofuSpacing.xs)
        }
        .pofuActionStyle(.primary)
        .accessibilityLabel(Text(verbatim: WorldStrings.collectLabel(seeds)))
    }
}

// MARK: - Calm lantern

/// The calm lantern: glow follows calm, 15 % at ×1.0 to 100 % at ×2.0. The
/// painted lantern has only its unlit master; the light is drawn over its
/// paper and as a pool around it.
struct CalmLanternView: View {
    let calm: Double
    let isGrowing: Bool
    let isFull: Bool
    let isNight: Bool
    let timing: HomeTiming

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var glow: Double {
        CalmLantern.glow(calm: calm)
    }

    private var width: CGFloat {
        HomeArt.paintedLantern ? 50 : 30
    }

    var body: some View {
        let height = CGFloat(HomeObjectsLayout.lanternHeight)
        ZStack {
            // The pool of light, larger and warmer as calm grows.
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [PofuPrimitive.honey300.rgb.color.opacity(0.85 * glow), PofuPrimitive.honey300.rgb.color.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 64
                    )
                )
                .frame(width: 130, height: 130)
                .offset(x: -width * 0.12, y: -height * 0.08)
                .allowsHitTesting(false)
            lantern(height: height)
        }
        .frame(width: width, height: height)
        .animation(PofuMotion.respecting(reduceMotion, .easeInOut(duration: timing.lanternGlow)), value: glow)
        .modifier(NightGrade(isNight: isNight && glow < 0.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: WorldStrings.lanternLabel))
        .accessibilityValue(Text(verbatim: WorldStrings.calmLabel(calm, growing: isGrowing, full: isFull)))
    }

    @ViewBuilder
    private func lantern(height: CGFloat) -> some View {
        if HomeArt.paintedLantern {
            Image("ui-lantern-off", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .overlay {
                    // The paper lit from inside: the bulb sits at the left
                    // of the post, a little above its middle.
                    GeometryReader { proxy in
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.9 * glow), PofuPrimitive.honey300.rgb.color.opacity(0.75 * glow), PofuPrimitive.honey400.rgb.color.opacity(0)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: proxy.size.width * 0.34
                                )
                            )
                            .frame(width: proxy.size.width * 0.74, height: proxy.size.height * 0.34)
                            .position(x: proxy.size.width * 0.36, y: proxy.size.height * 0.42)
                    }
                    .allowsHitTesting(false)
                }
        } else {
            VectorLantern(glow: glow)
                .frame(width: width, height: height)
        }
    }
}

private struct VectorLantern: View {
    let glow: Double

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(PofuPrimitive.peach400.rgb.color)
                .frame(width: 4, height: 10)
            Capsule(style: .continuous)
                .fill(PofuPrimitive.cream200.rgb.color.mix(with: PofuPrimitive.honey300.rgb.color, by: glow))
                .frame(width: 22, height: 28)
            Capsule()
                .fill(PofuPrimitive.peach400.rgb.color)
                .frame(width: 5, height: 58)
        }
    }
}

// MARK: - Skip pots

/// Today's skips on the island's lip: one clay pot per reach with a
/// sunflower bloom (skipped) or a closed bud (opened).
struct SkipPotsView: View {
    let pots: SkipPots
    let today: TodaySummary
    let timing: HomeTiming
    let isNight: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The "I resisted" payoff playing now, if one is (experience v1
    /// section 3.4): the newest pots bloom left to right as one cascade.
    @Environment(\.resistPayoff) private var payoff

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(pots.pots.indices, id: \.self) { index in
                PotView(pot: pots.pots[index], asleep: pots.isAsleep, badge: pots.isClustered)
                    .modifier(PayoffBloom(run: payoff, order: bloomOrder(of: index), reduceMotion: reduceMotion))
                    .transition(.scale(scale: 0.3, anchor: .bottom).combined(with: .opacity))
            }
        }
        .animation(PofuMotion.respecting(reduceMotion, .spring(duration: timing.potBloom, bounce: 0.35)), value: pots)
        .modifier(NightGrade(isNight: isNight))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: WorldStrings.potsLabel))
        .accessibilityValue(Text(verbatim: WorldStrings.todayLine(today)))
    }
}

extension SkipPotsView {
    /// The place of pot `index` in the payoff's cascade: the newest pots
    /// bloom, the leftmost of them first. `nil` for a pot that does not.
    fileprivate func bloomOrder(of index: Int) -> Int? {
        guard let payoff else { return nil }
        let count = min(payoff.payoff.potCount, pots.pots.count)
        let first = pots.pots.count - count
        return index >= first ? index - first : nil
    }
}

/// Pops a pot on the payoff's clock: a little swell and glow, then rest.
private struct PayoffBloom: ViewModifier {
    let run: ResistPayoffRun?
    let order: Int?
    let reduceMotion: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if let run, let order {
            TimelineView(.animation(paused: run.isOver(at: Date()))) { context in
                let progress = run.payoff.bloomProgress(of: order, at: run.time(at: context.date))
                let pulse = sin(progress * .pi)
                content
                    .scaleEffect(reduceMotion ? 1 : 1 + 0.3 * pulse, anchor: .bottom)
                    .brightness(0.08 * pulse)
            }
        } else {
            content
        }
    }
}

private struct PotView: View {
    let pot: SkipPots.Pot
    let asleep: Bool
    let badge: Bool

    var body: some View {
        VStack(spacing: -10) {
            heads
            potBody
        }
    }

    private var heads: some View {
        let blooms = min(pot.blooms, 2)
        let buds = min(pot.buds, 2 - blooms)
        return HStack(alignment: .bottom, spacing: 0) {
            ForEach(0..<blooms, id: \.self) { _ in
                Bloom(folded: asleep)
            }
            ForEach(0..<buds, id: \.self) { _ in
                Bud()
            }
        }
        .frame(height: 24, alignment: .bottom)
    }

    private var potBody: some View {
        Group {
            if HomeArt.paintedPot {
                Image("ui-pot-empty", bundle: .module)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(PofuPrimitive.peach400.rgb.color)
            }
        }
        .frame(width: HomeObjectsLayout.potWidth, height: HomeObjectsLayout.potWidth)
        .overlay(alignment: .bottom) {
            if badge {
                Text(pot.reaches, format: .number)
                    .font(.system(size: 10, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(PofuCraftedBadge.ink)
                    .padding(.horizontal, 4)
                    .background(PofuCraftedBadge.fill, in: Capsule())
                    .offset(y: 2)
            }
        }
    }
}

private enum PofuCraftedBadge {
    static var ink: Color { PofuPrimitive.ink900.rgb.color }
    static var fill: Color { PofuPrimitive.cream100.rgb.color.opacity(0.92) }
}

/// A sunflower bloom: eight honey petals round a brown heart on a stem. At
/// night the head folds down.
private struct Bloom: View {
    let folded: Bool

    var body: some View {
        VStack(spacing: -2) {
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(PofuPrimitive.honey400.rgb.color)
                        .frame(width: 5, height: 9)
                        .offset(y: -6)
                        .rotationEffect(.degrees(Double(index) * 45))
                }
                Circle()
                    .fill(PofuPrimitive.peach800.rgb.color)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 20, height: 20)
            .rotationEffect(.degrees(folded ? 70 : 0), anchor: .bottom)
            Capsule()
                .fill(PofuPrimitive.meadow400.rgb.color)
                .frame(width: 3, height: 7)
        }
    }
}

/// A closed green bud: shape, not only colour, says "opened".
private struct Bud: View {
    var body: some View {
        VStack(spacing: -1) {
            Capsule(style: .continuous)
                .fill(PofuPrimitive.meadow400.rgb.color)
                .frame(width: 9, height: 13)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(PofuPrimitive.meadow700.rgb.color.opacity(0.5))
                        .frame(width: 3, height: 6)
                }
            Capsule()
                .fill(PofuPrimitive.meadow400.rgb.color)
                .frame(width: 3, height: 6)
        }
    }
}

// MARK: - Paws

/// Pofu's paws pressed to his cheeks while he empties them into the jar
/// (the painted "collect push" pose is not made yet; two cream paws are the
/// stand-in, with a switch when it lands).
struct CheekPaws: View {
    let artWidth: Double
    let left: CGPoint
    let right: CGPoint

    var body: some View {
        ZStack {
            paw.position(left)
            paw.position(right)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var paw: some View {
        Ellipse()
            .fill(PofuPrimitive.cream100.rgb.color)
            .overlay { Ellipse().strokeBorder(PofuPrimitive.peach400.rgb.color, lineWidth: 1.2) }
            .frame(width: artWidth * 0.11, height: artWidth * 0.09)
            .shadow(color: PofuColor.shadow.opacity(0.2), radius: 1.5, y: 1)
    }
}

// MARK: - Glance

/// The peeking Today line: "Today 3/4 · 15 min". Where the seed tag hides
/// at the largest text sizes, the glance carries the jar's number.
struct HomeGlance: View {
    let today: TodaySummary
    let seedsInGlance: Int?
    var nextGoal: String?
    let onOpen: (@MainActor () -> Void)?

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let glance = HStack(spacing: PofuSpacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: WorldStrings.glance(today))
                    .font(PofuFont.subheadline)
                    .foregroundStyle(PofuColor.textPrimary)
                if let seedsInGlance {
                    Text(verbatim: WorldStrings.seeds(seedsInGlance))
                        .font(PofuFont.footnote)
                        .foregroundStyle(PofuColor.textSecondary)
                }
                if let nextGoal {
                    Text(verbatim: nextGoal)
                        .font(PofuFont.footnote)
                        .foregroundStyle(PofuColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            if !typeSize.isAccessibilitySize {
                GuardedSteps(today: today)
            }
            if onOpen != nil {
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PofuColor.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, PofuSpacing.l)
        .padding(.vertical, PofuSpacing.xs)
        .frame(minHeight: PofuSize.minimumTouch, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .pofuChrome(.glance)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(WorldStrings.todayLine(today)). \(WorldStrings.guardedLabel(today))\(nextGoal.map { ". \($0)" } ?? "")"))

        if let onOpen {
            Button(action: onOpen) { glance }
                .buttonStyle(.plain)
                .accessibilityHint(Text(verbatim: WorldStrings.openToday))
        } else {
            glance
        }
    }
}
#endif
