#if os(iOS)
import SpriteKit
import UIKit

/// One cell of the displayed board.
@MainActor
final class FlowTileNode: SKNode {
    let cell: FlowCell
    /// The tile the node shows (or is turning to).
    var shown: FlowTile
    let stone = SKSpriteNode()
    var crop: SKCropNode?
    var overlay: SKSpriteNode?

    init(cell: FlowCell, tile: FlowTile) {
        self.cell = cell
        shown = tile
        super.init()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("FlowTileNode is made in code")
    }
}

/// The flow game's SpriteKit scene: stone tiles code-drawn on a cliff, water
/// as a soft fill along each wet channel, the wheel turning while wet. It
/// does not read touches (the SwiftUI shell does, so every tile is also a
/// VoiceOver element); it only draws what the model says.
///
/// Battery: the scene reports when it has nothing left to animate
/// (`onSettled`) so the shell can pause the SKView at 0 Hz, and asks to be
/// woken (`onWake`) before it animates a turn, a pour or a wheel spin.
@MainActor
final class FlowScene: SKScene {
    /// Seconds a pour takes per tile (about 8 tiles a second).
    static let tileDelay: TimeInterval = 0.125
    static let turnDuration: TimeInterval = 0.12
    /// How long a wheel turns after its last change before it becomes a
    /// still, motion-blurred image.
    static let wheelSpinSeconds: TimeInterval = 4

    var onWake: (() -> Void)?
    var onSettled: (() -> Void)?
    var sound: any FlowSoundPlaying = SilentFlowSound()
    var reduceMotion = false
    var safeTop: CGFloat = 62 {
        didSet { if safeTop != oldValue { rebuild() } }
    }
    var safeBottom: CGFloat = 34 {
        didSet { if safeBottom != oldValue { rebuild() } }
    }

    private(set) var board: FlowBoard
    private(set) var layout: FlowLayout
    private var textures: FlowTextures
    private let haptics = FlowHaptics()

    private let backdrop = SKSpriteNode()
    private let stage = SKNode()
    private var boardLayer = SKNode()
    private var poolNode: SKNode?
    private var nodes: [FlowCell: FlowTileNode] = [:]
    private var wetCells: Set<FlowCell> = []
    private var spills: [String: SKNode] = [:]
    private var hintNodes: [SKNode] = []
    private var currentHint: FlowHint?

    private var isBuilt = false
    private var isSettled = false
    private var busyUntil: TimeInterval = 0.5
    private(set) var sceneTime: TimeInterval = 0
    private var lastUpdate: TimeInterval?
    /// Deferred work on the scene's own clock (the garden's pattern): the
    /// scene is awake exactly while this and its actions have work.
    private var timeline: [(time: TimeInterval, action: () -> Void)] = []

