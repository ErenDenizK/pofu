import Foundation
@testable import PofuWorld
import Testing

/// Sky sets (ADR-0025): the shipped layers and their motion. The motion constants come from
/// `Plates/skyset-home.json`, the file `tools/plate/skyset_render.py` also reads.
struct SkySetTests {
    static let lights = ["day", "golden", "night"]

    func sky(_ light: String) throws -> SkySet {
        let file = try #require(SkySetFile.shipped("home"), "the package ships Plates/skyset-home.json")
        return try #require(file.lights[light], "a sky set for \(light)")
    }

    @Test func homeHasASkySetForItsThreeLevelTenLights() throws {
        for light in Self.lights {
            #expect(try sky(light).light == light)
        }
        let plate = try #require(HomePlate.shipped)
        #expect(HomePlate(plate: plate.plate, light: "day", stage: 0).skySet != nil)
        #expect(HomePlate(plate: plate.plate, light: "golden", stage: 0).skySet != nil)
        #expect(HomePlate(plate: plate.plate, light: "night", stage: 0).skySet != nil)
        // The lower levels keep their plate until they are split.
        #expect(HomePlate(plate: plate.plate, light: "day", stage: 1).skySet == nil)
        #expect(HomePlate(plate: plate.plate, light: "day", stage: 8).skySet == nil)
    }

    @Test func layersRunBottomToTopEndingInTheIslandAndTheSkyIsFirst() throws {
        for light in Self.lights {
            let set = try sky(light)
            #expect(set.layers.first?.role == .sky)
            #expect(set.layers.last?.role == .island, "\(light)")
            let ids = set.layers.map(\.id)
            #expect(Set(ids).count == ids.count)
            let far = try #require(ids.firstIndex(of: "far")), mid = try #require(ids.firstIndex(of: "mid")), sea = try #require(ids.firstIndex(of: "sea"))
            let whale = try #require(ids.firstIndex(of: "whale"))
            #expect(far < whale && whale < mid && mid < sea)
            // The island stands still: no drift, no bob.
            let island = try #require(set.layers.last)
            #expect(island.drift == 0 && island.bob == nil && island.twinkle == nil)
        }
    }

    @Test func cloudsDriftAtTheStatedRatesAndTheSkyStandsStill() throws {
        let set = try sky("day")
        func rate(_ id: String) -> Double? { set.layers.first { $0.id == id }?.drift }
        #expect(rate("far") == 4)
        #expect(rate("mid") == 9)
        #expect(rate("sea") == 14)
        #expect(set.layers.first { $0.id == "sky" }?.drift == 0)
        for id in ["far", "mid", "sea"] {
            let bob = try #require(set.layers.first { $0.id == id }?.bob)
            #expect(bob.amp == 3 && bob.period == 8)
        }
        for id in ["isle_falls", "isle_house", "isle_dome", "isle_crystal"] {
            let layer = try #require(set.layers.first { $0.id == id })
            #expect(layer.bob?.amp == 2 && layer.drift == 0, "\(id) bobs and does not drift")
        }
        #expect(set.layers.first { $0.id == "whale" }?.drift == 5)
    }

    @Test func onlyNightHasStarsAndTheyAreThePaintedOnesOwnLight() throws {
        for light in ["day", "golden"] {
            #expect(try sky(light).layers.allSatisfy { $0.role != .stars })
        }
        let stars = try sky("night").layers.filter { $0.role == .stars }
        #expect(stars.count == 3)
        #expect(Set(stars.compactMap { $0.twinkle?.period }).count == 3, "the groups twinkle on different beats")
    }

    @Test func everyLayerIsAnImagesetOnDisk() throws {
        let catalog = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/PofuWorld/Resources/World.xcassets")
        for light in Self.lights {
            for layer in try sky(light).layers {
                let file = catalog.appendingPathComponent("\(layer.asset).imageset/\(layer.asset).heic")
                #expect(FileManager.default.fileExists(atPath: file.path), "\(layer.asset)")
            }
        }
    }

