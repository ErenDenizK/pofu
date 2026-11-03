import Foundation
import Testing
@testable import PofuWorld

@Suite("Graphics spike: depth of field and relighting maths")
struct GraphicsSpikeMathTests {
    // MARK: Blur radius

    @Test func theFocusSlabIsSharp() {
        let dof = DepthOfField(focus: 54, slab: 12, range: 120, maxRadius: 9)
        #expect(dof.blurRadius(depth: 54) == 0)
        #expect(dof.blurRadius(depth: 54 + 12) == 0)
        #expect(dof.blurRadius(depth: 54 - 12) == 0)
    }

    @Test func blurGrowsInFrontAndBehind() {
        let dof = DepthOfField(focus: 0, slab: 10, range: 100, maxRadius: 10)
        var last = 0.0
        for d in stride(from: 10.0, through: 110.0, by: 10) {
            let r = dof.blurRadius(depth: d)
            #expect(r >= last)
            last = r
        }
        last = 0
        for d in stride(from: -10.0, through: -110.0, by: -10) {
            let r = dof.blurRadius(depth: d)
            #expect(r >= last)
            last = r
        }
        #expect(dof.blurRadius(depth: 110) > 0)
        #expect(dof.blurRadius(depth: -110) > 0)
    }

    @Test func blurIsCappedAndBehindBlursMore() {
        let dof = DepthOfField(focus: 0, slab: 10, range: 100, maxRadius: 10, behindBias: 1.2)
        #expect(abs(dof.blurRadius(depth: 5000) - 10) < 1e-9)
        #expect(abs(dof.blurRadius(depth: -5000) - 10) < 1e-9)
        #expect(dof.blurRadius(depth: -50) > dof.blurRadius(depth: 50))
    }

    @Test func theCurveIsSmooth() {
        let dof = DepthOfField(focus: 0, slab: 0, range: 100, maxRadius: 10, behindBias: 1)
        #expect(abs(dof.blurRadius(depth: 50) - 5) < 1e-9)
        #expect(dof.blurRadius(depth: 1) < 0.01)
    }

    @Test func nonFiniteDepthIsSharp() {
        let dof = DepthOfField(focus: 0)
        #expect(dof.blurRadius(depth: .nan) == 0)
        #expect(dof.blurRadius(depth: .infinity) == 0)
    }

    // MARK: Depth mapping

    @Test func groundDepthFollowsTheScreenRow() {
        let pose = CameraPose(logScale: log(2.4), lookX: 0, lookY: 10, anchorY: 500)
        // The look point's row sits at the anchor.
        let atLook = DepthOfField.groundDepth(screenY: 500, pose: pose)
        #expect(abs(atLook - IslandLayout.depth(ofY: 10)) < 1e-9)
        // Lower on screen is nearer (larger depth).
        #expect(DepthOfField.groundDepth(screenY: 600, pose: pose) > atLook)
        #expect(DepthOfField.groundDepth(screenY: 400, pose: pose) < atLook)
    }

    @Test func screenRowAndDepthAreInverses() {
        let pose = CameraPose(logScale: log(1.7), lookX: 5, lookY: -4, anchorY: 380)
        for row in stride(from: 0.0, through: 900, by: 75) {
            let depth = DepthOfField.groundDepth(screenY: row, pose: pose, offsetY: 12)
            let back = DepthOfField.screenY(forDepth: depth, pose: pose, offsetY: 12)
            #expect(abs(back - row) < 1e-9)
        }
    }

    @Test func theGroundOnTheFocusRowIsSharpAndTheBackOfTheLawnIsSoft() {
        let pose = CameraPose(logScale: log(2.4), lookX: 0, lookY: 10, anchorY: 500)
        let focus = IslandLayout.depth(ofY: IslandLayout.pofu.y)
        let dof = DepthOfField(focus: focus)
        let pofuRow = DepthOfField.screenY(forDepth: focus, pose: pose)
        #expect(dof.blurRadius(depth: DepthOfField.groundDepth(screenY: pofuRow, pose: pose)) == 0)
        let backRow = DepthOfField.screenY(forDepth: IslandLayout.depth(ofY: -40), pose: pose)
        #expect(dof.blurRadius(depth: DepthOfField.groundDepth(screenY: backRow, pose: pose)) > 3)
    }

    @Test func encodingRoundTripsAndClamps() {
        for depth in [-400.0, -80, 0, 54, 200] {
            let e = DepthOfField.encoded(depth)
            #expect(e >= 0 && e <= 1)
            #expect(abs(DepthOfField.decoded(e) - depth) < 1e-9)
        }
        #expect(DepthOfField.encoded(-1000) == 0)
        #expect(DepthOfField.encoded(1000) == 1)
    }

    @Test func shaderUnitsMatchWorldUnits() {
        let dof = DepthOfField(focus: 54, slab: 12, range: 120, maxRadius: 9, behindBias: 1)
        let p = dof.shaderParameters
        for depth in [-86.0, 0, 30, 54, 100, 172] {
            let distance = abs(DepthOfField.encoded(depth) - p.focus)
            let t = min(max((distance - p.slab) / p.range, 0), 1)
            let radius = p.maxRadius * t * t * (3 - 2 * t)
            #expect(abs(radius - dof.blurRadius(depth: depth)) < 1e-9)
        }
    }

    // MARK: Relighting

