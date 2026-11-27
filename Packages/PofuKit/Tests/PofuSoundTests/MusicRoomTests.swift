import Foundation
import Testing
import PofuTuning
@testable import PofuSound

@Suite("Music room")
struct MusicRoomTests {
    static let index = MusicDirectorTests.index
    static let tuning = MusicDirectorTests.tuning

    static func answer(_ state: MusicState, isMusicOn: Bool = true) -> MusicRoomAnswer {
        MusicRoom.answer(for: state, isMusicOn: isMusicOn, index: index, tuning: tuning)
    }

    @Test func aDayStateAnswersWithItsFirstCellAndAllItsStems() {
        let answer = Self.answer(MusicDirectorTests.state())
        guard case .phrase(let phrase, let pause) = answer else {
            Issue.record("a clear Home morning has a tune")
            return
        }
        #expect(phrase.tune == "home-day")
        #expect(answer.stems == [.lead, .bed, .pulse])
        #expect(pause.lowerBound >= Self.tuning.musicPauseMin)
        #expect(pause.upperBound == Self.tuning.musicPauseMax)
    }

    @Test func theAnswerIsTheFirstPhraseTheAuditionPlays() {
        let state = MusicDirectorTests.state(weather: .overcast)
        var director = MusicDirector(index: Self.index, tuning: Self.tuning, seed: MusicRoom.seed)
        let played = director.next(for: state, isMusicOn: true)
        guard case .phrase(let shown, _) = Self.answer(state) else {
            Issue.record("expected a phrase")
            return
        }
        #expect(shown == played)
    }

    @Test func theWeatherAndTheStageThinTheStems() {
        #expect(Self.answer(MusicDirectorTests.state(weather: .lightRain)).stems == [.lead, .bed])
        #expect(Self.answer(MusicDirectorTests.state(weather: .mist)).stems == [.bed])
        #expect(Self.answer(MusicDirectorTests.state(stage: 1)).stems == [.bed])
    }

    @Test func eachSilenceNamesItsReason() {
        #expect(Self.answer(MusicDirectorTests.state(), isMusicOn: false) == .silence(.off))
        for hour in [23, 0, 3, 5] {
            #expect(Self.answer(MusicDirectorTests.state(hour: hour)) == .silence(.bedtime))
        }
        // Night has no tune until MU4, and no other island has one.
        #expect(Self.answer(MusicDirectorTests.state(hour: 20)) == .silence(.noTune))
        #expect(Self.answer(MusicDirectorTests.state(island: .koke)) == .silence(.noTune))
        #expect(Self.answer(MusicDirectorTests.state(), isMusicOn: false).stems.isEmpty)
    }

    @Test func aTiredPofuAndRainRaiseThePauseFloorWithinTheRange() {
        let director = MusicDirector(index: Self.index, tuning: Self.tuning, seed: 1)
        let rested = director.pauseRange(for: MusicDirectorTests.state(wellbeing: 90))
        let tired = director.pauseRange(for: MusicDirectorTests.state(wellbeing: 10))
        let rainy = director.pauseRange(for: MusicDirectorTests.state(weather: .lightRain, wellbeing: 90))
        #expect(rested.lowerBound == Self.tuning.musicPauseMin)
        #expect(tired.lowerBound > rested.lowerBound)
        #expect(rainy.lowerBound > rested.lowerBound)
        #expect(tired.upperBound == rested.upperBound)
    }

    @Test func everyHourOfEveryIslandAnswersWithoutAPhraseOrASilenceGap() {
        for island in MusicIsland.allCases {
            for hour in 0..<24 {
                let answer = Self.answer(MusicDirectorTests.state(island: island, hour: hour))
                switch answer {
                case .phrase(let phrase, _): #expect(!phrase.stems.isEmpty)
                case .silence: #expect(answer.stems.isEmpty)
                }
            }
        }
    }
}
