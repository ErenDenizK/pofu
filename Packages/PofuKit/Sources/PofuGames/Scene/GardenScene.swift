#if os(iOS)
import SpriteKit
import UIKit

/// What the scene tells its SwiftUI shell.
enum GardenSceneEvent: Equatable {
    /// A plot was planted; the yield and the bag after it (sent when its
    /// seeds have landed, so the HUD counts with Pofu's gulp).
    case progress(seeds: Int, piecesLeft: Int)
    /// The round's last plot is in: the harvest starts.
    case harvestBegan
    /// The round is over and the harvest has played.
    case roundEnded(GardenRoundResult)
}

/// Pofu's sunflower garden, drawn and animated with SpriteKit.
///
/// The rules live in `GardenRound` (pure, tested); this scene only turns
/// touches into placements and outcomes into feel. Everything time-based
/// runs on the scene's own clock (`sceneTime`, advanced in `update`, scaled
/// by `speed`), so pausing the view pauses the whole game and slow motion
/// slows it evenly. Tunable numbers are in `GardenFeel`.
final class GardenScene: SKScene {
    var onEvent: ((GardenSceneEvent) -> Void)?
    var sound: any GameSoundPlaying = SilentGameSound()
    var reduceMotion = false
    /// The tuned feel (`TuningValues.Garden`); the Ayar panel changes it
    /// live.
    var feel = GardenFeel.standard {
        didSet {
            shakeBudget.maximum = feel.shakeMaximum
            haptics.feel = feel
        }
    }
    var safeTop: CGFloat = 62 {
        didSet { if safeTop != oldValue { rebuild() } }
    }
    var safeBottom: CGFloat = 34 {
        didSet { if safeBottom != oldValue { rebuild() } }
    }

    private(set) var round: GardenRound
    private(set) var layout: GardenLayout
    private let textures = GardenTextures()
    private let haptics = GardenHaptics()
    private var shakeBudget = ShakeBudget()

    private let backdrop = SKSpriteNode()
    /// Everything that shakes.
    private let stage = SKNode()
    private let staticLayer = SKNode()
    private let tileLayer = SKNode()
    private let effectsLayer = SKNode()
    private let residentsLayer = SKNode()
    private var glowNodes: [SKSpriteNode] = []
    private var ghostNodes: [SKSpriteNode] = []
    private var tiles: [GardenCell: SKSpriteNode] = [:]
    private var tints: [GardenCell: Int] = [:]
    private var trayPieces: [PieceNode?] = [nil, nil, nil]
    private var drag: Drag?
    private var residents: Residents?
    private var timeline: [(time: TimeInterval, action: () -> Void)] = []
    private(set) var sceneTime: TimeInterval = 0
    private var lastUpdate: TimeInterval?
    private var inputLocked = false
    private var cheekLevel = SeedYield.base
    private var lastGulp: TimeInterval = -1
    private var isBuilt = false

    private struct Drag {
        let slot: Int
        let node: PieceNode
        var target: CGPoint
        var origin: GardenCell?
        var preview: LineSet
    }

