import Foundation
import PofuCore
#if os(iOS)
import SwiftUI
#endif

/// The Map in journey order (Map order A; WP6 of docs/design/world-presentation-build-spec.md): Home
/// low and in front, Koke and Çağlayan rising behind it. A slot holds the island once it is open, a
/// cloud tower while it is the next to open (its reveal is WP12's), and nothing while it is not yet
/// announced. Where the slots are, the tier pitch and the frame are `world-map.json` (`WorldMap`), relative
/// to Home's box centre; this places them on the world canvas, says what each holds for the player's
/// progress, frames each unlock, places the far picture and the horizon's haze, and bobs the islands. Pure.
public enum MapSlots {
    /// The Map's composition data shipped in the package.
    public static let map: WorldMap? = WorldMap.shipped

    /// Home's island box centre on the world canvas: `world-map.json`'s origin. The painted Home's box
    /// (one box for every state), or the sprite island's when the package has no painting.
    public static let homeCentre: WorldPoint = {
        let box = HomePlate.shipped?.islandBox ?? IslandFraming.plateBox
        return WorldPoint(x: box.midX, y: box.midY)
    }()

    /// A point given relative to Home's box centre, on the world canvas.
    public static func world(_ p: WorldPoint, homeCentre: WorldPoint = homeCentre) -> WorldPoint {
        WorldPoint(x: homeCentre.x + p.x, y: homeCentre.y + p.y)
    }

    /// An island's centre on the world canvas from its slot, or `fallback` when the package has no map.
    static func center(of island: IslandID, fallback: WorldPoint) -> WorldPoint {
        map?.center(of: island).map { world($0) } ?? fallback
    }

    // MARK: - Progress

    /// The tier-1 stage the Map shows (`WorldMap.state(of:stage:)`): 1 from day 1 (Koke's slot veiled,
    /// Çağlayan's a cloud tower), 2 once Koke can be visited (Çağlayan's veiled), 3 once Çağlayan can.
    public static func stage(koke: WonderStatus, caglayan: WonderStatus) -> Int {
        if caglayan.isArrived { return 3 }
        return koke.isArrived ? 2 : 1
    }

    /// The frame the Map shows, by the player's progress: 0 (Home's own frame) from day 1 until Koke can
    /// be visited, then the tier-1 frame until Çağlayan blooms (heals), then tier 2. Each unlock
    /// re-balances the Map; it changes only there.
    public static func tier(koke: WonderStatus, caglayan: WonderStatus) -> Int {
        if caglayan.isHealed { return 2 }
        return koke.isArrived ? 1 : 0
    }

    /// Before the first wonder island opens Home is framed alone, large: its box this share of the
    /// screen's width (founder input 32.1, a balanced layout per unlock), its foot where the tier frames
    /// put it, and the next island's tower beside it whole.
    public static let homeAloneWidth = 0.70

    /// The Map's stop at `tier` in reference points (402 x 874) on the world canvas: `WorldMap.tierFrame`
    /// moved to Home's box centre; tier 0 is Home's own frame (`homeAloneWidth`). `nil` when the package
    /// has no map.
    public static func frame(tier: Int, homeCentre: WorldPoint = homeCentre) -> CameraRail.Stop? {
        guard let map else { return nil }
        guard tier == 0 else {
            let stop = map.tierFrame(tier: tier)
            return CameraRail.Stop(scale: stop.scale, look: world(stop.look, homeCentre: homeCentre), anchorY: stop.anchorY)
        }
        let w = CameraRail.referenceWidth, h = CameraRail.referenceHeight
        let home = map.home
        // Home and the tower that stands on the screen with it, across the fit's width.
        let towers = slots(stage: 1, tier: 0, homeCentre: WorldPoint(x: 0, y: 0)).filter(\.showsTower).map(\.tower)
        let minX = ([-home.width / 2] + towers.map(\.minX)).min() ?? -home.width / 2
        let maxX = ([home.width / 2] + towers.map(\.maxX)).max() ?? home.width / 2
        let scale = min(homeAloneWidth * w / home.width, (map.fitMaxX - map.fitMinX) / max(maxX - minX, 1))
        let footWY = home.height / 2
        let anchorY = h / 2
        let look = WorldPoint(x: (minX + maxX) / 2, y: footWY - (map.footFraction * h - anchorY) / scale)
        return CameraRail.Stop(scale: scale, look: world(look, homeCentre: homeCentre), anchorY: anchorY)
    }

