import Foundation
import Testing
import PofuGames
import PofuTuning
@testable import PofuSound

@Suite("Sound cues and pitch")
struct SoundCueTests {
    @Test func pitchIndicesClampIntoTheRenderedLadder() {
        #expect(SoundPitch.seedPopIndex(-3) == 0)
        #expect(SoundPitch.seedPopIndex(99) == 4)
        #expect(SoundPitch.bloomIndex(-1) == 0)
        #expect(SoundPitch.bloomIndex(40) == 10)
        #expect(SoundPitch.comboIndex(1) == 0)
        #expect(SoundPitch.comboIndex(2) == 0)
        #expect(SoundPitch.comboIndex(9) == 2)
    }

    @Test func everyBloomStepIsPentatonic() {
        let scale: Set<Int> = [2, 4, 6, 9, 11]  // D E F# A B as pitch classes
        for step in 0...SoundPitch.maxBloomStep {
            #expect(scale.contains(SoundPitch.midi(step: step) % 12))
        }
    }

    @Test func gameMidiRoundTripsToTheSameLadderStep() {
        for step in 0...SoundPitch.maxBloomStep {
            #expect(SoundPitch.bloomStep(midi: PentatonicLadder.midi(step: step)) == step)
        }
        // Off-scale notes snap down; absurd ones clamp.
        #expect(SoundPitch.bloomStep(midi: 63) == 0)
        #expect(SoundPitch.bloomStep(midi: 200) == 10)
        #expect(SoundPitch.bloomStep(midi: 10) == 0)
    }

    @Test func assetNamesAreUniqueAndCoverEveryCue() {
        let names = SoundCue.allAssetNames
        #expect(Set(names).count == names.count)
        #expect(names.count == 30)
        let samples: [SoundCue] = [
            .seedPop(pitchIndex: 2), .bloom(step: 7), .comboRise(level: 3), .piecePickup, .pieceSnap,
            .pieceDrop, .piecePutBack, .deal, .cheek, .roundEnd, .collect, .skipChime, .pofuHop, .gulp,
        ]
        for cue in samples { #expect(names.contains(cue.assetName), "\(cue.assetName)") }
        #expect(SoundCue.bloom(step: 3).assetName == "bloom-03")
    }

    @Test func gardenCuesMapOneToOne() {
        #expect(GardenSoundMap.cues(for: .bloom(midi: 69)) == [.bloom(step: 3)])
        #expect(GardenSoundMap.cues(for: .lift) == [.piecePickup])
        #expect(GardenSoundMap.cues(for: .comboRise(level: 3)) == [.comboRise(level: 3)])
        #expect(GardenSoundMap.cues(for: .roundEnd) == [.roundEnd])
    }

    @Test func bundledAssetsAreTheOnesTheCuesNeed() {
        for name in SoundCue.allAssetNames {
            let url = SoundAssets.url(for: name)
            let size = url.flatMap { try? FileManager.default.attributesOfItem(atPath: $0.path)[.size] as? Int } ?? 0
            #expect(size > 0, "missing \(name).caf")
            #expect(size < 100_000, "\(name).caf is \(size) bytes")
        }
    }
}

@Suite("Sound policy")
struct SoundPolicyTests {
    @Test func mutedAndZeroVolumesPlayNothing() {
        var muted = SoundPolicy(settings: SoundSettings(isMuted: true))
        #expect(muted.decide(.skipChime, at: 0) == nil)
        var volumes = TuningValues.defaults.sound
        volumes.master = 0
        var silent = SoundPolicy(volumes: volumes)
        #expect(silent.decide(.skipChime, at: 0) == nil)
        volumes = TuningValues.defaults.sound
        volumes.seeds = 0
        var noSeeds = SoundPolicy(volumes: volumes)
        #expect(noSeeds.decide(.bloom(step: 1), at: 0) == nil)
        #expect(noSeeds.decide(.skipChime, at: 0) != nil)
    }

    @Test func volumesMultiplyIntoTheGain() throws {
        var policy = SoundPolicy()
        let v = TuningValues.defaults.sound
        let admitted = policy.decide(.pofuHop, at: 0)
        let decision = try #require(admitted)
        #expect(abs(Double(decision.gain) - v.master * v.pofu) < 1e-6)
        #expect(decision.assetName == "pofu-hop")
    }

    @Test func rateLimitDropsTooCloseRepeats() {
        var policy = SoundPolicy()
        #expect(policy.decide(.skipChime, at: 10) != nil)
        #expect(policy.decide(.skipChime, at: 10.5) == nil)
        #expect(policy.decide(.skipChime, at: 11.1) != nil)
    }

    @Test func differentBloomPitchesShareOneKindButStaggerPasses() {
        var policy = SoundPolicy()
        #expect(policy.decide(.bloom(step: 0), at: 0) != nil)
        #expect(policy.decide(.bloom(step: 1), at: 0.01) == nil)
        #expect(policy.decide(.bloom(step: 1), at: 0.045) != nil)
    }

    @Test func runsGetQuieterThenRecoverAfterAPause() {
        var limiter = CueLimiter()
        var gains: [Double] = []
        for i in 0..<12 {
            gains.append(limiter.admit(.seedPop(pitchIndex: 0), at: Double(i) * 0.1) ?? -1)
        }
        #expect(gains[0] == 1)
        #expect(gains[1] < gains[0])
        #expect(gains.last == 0.4)  // the floor: never silent, never louder
        #expect(limiter.admit(.seedPop(pitchIndex: 0), at: 10) == 1)
    }

    @Test func muteIsRememberedInDefaults() throws {
        let suite = try #require(UserDefaults(suiteName: "pofu.sound.tests.\(UUID().uuidString)"))
        #expect(SoundSettings.load(from: suite).isMuted == false)
        SoundSettings(isMuted: true).save(to: suite)
        #expect(SoundSettings.load(from: suite).isMuted == true)
    }
}
