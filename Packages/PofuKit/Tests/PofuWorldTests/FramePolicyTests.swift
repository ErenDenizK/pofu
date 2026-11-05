import Foundation
import Testing
@testable import PofuWorld

@MainActor
final class PowerTestClock {
    var now = 0.0
}

@Suite("Frame policy")
struct FramePolicyTests {
    private let policy = FramePolicy()

    private func directive(_ state: FrameState, lowPower: Bool = false, thermal: ThermalLevel = .nominal, reduceMotion: Bool = false) -> FrameDirective {
        policy.directive(for: state, conditions: FrameConditions(lowPower: lowPower, thermal: thermal, reduceMotion: reduceMotion))
    }

    // MARK: States

    @Test func theDemandPicksTheHighestState() {
        #expect(policy.state(for: FrameDemand(isActive: false, isCovered: true, isDirect: true)) == .background)
        #expect(policy.state(for: FrameDemand(isCovered: true, isMinigame: true, isDirect: true)) == .covered)
        #expect(policy.state(for: FrameDemand(isMinigame: true, isDirect: true)) == .minigame)
        #expect(policy.state(for: FrameDemand(isDirect: true, isMoment: true, isVisiting: true)) == .direct)
        #expect(policy.state(for: FrameDemand(isMoment: true, isVisiting: true)) == .moment)
        #expect(policy.state(for: FrameDemand(isVisiting: true)) == .ambient)
        #expect(policy.state(for: FrameDemand()) == .settled)
    }

    // MARK: The table at nominal conditions

    @Test func nominalRatesMatchTheTable() {
        #expect(directive(.direct).hz == 60, "the beta's directRate")
        #expect(directive(.moment).hz == 60)
        #expect(directive(.ambient).hz == 30)
        #expect(directive(.settled).hz == 0)
        #expect(directive(.covered).hz == 0)
        #expect(directive(.minigame).hz == 60)
        #expect(directive(.background).hz == 0)
    }

    @Test func directAt120AsksForTheTopRange() {
        var fast = policy
        fast.directRate = 120
        let d = fast.directive(for: .direct, conditions: .nominal)
        #expect(d.hz == 120)
        #expect(d.range == FrameRateRange(minimum: 80, maximum: 120, preferred: 120))
        // Fair thermal caps Direct at 60, Low Power too.
        #expect(fast.directive(for: .direct, conditions: FrameConditions(thermal: .fair)).hz == 60)
        #expect(fast.directive(for: .direct, conditions: FrameConditions(lowPower: true)).hz == 60)
    }

    @Test func pausedStatesCacheTheFrame() {
        for state in [FrameState.settled, .covered, .background] {
            let d = directive(state)
            #expect(d.isPaused)
            #expect(d.range.preferred == 0)
        }
        #expect(!directive(.direct).isPaused)
    }

    @Test func directRunsNoDepthPass() {
        #expect(!directive(.direct).depthOfField)
        #expect(directive(.settled).depthOfField)
        #expect(directive(.moment).depthOfField)
        #expect(directive(.ambient).depthOfField)
    }

    @Test func onlyAmbientFlickers() {
        for state in FrameState.allCases {
            #expect(directive(state).flicker == (state == .ambient), "\(state)")
        }
    }

    @Test func aCoverFlattensTheWorld() {
        #expect(directive(.covered).flattensWorld)
        for state in FrameState.allCases where state != .covered {
            #expect(!directive(state).flattensWorld, "\(state)")
        }
    }

    // MARK: Low Power Mode and thermal state

    @Test func lowPowerSkipsAmbientAndDropsTheExtras() {
        let ambient = directive(.ambient, lowPower: true)
        #expect(ambient.state == .settled)
        #expect(ambient.hz == 0)
        #expect(!ambient.flicker)
        let moment = directive(.moment, lowPower: true)
        #expect(moment.hz == 60)
        #expect(!moment.depthOfField)
        #expect(!moment.particles)
        #expect(!moment.shafts)
        #expect(directive(.direct, lowPower: true).hz == 60)
    }

    @Test func reduceMotionSkipsAmbient() {
        #expect(directive(.ambient, reduceMotion: true).state == .settled)
        #expect(directive(.moment, reduceMotion: true).hz == 60)
    }

    @Test func fairCapsDirectButNothingElse() {
        let direct = directive(.direct, thermal: .fair)
        #expect(direct.hz <= 60)
        #expect(directive(.moment, thermal: .fair).hz == 60)
        #expect(directive(.ambient, thermal: .fair).hz == 30)
        #expect(directive(.moment, thermal: .fair).depthOfField)
    }

    @Test func seriousDropsMomentAndTurnsOffAmbientDepthAndShafts() {
        let moment = directive(.moment, thermal: .serious)
        #expect(moment.hz == 30)
        #expect(!moment.depthOfField)
        #expect(!moment.shafts)
        #expect(!moment.particles)
        #expect(directive(.ambient, thermal: .serious).state == .settled)
        #expect(directive(.minigame, thermal: .serious).hz == 30)
        #expect(directive(.direct, thermal: .serious).hz == 60, "touch stays responsive")
    }