    // MARK: - Slots

    /// One slot as the Map draws it, on the world canvas.
    public struct Slot: Hashable, Sendable {
        public var id: String
        public var tier: Int
        public var state: SlotState
        /// The island's box (`world-map.json`'s): where an open island's painting sits.
        public var box: WorldBox
        /// The cloud tower standing on the box's foot, `towerWidth` by `towerHeight` of it.
        public var tower: WorldBox

        /// Only the next island to open shows its tower (the veiled slot); a slot not yet announced is
        /// left empty, so the Map never shows one picture twice side by side, and the next island's
        /// reveal is WP12's.
        public var showsTower: Bool { state == .veiled }
    }

    /// Every slot but Home's at `stage` and `tier`, back to front (the farthest, highest first). Home is
    /// always its own painting.
    public static func slots(stage: Int, tier: Int, homeCentre: WorldPoint = homeCentre) -> [Slot] {
        guard let map else { return [] }
        return map.slots
            .filter { $0.tier > 0 && $0.tier <= max(tier, 1) }
            .sorted { $0.center.y < $1.center.y }
            .map { slot in
                let c = world(slot.center, homeCentre: homeCentre)
                let box = WorldBox(
                    minX: c.x - slot.width / 2, minY: c.y - slot.height / 2,
                    maxX: c.x + slot.width / 2, maxY: c.y + slot.height / 2
                )
                let tw = slot.width * map.towerWidth, th = slot.height * map.towerHeight
                let tower = WorldBox(minX: c.x - tw / 2, minY: box.maxY - th, maxX: c.x + tw / 2, maxY: box.maxY)
                return Slot(id: slot.id, tier: slot.tier, state: map.state(of: slot.id, stage: stage), box: box, tower: tower)
            }
    }

    /// The cloud tower's painting (pofu-art batch 115, take 1).
    public static let towerArt = "world-cloud-tower-1"

    // MARK: - The far picture

    /// Which layer of Home's sky set stands in each of the Map's backdrop features
    /// (`world-map.json` `backdrop.map`): the crystal isle up in the empty sky above Çağlayan, the
    /// other far isles and the whale in the lane between the wonder islands and Home.
    public static let featureLayers: [String: String] = [
        "isle-top": "isle_crystal",
        "isle-lane": "isle_falls",
        "whale": "whale",
        "isle-lane-2": "isle_house",
        "isle-lane-3": "isle_dome",
    ]

    /// The moon's box on the Map at night (reference points): up in the free sky on the left, above Koke,
    /// where the sky set paints it it would stand behind Koke's island.
    public static let moonBox = ScreenBox(minX: 34, minY: 70, maxX: 104, maxY: 140)

    /// Home's sky set as the Map draws it: `PaintedSky.mapSet` (the island left out, the far isles and
    /// the whale at half their painted size, the cloud sea rearranged), each far isle and the whale moved
    /// so that at the Map's camera on the reference screen it stands in its feature's box: centred across
    /// it, its foot on the box's foot; and the whole cloud sea moved so its horizon (the farthest row's
    /// top) lies on the Map's horizon row (`WorldMap.horizon`), behind the far isles' lane, its nearer rows
    /// still running past the screen's foot. A layer with no feature keeps `mapSet`'s place. Pure.
    public static func sky(_ set: SkySet, plate: HomePlate) -> SkySet {
        var out = PaintedSky.mapSet(set)
        guard let map else { return out }
        let w = CameraRail.referenceWidth, h = CameraRail.referenceHeight
        let stop = plate.mapStop
        let camera = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        let reference = plate.skyReference(width: w, height: h)
        if let far = out.layers.first(where: { $0.asset.contains("-sea-") }), let window = far.window {
            let r = screenRect(of: far, in: out, plate: plate, camera: camera, reference: reference, width: w)
            let line = r.minY + window.top * (r.maxY - r.minY)
            let dy = (map.horizon * h - line) * far.size.y / (r.maxY - r.minY)
            out.layers = out.layers.map { $0.asset.contains("-sea-") ? moved($0, dx: 0, dy: dy) : $0 }
        }
        for (i, layer) in out.layers.enumerated() {
            let place = layer.id == "moon" ? WorldMap.Piece(id: "moon", box: moonBox) : map.mapFeatures.first { featureLayers[$0.id] == layer.id }
            guard let feature = place,
                  layer.size.x > 0, layer.size.y > 0 else { continue }
            let r = screenRect(of: layer, in: out, plate: plate, camera: camera, reference: reference, width: w)
            let dx = (feature.box.minX + feature.box.maxX) / 2 - (r.minX + r.maxX) / 2
            let dy = feature.box.maxY - r.maxY
            out.layers[i] = moved(
                layer,
                dx: dx * layer.size.x / (r.maxX - r.minX),
                dy: dy * layer.size.y / (r.maxY - r.minY)
            )
        }
        return out
    }