    @Test func eachStateFitsTheTextureBudget() throws {
        for light in Self.lights {
            let set = try sky(light)
            #expect(PlateMath.budgetOK(set), "\(light): \(set.textureBytes) bytes")
            #expect(set.textureBytes > 1_000_000)
        }
        // The plate states that keep the plate fit as before.
        #expect(PlateMath.budgetOK(try #require(HomePlate.shipped).plate))
    }

    @Test func layersLieOnTheMaster() throws {
        for light in Self.lights {
            let set = try sky(light)
            for layer in set.layers where layer.role != .sky {
                // The moon's halo runs on above the plate's top edge.
                #expect(layer.pos.x >= 0 && (layer.pos.y >= 0 || layer.id == "moon"), "\(layer.id)")
                #expect(layer.pos.x + layer.size.x <= set.master.x + 0.5, "\(layer.id)")
            }
            for layer in set.layers where layer.role == .tile {
                #expect(layer.tileWidth == set.master.x, "\(layer.id) wraps over the master's width")
            }
        }
    }

    // MARK: Motion

    @Test func timeZeroIsThePainting() throws {
        for light in Self.lights {
            for layer in try sky(light).layers {
                #expect(SkyMotion.bob(layer.bob, time: 0, scale: 1) == 0, "\(layer.id)")
                #expect(SkyMotion.twinkle(layer.twinkle, time: 0) == 0)
                #expect(SkyMotion.drift(rate: layer.drift, time: 0, tileWidth: 465, scale: 1) == 0)
            }
        }
    }

    @Test func driftWrapsSeamlesslyWithinOneTile() {
        let tile = 465.0
        var last = -1.0
        var wrapped = false
        for i in 0...2000 {
            let x = SkyMotion.drift(rate: 14, time: Double(i) * 0.5, tileWidth: tile, scale: 1)
            #expect(x >= 0 && x < tile)
            if x < last { wrapped = true }
            last = x
        }
        #expect(wrapped)
        // A tile's shift of exactly its width is the picture again.
        #expect(SkyMotion.drift(rate: 1, time: tile, tileWidth: tile, scale: 1) == 0)
        // Scaled by the screen: a third of a point per reference px on a 402 pt screen.
        #expect(abs(SkyMotion.drift(rate: 4, time: 3, tileWidth: 1000, scale: SkyMotion.scale(width: 402, referenceWidth: 1206)) - 4) < 1e-9)
    }

    @Test func theBobStaysWithinItsAmplitudeAndBreathesOverItsPeriod() {
        let bob = SkySet.Bob(amp: 3, period: 8, sign: 1)
        var most = 0.0
        for i in 0...800 {
            most = max(most, abs(SkyMotion.bob(bob, time: Double(i) * 0.05, scale: 1)))
        }
        #expect(most <= 3 + 1e-9 && most > 2.99)
        #expect(abs(SkyMotion.bob(bob, time: 2, scale: 1) - 3) < 1e-9)
        #expect(abs(SkyMotion.bob(bob, time: 8, scale: 1)) < 1e-9)
        #expect(SkyMotion.bob(SkySet.Bob(amp: 3, period: 8, sign: -1), time: 2, scale: 1) < 0)
    }

    @Test func theWhaleGlidesRightAndWrapsOnlyOffScreen() {
        let screen = 402.0, width = 150.0, margin = SkyMotion.glideMargin / 3
        let scale = SkyMotion.scale(width: screen, referenceWidth: 1206)
        let rest = 120.0
        #expect(abs(SkyMotion.glideLeft(restLeft: rest, width: width, speed: 5, time: 0, screenWidth: screen, scale: scale) - rest) < 1e-6)
        var last = rest
        var wraps = 0
        for i in 1...4_000 {
            let left = SkyMotion.glideLeft(restLeft: rest, width: width, speed: 5, time: Double(i) * 0.1, screenWidth: screen, scale: scale)
            if left < last - 1 {
                wraps += 1
                // A wrap jumps from past the right edge to past the left one: never a visible whale.
                #expect(last >= screen, "it left the right edge before it wrapped")
                #expect(left + width <= 0, "and came back from beyond the left one")
            } else {
                #expect(left - last < 1, "otherwise a smooth glide")
            }
            last = left
        }
        #expect(wraps >= 1)
        #expect(margin > 0)
    }