    init(round: GardenRound, size: CGSize) {
        self.round = round
        self.layout = GardenLayout(size: size, safeTop: 62, safeBottom: 34)
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
        backgroundColor = GardenPalette.skyBottom
        backdrop.anchorPoint = .zero
        backdrop.zPosition = -100
        addChild(backdrop)
        addChild(stage)
        for (layer, z) in [(residentsLayer, 5.0), (staticLayer, 10.0), (tileLayer, 12.0), (effectsLayer, 30.0)] {
            layer.zPosition = CGFloat(z)
            stage.addChild(layer)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("GardenScene is made in code")
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
        let dt = lastUpdate.map { min(1.0 / 30, max(0, currentTime - $0)) } ?? 0
        lastUpdate = currentTime
        sceneTime += dt * Double(speed)
        runDueEvents()

        let step = dt * Double(speed)
        if let drag {
            let follow = CGFloat(1 - exp(-step * feel.followStiffness))
            let position = drag.node.position
            drag.node.position = CGPoint(
                x: position.x + (drag.target.x - position.x) * follow,
                y: position.y + (drag.target.y - position.y) * follow
            )
            // A slight tilt with the drag's direction, like a held tile.
            let tilt = max(-0.06, min(0.06, (drag.target.x - position.x) * -0.004))
            drag.node.zRotation += (tilt - drag.node.zRotation) * follow
        }
        if let residents, !reduceMotion {
            // Pofu leans toward the plot in the air.
            let target: CGFloat = drag.map { max(-0.07, min(0.07, ($0.node.position.x - layout.pofu.x) / layout.size.width * -0.2)) } ?? 0
            let ease = CGFloat(1 - exp(-step * 6))
            residents.pofu.lean.zRotation += (target - residents.pofu.lean.zRotation) * ease
        }
    }

    // MARK: Rounds

    /// Starts `round` on a fresh bed and deals its tray.
    func begin(_ round: GardenRound) {
        self.round = round
        drag?.node.removeFromParent()
        drag = nil
        timeline.removeAll()
        tiles.removeAll()
        tints.removeAll()
        tileLayer.removeAllChildren()
        effectsLayer.removeAllChildren()
        inputLocked = false
        cheekLevel = round.seeds
        rebuild()
        for slot in trayPieces.indices {
            trayPieces[slot]?.removeFromParent()
            trayPieces[slot] = nil
        }
        dealTray(animated: true)
    }

    // MARK: Building

    private func rebuild() {
        guard isBuilt, size.width > 10, size.height > 10 else { return }
        layout = GardenLayout(size: size, safeTop: safeTop, safeBottom: safeBottom)
        let cell = layout.cell

        backdrop.texture = textures.sky(size: size, sunAt: CGPoint(x: layout.pofu.x, y: layout.pofu.y + layout.pofuHeight * 0.7))
        backdrop.size = size
        backdrop.position = .zero

        staticLayer.removeAllChildren()
        let bed = SKSpriteNode(texture: textures.bed(size: layout.bed.size, padding: GardenLayout.bedPadding))
        bed.size = layout.bed.size
        bed.position = CGPoint(x: layout.bed.midX, y: layout.bed.midY)
        staticLayer.addChild(bed)
        let soilTexture = textures.soilCell(side: cell - 2)
        for row in 0..<GardenBoard.size {
            for column in 0..<GardenBoard.size {
                let soil = SKSpriteNode(texture: soilTexture, size: CGSize(width: cell - 2, height: cell - 2))
                soil.position = layout.center(of: GardenCell(row: row, column: column))
                soil.zPosition = 1
                staticLayer.addChild(soil)
            }
        }
        let tray = SKSpriteNode(texture: textures.tray(size: layout.tray.size))
        tray.size = layout.tray.size
        tray.position = CGPoint(x: layout.tray.midX, y: layout.tray.midY)
        staticLayer.addChild(tray)

        glowNodes.forEach { $0.removeFromParent() }
        let glowTexture = textures.glow(side: cell - 2)
        glowNodes = (0..<GardenBoard.cellCount).map { index in
            let glow = SKSpriteNode(texture: glowTexture, size: CGSize(width: cell - 2, height: cell - 2))
            glow.position = layout.center(of: GardenCell(row: index / 8, column: index % 8))
            glow.alpha = 0
            glow.blendMode = .add
            glow.zPosition = 1.5
            tileLayer.addChild(glow)
            return glow
        }
        ghostNodes.forEach { $0.removeFromParent() }
        ghostNodes = (0..<9).map { _ in
            let ghost = SKSpriteNode(color: .clear, size: CGSize(width: cell - 3, height: cell - 3))
            ghost.isHidden = true
            ghost.zPosition = 2
            tileLayer.addChild(ghost)
            return ghost
        }

        for (cellKey, sprite) in tiles {
            sprite.removeAllActions()
            sprite.texture = textures.tile(tint: tints[cellKey] ?? 0, side: cell - 3)
            sprite.size = CGSize(width: cell - 3, height: cell - 3)
            sprite.position = layout.center(of: cellKey)
            sprite.setScale(1)
        }

        residentsLayer.removeAllChildren()
        residents = Residents(layout: layout, textures: textures, reduceMotion: reduceMotion)
        residents?.add(to: residentsLayer)
        residents?.pofu.setCheeks(level: cheekLevel, animated: false)

        for slot in trayPieces.indices {
            trayPieces[slot]?.removeFromParent()
            trayPieces[slot] = nil
        }
        dealTray(animated: false)
    }

    private func makeTile(tint: Int) -> SKSpriteNode {
        let side = layout.cell - 3
        let tile = SKSpriteNode(texture: textures.tile(tint: tint, side: side), size: CGSize(width: side, height: side))
        tile.zPosition = 1
        return tile
    }

    /// Fills empty tray slots from the round's tray.
    private func dealTray(animated: Bool) {
        var dealt = 0
        for slot in round.tray.indices where slot < trayPieces.count {
            guard trayPieces[slot] == nil, drag?.slot != slot, let shape = round.piece(in: slot) else { continue }
            let node = PieceNode(shape: shape, tint: shape.family.tint, cell: layout.cell, textures: textures)
            node.position = layout.slots[slot]
            node.zPosition = 20
            stage.addChild(node)
            trayPieces[slot] = node
            if animated, !reduceMotion {
                node.setScale(0.01)
                node.alpha = 0
                node.run(.sequence([
                    .wait(forDuration: Double(dealt) * feel.dealStagger),
                    .group([
                        SKAction.scale(to: trayScale(for: shape), duration: feel.deal).eased { GameEasing.outBack($0, overshoot: 1.4) },
                        .fadeIn(withDuration: 0.12),
                    ]),
                ]))
            } else if animated {
                node.setScale(trayScale(for: shape))
                node.alpha = 0
                node.run(.fadeIn(withDuration: 0.2))
            } else {
                node.setScale(trayScale(for: shape))
            }
            dealt += 1
        }
        if animated, dealt > 0 { sound.play(.deal) }
    }

    /// The tuned tray scale, shrunk where a plot would not fit its slot.
    private func trayScale(for shape: PieceShape) -> CGFloat {
        layout.trayScale(for: shape, preferred: CGFloat(feel.trayScale))
    }

    // MARK: Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard drag == nil, !inputLocked, let touch = touches.first else { return }
        let point = touch.location(in: self)
        guard let slot = layout.slot(at: point), let node = trayPieces[slot], round.piece(in: slot) != nil else { return }
        lift(node, slot: slot, to: liftTarget(for: point, shape: node.shape))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let shape = drag?.node.shape, let touch = touches.first else { return }
        drag?.target = liftTarget(for: touch.location(in: self), shape: shape)
        updateGhost()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        drop()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let drag else { return }
        self.drag = nil
        hideGhost()
        returnToTray(drag.node, slot: drag.slot)
    }

    /// The plot floats above the finger: `liftCells` plus half its height,
    /// so the thumb never covers it (the proven block-puzzle offset).
    private func liftTarget(for point: CGPoint, shape: PieceShape) -> CGPoint {
        CGPoint(x: point.x, y: point.y + layout.cell * (CGFloat(feel.liftCells) + CGFloat(shape.height) / 2))
    }

    private func lift(_ node: PieceNode, slot: Int, to target: CGPoint) {
        trayPieces[slot] = nil
        node.removeAllActions()
        node.alpha = 1
        node.zPosition = 100
        node.run(SKAction.scale(to: 1, duration: feel.pickUp).eased { GameEasing.outBack($0, overshoot: 1.2) })
        node.setLifted(true)
        drag = Drag(slot: slot, node: node, target: target, origin: nil, preview: LineSet.empty)
        haptics.lift()
        sound.play(.lift)
        updateGhost()
    }

    private func drop() {
        guard let drag else { return }
        self.drag = nil
        hideGhost()
        if let origin = drag.origin, let outcome = round.place(slot: drag.slot, at: origin) {
            commit(outcome, node: drag.node)
        } else {
            returnToTray(drag.node, slot: drag.slot)
        }
    }