    @Test func criticalCapsEverythingAt30AndShowsTheSettledWorld() {
        for state in FrameState.allCases {
            let d = directive(state, thermal: .critical)
            #expect(d.hz <= 30, "\(state)")
        }
        #expect(directive(.ambient, thermal: .critical).state == .settled)
        #expect(directive(.direct, thermal: .critical).hz == 30)
    }

    @Test func everyCombinationIsSane() {
        for state in FrameState.allCases {
            for lowPower in [false, true] {
                for thermal in [ThermalLevel.nominal, .fair, .serious, .critical] {
                    for reduce in [false, true] {
                        let d = directive(state, lowPower: lowPower, thermal: thermal, reduceMotion: reduce)
                        let label = "\(state) lpm \(lowPower) \(thermal) rm \(reduce)"
                        #expect(d.hz >= 0 && d.hz <= 120, "\(label)")
                        #expect(d.isPaused == (d.hz == 0), "\(label)")
                        #expect(d.range.preferred == d.hz, "\(label)")
                        #expect(d.timelineInterval > 0, "\(label)")
                        // Nothing runs in the Settled, Covered or Background frames.
                        if d.isPaused { #expect(!d.flicker, "\(label)") }
                        // The lower the power, the lower or equal the rate.
                        let base = directive(state)
                        #expect(d.hz <= base.hz, "\(label)")
                    }
                }
            }
        }
    }

    // MARK: Hysteresis

    @Test func theGovernorRisesAtOnceAndFallsAfterThirtySeconds() {
        var governor = ThermalGovernor()
        #expect(governor.observe(.nominal, at: 0) == .nominal)
        #expect(governor.observe(.serious, at: 1) == .serious)
        // Lower, but not for long enough yet.
        #expect(governor.observe(.fair, at: 5) == .serious)
        #expect(governor.observe(.fair, at: 34.9) == .serious)
        #expect(governor.observe(.fair, at: 35.1) == .fair)
        #expect(governor.observe(.nominal, at: 36) == .fair)
        #expect(governor.observe(.nominal, at: 66.1) == .nominal)
    }

    @Test func aRelapseRestartsTheWait() {
        var governor = ThermalGovernor()
        governor.observe(.serious, at: 0)
        governor.observe(.fair, at: 10)
        // Back up to serious before the 30 s: held, and the clock resets.
        #expect(governor.observe(.serious, at: 30) == .serious)
        #expect(governor.observe(.fair, at: 31) == .serious)
        #expect(governor.observe(.fair, at: 60) == .serious)
        #expect(governor.observe(.fair, at: 61.1) == .fair)
    }

    @Test func theGovernorNeverOscillatesOnAFlappingSensor() {
        var governor = ThermalGovernor()
        var changes = 0
        var last = governor.held
        for second in 0..<120 {
            let observed: ThermalLevel = second % 2 == 0 ? .serious : .fair
            let held = governor.observe(observed, at: Double(second))
            if held != last { changes += 1; last = held }
        }
        #expect(changes == 1)
        #expect(governor.held == .serious)
    }

    // MARK: WorldPower, the seam to the timeline

    @MainActor
    @Test func drivingTheSceneFromDirectToSettledPausesTheTimeline() {
        let clock = PowerTestClock()
        let power = WorldPower(clock: { clock.now })
        power.demand.isDirect = true
        #expect(power.needsFrames)
        #expect(power.directive.state == .direct)
        #expect(!power.directive.depthOfField)

        power.demand.isDirect = false
        #expect(power.directive.state == .settled)
        #expect(!power.needsFrames)
        #expect(power.directive.isPaused)

        // A touch opens the visit window: Ambient at 30 Hz for 8 s, then Settled.
        power.beginVisit()
        #expect(power.directive.state == .ambient)
        #expect(power.directive.hz == 30)
        clock.now = 7.9
        #expect(power.needsFrames)
        clock.now = 8.1
        #expect(!power.needsFrames)
    }

    @MainActor
    @Test func aCoverFreezesTheWorld() {
        let power = WorldPower(clock: { 0 })
        power.demand.isDirect = true
        power.demand.isCovered = true
        #expect(power.directive.state == .covered)
        #expect(power.directive.flattensWorld)
        #expect(!power.needsFrames)
    }

    @MainActor
    @Test func theSystemStateFeedsTheDirective() {
        let clock = PowerTestClock()
        let power = WorldPower(clock: { clock.now })
        power.beginVisit()
        #expect(power.directive.state == .ambient)
        power.update(lowPower: true, thermal: .nominal, reduceMotion: false)
        #expect(power.directive.state == .settled)
        power.update(lowPower: false, thermal: .serious, reduceMotion: false)
        #expect(power.directive.state == .settled)
        // The fall in temperature takes 30 s to be believed.
        clock.now = 1
        power.update(lowPower: false, thermal: .nominal, reduceMotion: false)
        #expect(power.conditions.thermal == .serious)
        clock.now = 32
        power.update(lowPower: false, thermal: .nominal, reduceMotion: false)
        #expect(power.conditions.thermal == .nominal)
    }

    @Test func ambientTimeIsQuantisedToThirtyHertz() {
        #expect(FramePolicy.ambientTime(0.0334) == 1.0 / 30.0)
        #expect(FramePolicy.ambientTime(0.0333) == 0)
        #expect(FramePolicy.ambientTime(.nan) == 0)
        #expect(abs(FramePolicy.ambientTime(10.01) - 10.0) < 1e-9)
    }
}
