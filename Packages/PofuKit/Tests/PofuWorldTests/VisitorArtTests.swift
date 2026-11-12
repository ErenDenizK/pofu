import PofuCore
@testable import PofuWorld
import Testing

/// Nothing on Home stands in for a painting (route R3): who may visit is exactly who has painted
/// visitor art, and the visit's pieces (the parcel, the quiet day's letter, Koke's moss and
/// Çağlayan's fountain) are baked sprites.
struct VisitorArtTests {
    private func hasArt(_ resident: ResidentID) -> Bool {
        WorldArt.sprite("visitor-\(resident.rawValue)")?.sharp != nil
    }

    @Test func everyVisitingResidentHasPaintedArt() {
        for resident in VisitorRules.shipped.visiting ?? [] {
            #expect(hasArt(resident), "\(resident.rawValue) may visit but has no painted visitor sprite")
        }
    }

    @Test func noResidentWithPaintedArtIsLeftOut() {
        let visiting = VisitorRules.shipped.visiting ?? []
        for profile in VisitorSchedule.standardRoster where hasArt(profile.resident) {
            #expect(visiting.contains(profile.resident), "\(profile.resident.rawValue) has art but cannot visit")
        }
    }

    @Test func residentsWithoutPaintedArtDoNotVisit() {
        let visiting = VisitorRules.shipped.visiting ?? []
        let unpainted = (VisitorSchedule.standardRoster.map(\.resident) + [.gezgin]).filter { !hasArt($0) }
        #expect(!unpainted.isEmpty, "Sumi's art waits for batch 83")
        for resident in unpainted {
            #expect(!visiting.contains(resident), "\(resident.rawValue)")
        }
    }

    @Test func theVisitsPiecesArePainted() {
        for name in [VisitorArt.giftParcel, VisitorArt.guestLetter, "gift-moss", "gift-fountain"] {
            #expect(WorldArt.sprite(name)?.sharp != nil, "\(name) has no baked sprite")
        }
    }

    @Test func theLetterListsOnlyPaintedResidents() {
        let met = VisitorSchedule.standardRoster.map(\.resident)
        let choices = VisitorStage.inviteChoices(met: met)
        #expect(choices.allSatisfy(hasArt))
        #expect(!choices.contains(.sumi))
        #expect(choices.contains(.damla))
    }
}
