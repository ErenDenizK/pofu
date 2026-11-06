import Testing
import PofuDesignSystem

@Suite("Sticker")
struct StickerTests {
    @Test("Every sticker names its asset after its manifest id")
    func assetNames() {
        for sticker in Sticker.allCases {
            #expect(sticker.assetName.hasPrefix("sticker-"))
            #expect(!sticker.fallbackSymbol.isEmpty)
        }
        #expect(Set(Sticker.allCases.map(\.assetName)).count == Sticker.allCases.count)
    }

    @Test("Residents map to their reaction, others to none")
    func residents() {
        #expect(Sticker.reaction(forResident: "mochi") == .mochiHappy)
        #expect(Sticker.reaction(forResident: "goat") == .goatIndignant)
        #expect(Sticker.reaction(forResident: "gezgin") == nil)
    }

    @Test("The day's mood is never a reproach")
    func dayMood() {
        #expect(Sticker.dayMood(skipped: 0, reaches: 0) == .pofuTea)
        #expect(Sticker.dayMood(skipped: 2, reaches: 4) == .pofuProud)
        #expect(Sticker.dayMood(skipped: 1, reaches: 4) == .pofuHappy)
        #expect(Sticker.dayMood(skipped: 0, reaches: 3) == .pofuWaving)
    }
}
