#if os(iOS)
import PofuTuning
import SpriteKit
import SwiftUI

/// Pofu's sunflower garden: the SpriteKit scene full screen, the crafted
/// HUD (round plate, seed plate) with a native glass pause, and the
/// crafted round and set cards. Entered on purpose only (A23): the caller
/// presents it from an island's "Play" door or the debug entry.
public struct GardenGameView: View {
    @State private var model: GardenGameModel
    /// The tuned feel; pass the Ayar store's values to tune it live.
    private let tuning: TuningValues.Garden
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(model: GardenGameModel, tuning: TuningValues.Garden = TuningValues.defaults.garden) {
        _model = State(initialValue: model)
        self.tuning = tuning
    }

    /// A set of rounds. `onRoundEnd` credits each finished round's seeds;
    /// `onFinish` gets the set's seeds when the player says "Enough for
    /// today".
    public init(
        roundsAvailable: Int = GardenSet.roundsPerSet,
        tuning: TuningValues.Garden = TuningValues.defaults.garden,
        sound: (any GameSoundPlaying)? = nil,
        onRoundEnd: @escaping (GardenRoundResult) -> Void = { _ in },
        onFinish: @escaping (Int) -> Void
    ) {
        let model = GardenGameModel(roundsAvailable: roundsAvailable, onRoundEnd: onRoundEnd, onFinish: onFinish)
        if let sound { model.sound = sound }
        _model = State(initialValue: model)
        self.tuning = tuning
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                sceneLayer
                    .ignoresSafeArea()
                hud
                overlay
            }
            .onAppear {
                model.setSafeArea(top: proxy.safeAreaInsets.top, bottom: proxy.safeAreaInsets.bottom)
                model.setReduceMotion(reduceMotion)
                model.setFeel(tuning)
            }
            .onChange(of: tuning) { _, values in
                model.setFeel(values)
            }
            .onChange(of: proxy.safeAreaInsets) { _, insets in
                model.setSafeArea(top: insets.top, bottom: insets.bottom)
            }
            .onChange(of: reduceMotion) { _, value in
                model.setReduceMotion(value)
            }
        }
        .background(Color(red: 0.97, green: 0.87, blue: 0.68).ignoresSafeArea())
        .sensoryFeedback(.success, trigger: model.cards)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.45, bounce: 0.3), value: model.phase)
    }

    @ViewBuilder private var sceneLayer: some View {
        ZStack {
            GardenSpriteView(model: model)
                .accessibilityElement()
                .accessibilityLabel(Text(verbatim: GardenStrings.boardAccessibility))
            if let frame = model.frozenFrame {
                Image(uiImage: frame)
                    .resizable()
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: HUD

    private var hud: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                model.pause()
            } label: {
                Image(systemName: "pause.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(GardenInk.ink)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel(Text(verbatim: GardenStrings.pause))
            Spacer(minLength: 0)
            RoundPlate(number: model.roundNumber, total: model.gardenSet.length, planted: model.piecesPerRound - model.piecesLeft, bag: model.piecesPerRound)
            Spacer(minLength: 0)
            SeedPlate(seeds: model.seeds)
        }
        .padding(.horizontal, 16)
        .frame(height: GardenLayout.hudHeight)
        .opacity(model.phase == .playing || model.phase == .paused ? 1 : 0)
    }

    // MARK: Cards

    @ViewBuilder private var overlay: some View {
        switch model.phase {
        case .playing:
            EmptyView()
        case .paused:
            ZStack {
                GardenInk.scrim.opacity(0.2).ignoresSafeArea()
                PausePanel(resume: { model.resume() }, finish: { model.finish() })
            }
            .transition(.opacity)
        case .roundEnd(let result):
            ZStack {
                GardenInk.scrim.opacity(0.28).ignoresSafeArea()
                RoundCard(
                    kicker: GardenStrings.roundKicker(model.gardenSet.results.count, of: model.gardenSet.length),
                    title: GardenStrings.roundTitle(result),
                    seeds: result.seeds,
                    detail: GardenStrings.rowsBloomed(result.lines),
                    stamps: [],
                    primary: (GardenStrings.nextRound, { model.nextRound() }),
                    secondary: (GardenStrings.enoughForToday, { model.finish() })
                )
                .frame(maxHeight: .infinity)
            }
            .transition(cardTransition)
        case .setEnd:
            ZStack {
                GardenInk.scrim.opacity(0.32).ignoresSafeArea()
                RoundCard(
                    kicker: GardenStrings.setKicker,
                    title: GardenStrings.setTitle,
                    seeds: model.gardenSet.seedsTotal,
                    detail: GardenStrings.setDetail,
                    stamps: model.gardenSet.results.map(\.seeds),
                    primary: (GardenStrings.enoughForToday, { model.finish() }),
                    secondary: model.gardenSet.roundsLeftAfterSet > 0
                        ? (GardenStrings.anotherSet(min(GardenSet.roundsPerSet, model.gardenSet.roundsLeftAfterSet)), { model.anotherSet() })
                        : nil
                )
                .frame(maxHeight: .infinity)
            }
            .transition(cardTransition)
        }
    }

    private var cardTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.88))
    }
}

