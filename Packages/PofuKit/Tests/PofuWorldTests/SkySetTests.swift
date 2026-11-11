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
}
