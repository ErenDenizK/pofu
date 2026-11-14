import Foundation
import Testing
@testable import PofuDesignSystem

/// The baked kit faces (`tools/assets/integrate.py`, target `kit`) against
/// the caps `PofuKitArt.slicing` stretches them by.
@Suite("Kit art")
struct KitArtTests {
    static let resources = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("../../Sources/PofuDesignSystem/Resources")
        .standardizedFileURL

    /// The pixel size from a PNG's IHDR chunk.
    static func pixelSize(_ art: PofuKitArt) -> (width: Double, height: Double)? {
        let url = resources.appendingPathComponent("\(art.rawValue).png")
        guard let data = try? Data(contentsOf: url), data.count > 24 else { return nil }
        func be32(_ offset: Int) -> Double {
            Double(data[offset..<offset + 4].reduce(UInt32(0)) { $0 << 8 | UInt32($1) })
        }
        return (be32(16), be32(20))
    }

    @Test("Home's slice is baked: plaque, bubble, tail, tab, linen, disc, day and night")
    func homeSliceIsBaked() {
        let baked = Set(PofuKitArt.allCases.filter { Self.pixelSize($0) != nil })
        let home: Set<PofuKitArt> = [
            .plaqueHoney, .bubblePaper, .bubblePaperNight, .bubbleTail, .bubbleTailNight,
            .tabRibbon, .cardLinen, .cardLinenNight, .discClay, .discClayNight,
        ]
        #expect(home.isSubset(of: baked))
    }

    @Test("The sheet, card, chip, toast, groove, seal and pip faces are baked, day and night where painted")
    func stationSliceIsBaked() {
        let baked = Set(PofuKitArt.allCases.filter { Self.pixelSize($0) != nil })
        let station: Set<PofuKitArt> = [
            .sheetPaper, .sheetPaperNight, .cardStitched, .cardStitchedNight, .plaqueBare, .plaqueCream,
            .plaqueCreamPressed, .chipFelt, .chipFeltSelected, .toastStrip, .toastStripNight, .grooveWood,
            .sealResist, .pipPotEmpty, .pipPotBud, .pipPotBloom,
        ]
        #expect(station.isSubset(of: baked))
    }

    @Test("The three pip pots share one canvas, so they stand on one line")
    func pipPotsShareACanvas() throws {
        let sizes = try [PofuKitArt.pipPotEmpty, .pipPotBud, .pipPotBloom].map { try #require(Self.pixelSize($0)) }
        #expect(Set(sizes.map { "\($0.width)x\($0.height)" }).count == 1)
    }

    @Test("Every baked face has caps that fit inside it")
    func capsFit() throws {
        for art in PofuKitArt.allCases {
            guard let size = Self.pixelSize(art) else { continue }
            let scale = PofuKitArt.scale
            switch art.slicing {
            case let .nine(top, leading, bottom, trailing):
                #expect((leading + trailing) * scale < size.width, "\(art.rawValue)")
                #expect((top + bottom) * scale < size.height, "\(art.rawValue)")
            case let .ends(leading, trailing):
                #expect((leading + trailing) * size.height < size.width, "\(art.rawValue)")
            case .whole:
                #expect(size.width > 0 && size.height > 0)
            case .halfHeight:
                Issue.record("\(art.rawValue) is baked but has no slicing of its own")
            }
        }
    }

    @Test("A disc is round and a pressed plaque stands in with its rest face")
    func discsAndStandIns() throws {
        for art in [PofuKitArt.discClay, .discClayNight] {
            let size = try #require(Self.pixelSize(art))
            #expect(abs(size.width - size.height) <= 2)
        }
        #expect(PofuKitArt.plaqueHoneyPressed.standIn == .plaqueHoney)
        #expect(PofuKitArt.plaqueHoneyPressed.slicing == PofuKitArt.plaqueHoney.slicing)
    }

    @Test("Every kit file in the bundle is a hook")
    func noOrphans() throws {
        let names = try FileManager.default.contentsOfDirectory(atPath: Self.resources.path)
        let hooks = Set(PofuKitArt.allCases.map { "\($0.rawValue).png" })
        let orphans = names.filter { $0.hasPrefix("ui-") && !hooks.contains($0) }
        #expect(orphans.isEmpty, "\(orphans)")
    }
}
