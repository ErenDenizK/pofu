import Testing
import PofuDesignSystem

@Suite("Skin policy")
struct PofuSkinTests {
    @Test func glassIsTheDefault() {
        #expect(PofuSkinPolicy().skin == .glass)
    }

    @Test func priorityIsAccessibilityThenDeveloperThenBetaThenDefault() {
        #expect(PofuSkinPolicy(betaAssignment: .crafted).skin == .crafted)
        #expect(PofuSkinPolicy(developerOverride: .glass, betaAssignment: .crafted).skin == .glass)
        #expect(PofuSkinPolicy(reduceTransparency: true, developerOverride: .glass, betaAssignment: .glass).skin == .crafted)
    }

    @Test func roleOverridesMakeAMixedConfiguration() {
        let policy = PofuSkinPolicy(roleOverrides: [.worldTag: .crafted])
        #expect(policy.skin(for: .worldTag) == .crafted)
        #expect(policy.skin(for: .iconButton) == .glass)
        let reduced = PofuSkinPolicy(reduceTransparency: true, roleOverrides: [.worldTag: .glass])
        #expect(reduced.skin(for: .worldTag) == .crafted)
    }

    @Test func reduceTransparencyForcesTheOpaqueFaces() {
        #expect(PofuSkinPolicy.effective(.glass, reduceTransparency: true) == .crafted)
        #expect(PofuSkinPolicy.effective(.glass, reduceTransparency: false) == .glass)
        #expect(PofuSkinPolicy.effective(.crafted, reduceTransparency: false) == .crafted)
    }

    @Test func theLaunchArgumentParses() {
        #expect(PofuSkinPolicy.override(from: "crafted") == .crafted)
        #expect(PofuSkinPolicy.override(from: "Glass") == .glass)
        #expect(PofuSkinPolicy.override(from: "wood") == nil)
        #expect(PofuSkinPolicy.override(from: nil) == nil)
    }
}