    private func returnToTray(_ node: PieceNode, slot: Int) {
        node.setLifted(false)
        node.zPosition = 20
        node.removeAllActions()
        node.run(.group([
            SKAction.move(to: layout.slots[slot], duration: feel.trayReturn).eased { GameEasing.outBack($0, overshoot: 1.1) },
            SKAction.scale(to: trayScale(for: node.shape), duration: feel.trayReturn).eased(GameEasing.outCubic),
            SKAction.rotate(toAngle: 0, duration: feel.trayReturn),
        ]))
        trayPieces[slot] = node
        sound.play(.putBack)
    }

    // MARK: Ghost and preview

    private func updateGhost() {
        guard var drag else { return }
        let fractional = layout.fractionalOrigin(of: drag.node.shape, centeredAt: drag.target)
        let origin = round.board.snap(drag.node.shape, row: fractional.row, column: fractional.column, tolerance: feel.snapTolerance)
        guard origin != drag.origin else { return }
        drag.origin = origin
        drag.preview = origin.map { round.preview(slot: drag.slot, at: $0) } ?? LineSet.empty
        self.drag = drag
        showGhost(drag.node.shape, at: origin, tint: drag.node.tint)
        showPreview(drag.preview)
        if origin != nil {
            haptics.tick(at: sceneTime)
            sound.play(.snap)
        }
    }

    private func showGhost(_ shape: PieceShape, at origin: GardenCell?, tint: Int) {
        for ghost in ghostNodes { ghost.isHidden = true }
        guard let origin else { return }
        let texture = textures.tile(tint: tint, side: layout.cell - 3)
        for (index, offset) in shape.cells.enumerated() where index < ghostNodes.count {
            let ghost = ghostNodes[index]
            ghost.texture = texture
            ghost.color = .white
            ghost.colorBlendFactor = 0
            ghost.alpha = 0.42
            ghost.isHidden = false
            ghost.position = layout.center(of: GardenCell(row: origin.row + offset.row, column: origin.column + offset.column))
        }
    }

    private func hideGhost() {
        for ghost in ghostNodes { ghost.isHidden = true }
        showPreview(LineSet.empty)
    }

    /// Cells of every line the drop would bloom brighten with added honey
    /// light and breathe.
    private func showPreview(_ lines: LineSet) {
        let mask = lines.mask
        let peak = CGFloat(feel.glowStrength)
        for (index, glow) in glowNodes.enumerated() {
            let on = mask & (UInt64(1) << UInt64(index)) != 0
            if on, glow.action(forKey: "pulse") == nil {
                glow.run(.sequence([
                    SKAction.fadeAlpha(to: peak, duration: 0.1),
                    .repeatForever(.sequence([
                        SKAction.fadeAlpha(to: peak * 0.55, duration: 0.42).eased(GameEasing.inOutSine),
                        SKAction.fadeAlpha(to: peak, duration: 0.42).eased(GameEasing.inOutSine),
                    ])),
                ]), withKey: "pulse")
            } else if !on, glow.alpha > 0 || glow.action(forKey: "pulse") != nil {
                glow.removeAction(forKey: "pulse")
                glow.run(.fadeAlpha(to: 0, duration: 0.08))
            }
        }
    }

    // MARK: Planting and blooming

    private func commit(_ outcome: PlacementOutcome, node: PieceNode) {
        let tint = node.tint
        for (index, offset) in outcome.shape.cells.enumerated() {
            let cell = GardenCell(row: outcome.origin.row + offset.row, column: outcome.origin.column + offset.column)
            let sprite = makeTile(tint: tint)
            let drawn = node.tiles[index]
            sprite.position = node.convert(drawn.position, to: tileLayer)
            sprite.zRotation = node.zRotation
            tileLayer.addChild(sprite)
            tiles[cell] = sprite
            tints[cell] = tint
            let travel = SKAction.group([
                SKAction.move(to: layout.center(of: cell), duration: feel.snapToCell).eased(GameEasing.outCubic),
                SKAction.rotate(toAngle: 0, duration: feel.snapToCell),
            ])
            sprite.run(.sequence([travel, squash(delay: Double(index) * 0.012)]))
        }
        node.removeFromParent()

        after(feel.snapToCell) { [weak self] in
            guard let self else { return }
            haptics.plant()
            sound.play(.plant)
            crumbs(around: outcome.planted)
        }

        let bloomEnd = outcome.cleared.isEmpty ? feel.snapToCell : bloom(outcome)
        if outcome.dealtTray != nil {
            after(0.12) { [weak self] in self?.dealTray(animated: true) }
        }
        after(bloomEnd) { [weak self] in
            guard let self else { return }
            let gained = outcome.seedsAfter - cheekLevel
            guard gained > 0 else {
                onEvent?(.progress(seeds: outcome.seedsAfter, piecesLeft: round.piecesLeft))
                return
            }
            cheekLevel = outcome.seedsAfter
            residents?.pofu.setCheeks(level: cheekLevel, animated: !reduceMotion)
            // The yield's step arcs from Pofu's cheeks up to the seed plate,
            // and the plate counts when it lands.
            let landing = countArc(gained)
            after(landing) { [weak self] in
                guard let self else { return }
                onEvent?(.progress(seeds: outcome.seedsAfter, piecesLeft: round.piecesLeft))
            }
        }
        if outcome.ending != nil {
            inputLocked = true
            after(bloomEnd + 0.45) { [weak self] in self?.harvest(ending: outcome.ending ?? .bagEmpty) }
        }
    }

    /// One decaying wobble: wide and short, then tall, then still.
    private func squash(delay: TimeInterval) -> SKAction {
        if reduceMotion { return .wait(forDuration: 0) }
        let d = feel.squash
        let a = CGFloat(feel.squashAmount)
        return .sequence([
            .wait(forDuration: delay),
            SKAction.group([SKAction.scaleX(to: 1 + a, duration: d * 0.3), SKAction.scaleY(to: 1 - a, duration: d * 0.3)]).eased(GameEasing.outCubic),
            SKAction.group([SKAction.scaleX(to: 1 - a * 0.28, duration: d * 0.35), SKAction.scaleY(to: 1 + a * 0.36, duration: d * 0.35)]).eased(GameEasing.inOutSine),
            SKAction.group([SKAction.scaleX(to: 1, duration: d * 0.35), SKAction.scaleY(to: 1, duration: d * 0.35)]).eased(GameEasing.outCubic),
        ])
    }

