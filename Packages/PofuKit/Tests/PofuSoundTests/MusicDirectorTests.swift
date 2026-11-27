import Foundation
import Testing
import PofuTuning
@testable import PofuSound

@Suite("Music director")
struct MusicDirectorTests {
    static let tuning = TuningValues.defaults.sound

    static func cell(_ name: String, _ tune: String) -> (String, MusicIndex.Cell) {
        let key = name.lowercased()
        let stems = Dictionary(uniqueKeysWithValues: MusicStem.allCases.map { ($0.rawValue, "\(tune)-\(key)-\($0.rawValue).m4a") })
        return (name, MusicIndex.Cell(seconds: 12.5, stems: stems))
    }

    static func tune(_ island: String, _ time: String) -> MusicIndex.Tune {
        let name = "\(island)-\(time)"
        let order = ["A", "A2", "B", "END"]
        return MusicIndex.Tune(
            island: island, time: time, lead: "kalimba", bpm: 96, order: order,
            cells: Dictionary(uniqueKeysWithValues: order.map { cell($0, name) })
        )
    }

    /// Home's day tune only, as MU2 ships.
    static let index = MusicIndex(tunes: ["home-day": tune("home", "day")])

    static func state(
        island: MusicIsland = .home, hour: Int = 10, weather: AmbienceWeather = .clear,
        season: MusicSeason = .spring, stage: Int = 10, wellbeing: Double = 80
    ) -> MusicState {
        MusicState(island: island, hour: hour, weather: weather, season: season, stage: stage, wellbeing: wellbeing)
    }

    static func director(seed: UInt64 = 7) -> MusicDirector {
        MusicDirector(index: index, tuning: tuning, seed: seed)
    }

    /// The first phrase a fresh director gives for `state`.
    static func first(_ state: MusicState) -> MusicPhrase? {
        var d = director()
        return d.next(for: state, isMusicOn: true)
    }

    @Test func theSameInputsAndSeedGiveTheSameSequence() {
        func run(_ seed: UInt64) -> [MusicPhrase?] {
            var d = Self.director(seed: seed)
            let weathers = AmbienceWeather.allCases
            return (0..<40).map { i in
                d.next(for: Self.state(hour: 6 + i % 17, weather: weathers[i % weathers.count], wellbeing: Double(i * 3 % 100)), isMusicOn: true)
            }
        }
        #expect(run(42) == run(42))
        #expect(run(42) != run(43))
    }

    @Test func pausesStayInsideTheRange() {
        var d = Self.director()
        for wellbeing in stride(from: 0.0, through: 100, by: 10) {
            for weather in AmbienceWeather.allCases {
                for _ in 0..<20 {
                    let phrase = d.next(for: Self.state(weather: weather, wellbeing: wellbeing), isMusicOn: true)
                    let pause = phrase?.pause ?? -1
                    #expect(pause >= 4 && pause <= 12, "\(pause)")
                }
            }
        }
    }

    @Test func aTiredPofuAndRainWaitLongerOnAverage() {
        func mean(_ state: MusicState) -> Double {
            var d = Self.director()
            let pauses = (0..<400).compactMap { _ in d.next(for: state, isMusicOn: true)?.pause }
            return pauses.reduce(0, +) / Double(pauses.count)
        }
        let rested = mean(Self.state(wellbeing: 90))
        #expect(mean(Self.state(wellbeing: 10)) > rested + 0.5)
        #expect(mean(Self.state(weather: .lightRain)) > rested + 0.5)
    }

    @Test func theOpeningDelayIsThreeToEightSeconds() {
        for seed in 0..<50 as Range<UInt64> {
            var d = Self.director(seed: seed)
            let delay = d.openingDelay()
            #expect(delay >= 3 && delay <= 8)
        }
    }

    @Test func cellsComeInOrderAndWrap() {
        var d = Self.director()
        let order = ["A", "A2", "B", "END"]
        let played = (0..<12).compactMap { _ in d.next(for: Self.state(), isMusicOn: true)?.cell }
        #expect(played.count == 12)
        let start = order.firstIndex(of: played[0])
        #expect(start != nil && played[0] != "END")
        for (i, cell) in played.enumerated() {
            #expect(cell == order[((start ?? 0) + i) % order.count])
        }
    }