    @Test func twinkleBrightensAndNeverDims() {
        let tw = SkySet.Twinkle(peak: 0.9, period: 4)
        for i in 0...400 {
            let v = SkyMotion.twinkle(tw, time: Double(i) * 0.05)
            #expect(v >= 0 && v <= 0.9 + 1e-9)
        }
        #expect(abs(SkyMotion.twinkle(tw, time: 2) - 0.9) < 1e-9)
    }

    @Test func theIslandLayerCoversTheIslandsArtAtThePlatesPlacement() throws {
        let plate = try #require(HomePlate.shipped)
        let home = HomePlate(plate: plate.plate, light: "day", stage: 0)
        let set = try sky("day")
        let island = try #require(set.layers.last)
        let box = home.worldBox(
            master: PlateRect(minX: island.pos.x, minY: island.pos.y, maxX: island.pos.x + island.size.x, maxY: island.pos.y + island.size.y),
            of: set
        )
        // The layer is the island's art plus the cloud bank round its base: it contains the art's box.
        let art = home.islandBox
        #expect(box.minX <= art.minX + 1 && box.maxX >= art.maxX - 1)
        #expect(box.minY <= art.minY && box.maxY >= art.maxY)
        // And it is placed by the plate's own transform: its width is the master's width in world units.
        #expect(abs(box.width - home.plateBox.width) < 1e-6)
    }

    // MARK: Çağlayan (landscape plates on a portrait master)

    @Test func caglayansDayHasASkySetAtEveryStoryStage() throws {
        let island = try #require(HomePlate.caglayanIsland)
        let file = try #require(SkySetFile.shipped("caglayan"), "the package ships Plates/skyset-caglayan.json")
        let frame = try #require(file.lights["day-4"]?.plateFrame, "the plates' place on the master")
        var islandAssets: Set<String> = []
        for stage in 0..<5 {
            let state = HomePlate(plate: island, light: "day", stage: stage, placement: CaglayanLayout.placement)
            let set = try #require(state.skySet, "stage \(stage)")
            #expect(set.light == "day")
            #expect(set.layers.first?.role == .sky)
            let top = try #require(set.layers.last)
            #expect(top.role == .island && top.drift == 0 && top.bob == nil, "the island never moves")
            islandAssets.insert(top.asset)
            #expect(set.plateFrame == frame)
            #expect(PlateMath.budgetOK(set), "stage \(stage): \(set.textureBytes) bytes")
        }
        #expect(islandAssets.count == 5, "each stage's plate cuts its own island layer")
        // Golden, night and rain have their own sets too (`CaglayanPlateDataTests`).
        for (light, stage) in [("golden", 4), ("night", 0), ("night", 4), ("rain", 4)] {
            #expect(HomePlate(plate: island, light: light, stage: stage, placement: CaglayanLayout.placement).skySet?.light == light, "\(light) \(stage)")
        }
    }

    @Test func caglayansSkyKeepsHomesMotionConstants() throws {
        let set = try #require(SkySet.shipped(island: "caglayan", light: "day", stage: 4))
        let layers = Dictionary(uniqueKeysWithValues: set.layers.map { ($0.id, $0) })
        #expect(["far", "mid", "sea"].compactMap { layers[$0]?.drift } == [4, 9, 14])
        for id in ["far", "mid", "sea"] {
            let bob = try #require(layers[id]?.bob)
            #expect(bob.amp == 3 && bob.period == 8)
        }
        for sprite in set.layers where sprite.role == .sprite {
            #expect(try #require(sprite.bob).amp == 2, "\(sprite.id)")
        }
        // The layers below the island are shared by every stage.
        let first = try #require(SkySet.shipped(island: "caglayan", light: "day", stage: 0))
        #expect(first.layers.dropLast().map(\.asset) == set.layers.dropLast().map(\.asset))
    }