    /// Soil crumbs kicked out from under the plot's bottom edge.
    private func crumbs(around cells: [GardenCell]) {
        guard !reduceMotion, let lowest = cells.map(\.row).max() else { return }
        let bottom = cells.filter { $0.row == lowest }
        for (index, cell) in bottom.enumerated() {
            let center = layout.center(of: cell)
            for side in [-1.0, 1.0] where index == 0 && side < 0 || index == bottom.count - 1 && side > 0 || bottom.count == 1 {
                let crumb = SKSpriteNode(texture: textures.crumb(), size: CGSize(width: 5, height: 5))
                crumb.position = CGPoint(x: center.x + CGFloat(side) * layout.cell * 0.4, y: center.y - layout.cell * 0.4)
                crumb.zPosition = 5
                effectsLayer.addChild(crumb)
                let dx = CGFloat(side) * 14
                crumb.run(.sequence([
                    .group([
                        SKAction.move(by: CGVector(dx: dx, dy: 8), duration: 0.22).eased(GameEasing.outCubic),
                        .fadeOut(withDuration: 0.3),
                    ]),
                    .removeFromParent(),
                ]))
            }
        }
    }

    /// Blooms the cleared lines; returns when its seeds have landed.
    private func bloom(_ outcome: PlacementOutcome) -> TimeInterval {
        let lines = outcome.cleared
        let combo = max(1, outcome.combo)
        let planted = outcome.planted
        // Sweep out from where the plot landed.
        let ordered: [(cell: GardenCell, distance: Int)] = lines.cells.map { cell in
            let distance = planted.map { max(abs($0.row - cell.row), abs($0.column - cell.column)) }.min() ?? 0
            return (cell, distance)
        }.sorted { ($0.distance, $0.cell) < ($1.distance, $1.cell) }

        let start = feel.snapToCell + GardenFeel.bloomDelay
        let seedEvery = feel.seedStride(cells: ordered.count, lines: lines.count)
        var lastSeed: TimeInterval = start
        var noteIndex = 0
        for (rank, entry) in ordered.enumerated() {
            let delay = start + Double(entry.distance) * feel.bloomStagger * 1.4
            let sprite = tiles.removeValue(forKey: entry.cell)
            tints.removeValue(forKey: entry.cell)
            let isNote = rank == 0 || ordered[rank - 1].distance != entry.distance
            let note = noteIndex
            if isNote { noteIndex += 1 }
            after(delay) { [weak self] in
                guard let self else { return }
                bloomCell(entry.cell, tile: sprite, rank: rank, combo: combo)
                if isNote { sound.play(.bloom(midi: PentatonicLadder.bloomNote(index: note, combo: combo))) }
            }
            if rank % seedEvery == 0 {
                let launch = delay + feel.bloomPop + feel.bloomHold
                let landing = launch + feel.seedFlight + Double(rank) * GardenFeel.seedStagger * 0.5
                lastSeed = max(lastSeed, landing)
                after(launch) { [weak self] in
                    self?.launchSeed(from: entry.cell, rank: rank)
                }
            }
        }

        after(start) { [weak self] in
            guard let self else { return }
            haptics.bloom(intensity: feel.bloomHaptic(lines: lines.count, combo: combo))
            word(for: lines, combo: outcome.combo)
            residents?.react(lines: lines.count, combo: combo, reduceMotion: reduceMotion)
            let amplitude = shakeBudget.request(lines: lines.count, combo: combo, at: sceneTime, reduceMotion: reduceMotion)
            if amplitude > 0 { shake(amplitude) }
        }
        return lastSeed
    }

    private func bloomCell(_ cell: GardenCell, tile: SKSpriteNode?, rank: Int, combo: Int) {
        let center = layout.center(of: cell)
        if let tile {
            tile.removeAllActions()
            tile.run(.sequence([
                .group([SKAction.scale(to: 1.16, duration: 0.08), .fadeOut(withDuration: 0.1)]),
                .removeFromParent(),
            ]))
        }
        let art: GardenTextures.Art = (cell.row * 3 + cell.column) % 4 == 1 ? .bloomSmall : .bloom
        let flower = SKSpriteNode(texture: textures.art(art), size: CGSize(width: layout.cell * 1.08, height: layout.cell * 1.08))
        flower.position = center
        flower.zPosition = 2
        effectsLayer.addChild(flower)
        let hold = feel.bloomHold + Double(min(combo, 4)) * 0.03
        if reduceMotion {
            flower.alpha = 0
            flower.run(.sequence([
                .fadeIn(withDuration: 0.16),
                .wait(forDuration: feel.bloomPop + hold),
                .fadeOut(withDuration: 0.2),
                .removeFromParent(),
            ]))
            return
        }
        let spin = CGFloat((cell.row * 7 + cell.column * 13) % 9 - 4) * 0.08
        flower.setScale(0.15)
        flower.zRotation = spin
        let overshoot = feel.bloomOvershoot(combo: combo)
        flower.run(.sequence([
            .group([
                SKAction.scale(to: 1, duration: feel.bloomPop).eased { GameEasing.outBack($0, overshoot: overshoot) },
                SKAction.rotate(toAngle: 0, duration: feel.bloomPop).eased(GameEasing.outCubic),
            ]),
            .wait(forDuration: hold),
            .group([
                SKAction.scale(to: 0.2, duration: 0.18).eased(GameEasing.inQuad),
                .fadeOut(withDuration: 0.18),
            ]),
            .removeFromParent(),
        ]))

        let petals = feel.petals(combo: combo)
        for index in 0..<petals {
            let angle = (Double(index) / Double(petals) + Double(rank % 5) * 0.07) * 2 * Double.pi
            let reach = layout.cell * (0.55 + CGFloat((rank + index) % 3) * 0.12)
            let petal = SKSpriteNode(texture: textures.petal(), size: CGSize(width: 6, height: 10))
            petal.position = center
            petal.zRotation = CGFloat(angle) - .pi / 2
            petal.zPosition = 3
            effectsLayer.addChild(petal)
            petal.run(.sequence([
                .group([
                    SKAction.move(by: CGVector(dx: CGFloat(cos(angle)) * reach, dy: CGFloat(sin(angle)) * reach - 4), duration: 0.42).eased(GameEasing.outCubic),
                    SKAction.rotate(byAngle: 1.4, duration: 0.42),
                    .sequence([.wait(forDuration: 0.18), .fadeOut(withDuration: 0.24)]),
                ]),
                .removeFromParent(),
            ]))
        }
        if rank % 3 == 0 {
            let sparkle = SKSpriteNode(texture: textures.sparkle(), size: CGSize(width: 14, height: 14))
            sparkle.position = CGPoint(x: center.x + layout.cell * 0.3, y: center.y + layout.cell * 0.3)
            sparkle.zPosition = 4
            sparkle.setScale(0.2)
            effectsLayer.addChild(sparkle)
            sparkle.run(.sequence([
                .group([
                    SKAction.scale(to: 1.2, duration: 0.2).eased { GameEasing.outBack($0) },
                    SKAction.rotate(byAngle: 0.8, duration: 0.4),
                ]),
                .fadeOut(withDuration: 0.2),
                .removeFromParent(),
            ]))
        }
    }

