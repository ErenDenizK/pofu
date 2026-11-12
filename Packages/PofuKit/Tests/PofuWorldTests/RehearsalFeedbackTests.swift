import Foundation
import PofuCore
import Testing
@testable import PofuWorld

/// Rehearsal feedback (game solid v1 §1, bar item 2: every action gives
/// visible feedback): the greeting's heart, the gift's tag on the day it
/// arrives, and the copy the screenshots quote.
@Suite("Rehearsal feedback")
struct RehearsalFeedbackTests {
    private func visitor(_ state: VisitState, reason: VisitReason = .gift, slot: VisitSlot = .v1) -> VisitorSnapshot {
        VisitorSnapshot(resident: .sumi, reason: reason, slot: slot, state: state, gift: .seeds(3), hearts: 1)
    }

    // MARK: - The greeting

    @Test func aGreetedVisitorWearsAHeartOverTheirHead() throws {
        let greeted = visitor(.greeted)
        let parts = VisitorStage.parts(visitor: greeted, invitationOpen: false, isBedtime: false)
        let feet = try #require(parts.first { $0.part == .visitor }).feet
        let heart = try #require(VisitorStage.greetingHeart(parts: parts, visitor: greeted))
        #expect(heart.x == feet.x)
        #expect(heart.y == feet.y - VisitorStage.heartLift)
        // On the plate it floats over the visitor at the plate's scale.
        let scaled = try #require(VisitorStage.greetingHeart(parts: parts, visitor: greeted, scale: 0.5))
        #expect(scaled.y == feet.y - VisitorStage.heartLift * 0.5)
    }

    @Test func noHeartBeforeTheGreetingOrWhileTheGuestSleeps() {
        for state in [VisitState.arriving, .present] {
            let v = visitor(state)
            #expect(VisitorStage.greetingHeart(parts: VisitorStage.parts(visitor: v, invitationOpen: false, isBedtime: false), visitor: v) == nil)
        }
        let sleeping = visitor(.greeted, reason: .stayOver, slot: .h4)
        let night = VisitorStage.parts(visitor: sleeping, invitationOpen: false, isBedtime: true)
        #expect(VisitorStage.greetingHeart(parts: night, visitor: sleeping) == nil)
        #expect(VisitorStage.greetingHeart(parts: [], visitor: nil) == nil)
    }

    // MARK: - The gifts

    @Test func aGiftWearsItsTagOnlyOnTheDayItArrives() {
        var world = IslandSamples.grownIsland()
        #expect(HomeGifts.tagged(in: world).isEmpty)
        world.koke = WonderStatus(phase: .arrived, stage: 4, giftIsNew: true)
        world.caglayan = WonderStatus(phase: .arrived, stage: 4, giftIsNew: true)
        let pondBuilt = (world.stations.first { $0.id == .pond }?.level ?? 0) > 0
        #expect(HomeGifts.tagged(in: world) == (pondBuilt ? [.kokeMoss, .caglayanFountain] : [.kokeMoss]))
        world.koke.giftIsNew = false
        world.caglayan.giftIsNew = false
        #expect(HomeGifts.shown(in: world).contains(.kokeMoss))
        #expect(HomeGifts.tagged(in: world).isEmpty)
        // Not healed: no gift, so no tag, whatever the flag says.
        world.koke = WonderStatus(phase: .arrived, stage: 3, giftIsNew: true)
        #expect(!HomeGifts.shown(in: world).contains(.kokeMoss))
        #expect(!HomeGifts.tagged(in: world).contains(.kokeMoss))
    }

    @Test func theFountainNeedsThePond() {
        var world = IslandSamples.firstDay()
        world.caglayan = WonderStatus(phase: .arrived, stage: 4, giftIsNew: true)
        #expect(!HomeGifts.tagged(in: world).contains(.caglayanFountain))
    }

    /// A tag near the screen's edge stays inside the 16 pt gutter and its
    /// tail still points at the gift.
    @Test func aBubbleKeepsTheGutterAndPointsAtItsThing() {
        let middle = TailedBubblePlacement.place(tipX: 200, width: 150, screenWidth: 402)
        #expect(middle.centreX == 200 && middle.tailOffset == 0)
        let left = TailedBubblePlacement.place(tipX: 60, width: 150, screenWidth: 402)
        #expect(left.centreX - 75 == 16)
        #expect(left.centreX + left.tailOffset == 60)
        let right = TailedBubblePlacement.place(tipX: 395, width: 150, screenWidth: 402)
        #expect(right.centreX + 75 == 402 - 16)
        // Past the bubble's corner the tail stops at the corner.
        #expect(right.tailOffset == 75 - 13 - 5)
    }

    // MARK: - Copy

    private var root: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    private func catalog() throws -> [String: Any] {
        let path = root.appendingPathComponent("Sources/PofuWorld/Resources/Localizable.xcstrings")
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: path))
        return try #require((object as? [String: Any])?["strings"] as? [String: Any])
    }

    private func turkish(_ key: String, in strings: [String: Any]) throws -> String {
        let entry = try #require(strings[key] as? [String: Any], "missing \(key)")
        let tr = try #require((entry["localizations"] as? [String: Any])?["tr"] as? [String: Any])
        return try #require((tr["stringUnit"] as? [String: Any])?["value"] as? String)
    }

    @Test func theGiftTagsHaveTurkishAndEnglish() throws {
        let strings = try catalog()
        for key in ["koke.gift", "caglayan.gift.tag"] {
            let entry = try #require(strings[key] as? [String: Any], "missing \(key)")
            let localizations = try #require(entry["localizations"] as? [String: Any])
            #expect(localizations["tr"] != nil && localizations["en"] != nil, "\(key) needs tr and en")
        }
    }

    /// The screenshots' stand-in for Pofu's away line quotes the shipped
    /// line, so one message never names two things ("ada" in the app,
    /// "bahçe" in a screenshot).
    @Test func theScreenshotsQuoteTheShippedAwayLine() throws {
        let line = try turkish("While you were away, the island gathered %lld seeds.", in: try catalog())
        let parts = line.components(separatedBy: "%lld")
        #expect(parts.count == 2)
        let folder = root.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/WorldScreenshots")
        var quoted = 0
        for file in try FileManager.default.contentsOfDirectory(atPath: folder.path) where file.hasSuffix(".swift") {
            let source = try String(contentsOf: folder.appendingPathComponent(file), encoding: .utf8)
            for chunk in source.components(separatedBy: "\"").dropFirst() where chunk.hasPrefix("Sen yokken") {
                quoted += 1
                #expect(chunk.hasPrefix(parts[0]) && chunk.hasSuffix(parts[1]), "\(file): \(chunk)")
            }
        }
        #expect(quoted >= 1)
    }
}