    /// A sky layer's box on a screen `width` wide at `camera`, through the depth function from `reference`.
    public static func screenRect(of layer: SkySet.Layer, in set: SkySet, plate: HomePlate, camera: CameraPose, reference: CameraPose, width: Double) -> ScreenBox {
        let pose = DepthLayer.pose(camera, reference: reference, k: layer.k)
        let box = plate.worldBox(
            master: PlateRect(minX: layer.pos.x, minY: layer.pos.y, maxX: layer.pos.x + layer.size.x, maxY: layer.pos.y + layer.size.y),
            of: set
        )
        let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: width)
        return ScreenBox(minX: a.x, minY: a.y, maxX: a.x + box.width * pose.scale, maxY: a.y + box.height * pose.scale)
    }

    /// A sprite and its painted detail moved by (`dx`, `dy`) master px.
    static func moved(_ layer: SkySet.Layer, dx: Double, dy: Double) -> SkySet.Layer {
        var out = layer
        out.pos = PlatePoint(x: layer.pos.x + dx, y: layer.pos.y + dy)
        out.details = layer.details.map { d in
            var d = d
            d.pos = PlatePoint(x: d.pos.x + dx, y: d.pos.y + dy)
            d.mist = d.mist.map { m in
                var m = m
                m.centre = PlatePoint(x: m.centre.x + dx, y: m.centre.y + dy)
                return m
            }
            return d
        }
        return out
    }

    // MARK: - The frame the composition rules judge

    /// The settled Map as the player sees it on the reference screen, for C1 to C6: the real stop
    /// (`HomePlate.mapStop`), Home's painted island with its name chip, Koke's and Çağlayan's painted
    /// islands where they are open and their towers where not (the tier-2 slots at tier 2), the corner
    /// control, and the far isles and the whale where Home's sky set of `light` puts them.
    public static func frame(stage: Int, plate: HomePlate, light: String = "day") -> CompositionFrame? {
        guard let map else { return nil }
        let bands = ScreenBands.reference
        let w = bands.width
        let stop = plate.mapStop
        let camera = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        func project(_ b: WorldBox) -> ScreenBox {
            let a = camera.project(WorldPoint(x: b.minX, y: b.minY), width: w)
            return ScreenBox(minX: a.x, minY: a.y, maxX: a.x + b.width * camera.scale, maxY: a.y + b.height * camera.scale)
        }
        func chipped(_ art: ScreenBox, under island: ScreenBox, chip: Double) -> ScreenBox {
            ScreenBox(minX: art.minX, minY: art.minY, maxX: art.maxX, maxY: max(art.maxY, island.maxY + map.chipGap + chip))
        }
        let homeBox = project(plate.islandBox)
        var subjects = [CompositionFrame.Subject(
            id: IslandID.home.rawValue, type: .island,
            box: chipped(homeBox, under: homeBox, chip: map.home.chip?.height ?? map.chipHeight),
            island: homeBox, art: homeBox, tappable: true
        )]
        let centre = WorldPoint(x: plate.islandBox.midX, y: plate.islandBox.midY)
        for slot in slots(stage: stage, tier: plate.mapTier, homeCentre: centre) {
            if slot.state == .island, let art = islandArt(slot.id) {
                let island = project(art.island)
                let drawn = project(art.drawn)
                subjects.append(CompositionFrame.Subject(
                    id: slot.id, type: .island,
                    box: chipped(drawn, under: island, chip: map.slot(slot.id)?.chip?.height ?? map.chipHeight),
                    island: island, art: drawn, tappable: true
                ))
            } else if slot.showsTower {
                subjects.append(CompositionFrame.Subject(
                    id: slot.id, type: .tower, box: project(slot.tower),
                    island: nil, art: nil, tappable: false
                ))
            }
        }
        var features: [WorldMap.Piece] = []
        let sky = HomePlate(plate: plate.plate, light: light, stage: 0)
        if let set = sky.skySet {
            let placed = Self.sky(set, plate: plate)
            let reference = sky.skyReference(width: w, height: bands.height)
            for (id, layerID) in featureLayers.sorted(by: { $0.key < $1.key }) {
                guard let layer = placed.layers.first(where: { $0.id == layerID }) else { continue }
                features.append(WorldMap.Piece(id: id, box: screenRect(of: layer, in: placed, plate: sky, camera: camera, reference: reference, width: w)))
            }
        }
        features.append(WorldMap.Piece(id: "lip", box: ScreenBox(minX: 0, minY: map.lipTop, maxX: w, maxY: bands.height)))
        return CompositionFrame(
            name: "map-real-tier\(plate.mapTier)-stage\(stage)-\(light)", kind: .map, bands: bands,
            horizon: map.horizon * bands.height, hero: homeBox, feet: nil,
            subjects: subjects, chrome: [map.mapCorner], features: features
        )
    }

    /// An open wonder island's boxes on the world canvas: the island the tap and the name answer to,
    /// and the painting as drawn. `nil` for a slot with no island.
    static func islandArt(_ id: String) -> (island: WorldBox, drawn: WorldBox)? {
        switch id {
        case IslandID.koke.rawValue:
            let island = KokeLayout.islandBox
            guard let art = WorldArt.sprite(String(KokeLayout.plateArt(stage: 0).dropFirst("world-".count)))?.sharp else { return (island, island) }
            let c = KokeLayout.center
            return (island, WorldBox(minX: c.x + art.minX, minY: c.y + art.minY, maxX: c.x + art.maxX, maxY: c.y + art.maxY))
        case IslandID.caglayan.rawValue:
            return (CaglayanLayout.islandBox, CaglayanLayout.islandBox)
        default:
            return nil
        }
    }

    // MARK: - The horizon's haze

    /// Until WP9's cloud beds: a soft haze over the cloud sea's horizon on the Map, so the horizon is no
    /// ruler edge and the wonder islands' feet stand in it. It rises from nothing `hazeAbove` of the
    /// screen's height above the horizon row to `hazePeak` on the row, and is gone `hazeBelow` under it.
    public static let hazeAbove = 0.2
    public static let hazeBelow = 0.07
    public static let hazePeak = 0.7
    /// Its colour by day (the light of the sea's tops); the hour's grade takes it to dusk and night.
    public static let hazeRGB = (r: 0.93, g: 0.93, b: 0.985)

    /// The haze's rows on a screen `height` tall, with the horizon on row `horizon`.
    public static func haze(horizon: Double, height: Double) -> (top: Double, bottom: Double) {
        (horizon - hazeAbove * height, horizon + hazeBelow * height)
    }

    /// The haze's opacity at screen row `y`: eased up to `hazePeak` on the horizon row and down below it.
    public static func hazeOpacity(atRow y: Double, horizon: Double, height: Double) -> Double {
        let band = haze(horizon: horizon, height: height)
        let t = y <= horizon ? (y - band.top) / max(horizon - band.top, 1e-6) : (band.bottom - y) / max(band.bottom - horizon, 1e-6)
        let c = min(max(t, 0), 1)
        return hazePeak * c * c * (3 - 2 * c)
    }

    /// The cloud sea's horizon row on the screen at `camera` (the Map's sky set as `sky` places it, the
    /// farthest row's top), on a `width` x `height` screen. `nil` without a sky set.
    public static func horizonRow(plate: HomePlate, camera: CameraPose, width: Double, height: Double) -> Double? {
        guard let source = plate.skySet else { return nil }
        let set = sky(source, plate: plate)
        guard let far = set.layers.first(where: { $0.asset.contains("-sea-") }), let window = far.window else { return nil }
        let r = screenRect(of: far, in: set, plate: plate, camera: camera, reference: plate.skyReference(width: width, height: height), width: width)
        return r.minY + window.top * (r.maxY - r.minY)
    }

    // MARK: - The bob

    /// Each island rises and sinks `bobTravel` points, top to bottom, at the Map only.
    public static let bobTravel = 2.0
    /// From this rail position in, the bob is gone (it fades out from the Map, z 0).
    public static let bobFadeZ = 0.25

    /// Seconds per bob, 6 to 9, a different one per island so they never move together.
    public static func bobPeriod(_ id: String) -> Double {
        switch id {
        case IslandID.home.rawValue: 7.0
        case IslandID.koke.rawValue: 6.2
        case IslandID.caglayan.rawValue: 8.4
        default: 6.0 + Double(id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 30) / 10
        }
    }

    /// The island's vertical offset in screen points at `time` seconds and rail position `z`: a sine of
    /// `bobTravel` top to bottom at the Map, fading out by `bobFadeZ`; none at rest (`time` nil).
    public static func bob(_ id: String, time: Double?, z: Double) -> Double {
        guard let time else { return 0 }
        let weight = 1 - min(max(z / bobFadeZ, 0), 1)
        guard weight > 0 else { return 0 }
        let phase = Double(id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 17) / 17
        return weight * bobTravel / 2 * sin(2 * Double.pi * (time / bobPeriod(id) + phase))
    }
}