    private func rig(strength: Double = 1, practicals: [RelightRig.WorldPractical] = []) -> RelightRig {
        RelightRig(
            keyX: -0.5,
            keyY: 0.5,
            keyZ: 0.7071,
            keyColour: GradeRGB(1, 0.96, 0.9),
            ambient: GradeRGB(0.3, 0.35, 0.4),
            rim: GradeRGB(0.3, 0.25, 0.2),
            practicals: practicals,
            strength: strength
        )
    }

    private let albedo = GradeRGB(0.6, 0.5, 0.4)
    private let flat = RelightMath.Normal(0, 0, 1)

    @Test func aFlatSurfaceKeepsItsPaintedColour() {
        let out = RelightMath.shade(albedo: albedo, normal: flat, x: 10, y: 10, rig: rig())
        #expect(abs(out.r - albedo.r) < 1e-9 && abs(out.g - albedo.g) < 1e-9 && abs(out.b - albedo.b) < 1e-9)
    }

    @Test func zeroStrengthChangesNothing() {
        let n = RelightMath.normal(r: 0.2, g: 0.7, b: 0.9)
        let ember = RelightRig.WorldPractical(point: WorldPoint(x: 0, y: 0), height: 12, radius: 80, colour: GradeRGB(1, 0.6, 0.3))
        let out = RelightMath.shade(albedo: albedo, normal: n, x: 5, y: 5, rig: rig(strength: 0, practicals: [ember]))
        #expect(out == albedo)
    }

    @Test func slopesFacingTheKeyBrightenAndAwayDarken() {
        // The key comes from the upper left: (-0.5, +0.5 up, 0.7).
        let toward = RelightMath.shade(albedo: albedo, normal: .init(-0.6, 0.6, 0.529), x: 0, y: 0, rig: rig())
        let away = RelightMath.shade(albedo: albedo, normal: .init(0.6, -0.6, 0.529), x: 0, y: 0, rig: rig())
        #expect(toward.r > albedo.r)
        #expect(away.r < albedo.r)
    }

    @Test func aPracticalLightsNearbyPixelsMoreThanFarOnes() {
        let ember = RelightRig.WorldPractical(point: WorldPoint(x: 0, y: 0), height: 12, radius: 80, colour: GradeRGB(1, 0.6, 0.3))
        let r = rig(practicals: [ember])
        let near = RelightMath.shade(albedo: albedo, normal: flat, x: 10, y: 0, rig: r)
        let far = RelightMath.shade(albedo: albedo, normal: flat, x: 70, y: 0, rig: r)
        let outside = RelightMath.shade(albedo: albedo, normal: flat, x: 200, y: 0, rig: r)
        #expect(near.r > far.r)
        #expect(far.r > outside.r)
        #expect(abs(outside.r - albedo.r) < 1e-9)
        // The albedo tints the warm light: red gains most.
        #expect(near.r - albedo.r > near.b - albedo.b)
    }

    @Test func aPracticalLightsASlopeFacingItAndNotOneFacingAway() {
        let ember = RelightRig.WorldPractical(point: WorldPoint(x: 40, y: 0), height: 4, radius: 120, colour: GradeRGB(1, 0.6, 0.3))
        var r = rig(practicals: [ember])
        r.keyColour = GradeRGB(0, 0, 0)
        // A pixel left of the light: a normal facing right (+x) catches it.
        let facing = RelightMath.shade(albedo: albedo, normal: .init(0.8, 0, 0.6), x: 0, y: 0, rig: r)
        let backing = RelightMath.shade(albedo: albedo, normal: .init(-0.8, 0, 0.6), x: 0, y: 0, rig: r)
        #expect(facing.r > backing.r)
    }

    @Test func theRimOnlyAppearsOnTheKeySide() {
        let black = GradeRGB(0, 0, 0)
        let towardKey = RelightMath.shade(albedo: black, normal: .init(-0.9, 0.3, 0.3), x: 0, y: 0, rig: rig())
        let awayFromKey = RelightMath.shade(albedo: black, normal: .init(0.9, -0.3, 0.3), x: 0, y: 0, rig: rig())
        #expect(towardKey.r > 0.05)
        #expect(awayFromKey.r < 1e-9)
    }

    @Test func normalDecodingIsUnit() {
        let n = RelightMath.normal(r: 0.5, g: 0.5, b: 1)
        #expect(abs(n.x) < 1e-9 && abs(n.y) < 1e-9 && abs(n.z - 1) < 1e-9)
        let t = RelightMath.normal(r: 0.9, g: 0.2, b: 0.8)
        #expect(abs((t.x * t.x + t.y * t.y + t.z * t.z) - 1) < 1e-9)
    }

    @Test func theRigFollowsTheColourScript() {
        let day = WorldLight.at(hour: 12, wellbeing: 78, calm: 1.4, isBedtime: false, darkAppearance: false)
        let golden = WorldLight.at(hour: 18.5, wellbeing: 78, calm: 1.4, isBedtime: false, darkAppearance: false)
        let dayRig = RelightRig.make(light: day, emitters: IslandLayout.emitters, strength: 1)
        let goldenRig = RelightRig.make(light: golden, emitters: IslandLayout.emitters, strength: 1)
        // Day: from the left; golden: from the right.
        #expect(dayRig.keyX < 0)
        #expect(goldenRig.keyX > 0)
        for r in [dayRig, goldenRig] {
            #expect(abs((r.keyX * r.keyX + r.keyY * r.keyY + r.keyZ * r.keyZ) - 1) < 1e-9)
        }
        // Golden's key is honey, warmer than day's.
        #expect(goldenRig.keyColour.r - goldenRig.keyColour.b > dayRig.keyColour.r - dayRig.keyColour.b)
    }
}
