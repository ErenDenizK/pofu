#if os(iOS)
import SpriteKit
import SwiftUI

/// The flow game: the SpriteKit scene full screen, a SwiftUI layer on top
/// that reads the taps (so each tile is also a VoiceOver element), a small
/// crafted HUD (leave, board pips, targets wet), undo and hint in the bottom
/// corners, and the one card at the end. Entered on purpose only (A23): the
/// island presents it as a full-screen cover when a day can advance it.
public struct FlowGameView: View {
    @State private var model: FlowGameModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    public init(model: FlowGameModel) {
        _model = State(initialValue: model)
    }

    /// A round of `round`'s boards. `onLeave` gets the round to save when
    /// the player leaves mid-way; `onFinish` fires on "Done".
    public init(
        round: FlowRound,
        skin: FlowSkin = .water,
        sound: (any FlowSoundPlaying)? = nil,
        onLeave: @escaping (FlowRound) -> Void = { _ in },
        onFinish: @escaping () -> Void
    ) {
        let model = FlowGameModel(round: round, skin: skin, onLeave: onLeave, onFinish: onFinish)
        if let sound { model.sound = sound }
        _model = State(initialValue: model)
    }

    /// The hook Çağlayan's island calls to open a round for `stage` (1...4),
    /// like the garden for Koke: a fresh round, or `resuming` a saved one.
    /// Nil when the stage has no boards.
    public static func caglayan(
        stage: Int,
        resuming saved: FlowRound? = nil,
        sound: (any FlowSoundPlaying)? = nil,
        onLeave: @escaping (FlowRound) -> Void = { _ in },
        onFinish: @escaping () -> Void
    ) -> FlowGameView? {
        guard let round = saved ?? FlowLibrary.round(island: FlowLibrary.caglayan, stage: stage) else { return nil }
        return FlowGameView(
            round: round,
            skin: FlowLibrary.skin(island: FlowLibrary.caglayan, stage: stage),
            sound: sound,
            onLeave: onLeave,
            onFinish: onFinish
        )
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                sceneLayer
                    .ignoresSafeArea()
                tileLayer(safeTop: proxy.safeAreaInsets.top, safeBottom: proxy.safeAreaInsets.bottom)
                    .ignoresSafeArea()
                hud
                captionLayer(safeTop: proxy.safeAreaInsets.top, safeBottom: proxy.safeAreaInsets.bottom)
                controls
            }
            .onAppear {
                model.setSafeArea(top: proxy.safeAreaInsets.top, bottom: proxy.safeAreaInsets.bottom)
                model.setReduceMotion(reduceMotion)
            }
            .onChange(of: proxy.safeAreaInsets) { _, insets in
                model.setSafeArea(top: insets.top, bottom: insets.bottom)
            }
            .onChange(of: reduceMotion) { _, value in
                model.setReduceMotion(value)
            }
            .onChange(of: scenePhase) { _, value in
                model.setInForeground(value == .active)
            }
        }
        .background(Color(red: 0.90, green: 0.94, blue: 0.90).ignoresSafeArea())
        .sensoryFeedback(.success, trigger: model.solvedCount)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0.25), value: model.phase)
        .animation(.easeInOut(duration: 0.25), value: model.hint)
    }

    @ViewBuilder private var sceneLayer: some View {
        ZStack {
            FlowSpriteView(model: model)
                .accessibilityHidden(true)
            if let frame = model.frozenFrame {
                Image(uiImage: frame)
                    .resizable()
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: Tiles

    /// One invisible button per stone, over the scene, in the scene's own
    /// coordinates. Rocks and grass are decoration and stay out of the
    /// VoiceOver order.
    private func tileLayer(safeTop: CGFloat, safeBottom: CGFloat) -> some View {
        GeometryReader { geo in
            let board = model.board
            let layout = FlowLayout(size: geo.size, safeTop: safeTop, safeBottom: safeBottom, columns: board.columns, rows: board.rows)
            ZStack(alignment: .topLeading) {
                ForEach(touchable(board), id: \.self) { cell in
                    let rect = layout.rect(of: cell)
                    let tile = board[cell] ?? FlowTile(kind: .grass)
                    Button {
                        model.tap(cell)
                    } label: {
                        Color.clear
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: rect.width, height: rect.height)
                    .offset(x: rect.minX, y: rect.minY)
                    .accessibilityLabel(Text(verbatim: FlowStrings.tile(tile, wet: model.wet.contains(cell), cell: cell)))
                    .accessibilityAddTraits(tile.isFixed ? [] : .isButton)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(verbatim: FlowStrings.boardAccessibility))
            .allowsHitTesting(model.phase == .playing)
        }
    }

    private func touchable(_ board: FlowBoard) -> [FlowCell] {
        board.allCells.filter { cell in
            guard let kind = board[cell]?.kind else { return false }
            return kind != .rock && kind != .grass
        }
    }

    // MARK: HUD

    private var hud: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                model.leave()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(GardenInk.ink)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .background(PaperSurface(shape: Circle(), stitchInset: 4))
            .accessibilityLabel(Text(verbatim: FlowStrings.leave))
            Spacer(minLength: 0)
            boardPlate
            Spacer(minLength: 0)
            targetsPlate
        }
        .padding(.horizontal, 16)
        .frame(height: FlowLayout.hudHeight)
    }

    private var boardPlate: some View {
        let total = model.round.boardCount
        return HStack(spacing: 8) {
            Text(verbatim: FlowStrings.board(model.boardNumber, of: total))
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(GardenInk.ink)
            HStack(spacing: 4) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index < model.boardsSolved ? GardenInk.ink.opacity(0.75) : .clear)
                        .overlay {
                            Circle().strokeBorder(GardenInk.ink.opacity(index == model.boardNumber - 1 ? 0.9 : 0.35), lineWidth: index == model.boardNumber - 1 ? 2 : 1.2)
                        }
                        .frame(width: 9, height: 9)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .fixedSize()
        .background(PaperSurface(shape: Capsule(style: .continuous), stitchInset: 3.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: FlowStrings.board(model.boardNumber, of: total)))
        .accessibilityAddTraits(.isHeader)
    }

    private var targetsPlate: some View {
        HStack(spacing: 6) {
            // The drop turns into a check once every target is wet.
            Image(systemName: model.isBoardSolved ? "checkmark.circle.fill" : "drop.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(red: 0.25, green: 0.58, blue: 0.86))
                .contentTransition(.symbolEffect(.replace))
            Text(verbatim: "\(model.targetsWet)/\(model.targetCount)")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(GardenInk.ink)
                .contentTransition(.numericText(value: Double(model.targetsWet)))
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(PaperSurface(shape: Capsule(style: .continuous), stitchInset: 3.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: FlowStrings.targetsAccessibility(model.targetsWet, of: model.targetCount)))
    }

    // MARK: Controls and the card

    @ViewBuilder private var controls: some View {
        VStack {
            Spacer(minLength: 0)
            if model.phase == .finished {
                VStack(spacing: 6) {
                    Text(verbatim: FlowStrings.doneTitle)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(GardenInk.ink)
                    Button {
                        model.finish()
                    } label: {
                        Text(verbatim: FlowStrings.done)
                    }
                    .buttonStyle(ClayButtonStyle())
                }
                .frame(height: FlowLayout.controlsHeight)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                HStack(alignment: .center) {
                    roundButton(symbol: "arrow.uturn.backward", label: FlowStrings.undo, enabled: model.canUndo) { model.undo() }
                    Spacer(minLength: 8)
                    roundButton(symbol: "lightbulb.fill", label: FlowStrings.hint, enabled: model.phase == .playing) { model.requestHint() }
                }
                .padding(.horizontal, 16)
                .frame(height: FlowLayout.controlsHeight)
            }
        }
    }

    /// What the round says, once and small: the solve while the water pours,
    /// or the hint. It sits in the clear band between the HUD and the
    /// spring's lip, above the board, so it never covers the play area.
    private func captionLayer(safeTop: CGFloat, safeBottom: CGFloat) -> some View {
        GeometryReader { geo in
            let layout = FlowLayout(size: geo.size, safeTop: safeTop, safeBottom: safeBottom, columns: model.board.columns, rows: model.board.rows)
            let text: String? = model.phase == .pouring
                ? (model.round.isLastBoard ? FlowStrings.doneTitle : FlowStrings.boardDone)
                : (model.hint != nil ? FlowStrings.hintCaption(helper: model.helperName) : nil)
            let bandTop = safeTop + FlowLayout.hudHeight
            let bandBottom = layout.lip.minY
            // A board that fills the height leaves no band: the caption then
            // keeps the controls row, below the pool.
            let fits = bandBottom - bandTop >= 40
            let y = fits ? bandBottom - 22 : geo.size.height - safeBottom - FlowLayout.controlsHeight / 2
            if let text {
                caption(text)
                    .frame(maxWidth: .infinity)
                    .position(x: geo.size.width / 2, y: y)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }

    private func caption(_ text: String) -> some View {
        Text(verbatim: text)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(GardenInk.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(PaperSurface(shape: Capsule(style: .continuous), stitchInset: 3))
            .transition(.opacity)
    }

    private func roundButton(symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(GardenInk.ink)
                .frame(width: 56, height: 56)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(PaperSurface(shape: Circle(), stitchInset: 5))
        .opacity(enabled ? 1 : 0.4)
        .disabled(!enabled)
        .accessibilityLabel(Text(verbatim: label))
    }
}


struct FlowSpriteView: UIViewRepresentable {
    let model: FlowGameModel

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        // 30 Hz while water flows or a stone turns; the model pauses the
        // view entirely (0 Hz) once the scene settles.
        view.preferredFramesPerSecond = 30
        view.ignoresSiblingOrder = true
        view.isMultipleTouchEnabled = false
        view.isUserInteractionEnabled = false
        view.presentScene(model.scene)
        model.attach(view)
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {}
}
#endif