    @Test func theSkySetIsPlacedByTheIslandNotByTheMasterAtThePlatesScale() throws {
        let island = try #require(HomePlate.caglayanIsland)
        let state = HomePlate(plate: island, light: "day", stage: 4, placement: CaglayanLayout.placement)
        let set = try #require(state.skySet)
        let top = try #require(set.layers.last)
        let box = state.worldBox(
            master: PlateRect(minX: top.pos.x, minY: top.pos.y, maxX: top.pos.x + top.size.x, maxY: top.pos.y + top.size.y),
            of: set
        )
        // The island layer is the island's art plus its cloud bank: it holds the plate's island box, to a world unit.
        let art = state.islandBox
        #expect(box.minX <= art.minX + 1.5 && box.maxX >= art.maxX - 1.5)
        #expect(box.minY <= art.minY + 1.5 && box.maxY >= art.maxY - 1.5)
        #expect(abs(box.width - art.width) < 0.04 * art.width, "and is about as wide, not the master's width")
        // The master reaches past the landscape plate above and below: the sky is taller than the plate.
        let master = state.worldBox(master: PlateRect(minX: 0, minY: 0, maxX: set.master.x, maxY: set.master.y), of: set)
        #expect(master.height > 2.2 * state.plateBox.height)
        #expect(abs(master.width - state.plateBox.width) < 0.01 * master.width)
    }

    // MARK: Painted detail (isles and whale)

    @Test func theFallsLampsAndCanopiesAreShippedOnTheSpritesOnly() throws {
        for light in Self.lights {
            let set = try sky(light)
            let withDetail = set.layers.filter { !$0.details.isEmpty }
            #expect(Set(withDetail.map(\.id)) == ["isle_falls", "whale"], "\(light)")
            for layer in set.layers where layer.role != .sprite && layer.role != .whale {
                #expect(layer.details.isEmpty, "\(layer.id): the island and the clouds carry none")
            }
            for layer in withDetail {
                #expect(layer.details.contains { $0.kind == .fall }, "\(light) \(layer.id) has a waterfall")
                for d in layer.details {
                    // A detail lies inside its sprite.
                    #expect(d.pos.x >= layer.pos.x - 0.5 && d.pos.y >= layer.pos.y - 0.5, "\(d.id)")
                    #expect(d.pos.x + d.size.x <= layer.pos.x + layer.size.x + 0.5, "\(d.id)")
                    #expect(d.pos.y + d.size.y <= layer.pos.y + layer.size.y + 0.5, "\(d.id)")
                }
            }
        }
    }

    @Test func detailAssetsAreImagesetsOnDisk() throws {
        let catalog = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/PofuWorld/Resources/World.xcassets")
        for light in Self.lights {
            for layer in try sky(light).layers {
                for d in layer.details {
                    for name in [d.mask, d.flow, d.crop, d.asset].compactMap({ $0 }) {
                        let file = catalog.appendingPathComponent("\(name).imageset/\(name).png")
                        #expect(FileManager.default.fileExists(atPath: file.path), "\(name)")
                    }
                }
            }
        }
    }