#if os(iOS)
/// The next island's slot on the Map (`MapSlots`, `Slot.showsTower`): a plain cloud tower, its foot
/// dissolving into the sky (its reveal is WP12's); a slot not yet announced stays empty. Drawn behind the
/// islands, bobbing with them, and gone as the camera leaves the Map as the wonder islands are.
struct MapSlotsLayer: View {
    let slots: [MapSlots.Slot]
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize
    /// Seconds for the bob, or `nil` for the rest pose.
    let time: Double?
    let z: Double

    /// The share of the tower's height, from its top, that is drawn whole before the foot dissolves into
    /// the sky (eased: about half gone at `footHalf`), so it rises out of mist rather than ending flat.
    static let footFade = 0.6
    static let footHalf = 0.8

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(slots.filter(\.showsTower), id: \.id) { slot in
                tower(slot.tower)
                    .offset(y: CGFloat(MapSlots.bob(slot.id, time: time, z: z)))
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func tower(_ box: WorldBox) -> some View {
        let s = pose.scale
        let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: Double(size.width))
        let w = box.width * s, h = box.height * s
        return Image(MapSlots.towerArt, bundle: .module)
            .resizable()
            .interpolation(.high)
            .frame(width: CGFloat(w), height: CGFloat(h))
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: Self.footFade),
                        .init(color: .black.opacity(0.45), location: Self.footHalf),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .position(x: CGFloat(a.x + w / 2) + offset.width, y: CGFloat(a.y + h / 2) + offset.height)
    }
}

/// The Map's haze over the cloud sea's horizon (`MapSlots.hazeOpacity`), across the screen, behind the
/// islands.
struct MapHazeLayer: View {
    let horizon: Double
    let size: CGSize
    let offset: CGSize

    var body: some View {
        let h = Double(size.height)
        let band = MapSlots.haze(horizon: horizon, height: h)
        let rgb = MapSlots.hazeRGB
        let colour = Color(red: rgb.r, green: rgb.g, blue: rgb.b)
        // Rows down to the horizon, then under it, so the gradient peaks on the horizon row itself.
        let rows = (0...8).map { band.top + Double($0) / 8 * (horizon - band.top) }
            + (1...4).map { horizon + Double($0) / 4 * (band.bottom - horizon) }
        let stops = rows.map { y in
            Gradient.Stop(color: colour.opacity(MapSlots.hazeOpacity(atRow: y, horizon: horizon, height: h)), location: CGFloat((y - band.top) / (band.bottom - band.top)))
        }
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
            .frame(width: size.width, height: CGFloat(band.bottom - band.top))
            .position(x: size.width / 2 + offset.width, y: CGFloat((band.top + band.bottom) / 2) + offset.height)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
#endif