    /// A seed arcs from a bloom into Pofu's cheeks.
    private func launchSeed(from cell: GardenCell, rank: Int) {
        let start = layout.center(of: cell)
        let mouth = CGPoint(x: layout.pofu.x, y: layout.pofu.y + layout.pofuHeight * 0.4)
        let seedHeight = CGFloat(feel.seedSize)
        let seed = SKSpriteNode(texture: textures.seed(), size: CGSize(width: seedHeight * 0.68, height: seedHeight))
        seed.position = start
        seed.zPosition = 30
        effectsLayer.addChild(seed)
        let flight = feel.seedFlight + Double(rank) * GardenFeel.seedStagger * 0.5
        if reduceMotion {
            seed.alpha = 0
            seed.run(.sequence([.fadeIn(withDuration: 0.1), .fadeOut(withDuration: 0.25), .removeFromParent()]))
            after(0.3) { [weak self] in self?.seedArrived() }
            return
        }
        let path = CGMutablePath()
        path.move(to: start)
        let lift = 70 + CGFloat(rank % 4) * 10
        let control = CGPoint(x: (start.x + mouth.x) / 2 + (start.x - mouth.x) * 0.35, y: max(start.y, mouth.y) + lift)
        path.addQuadCurve(to: mouth, control: control)
        seed.run(.sequence([
            .group([
                SKAction.follow(path, asOffset: false, orientToPath: false, duration: flight).eased(GameEasing.inQuad),
                SKAction.rotate(byAngle: CGFloat(rank % 2 == 0 ? 6 : -6), duration: flight),
                SKAction.scale(to: 0.7, duration: flight),
            ]),
            .removeFromParent(),
        ]))
        after(flight) { [weak self] in self?.seedArrived() }
    }

    private func seedArrived() {
        guard sceneTime - lastGulp > 0.14 else { return }
        lastGulp = sceneTime
        residents?.pofu.gulp(reduceMotion: reduceMotion)
        haptics.cheek()
        sound.play(.cheek)
    }

    /// "+1" rises out of Pofu's cheeks and arcs to the HUD's seed plate;
    /// returns when it lands.
    private func countArc(_ gained: Int) -> TimeInterval {
        let start = CGPoint(x: layout.pofu.x + layout.pofuHeight * 0.3, y: layout.pofu.y + layout.pofuHeight * 0.55)
        let plate = CGPoint(x: size.width - 52, y: size.height - safeTop - GardenLayout.hudHeight / 2)
        let label = Self.label("+\(gained)", size: 34, color: GardenPalette.comboInk(1))
        label.position = start
        label.zPosition = 60
        effectsLayer.addChild(label)
        if reduceMotion {
            label.alpha = 0
            label.run(.sequence([.fadeIn(withDuration: 0.12), .wait(forDuration: 0.35), .fadeOut(withDuration: 0.2), .removeFromParent()]))
            return 0.45
        }
        let path = CGMutablePath()
        path.move(to: start)
        path.addQuadCurve(to: plate, control: CGPoint(x: (start.x + plate.x) / 2 - 30, y: max(start.y, plate.y) + 60))
        label.setScale(0.4)
        let rise = 0.22
        let flight = 0.5
        label.run(.sequence([
            SKAction.scale(to: 1.25, duration: rise).eased { GameEasing.outBack($0, overshoot: 2.4) },
            .group([
                SKAction.follow(path, asOffset: false, orientToPath: false, duration: flight).eased(GameEasing.inQuad),
                SKAction.scale(to: 0.6, duration: flight).eased(GameEasing.inQuad),
            ]),
            .fadeOut(withDuration: 0.08),
            .removeFromParent(),
        ]))
        return rise + flight
    }