/// Hosts the scene in an `SKView` (rather than `SpriteView`) to set the
/// 120 Hz frame rate and sibling-order rendering, and to hand the view to
/// the model for pausing and snapshots.
struct GardenSpriteView: UIViewRepresentable {
    let model: GardenGameModel

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.preferredFramesPerSecond = 120
        view.ignoresSiblingOrder = true
        view.isMultipleTouchEnabled = false
        view.shouldCullNonVisibleNodes = true
        view.presentScene(model.scene)
        model.attach(view)
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {}
}

/// "Tur 2 / 5", the set's pips, and a thin line for the round's bag.
struct RoundPlate: View {
    let number: Int
    let total: Int
    let planted: Int
    let bag: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Text(verbatim: GardenStrings.round(number, of: total))
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(GardenInk.ink)
                HStack(spacing: 4) {
                    ForEach(0..<max(1, total), id: \.self) { index in
                        Circle()
                            .fill(index < number - 1 ? GardenInk.ink.opacity(0.75) : .clear)
                            .overlay {
                                Circle().strokeBorder(GardenInk.ink.opacity(index == number - 1 ? 0.9 : 0.35), lineWidth: index == number - 1 ? 2 : 1.2)
                            }
                            .frame(width: 8, height: 8)
                    }
                }
            }
            GeometryReader { proxy in
                Capsule()
                    .fill(GardenInk.ink.opacity(0.12))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(GardenInk.stitch.opacity(0.8))
                            .frame(width: proxy.size.width * CGFloat(min(planted, bag)) / CGFloat(max(1, bag)))
                    }
            }
            .frame(height: 3)
            .animation(.spring(duration: 0.3), value: planted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .fixedSize()
        .background(PaperSurface(shape: Capsule(style: .continuous), stitchInset: 3.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: GardenStrings.round(number, of: total)))
        .accessibilityAddTraits(.isHeader)
    }
}

/// The round's seeds so far, on paper, counting up with Pofu's gulps.
struct SeedPlate: View {
    let seeds: Int