    init(board: FlowBoard, size: CGSize) {
        self.board = board
        let initial = FlowLayout(size: size, safeTop: 62, safeBottom: 34, columns: board.columns, rows: board.rows)
        layout = initial
        textures = FlowTextures(cell: initial.cell)
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
        backgroundColor = FlowPalette.skyMid
        backdrop.anchorPoint = .zero
        backdrop.zPosition = -100
        addChild(backdrop)
        addChild(stage)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("FlowScene is made in code")
    }

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        haptics.attach(to: view)
        isBuilt = true
        rebuild()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if isBuilt, size != oldSize { rebuild() }
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate.map { min(1.0 / 15, max(0, currentTime - $0)) } ?? 0
        lastUpdate = currentTime
        sceneTime += dt
        runDueEvents()
        if !isSettled, sceneTime >= busyUntil {
            isSettled = true
            lastUpdate = nil
            onSettled?()
        }
    }

    private func after(_ delay: TimeInterval, _ action: @escaping () -> Void) {
        timeline.append((sceneTime + delay, action))
    }

    private func runDueEvents() {
        while let index = timeline.indices.min(by: { timeline[$0].time < timeline[$1].time }), timeline[index].time <= sceneTime {
            let event = timeline.remove(at: index)
            event.action()
        }
    }

    /// Keeps the scene running for `duration` more seconds, waking the
    /// view first if it was paused.
    private func wake(for duration: TimeInterval) {
        busyUntil = max(busyUntil, sceneTime + duration + 0.15)
        if isSettled {
            isSettled = false
            onWake?()
        }
    }

    /// Draws a few more frames (the app returned to the front).
    func nudge() {
        wake(for: 0.3)
    }

    // MARK: Geometry

    private func point(of cell: FlowCell) -> CGPoint {
        let rect = layout.rect(of: cell)
        return CGPoint(x: rect.midX, y: size.height - rect.midY)
    }

    private func sceneRect(_ rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: size.height - rect.maxY, width: rect.width, height: rect.height)
    }

    private var cellSize: CGSize { CGSize(width: layout.cell, height: layout.cell) }

    // MARK: Building

    private func rebuild() {
        guard isBuilt else { return }
        layout = FlowLayout(size: size, safeTop: safeTop, safeBottom: safeBottom, columns: board.columns, rows: board.rows)
        textures = FlowTextures(cell: layout.cell)
        backdrop.texture = backdropTexture()
        backdrop.size = size
        boardLayer.removeFromParent()
        boardLayer = makeBoardLayer(board)
        stage.addChild(boardLayer)
        if let currentHint { showHint(currentHint) }
        wake(for: 0.4)
    }

    private func backdropTexture() -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { rendererContext in
            let context = rendererContext.cgContext
            let colors = [FlowPalette.skyTop.cgColor, FlowPalette.skyMid.cgColor, FlowPalette.skyBottom.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.55, 1]) {
                context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            }
            // A soft warm light high on the left.
            let glow = [UIColor.white.withAlphaComponent(0.55).cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: glow, locations: [0, 1]) {
                context.drawRadialGradient(gradient, startCenter: CGPoint(x: size.width * 0.2, y: size.height * 0.1), startRadius: 0, endCenter: CGPoint(x: size.width * 0.2, y: size.height * 0.1), endRadius: size.width * 0.9, options: [])
            }
        }
        return SKTexture(image: image)
    }

    /// The board's container: the cliff lip, the bank, the pool and the tiles.
    private func makeBoardLayer(_ board: FlowBoard) -> SKNode {
        let container = SKNode()
        nodes = [:]
        wetCells = []
        spills = [:]
        hintNodes = []

        let lip = SKShapeNode(rect: sceneRect(layout.lip), cornerRadius: 12)
        lip.fillColor = FlowPalette.cliff
        lip.strokeColor = FlowPalette.cliffDark
        lip.lineWidth = 1.5
        lip.zPosition = 1
        container.addChild(lip)
        var mossRect = sceneRect(layout.lip)
        mossRect.origin.y += mossRect.height - 9
        mossRect.size.height = 9
        let moss = SKShapeNode(rect: mossRect.insetBy(dx: 6, dy: 0), cornerRadius: 4)
        moss.fillColor = FlowPalette.moss
        moss.strokeColor = .clear
        moss.zPosition = 1.1
        container.addChild(moss)

        let bank = SKShapeNode(rect: sceneRect(layout.board).insetBy(dx: -6, dy: -6), cornerRadius: 18)
        bank.fillColor = FlowPalette.cliff.withAlphaComponent(0.5)
        bank.strokeColor = FlowPalette.cliffDark.withAlphaComponent(0.35)
        bank.lineWidth = 1.2
        bank.zPosition = 0.5
        container.addChild(bank)

        let pool = SKShapeNode(rect: sceneRect(layout.pool), cornerRadius: 18)
        pool.fillColor = FlowPalette.rgb(0.58, 0.82, 0.95)
        pool.strokeColor = FlowPalette.cliffDark
        pool.lineWidth = 3
        pool.zPosition = 0.6
        let ripples = CGMutablePath()
        let poolRect = sceneRect(layout.pool)
        for index in 0..<3 {
            let x = poolRect.minX + poolRect.width * (0.2 + 0.3 * CGFloat(index))
            let y = poolRect.midY - 4 + CGFloat(index % 2) * 8
            ripples.move(to: CGPoint(x: x - 14, y: y))
            ripples.addQuadCurve(to: CGPoint(x: x + 14, y: y), control: CGPoint(x: x, y: y - 6))
        }
        let ripple = SKShapeNode(path: ripples)
        ripple.strokeColor = UIColor.white.withAlphaComponent(0.7)
        ripple.lineWidth = 1.6
        ripple.lineCap = .round
        pool.addChild(ripple)
        container.addChild(pool)
        poolNode = pool

        let flow = FlowSolver.flow(board)
        for cell in board.allCells {
            guard let tile = board[cell] else { continue }
            let node = makeTile(cell, tile)
            container.addChild(node)
            nodes[cell] = node
            if flow[cell] != nil {
                showWater(on: node, entered: nil, delay: 0, animated: false)
                if tile.kind == .wheel { node.overlay?.texture = textures.wheel(blurred: true) }
            }
        }
        wetCells = Set(flow.keys)
        refreshSpills(for: board, wet: wetCells, delays: [:], animated: false)
        return container
    }

    private func makeTile(_ cell: FlowCell, _ tile: FlowTile) -> FlowTileNode {
        let node = FlowTileNode(cell: cell, tile: tile)
        node.position = point(of: cell)
        node.stone.texture = textures.stone(tile.kind, tile.openings)
        node.stone.size = cellSize
        node.stone.zPosition = 1
        node.addChild(node.stone)
        switch tile.kind {
        case .gate:
            let board = SKSpriteNode(texture: textures.gateBoard(), size: cellSize)
            board.zPosition = 3
            node.addChild(board)
            node.overlay = board
        case .wheel:
            let wheel = SKSpriteNode(texture: textures.wheel(blurred: false), size: cellSize)
            wheel.zPosition = 3
            node.addChild(wheel)
            node.overlay = wheel
        default:
            break
        }
        return node
    }

    // MARK: Water

    private func showWater(on node: FlowTileNode, entered: FlowDirection?, delay: TimeInterval, animated: Bool) {
        node.crop?.removeFromParent()
        let crop = SKCropNode()
        crop.zPosition = 2
        let tile = node.shown
        crop.addChild(SKSpriteNode(texture: textures.water(tile.kind, tile.openings), size: cellSize))
        let mask = SKSpriteNode(color: .white, size: cellSize)
        crop.maskNode = mask
        node.addChild(crop)
        node.crop = crop
        guard animated else { return }
        guard let entered, !reduceMotion else {
            crop.alpha = 0
            crop.run(.sequence([.wait(forDuration: delay), .fadeIn(withDuration: 0.25)]))
            return
        }
        let half = layout.cell / 2
        let grow: SKAction
        switch entered {
        case .north:
            mask.anchorPoint = CGPoint(x: 0.5, y: 1)
            mask.position = CGPoint(x: 0, y: half)
            mask.yScale = 0.001
            grow = .scaleY(to: 1, duration: Self.tileDelay)
        case .south:
            mask.anchorPoint = CGPoint(x: 0.5, y: 0)
            mask.position = CGPoint(x: 0, y: -half)
            mask.yScale = 0.001
            grow = .scaleY(to: 1, duration: Self.tileDelay)
        case .east:
            mask.anchorPoint = CGPoint(x: 1, y: 0.5)
            mask.position = CGPoint(x: half, y: 0)
            mask.xScale = 0.001
            grow = .scaleX(to: 1, duration: Self.tileDelay)
        default:
            mask.anchorPoint = CGPoint(x: 0, y: 0.5)
            mask.position = CGPoint(x: -half, y: 0)
            mask.xScale = 0.001
            grow = .scaleX(to: 1, duration: Self.tileDelay)
        }
        mask.run(.sequence([.wait(forDuration: delay), grow]))
    }

    private func hideWater(on node: FlowTileNode) {
        guard let crop = node.crop else { return }
        node.crop = nil
        crop.run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
        if node.shown.kind == .wheel, let wheel = node.overlay {
            wheel.removeAction(forKey: "spin")
            wheel.zRotation = 0
            wheel.texture = textures.wheel(blurred: false)
        }
    }

    private func spinWheel(_ node: FlowTileNode, after delay: TimeInterval) {
        after(delay) { [weak self, weak node] in
            guard let self, let wheel = node?.overlay else { return }
            wheel.texture = self.textures.wheel(blurred: false)
            wheel.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: self.reduceMotion ? 6 : 2.4)), withKey: "spin")
        }
        // After four seconds the wheel becomes a still, motion-blurred image
        // and the scene can rest again.
        after(delay + Self.wheelSpinSeconds) { [weak self, weak node] in
            guard let self, let wheel = node?.overlay, self.wetCells.contains(node?.cell ?? FlowCell(row: -1, column: -1)) else { return }
            wheel.removeAction(forKey: "spin")
            wheel.zRotation = 0
            wheel.texture = self.textures.wheel(blurred: true)
        }
    }

    // MARK: Changes

    /// Draws `newBoard`: turns the tiles that changed and pours (or drains)
    /// whatever connected (or disconnected). `reverse` turns counter-clockwise
    /// (an undo).
    func apply(_ newBoard: FlowBoard, reverse: Bool = false) {
        let flow = FlowSolver.flow(newBoard)
        let newWet = Set(flow.keys)
        let oldWet = wetCells
        board = newBoard
        wetCells = newWet

        var turned: [FlowCell] = []
        for cell in newBoard.allCells {
            guard let tile = newBoard[cell], let node = nodes[cell], node.shown != tile else { continue }
            turn(node, to: tile, reverse: reverse)
            turned.append(cell)
        }
        haptics.tap()
        sound.play(.click)

        let appearing = newWet.subtracting(oldWet).sorted { (flow[$0]?.depth ?? 0, $0) < (flow[$1]?.depth ?? 0, $1) }
        let firstDepth = appearing.compactMap { flow[$0]?.depth }.min() ?? 0
        var delays: [FlowCell: TimeInterval] = [:]
        var duration = Self.turnDuration
        for (index, cell) in appearing.enumerated() {
            guard let node = nodes[cell], let info = flow[cell] else { continue }
            let delay = Self.turnDuration + Double(info.depth - firstDepth) * Self.tileDelay
            delays[cell] = delay
            duration = max(duration, delay + Self.tileDelay)
            showWater(on: node, entered: info.entered, delay: delay, animated: true)
            let kind = node.shown.kind
            after(delay) { [weak self] in
                guard let self else { return }
                self.sound.play(.trickle(step: index))
                switch kind {
                case .wheel:
                    self.haptics.target()
                    self.sound.play(.wheelCreak)
                case .mouth:
                    self.haptics.target()
                    self.sound.play(.splash)
                default:
                    self.haptics.wet()
                }
            }
            if kind == .wheel {
                spinWheel(node, after: delay)
                duration = max(duration, delay + Self.wheelSpinSeconds)
            }
        }
        for cell in oldWet.subtracting(newWet) {
            if let node = nodes[cell] { hideWater(on: node) }
        }
        // A tile that turned and stays wet shows its new channel once it lands.
        for cell in turned where newWet.contains(cell) && oldWet.contains(cell) {
            if let node = nodes[cell] {
                showWater(on: node, entered: nil, delay: 0, animated: false)
                node.crop?.alpha = 0
                node.crop?.run(.sequence([.wait(forDuration: Self.turnDuration), .fadeIn(withDuration: 0.08)]))
            }
        }
        refreshSpills(for: newBoard, wet: newWet, delays: delays, animated: true)
        wake(for: duration + 0.3)
    }

    private func turn(_ node: FlowTileNode, to tile: FlowTile, reverse: Bool) {
        // Land any turn still in flight, then start the next.
        node.stone.removeAction(forKey: "turn")
        node.stone.zRotation = 0
        node.stone.texture = textures.stone(node.shown.kind, node.shown.openings)
        node.shown = tile
        let texture = textures.stone(tile.kind, tile.openings)
        let angle: CGFloat = reverse ? .pi / 2 : -.pi / 2
        if reduceMotion {
            node.stone.texture = texture
            return
        }
        let spin = SKAction.rotate(byAngle: angle, duration: Self.turnDuration)
        spin.timingMode = .easeOut
        node.stone.run(spin, withKey: "turn")
        node.crop?.run(.rotate(byAngle: angle, duration: Self.turnDuration))
        after(Self.turnDuration) { [weak node] in
            // A newer turn on the same tile lands itself.
            guard let node, node.shown == tile else { return }
            node.stone.removeAction(forKey: "turn")
            node.stone.zRotation = 0
            node.stone.texture = texture
            node.crop?.zRotation = 0
        }
    }

    /// A tap on a fixed tile: a soft thunk, no turn, no haptic.
    func thunk(at cell: FlowCell) {
        guard let node = nodes[cell] else { return }
        sound.play(.thunk)
        guard !reduceMotion else { return }
        wake(for: 0.3)
        node.removeAction(forKey: "thunk")
        node.run(.sequence([.scale(to: 0.94, duration: 0.05), .scale(to: 1, duration: 0.1)]), withKey: "thunk")
    }

    // MARK: Spills

    private func refreshSpills(for board: FlowBoard, wet: Set<FlowCell>, delays: [FlowCell: TimeInterval], animated: Bool) {
        let current = FlowSolver.spills(board, wet: wet)
        var keep: Set<String> = []
        for spill in current {
            let key = "\(spill.cell.row)-\(spill.cell.column)-\(spill.side.rawValue)"
            keep.insert(key)
            guard spills[key] == nil, let node = nodes[spill.cell] else { continue }
            let drop = makeSpill(side: spill.side)
            node.addChild(drop)
            spills[key] = drop
            // A board that is just being drawn already has its dribbles.
            guard animated else { continue }
            let delay = (delays[spill.cell] ?? 0) + Self.tileDelay
            drop.alpha = 0
            drop.run(.sequence([.wait(forDuration: delay), .fadeIn(withDuration: 0.2)]))
        }
        for (key, node) in spills where !keep.contains(key) {
            spills[key] = nil
            node.run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
        }
    }

    /// A small harmless dribble on the bank edge: a puddle and a falling drop.
    private func makeSpill(side: FlowDirection) -> SKNode {
        let container = SKNode()
        container.zPosition = 4
        let half = layout.cell / 2
        let offset: CGPoint
        switch side {
        case .north: offset = CGPoint(x: 0, y: half)
        case .east: offset = CGPoint(x: half, y: 0)
        case .south: offset = CGPoint(x: 0, y: -half)
        default: offset = CGPoint(x: -half, y: 0)
        }
        container.position = offset
        let puddle = SKShapeNode(ellipseOf: CGSize(width: layout.cell * 0.26, height: layout.cell * 0.17))
        puddle.fillColor = FlowPalette.water.withAlphaComponent(0.85)
        puddle.strokeColor = FlowPalette.waterLight
        puddle.lineWidth = 1.2
        container.addChild(puddle)
        if !reduceMotion {
            let drip = SKShapeNode(circleOfRadius: 2.4)
            drip.fillColor = FlowPalette.water
            drip.strokeColor = .clear
            container.addChild(drip)
            let fall = SKAction.sequence([
                .group([.moveBy(x: 0, y: -10, duration: 0.6), .fadeOut(withDuration: 0.6)]),
                .moveBy(x: 0, y: 10, duration: 0),
                .fadeIn(withDuration: 0),
            ])
            drip.run(.repeat(fall, count: 3))
        }
        return container
    }

    // MARK: Pour, hint, boards

    /// The last connection: the whole channel brightens, the mouths splash,
    /// the pool rises a little. Reduce Motion: a crossfade-like brightening.
    func celebrate() {
        sound.play(.pour)
        wake(for: 1.5)
        for node in nodes.values {
            if let crop = node.crop {
                crop.run(.sequence([.fadeAlpha(to: 0.65, duration: 0.2), .fadeAlpha(to: 1, duration: 0.4)]))
                if !reduceMotion {
                    crop.run(.sequence([.scale(to: 1.05, duration: 0.2), .scale(to: 1, duration: 0.4)]))
                }
            }
            guard node.shown.kind == .mouth, !reduceMotion else { continue }
            for index in 0..<7 {
                let drop = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.2...3.8))
                drop.fillColor = FlowPalette.waterLight
                drop.strokeColor = FlowPalette.water
                drop.lineWidth = 0.8
                drop.zPosition = 6
                drop.position = CGPoint(x: 0, y: layout.cell * 0.1)
                node.addChild(drop)
                let angle = CGFloat(index) / 6 * .pi * 0.9 + 0.1
                let rise = SKAction.moveBy(x: cos(angle) * layout.cell * 0.4, y: sin(angle) * layout.cell * 0.55, duration: 0.45)
                rise.timingMode = .easeOut
                drop.run(.sequence([.group([rise, .sequence([.wait(forDuration: 0.25), .fadeOut(withDuration: 0.25)])]), .removeFromParent()]))
            }
        }
        if let poolNode, !reduceMotion {
            poolNode.run(.sequence([.scaleY(to: 1.12, duration: 0.25), .scaleY(to: 1, duration: 0.45)]))
        }
    }

    /// The next board: the old one slides up and away, the new one rises from
    /// below (Reduce Motion: a crossfade).
    func present(_ newBoard: FlowBoard, animated: Bool) {
        let old = boardLayer
        board = newBoard
        clearHintNodes()
        currentHint = nil
        layout = FlowLayout(size: size, safeTop: safeTop, safeBottom: safeBottom, columns: newBoard.columns, rows: newBoard.rows)
        textures = FlowTextures(cell: layout.cell)
        boardLayer = makeBoardLayer(newBoard)
        stage.addChild(boardLayer)
        wake(for: animated ? 1.0 : 0.3)
        guard animated else {
            old.removeFromParent()
            return
        }
        if reduceMotion {
            boardLayer.alpha = 0
            boardLayer.run(.fadeIn(withDuration: 0.3))
            old.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
            return
        }
        let travel = size.height * 0.8
        boardLayer.position = CGPoint(x: 0, y: -travel)
        let rise = SKAction.moveTo(y: 0, duration: 0.55)
        rise.timingMode = .easeOut
        boardLayer.run(rise)
        let leave = SKAction.moveBy(x: 0, y: travel, duration: 0.5)
        leave.timingMode = .easeIn
        old.run(.sequence([leave, .removeFromParent()]))
    }

    func showHint(_ hint: FlowHint) {
        clearHintNodes()
        currentHint = hint
        guard let node = nodes[hint.cell], let tile = board[hint.cell] else { return }
        let target = FlowTile(kind: tile.kind, rotation: hint.rotation)
        let ghost = SKSpriteNode(texture: textures.ghost(target.openings), size: cellSize)
        ghost.zPosition = 5
        ghost.alpha = 0
        ghost.run(.fadeIn(withDuration: 0.3))
        let ring = SKSpriteNode(texture: textures.ring(), size: cellSize)
        ring.zPosition = 5
        ring.alpha = 0.9
        if !reduceMotion {
            let pulse = SKAction.sequence([
                .group([.scale(to: 1.1, duration: 0.45), .fadeAlpha(to: 0.3, duration: 0.45)]),
                .group([.scale(to: 1, duration: 0.45), .fadeAlpha(to: 0.95, duration: 0.45)]),
            ])
            ring.run(.repeat(pulse, count: 3))
        }
        node.addChild(ghost)
        node.addChild(ring)
        hintNodes = [ghost, ring]
        wake(for: reduceMotion ? 0.4 : 3.0)
    }

    func clearHint() {
        currentHint = nil
        clearHintNodes()
    }

    private func clearHintNodes() {
        for node in hintNodes { node.removeFromParent() }
        hintNodes = []
    }
}
#endif