    @Test func detailTimeZeroIsThePainting() throws {
        for light in Self.lights {
            for layer in try sky(light).layers {
                for d in layer.details {
                    #expect(SkyMotion.ease(time: 0, ramp: d.ramp) == 0)
                    #expect(SkyMotion.flicker(d, time: 0) == 0)
                    #expect(SkyMotion.sway(d, time: 0, scale: 1) == 0)
                    if let mist = d.mist { #expect(SkyMotion.mist(mist, time: 0, ease: 0) == 0) }
                }
            }
        }
    }

    @Test func theEnvelopeRisesSmoothlyFromZeroToOne() {
        #expect(SkyMotion.ease(time: 0, ramp: 1.5) == 0)
        #expect(abs(SkyMotion.ease(time: 0.75, ramp: 1.5) - 0.5) < 1e-9)
        #expect(SkyMotion.ease(time: 1.5, ramp: 1.5) == 1)
        #expect(SkyMotion.ease(time: 99, ramp: 1.5) == 1)
        var last = 0.0
        for i in 0...150 {
            let e = SkyMotion.ease(time: Double(i) * 0.01, ramp: 1.5)
            #expect(e >= last)
            last = e
        }
    }

    @Test func aFallsStreaksScrollDownAtTheStatedRateAndWrapWithinOneTile() {
        // 20 reference px/s on a 402 pt screen (a third): 6.667 pt/s.
        let scale = SkyMotion.scale(width: 402, referenceWidth: 1206)
        #expect(abs(SkyMotion.flowOffset(speed: 20, time: 3, period: 100, scale: scale) - 20) < 1e-9)
        // After exactly one tile's worth of time the picture is the same.
        let whole = SkyMotion.flowOffset(speed: 20, time: 15, period: 100, scale: scale)
        #expect(whole < 1e-6 || abs(whole - 100) < 1e-6)
        var last = -1.0
        var wrapped = false
        for i in 0...2_000 {
            let v = SkyMotion.flowOffset(speed: 20, time: Double(i) * 0.05, period: 60, scale: scale)
            #expect(v >= 0 && v < 60)
            if v < last { wrapped = true }
            last = v
        }
        #expect(wrapped)
    }

    @Test func theMistBreathesBetweenNothingAndItsPeak() {
        let mist = SkySet.Detail.Mist(centre: PlatePoint(x: 0, y: 0), radius: PlatePoint(x: 10, y: 5), color: [1, 1, 1], peak: 0.16, period: 5)
        var most = 0.0
        for i in 0...1_000 {
            let v = SkyMotion.mist(mist, time: Double(i) * 0.01, ease: 1)
            #expect(v >= 0 && v <= 0.16 + 1e-9)
            most = max(most, v)
        }
        #expect(abs(most - 0.16) < 1e-3)
        #expect(abs(SkyMotion.mist(mist, time: 2.5, ease: 1) - 0.16) < 1e-9)
        #expect(abs(SkyMotion.mist(mist, time: 2.5, ease: 0.5) - 0.08) < 1e-9)
    }

    @Test func aLampFlickersAFewPerCentEitherWayAndASwayStaysUnderItsAmplitude() throws {
        for light in Self.lights {
            for layer in try sky(light).layers {
                for d in layer.details where d.kind == .glow {
                    #expect(d.amp > 0 && d.amp <= 0.06 + 1e-9, "\(light) \(d.id): at most +-6 %")
                    var lo = 0.0, hi = 0.0
                    for i in 0...4_000 {
                        let v = SkyMotion.flicker(d, time: Double(i) * 0.05)
                        lo = min(lo, v); hi = max(hi, v)
                    }
                    #expect(lo < -0.2 * d.amp && hi > 0.2 * d.amp, "it goes both ways")
                    #expect(lo >= -d.amp - 1e-9 && hi <= d.amp + 1e-9)
                }
                for d in layer.details where d.kind == .sway {
                    #expect(d.amp > 0 && d.amp <= 2, "\(d.id): a 1 to 2 px sway")
                    var most = 0.0
                    for i in 0...4_000 {
                        most = max(most, abs(SkyMotion.sway(d, time: Double(i) * 0.05, scale: 1)))
                    }
                    #expect(most <= d.amp + 1e-9 && most > 0.95 * d.amp)
                }
            }
        }
    }
}