    var body: some View {
        HStack(spacing: 6) {
            SeedGlyph()
                .frame(width: 13, height: 20)
            Text(verbatim: "+\(seeds)")
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(GardenInk.ink)
                .contentTransition(.numericText(value: Double(seeds)))
                .animation(.spring(duration: 0.4, bounce: 0.5), value: seeds)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(PaperSurface(shape: Capsule(style: .continuous), stitchInset: 3.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: GardenStrings.seedsThisRound(seeds)))
    }
}

/// The native pause: glass, because pausing is the device talking
/// (ui-system-v2 §2.3: "pause in an island game stays glass").
struct PausePanel: View {
    let resume: () -> Void
    let finish: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(verbatim: GardenStrings.paused)
                .font(.system(.title2, design: .rounded, weight: .bold))
            Button(action: resume) {
                Text(verbatim: GardenStrings.resume)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            Button(action: finish) {
                Text(verbatim: GardenStrings.enoughForToday)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
        .padding(24)
        .frame(width: 300)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .frame(maxHeight: .infinity)
    }
}

/// A round's or a set's card: Pofu peeking over warm paper with his
/// cheeks as full as the yield, a feeling line, "+3 to your cheeks"
/// counting up, and one primary action.
struct RoundCard: View {
    let kicker: String
    let title: String
    let seeds: Int
    let detail: String
    /// Each round's seeds, on the set's card.
    let stamps: [Int]
    let primary: (String, () -> Void)
    let secondary: (String, () -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = 0

    var body: some View {
        VStack(spacing: 10) {
            Text(verbatim: kicker)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(GardenInk.ink.opacity(0.6))
            Text(verbatim: title)
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(GardenInk.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                SeedGlyph()
                    .frame(width: 17, height: 26)
                Text(verbatim: GardenStrings.toCheeks(shown))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(GardenInk.ink)
                    .contentTransition(.numericText(value: Double(shown)))
            }
            .padding(.top, 2)
            if !stamps.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(stamps.enumerated()), id: \.offset) { _, value in
                        ZStack {
                            BloomImage(small: value < 4)
                                .opacity(0.9)
                            Text(verbatim: "+\(value)")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(GardenInk.ink)
                                .padding(.horizontal, 5)
                                .background(Capsule().fill(GardenInk.paperTop.opacity(0.92)))
                                .offset(y: 15)
                        }
                        .frame(width: 44, height: 44)
                    }
                }
                .padding(.vertical, 4)
            }
            Text(verbatim: detail)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(GardenInk.ink.opacity(0.75))
                .multilineTextAlignment(.center)
            Button(action: primary.1) {
                Text(verbatim: primary.0)
            }
            .buttonStyle(ClayButtonStyle())
            .padding(.top, 8)
            if let secondary {
                Button(action: secondary.1) {
                    Text(verbatim: secondary.0)
                }
                .buttonStyle(PaperTextButtonStyle())
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 72)
        .padding(.bottom, 22)
        .frame(width: 330)
        .background(PaperSurface(shape: RoundedRectangle(cornerRadius: 28, style: .continuous), stitchInset: 8))
        .overlay(alignment: .top) {
            pofu
                .offset(y: -58)
        }
        .overlay(alignment: .topTrailing) {
            BloomImage()
                .frame(width: 58, height: 58)
                .rotationEffect(.degrees(-14))
                .offset(x: 12, y: -14)
        }
        .padding(.top, 58)
        .accessibilityElement(children: .contain)
        .task {
            if reduceMotion {
                shown = seeds
                return
            }
            try? await Task.sleep(for: .milliseconds(380))
            withAnimation(.spring(duration: 0.6, bounce: 0.4)) {
                shown = seeds
            }
        }
    }

    /// Pofu, wider with each seed above the base: his cheeks show the yield.
    /// Pofu with his cheeks as full as the yield: the painted puff pose
    /// fades in over his base as the count lands.
    @ViewBuilder private var pofu: some View {
        if let image = GardenTextures.image(.pofu) {
            let extra = Double(max(0, min(shown, SeedYield.maximum) - SeedYield.base))
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                if let puff = GardenTextures.image(.pofuPuff) {
                    Image(uiImage: puff)
                        .resizable()
                        .scaledToFit()
                        .opacity(min(1, extra / 3))
                }
            }
            .frame(height: 118)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: GardenStrings.cheeksAccessibility(seeds)))
        }
    }
}
#endif
