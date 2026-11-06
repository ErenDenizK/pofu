import Foundation
import Testing
@testable import PofuCompanion

@Suite("Pofu's face by mood")
struct PofuExpressionTests {
    @Test("every mood maps to a drawable face")
    func everyMoodIsValid() {
        for mood in PofuMood.allCases {
            #expect(PofuExpression.isValid(PofuExpression.parts(for: mood)), "\(mood)")
        }
    }

    @Test("the mapping is fixed")
    func mapping() {
        #expect(PofuExpression.parts(for: .calm).isEmpty)
        #expect(PofuExpression.parts(for: .happy) == [.mouthOpen, .pawsWave])
        #expect(PofuExpression.parts(for: .sleepy) == [.earsDroop])
        #expect(PofuExpression.parts(for: .proud) == [.mouthSmirk])
        #expect(PofuExpression.parts(for: .curious) == [.mouthO])
        #expect(PofuExpression.parts(for: .worried) == [.mouthWorried])
        #expect(PofuExpression.parts(for: .relieved) == [.earsDroop, .mouthSmirk])
    }

    @Test("worried never droops the ears or closes the eyes (ADR-0017)")
    func neverSadGuilt() {
        #expect(!PofuExpression.parts(for: .worried).contains(.earsDroop))
        #expect(PofuExpression.restingLidClosure(for: .worried) == 0)
        #expect(PofuExpression.restingLidClosure(for: .sleepy) > PofuExpression.restingLidClosure(for: .relieved))
    }

    @Test("opacity follows membership")
    func opacity() {
        #expect(PofuExpression.opacity(of: .mouthO, in: .curious) == 1)
        #expect(PofuExpression.opacity(of: .mouthO, in: .happy) == 0)
    }

    #if canImport(ImageIO)
    @Test("every part's image is bundled")
    func partsAreBundled() {
        for part in PofuFacePart.allCases {
            #expect(CompanionArt.resourceURL(named: part.resourceName) != nil, "\(part)")
        }
    }
    #endif
}
