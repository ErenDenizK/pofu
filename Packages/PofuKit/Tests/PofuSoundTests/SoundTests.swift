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
        #expect(names.count == 36)
        let samples: [SoundCue] = [
            .seedPop(pitchIndex: 2), .bloom(step: 7), .comboRise(level: 3), .piecePickup, .pieceSnap,
            .pieceDrop, .piecePutBack, .deal, .cheek, .roundEnd, .collect, .skipChime, .pofuHop, .gulp,
            .levelUp, .doorKnock, .kettle, .waterWheel, .waterSplash, .waterPour,
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
        // The ambience pass: loops, gulls and the breath pad, each under 50 KB.
        let ambience = AmbienceBed.allCases.map(\.assetName) + ["gull-0", "gull-1", "breath-pad"]
        for name in ambience + ["level-up", "door-knock", "kettle", "water-wheel", "water-splash", "water-pour"] {
            let url = SoundAssets.url(for: name)
            let size = url.flatMap { try? FileManager.default.attributesOfItem(atPath: $0.path)[.size] as? Int } ?? 0
            #expect(size > 0 && size <= 50_000, "\(name).caf is \(size) bytes")
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


@Suite("World ambience")
struct AmbienceTests {
    private func mix(_ hour: Int, _ weather: AmbienceWeather = .clear, level: Int = 1) -> AmbienceMix {
        AmbienceMixer.mix(for: AmbienceScene(hour: hour, weather: weather, islandLevel: level))
    }

    @Test func windByDayCricketsInTheEvening() {
        #expect(mix(12).level(of: .wind) > 0.5)
        #expect(mix(12).level(of: .crickets) == 0)
        #expect(mix(21).level(of: .crickets) > 0.5)
        #expect(mix(21).level(of: .wind) < mix(12).level(of: .wind))
    }

    @Test func bedtimeIsSilentWhateverTheWeather() {
        for hour in AmbienceMixer.bedtimeHours {
            for weather in AmbienceWeather.allCases {
                #expect(mix(hour, weather, level: 10).isSilent, "hour \(hour) \(weather)")
            }
        }
        #expect(!mix(5).isSilent)
        #expect(!mix(22).isSilent)
    }

    @Test func rainFallsOnLeavesAndMistHushes() {
        let rain = mix(14, .lightRain)
        #expect(rain.level(of: .rain) == 1)
        #expect(rain.level(of: .crickets) == 0)
        #expect(!rain.gulls)
        let mist = mix(8, .mist, level: 5)
        #expect(mist.level(of: .hush) == 1)
        #expect(mist.level(of: .wind) == 0)
        #expect(!mist.gulls)
    }

    @Test func gullsComeWithTheHarborByDaylightOnly() {
        #expect(!mix(10, .clear, level: 2).gulls)
        #expect(mix(10, .clear, level: 3).gulls)
        #expect(mix(10, .goldenHaze, level: 3).gulls)
        #expect(!mix(10, .overcast, level: 3).gulls)
        #expect(!mix(21, .clear, level: 10).gulls)
        #expect(!mix(5, .clear, level: 10).gulls)
        #expect(!mix(19, .clear, level: 10).gulls)
    }

    @Test func weatherNamesMapAndUnknownIsClear() {
        #expect(AmbienceWeather(weatherName: "lightRain") == .lightRain)
        #expect(AmbienceWeather(weatherName: "goldenHaze") == .goldenHaze)
        #expect(AmbienceWeather(weatherName: "snow") == .clear)
        #expect(AmbienceScene(hour: 26, weather: .clear, islandLevel: 1).hour == 2)
    }

    @Test func everyBedHasAFile() {
        for bed in AmbienceBed.allCases {
            #expect(SoundAssets.url(for: bed.assetName) != nil, "\(bed.assetName)")
        }
    }

    @Test func duckingDropsAtOnceHoldsAndReturns() {
        #expect(AmbienceDucking.factor(secondsSinceCue: nil) == 1)
        #expect(AmbienceDucking.factor(secondsSinceCue: 0) == AmbienceDucking.depth)
        #expect(AmbienceDucking.factor(secondsSinceCue: AmbienceDucking.hold) == AmbienceDucking.depth)
        let mid = AmbienceDucking.factor(secondsSinceCue: AmbienceDucking.hold + AmbienceDucking.release / 2)
        #expect(mid > AmbienceDucking.depth && mid < 1)
        #expect(AmbienceDucking.factor(secondsSinceCue: 10) == 1)
    }

    @Test func offByDefaultAndWhenMutedBackgroundedIdleOrSharing() {
        // Ambience is optional: a fresh install is silent.
        #expect(!AmbiencePolicy().mayPlay)
        let on = SoundSettings(isMuted: false, isAmbienceOn: true)
        #expect(AmbiencePolicy(settings: on).mayPlay)
        #expect(!AmbiencePolicy(settings: SoundSettings(isMuted: true, isAmbienceOn: true)).mayPlay)
        #expect(!AmbiencePolicy(settings: on, isActive: false).mayPlay)
        #expect(!AmbiencePolicy(settings: on, otherAudioPlaying: true).mayPlay)
        #expect(AmbiencePolicy(settings: on, secondsIdle: AmbienceLevels.idleSeconds - 1).mayPlay)
        #expect(!AmbiencePolicy(settings: on, secondsIdle: AmbienceLevels.idleSeconds).mayPlay)
        var silent = TuningValues.defaults.sound
        silent.master = 0
        #expect(!AmbiencePolicy(settings: on, volumes: silent).mayPlay)
    }

    @Test func gainIsVeryLowDuckedAndQuieterUnderVoiceOver() {
        let on = SoundSettings(isMuted: false, isAmbienceOn: true)
        let plain = AmbiencePolicy(settings: on).gain(level: 1, secondsSinceCue: nil)
        #expect(plain > 0 && plain <= 0.2)
        let ducked = AmbiencePolicy(settings: on).gain(level: 1, secondsSinceCue: 0.1)
        #expect(ducked < plain)
        let voiceOver = AmbiencePolicy(settings: on, voiceOverRunning: true).gain(level: 1, secondsSinceCue: nil)
        #expect(abs(voiceOver / plain - Float(AmbienceLevels.voiceOverFactor)) < 0.001)
        #expect(AmbiencePolicy(settings: SoundSettings()).gain(level: 1, secondsSinceCue: nil) == 0)
    }

    @Test func ambienceSettingIsRememberedAndDefaultsOff() throws {
        let suite = try #require(UserDefaults(suiteName: "pofu.sound.tests.\(UUID().uuidString)"))
        #expect(SoundSettings.load(from: suite).isAmbienceOn == false)
        SoundSettings(isMuted: false, isAmbienceOn: true).save(to: suite)
        #expect(SoundSettings.load(from: suite).isAmbienceOn == true)
    }
}

@Suite("World moments and the breath")
struct WorldMomentTests {
    @Test func kettleWhistlesOncePerMorningAtABuiltStall() {
        #expect(WorldMoments.shouldWhistleKettle(hour: 7, teaStallLevel: 1, alreadyToday: false))
        #expect(!WorldMoments.shouldWhistleKettle(hour: 7, teaStallLevel: 0, alreadyToday: false))
        #expect(!WorldMoments.shouldWhistleKettle(hour: 7, teaStallLevel: 2, alreadyToday: true))
        #expect(!WorldMoments.shouldWhistleKettle(hour: 5, teaStallLevel: 2, alreadyToday: false))
        #expect(!WorldMoments.shouldWhistleKettle(hour: 11, teaStallLevel: 2, alreadyToday: false))
    }

    @Test func levelUpOnlyWhenTheLevelRoseSinceTheLastLook() {
        #expect(!WorldMoments.islandLevelRose(from: nil, to: 4))
        #expect(!WorldMoments.islandLevelRose(from: 4, to: 4))
        #expect(WorldMoments.islandLevelRose(from: 4, to: 5))
        #expect(!WorldMoments.islandLevelRose(from: 5, to: 4))
    }

    @Test func flowCuesMapOntoTheLadderAndTheWater() {
        #expect(FlowSoundMap.cues(for: .pour) == [.waterPour])
        #expect(FlowSoundMap.cues(for: .splash) == [.waterSplash])
        #expect(FlowSoundMap.cues(for: .wheelCreak) == [.waterWheel])
        #expect(FlowSoundMap.cues(for: .trickle(step: 2)) == [.bloom(step: 2)])
        #expect(FlowSoundMap.cues(for: .trickle(step: 40)) == [.bloom(step: FlowSoundMap.trickleTopStep)])
    }

    @Test func breathPadRisesThenFallsAndStartsSoft() {
        let start = BreathSwell.shape(.rising, progress: 0)
        let end = BreathSwell.shape(.rising, progress: 1)
        #expect(start.rate == BreathSwell.lowRate && end.rate == BreathSwell.highRate)
        #expect(start.gain == BreathSwell.floorGain && end.gain == 1)
        #expect(BreathSwell.shape(.falling, progress: 0).rate == BreathSwell.highRate)
        #expect(BreathSwell.shape(.falling, progress: 1).gain == 0)
        #expect(BreathSwell.shape(.rising, progress: 7).gain == 1)
        #expect(BreathSwell.response(to: .opens).direction == .rising)
        #expect(BreathSwell.response(to: .closes).direction == .falling)
        #expect(BreathSwell.response(to: .chime).chime == .skipChime)
    }

    @Test func worldCuesAreRateLimitedAndFollowTheMute() {
        var policy = SoundPolicy()
        #expect(policy.decide(.levelUp, at: 0)?.assetName == "level-up")
        #expect(policy.decide(.levelUp, at: 0.5) == nil)
        policy.settings.isMuted = true
        #expect(policy.decide(.doorKnock, at: 10) == nil)
    }
}