    /// The bloom's word: a double bloom, a full spring, and the combo.
    private func word(for lines: LineSet, combo: Int) {
        var texts: [(String, CGFloat)] = []
        if lines.count >= 3 {
            texts.append((GardenStrings.fullSpring, 30))
        } else if lines.count == 2 {
            texts.append((GardenStrings.doubleBloom, 28))
        }
        if combo >= 2 {
            texts.append((GardenStrings.combo(combo), texts.isEmpty ? 28 : 20))
        }
        guard !texts.isEmpty else { return }
        let cells = lines.cells
        let centers = cells.map { layout.center(of: $0) }
        let x = min(layout.grid.maxX - 90, max(layout.grid.minX + 90, centers.map(\.x).reduce(0, +) / CGFloat(max(1, centers.count))))
        let y = min(layout.grid.maxY - 20, max(layout.grid.minY + 50, centers.map(\.y).reduce(0, +) / CGFloat(max(1, centers.count)) + layout.cell * 0.6))
        for (index, entry) in texts.enumerated() {
            let label = Self.label(entry.0, size: entry.1, color: GardenPalette.comboInk(combo))
            label.position = CGPoint(x: x, y: y - CGFloat(index) * 30)
            label.zPosition = 50
            effectsLayer.addChild(label)
            if reduceMotion {
                label.alpha = 0
                label.run(.sequence([.fadeIn(withDuration: 0.15), .wait(forDuration: 0.6), .fadeOut(withDuration: 0.25), .removeFromParent()]))
                continue
            }
            label.setScale(0.3)
            label.run(.sequence([
                .wait(forDuration: Double(index) * 0.08),
                SKAction.scale(to: 1, duration: 0.3).eased { GameEasing.outBack($0, overshoot: 2.2) },
                .wait(forDuration: 0.45),
                .group([
                    SKAction.move(by: CGVector(dx: 0, dy: 26), duration: 0.35).eased(GameEasing.outCubic),
                    .fadeOut(withDuration: 0.35),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    static func label(_ text: String, size: CGFloat, color: UIColor) -> SKLabelNode {
        let base = UIFont.systemFont(ofSize: size, weight: .heavy)
        let font = base.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: size) } ?? base
        let attributed = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color,
            .strokeColor: GardenPalette.ink,
            .strokeWidth: -5,
        ])
        let label = SKLabelNode(attributedText: attributed)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        return label
    }

    /// A tiny decaying shake of the stage (budgeted by `ShakeBudget`).
    private func shake(_ amplitude: Double) {
        let a = CGFloat(amplitude)
        let offsets: [(CGFloat, CGFloat)] = [(1, -0.6), (-0.8, 0.9), (0.6, -0.4), (-0.4, 0.5), (0.2, -0.2), (0, 0)]
        stage.removeAction(forKey: "shake")
        stage.run(.sequence(offsets.map { SKAction.move(to: CGPoint(x: $0.0 * a, y: $0.1 * a), duration: 0.032) }), withKey: "shake")
    }

    /// The round's end: every remaining sprout blooms, row by row, then the
    /// card. The harvest pays nothing extra: it is the natural, kind end.
    private func harvest(ending: GardenRound.Ending) {
        onEvent?(.harvestBegan)
        if ending == .gardenFull {
            let label = Self.label(GardenStrings.gardenFull, size: 30, color: GardenPalette.comboInk(1))
            label.position = CGPoint(x: layout.grid.midX, y: layout.grid.midY)
            label.zPosition = 50
            effectsLayer.addChild(label)
            label.setScale(reduceMotion ? 1 : 0.3)
            label.run(.sequence([
                SKAction.scale(to: 1, duration: 0.3).eased { GameEasing.outBack($0, overshoot: 2) },
                .wait(forDuration: 0.9),
                .fadeOut(withDuration: 0.3),
                .removeFromParent(),
            ]))
        }
        let remaining = tiles.sorted { $0.key < $1.key }
        tiles.removeAll()
        tints.removeAll()
        for (index, entry) in remaining.enumerated() {
            let delay = 0.25 + Double(entry.key.row) * 0.06 + Double(entry.key.column) * 0.012
            after(delay) { [weak self] in
                self?.bloomCell(entry.key, tile: entry.value, rank: index, combo: 1)
            }
        }
        let harvestEnd = 0.25 + Double(GardenBoard.size) * 0.07 + feel.bloomPop + feel.bloomHold + 0.3
        after(harvestEnd) { [weak self] in
            guard let self else { return }
            residents?.cheer(reduceMotion: reduceMotion)
            sound.play(.roundEnd)
            onEvent?(.roundEnded(round.result))
        }
    }

    // MARK: The scene's clock

    private func after(_ delay: TimeInterval, _ action: @escaping () -> Void) {
        timeline.append((sceneTime + delay, action))
    }

    private func runDueEvents() {
        while let index = timeline.indices.min(by: { timeline[$0].time < timeline[$1].time }), timeline[index].time <= sceneTime {
            let event = timeline.remove(at: index)
            event.action()
        }
    }

    /// While a card is up, Pofu is on the card: his figure in the garden
    /// steps aside so he is never seen twice.
    func setCardShown(_ shown: Bool) {
        guard let pofu = residents?.pofu.root else { return }
        pofu.removeAction(forKey: "card")
        // Gone the instant the card (with its own Pofu) arrives, so he is
        // never seen twice; back with a short fade.
        if shown {
            pofu.alpha = 0
        } else {
            pofu.run(.fadeAlpha(to: 1, duration: reduceMotion ? 0 : 0.2), withKey: "card")
        }
    }

    // MARK: Screenshots and previews

    /// Plays `move` as if dragged and dropped there (animated), or applies
    /// it at once (for setting up a mid-round bed).
    @discardableResult
    func play(_ move: GardenAutoplayer.Move, animated: Bool) -> PlacementOutcome? {
        guard let node = trayPieces[move.slot], let outcome = round.place(slot: move.slot, at: move.origin) else { return nil }
        trayPieces[move.slot] = nil
        if animated {
            node.setScale(1)
            node.zPosition = 100
            node.position = layout.center(of: outcome.shape, at: move.origin)
            commit(outcome, node: node)
            return outcome
        }
        node.removeFromParent()
        for cell in outcome.planted {
            let sprite = makeTile(tint: outcome.shape.family.tint)
            sprite.position = layout.center(of: cell)
            tileLayer.addChild(sprite)
            tiles[cell] = sprite
            tints[cell] = outcome.shape.family.tint
        }
        for cell in outcome.cleared.cells {
            tiles.removeValue(forKey: cell)?.removeFromParent()
            tints.removeValue(forKey: cell)
        }
        cheekLevel = outcome.seedsAfter
        residents?.pofu.setCheeks(level: cheekLevel, animated: false)
        dealTray(animated: false)
        onEvent?(.progress(seeds: outcome.seedsAfter, piecesLeft: round.piecesLeft))
        if outcome.ending != nil { inputLocked = true }
        return outcome
    }

    /// Loads a bed mid-play (a scenario), painting its sprouts with the
    /// palette in a stable pattern.
    func load(_ round: GardenRound) {
        begin(round)
        for slot in trayPieces.indices {
            trayPieces[slot]?.removeAllActions()
            trayPieces[slot]?.alpha = 1
            if let node = trayPieces[slot] {
                node.setScale(trayScale(for: node.shape))
            }
        }
        for cell in round.board.plantedCells {
            let tint = (cell.row / 2 + cell.column / 3 * 2) % GardenPalette.glazes.count
            let sprite = makeTile(tint: tint)
            sprite.position = layout.center(of: cell)
            tileLayer.addChild(sprite)
            tiles[cell] = sprite
            tints[cell] = tint
        }
        cheekLevel = round.seeds
        residents?.pofu.setCheeks(level: cheekLevel, animated: false)
    }

    /// Holds the plot in `slot` in the air over `origin`, with its ghost and
    /// the preview glow, as a frozen drag (the mid-round screenshot).
    func hold(slot: Int, over origin: GardenCell) {
        guard let node = trayPieces[slot] else { return }
        let center = layout.center(of: node.shape, at: origin)
        lift(node, slot: slot, to: CGPoint(x: center.x + layout.cell * 0.18, y: center.y + layout.cell * 0.22))
        // Where a thumb would leave it: up and a little to the side of the
        // ghost, which stays where it snapped.
        let shown = CGPoint(x: center.x + layout.cell * 0.35, y: center.y + layout.cell * 0.9)
        drag?.target = shown
        node.removeAllActions()
        node.setScale(1)
        node.position = shown
    }
}

// MARK: - Pieces

/// A plot of sprouts: its tiles, and their shadows (shown when lifted).
final class PieceNode: SKNode {
    let shape: PieceShape
    let tint: Int
    private(set) var tiles: [SKSpriteNode] = []
    private var shadows: [SKSpriteNode] = []

    init(shape: PieceShape, tint: Int, cell: CGFloat, textures: GardenTextures) {
        self.shape = shape
        self.tint = tint
        super.init()
        let side = cell - 3
        let tileTexture = textures.tile(tint: tint, side: side)
        let shadowTexture = textures.shadow(side: side)
        for offset in shape.cells {
            let position = CGPoint(
                x: (CGFloat(offset.column) - CGFloat(shape.width - 1) / 2) * cell,
                y: -(CGFloat(offset.row) - CGFloat(shape.height - 1) / 2) * cell
            )
            let shadow = SKSpriteNode(texture: shadowTexture, size: CGSize(width: side * 1.04, height: side * 1.04))
            shadow.position = CGPoint(x: position.x + cell * 0.06, y: position.y - cell * 0.16)
            shadow.zPosition = -1
            shadow.alpha = 0
            addChild(shadow)
            shadows.append(shadow)
            let tile = SKSpriteNode(texture: tileTexture, size: CGSize(width: side, height: side))
            tile.position = position
            addChild(tile)
            tiles.append(tile)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("PieceNode is made in code")
    }

    func setLifted(_ lifted: Bool) {
        for shadow in shadows {
            shadow.removeAllActions()
            shadow.run(.fadeAlpha(to: lifted ? 1 : 0, duration: 0.1))
        }
    }
}

// MARK: - Residents

/// Pofu between Mochi and Fındık, peeking over the bed's back rim.
@MainActor
final class Residents {
    @MainActor
    final class Figure {
        /// Position and hops.
        let root = SKNode()
        /// Leaning (Pofu toward the plot in the air), pivoting at the feet.
        let lean = SKNode()
        /// Rolling (Fındık), pivoting at the middle of the body.
        let spin = SKNode()
        /// Squash, and Pofu's cheek fill.
        let body = SKNode()
        let sprite: SKSpriteNode
        let shadow: SKSpriteNode
        var blushes: [SKSpriteNode] = []
        /// Pofu's painted cheeks-puff pose over his base, faded in with
        /// the round's yield.
        var puff: SKSpriteNode?
        private var fill: CGFloat = 1
        /// The body's resting height inside `spin` (its feet at the root).
        private let rest: CGFloat

        init(texture: SKTexture, shadowTexture: SKTexture, feet: CGPoint, height: CGFloat) {
            let aspect = texture.size().height > 0 ? texture.size().width / texture.size().height : 1
            sprite = SKSpriteNode(texture: texture, size: CGSize(width: height * aspect, height: height))
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
            shadow = SKSpriteNode(texture: shadowTexture, size: CGSize(width: height * aspect * 0.9, height: height * 0.18))
            shadow.position = CGPoint(x: 0, y: 4)
            shadow.zPosition = -1
            rest = -height / 2
            root.position = feet
            root.addChild(shadow)
            root.addChild(lean)
            lean.addChild(spin)
            spin.position = CGPoint(x: 0, y: height / 2)
            body.position = CGPoint(x: 0, y: rest)
            spin.addChild(body)
            body.addChild(sprite)
        }

        func breathe(period: TimeInterval, phase: TimeInterval) {
            sprite.run(.sequence([
                .wait(forDuration: phase),
                .repeatForever(.sequence([
                    SKAction.scaleY(to: 1.022, duration: period / 2).eased(GameEasing.inOutSine),
                    SKAction.scaleY(to: 1, duration: period / 2).eased(GameEasing.inOutSine),
                ])),
            ]))
        }

        /// A hop with a squash on landing.
        func hop(height: CGFloat, delay: TimeInterval = 0, reduceMotion: Bool) {
            body.removeAction(forKey: "hop")
            if reduceMotion {
                body.run(.sequence([
                    .wait(forDuration: delay),
                    SKAction.scaleX(to: fill * 1.04, duration: 0.12),
                    SKAction.scaleX(to: fill, duration: 0.18),
                ]), withKey: "hop")
                return
            }
            body.run(.sequence([
                .wait(forDuration: delay),
                SKAction.group([SKAction.scaleX(to: fill * 1.08, duration: 0.06), SKAction.scaleY(to: 0.9, duration: 0.06)]),
                .group([
                    SKAction.moveTo(y: rest + height, duration: 0.16).eased(GameEasing.outCubic),
                    SKAction.scaleX(to: fill * 0.94, duration: 0.1),
                    SKAction.scaleY(to: 1.08, duration: 0.1),
                ]),
                SKAction.moveTo(y: rest, duration: 0.15).eased(GameEasing.inQuad),
                SKAction.group([SKAction.scaleX(to: fill * 1.1, duration: 0.05), SKAction.scaleY(to: 0.88, duration: 0.05)]),
                SKAction.group([SKAction.scaleX(to: fill, duration: 0.18), SKAction.scaleY(to: 1, duration: 0.18)]).eased { GameEasing.outBack($0, overshoot: 2) },
            ]), withKey: "hop")
        }

        /// Fındık's move: a hedgehog's roll, once round.
        func roll(delay: TimeInterval, reduceMotion: Bool) {
            guard !reduceMotion else { return hop(height: 0, delay: delay, reduceMotion: true) }
            spin.removeAction(forKey: "roll")
            spin.run(.sequence([
                .wait(forDuration: delay),
                SKAction.rotate(byAngle: -2 * .pi, duration: 0.52).eased(GameEasing.inOutSine),
            ]), withKey: "roll")
            hop(height: 14, delay: delay + 0.08, reduceMotion: false)
        }

        /// Pofu's cheeks: the painted puff fades in with each seed above
        /// the base (without the art, a drawn stand-in widens and blushes).
        func setCheeks(level: Int, animated: Bool) {
            let extra = CGFloat(max(0, level - SeedYield.base))
            if let puff {
                let target = min(1, extra / 3)
                fill = 1 + 0.01 * extra
                if animated {
                    puff.run(.fadeAlpha(to: target, duration: 0.25))
                    body.run(SKAction.scaleX(to: fill, duration: 0.3).eased { GameEasing.outBack($0, overshoot: 2.4) })
                } else {
                    puff.alpha = target
                    body.xScale = fill
                }
                return
            }
            fill = 1 + 0.035 * extra
            let alpha = min(0.5, 0.14 * extra)
            if animated {
                body.run(SKAction.scaleX(to: fill, duration: 0.3).eased { GameEasing.outBack($0, overshoot: 2.4) })
                blushes.forEach { $0.run(.fadeAlpha(to: alpha, duration: 0.3)) }
            } else {
                body.xScale = fill
                blushes.forEach { $0.alpha = alpha }
            }
        }

        /// A seed goes in: a quick squash, the cheeks bulge for a moment.
        func gulp(reduceMotion: Bool) {
            guard !reduceMotion else { return }
            body.removeAction(forKey: "gulp")
            body.run(.sequence([
                SKAction.group([SKAction.scaleX(to: fill * 1.07, duration: 0.05), SKAction.scaleY(to: 0.95, duration: 0.05)]),
                SKAction.group([SKAction.scaleX(to: fill, duration: 0.16), SKAction.scaleY(to: 1, duration: 0.16)]).eased { GameEasing.outBack($0, overshoot: 2.2) },
            ]), withKey: "gulp")
        }
    }

    let pofu: Figure
    let mochi: Figure
    let findik: Figure

    init(layout: GardenLayout, textures: GardenTextures, reduceMotion: Bool) {
        let ground = textures.groundShadow()
        pofu = Figure(texture: textures.art(.pofu), shadowTexture: ground, feet: layout.pofu, height: layout.pofuHeight)
        mochi = Figure(texture: textures.art(.mochi), shadowTexture: ground, feet: layout.mochi, height: layout.residentHeight)
        findik = Figure(texture: textures.art(.findik), shadowTexture: ground, feet: layout.findik, height: layout.residentHeight)
        pofu.root.zPosition = 1
        if GardenTextures.image(.pofuPuff) != nil {
            // Same canvas as the base (baked together), so it lies exactly
            // over him and breathes with him as a child of his sprite.
            let puff = SKSpriteNode(texture: textures.art(.pofuPuff), size: pofu.sprite.size)
            puff.anchorPoint = CGPoint(x: 0.5, y: 0)
            puff.alpha = 0
            puff.zPosition = 0.5
            pofu.sprite.addChild(puff)
            pofu.puff = puff
        }
        // The drawn stand-in's blush sits on his painted cheeks.
        let size = pofu.sprite.size
        for x in [-0.24, 0.24] where pofu.puff == nil {
            let blush = SKSpriteNode(texture: textures.blush(), size: CGSize(width: size.width * 0.2, height: size.width * 0.14))
            blush.position = CGPoint(x: size.width * CGFloat(x), y: size.height * 0.45)
            blush.alpha = 0
            blush.zPosition = 1
            pofu.body.addChild(blush)
            pofu.blushes.append(blush)
        }
        if !reduceMotion {
            pofu.breathe(period: 2.8, phase: 0)
            mochi.breathe(period: 3.2, phase: 0.7)
            findik.breathe(period: 3.0, phase: 1.3)
        }
    }

    func add(to layer: SKNode) {
        for figure in [mochi, findik, pofu] {
            layer.addChild(figure.root)
        }
    }

    /// Mochi hops at every bloom; Fındık rolls at a double bloom or a
    /// combo; Pofu hops along from a combo of three.
    func react(lines: Int, combo: Int, reduceMotion: Bool) {
        mochi.hop(height: 12 + 4 * CGFloat(min(combo, 3)), reduceMotion: reduceMotion)
        if lines >= 2 || combo >= 2 {
            findik.roll(delay: 0.06, reduceMotion: reduceMotion)
        }
        if lines >= 3 || combo >= 3 {
            pofu.hop(height: 10, delay: 0.12, reduceMotion: reduceMotion)
        }
    }

    func cheer(reduceMotion: Bool) {
        pofu.hop(height: 16, reduceMotion: reduceMotion)
        mochi.hop(height: 12, delay: 0.1, reduceMotion: reduceMotion)
        findik.hop(height: 12, delay: 0.18, reduceMotion: reduceMotion)
    }
}

// MARK: - Easing

extension SKAction {
    /// This action with a `GameEasing` curve as its timing function.
    func eased(_ curve: @escaping @Sendable (Double) -> Double) -> SKAction {
        timingFunction = { Float(curve(Double($0))) }
        return self
    }
}
#endif