    @Test func noCellRepeatsWithinFour() {
        for seed in 0..<30 as Range<UInt64> {
            var d = Self.director(seed: seed)
            let played = (0..<60).compactMap { _ in d.next(for: Self.state(), isMusicOn: true)?.cell }
            for i in played.indices {
                for j in max(0, i - 3)..<i { #expect(played[i] != played[j]) }
            }
        }
    }

    @Test func aStateChangeInTheMiddleNeverRepeatsACellEither() {
        var d = Self.director(seed: 3)
        var played: [String] = []
        for i in 0..<60 {
            // Hours drift in and out of the bedtime window and the night, where nothing plays.
            let hour = [10, 10, 18, 23, 10, 3, 12][i % 7]
            if let phrase = d.next(for: Self.state(hour: hour), isMusicOn: true) { played.append(phrase.cell) }
        }
        #expect(played.count > 20)
        for i in played.indices { for j in max(0, i - 3)..<i { #expect(played[i] != played[j]) } }
    }

    @Test func musicOffReturnsNothing() {
        var d = Self.director()
        for hour in 0..<24 {
            let phrase = d.next(for: Self.state(hour: hour), isMusicOn: false)
            #expect(phrase == nil)
        }
        #expect(d.silence(for: Self.state(), isMusicOn: false) == .off)
    }

    @Test func theBedtimeWindowIsSilent() {
        var d = Self.director()
        for hour in [23, 0, 1, 3, 5] {
            let phrase = d.next(for: Self.state(hour: hour), isMusicOn: true)
            #expect(phrase == nil)
            #expect(d.silence(for: Self.state(hour: hour), isMusicOn: true) == .bedtime)
        }
        let morning = d.next(for: Self.state(hour: 6), isMusicOn: true)
        #expect(morning != nil)
        let afternoon = d.next(for: Self.state(hour: 16), isMusicOn: true)
        #expect(afternoon != nil)
    }

    @Test func everyOtherIslandHourWeatherAndSeasonFallsBackAndNeverPlaysAWrongTune() {
        var d = Self.director()
        for island in MusicIsland.allCases {
            for hour in 0..<24 {
                for weather in AmbienceWeather.allCases {
                    for season in MusicSeason.allCases {
                        let state = Self.state(island: island, hour: hour, weather: weather, season: season)
                        let phrase = d.next(for: state, isMusicOn: true)
                        let hasTune = island == .home && (6..<17).contains(hour)
                        if hasTune {
                            #expect(phrase?.tune == "home-day")
                            // Only the kalimba lead is rendered, so every season plays it.
                            #expect(phrase?.lead == "kalimba")
                        } else {
                            #expect(phrase == nil)
                            let silence = d.silence(for: state, isMusicOn: true)
                            #expect(silence == (MusicDirector.bedtime.contains(hour) ? .bedtime : .noTune))
                        }
                    }
                }
            }
        }
    }

    @Test func weatherThinsTheStems() throws {
        func stems(_ weather: AmbienceWeather, stage: Int = 10) throws -> [MusicStem: Double] {
            let phrase = try #require(Self.first(Self.state(weather: weather, stage: stage)))
            return Dictionary(uniqueKeysWithValues: phrase.stems.map { ($0.stem, $0.gain) })
        }
        #expect(try stems(.clear) == [.lead: 1, .bed: 1, .pulse: 1])
        #expect(try stems(.overcast) == [.lead: 1, .bed: 1])
        #expect(try stems(.lightRain) == [.lead: 1, .bed: 1])
        #expect(try stems(.mist) == [.bed: 1])
        let haze = try stems(.goldenHaze)
        #expect(Set(haze.keys) == [.lead, .bed, .pulse])
        #expect(haze[.lead] == Self.tuning.musicHazeLead && haze[.bed] == 1 && haze[.pulse] == 1)
    }

    @Test func aHealingIslandGainsStems() throws {
        func stems(_ stage: Int) throws -> Set<MusicStem> {
            Set(try #require(Self.first(Self.state(stage: stage))).stems.map(\.stem))
        }
        #expect(try stems(1) == [.bed])
        #expect(try stems(3) == [.bed])
        #expect(try stems(5) == [.bed, .lead])
        #expect(try stems(9) == [.bed, .lead])
        #expect(try stems(10) == [.bed, .lead, .pulse])
    }

    @Test func wellbeingChangesOnlyThePauses() throws {
        func phrase(_ wellbeing: Double) throws -> MusicPhrase {
            try #require(Self.first(Self.state(wellbeing: wellbeing)))
        }
        var tired = try phrase(5), rested = try phrase(95)
        #expect(tired.pause >= rested.pause)
        tired.pause = 0
        rested.pause = 0
        #expect(tired == rested)
    }

    @Test func aYearOfVisitsNeverPlaysTwoCellsAtOnce() {
        // A phrase starts, rings for `seconds`, then the pause: the next starts after both.
        var d = Self.director(seed: 99)
        var clock = d.openingDelay()
        var busyUntil = 0.0
        var count = 0
        let end = 365.0 * 24 * 3600
        while clock < end {
            let hour = Int(clock / 3600) % 24
            if let phrase = d.next(for: Self.state(hour: hour), isMusicOn: true) {
                #expect(clock >= busyUntil)
                busyUntil = clock + phrase.seconds
                clock = busyUntil + phrase.pause
                count += 1
            } else {
                clock += 30
            }
        }
        #expect(count > 1000)
    }

    @Test func theBundledIndexHasEveryFileOfEveryCell() throws {
        let index = try MusicIndex.bundled()
        #expect(index.tune(island: .home, time: "day") != nil)
        for (name, tune) in index.tunes {
            #expect(Set(tune.cells.keys) == Set(tune.order), "\(name): order and cells differ")
            for (cellName, cell) in tune.cells {
                #expect(Set(cell.stems.keys) == Set(MusicStem.allCases.map(\.rawValue)), "\(name)/\(cellName)")
                #expect(cell.seconds > 4)
                for file in cell.stems.values {
                    #expect(MusicAssets.url(forFile: file) != nil, "\(file) is not bundled")
                }
            }
        }
    }

    @Test func theBundledTunesFitTheSizeLimit() throws {
        let folder = try #require(MusicAssets.url(for: "music", withExtension: "json")).deletingLastPathComponent()
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey])
        let bytes = try files.reduce(0) { $0 + (try $1.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) }
        #expect(bytes < 24_000_000)
    }
}

@Suite("Music policy")
struct MusicPolicyTests {
    @Test func musicIsOnByDefaultAndKeepsItsOwnSwitch() {
        #expect(SoundSettings().isMusicOn)
        let suite = UserDefaults(suiteName: "pofu.test.music.\(UUID().uuidString)")!
        #expect(SoundSettings.load(from: suite).isMusicOn)
        SoundSettings(isMusicOn: false).save(to: suite)
        #expect(!SoundSettings.load(from: suite).isMusicOn)
        #expect(SoundSettings.load(from: suite).isAmbienceOn)
    }

    @Test func theSwitchTheMuteTheForegroundAndOtherAudioAllSilenceIt() {
        #expect(MusicPolicy().mayPlay)
        #expect(!MusicPolicy(settings: SoundSettings(isMusicOn: false)).mayPlay)
        #expect(!MusicPolicy(settings: SoundSettings(isMuted: true)).mayPlay)
        #expect(!MusicPolicy(isActive: false).mayPlay)
        #expect(!MusicPolicy(otherAudioPlaying: true).mayPlay)
        // Ambience off does not silence the music.
        #expect(MusicPolicy(settings: SoundSettings(isAmbienceOn: false)).mayPlay)
    }

    @Test func aCueDucksTheMusicWithTheAmbiencesRule() {
        let policy = MusicPolicy()
        let base = policy.gain(level: 1, secondsSinceCue: nil)
        #expect(base > 0)
        #expect(abs(Double(policy.gain(level: 1, secondsSinceCue: 0.1)) - Double(base) * AmbienceDucking.depth) < 1e-6)
        #expect(policy.gain(level: 1, secondsSinceCue: 5) == base)
        #expect(MusicPolicy(isActive: false).gain(level: 1, secondsSinceCue: nil) == 0)
    }
}
