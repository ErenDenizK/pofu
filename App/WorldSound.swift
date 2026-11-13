import Foundation
import PofuCore
import PofuDesignSystem
import PofuSound
import PofuWorld

/// Wires the world's sound pass (docs/design/sound-identity.md): the
/// ambience by hour and weather, the world cues and the breath pad. The
/// decisions live in `PofuSound` (pure, tested); this file only reads the
/// world and calls them.
@MainActor
enum WorldSound {
    private static let kettleKey = "pofu.sound.kettleDay"
    /// The last step of the far bell's road Pofu told (0 for none): "told
    /// once" without a saved game state (docs/design/days-17-21-v1.md, D5).
    private static let preludeKey = "pofu.farBell.preludeHeard"
    private static var farBellTask: Task<Void, Never>?

    static var preludeHeard: Int {
        UserDefaults.standard.integer(forKey: preludeKey)
    }

    static func notePreludeHeard(_ step: Int) {
        UserDefaults.standard.set(step, forKey: preludeKey)
    }

    /// Rehearsal's reset: the road is told again.
    static func forgetPrelude() {
        UserDefaults.standard.removeObject(forKey: preludeKey)
    }

    /// Plays the far bell's notes as single ladder notes at their times: the
    /// hum a tap in the hand, the far notes a heavier one. A new tune cuts
    /// the old one.
    static func play(_ notes: [FarBellTune.Note]) {
        farBellTask?.cancel()
        farBellTask = Task { @MainActor in
            let begin = ContinuousClock.now
            for note in notes.sorted(by: { $0.at < $1.at }) {
                do {
                    try await Task.sleep(until: begin + .seconds(note.at), clock: .continuous)
                } catch {
                    return
                }
                SoundEngine.shared.play(.bloom(step: note.step))
                PofuHaptics.shared.play(note.isFar ? .land : .tap)
            }
        }
    }

    /// Once at launch: the breath room's phases drive the pad.
    static func install() {
        FarBellStage.shared.onPlay = { WorldSound.play($0) }
        BreathSound.handler = { cue in
            let phase: BreathPhaseCue = switch cue {
            case .airOpens: .opens
            case .airCloses: .closes
            case .chime: .chime
            }
            let response = BreathSwell.response(to: phase)
            if let direction = response.direction {
                let plan = BreathSound.plan
                AmbienceConductor.shared.swell(direction, seconds: direction == .rising ? plan.inhale : plan.exhale)
            }
            if let chime = response.chime {
                AmbienceConductor.shared.endBreath()
                SoundEngine.shared.play(chime)
            }
        }
    }

    /// Plays the kettle once on a morning, at most.
    static func whistleKettleIfOwed(hour: Int, teaStallLevel: Int, now: Date, calendar: Calendar) {
        let day = calendar.startOfDay(for: now).formatted(.iso8601.year().month().day())
        let done = UserDefaults.standard.string(forKey: kettleKey) == day
        guard WorldMoments.shouldWhistleKettle(hour: hour, teaStallLevel: teaStallLevel, alreadyToday: done) else { return }
        UserDefaults.standard.set(day, forKey: kettleKey)
        SoundEngine.shared.play(.kettle)
    }
}

extension AppModel {
    /// The far bell's road for the ears: a step's button hums and the far
    /// notes answer; the bell's card plays its song when it comes up.
    func farBellVisitChanged(from old: VisitProgress, to new: VisitProgress) {
        perform(farBellCueGuard.cue(from: old, to: new))
    }

    /// Home appeared: a cold launch straight onto the bell card begins the
    /// visit before the change observer exists, so the song is cued here.
    func farBellHomeAppeared() {
        perform(farBellCueGuard.cueOnAppear(worldHome.visit))
    }

    private func perform(_ cue: FarBellCue?) {
        switch cue {
        case .prelude(let step):
            WorldSound.notePreludeHeard(step)
            FarBellStage.shared.play(FarBellTune.prelude(step: step))
        case .bell:
            FarBellStage.shared.play(FarBellTune.bell())
        case nil:
            break
        }
    }

    /// Tells the sound pass what the world is now. Cheap; called when Home
    /// appears, when the scene phase changes and on the 30-second tick.
    func updateWorldSound(active: Bool) {
        island.onVisitorArrived = { SoundEngine.shared.play(.doorKnock) }
        // The island's growth plays the level-up cue at its bloom ("Ada büyüdü"),
        // not when the level is derived.
        island.onIslandGrew = { SoundEngine.shared.play(.levelUp) }
        guard active else {
            AmbienceConductor.shared.update(scene: nil, isActive: false)
            return
        }
        let calendar = Calendar.current
        let snapshot = world
        let date = snapshot.clock ?? Date()
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let hour = parts.hour ?? 12
        let weather = WeatherForecast.conditions(
            clock: snapshot.clock,
            firstDay: snapshot.firstDay,
            hour: Double(hour) + Double(parts.minute ?? 0) / 60,
            calendar: calendar
        ).weather
        AmbienceConductor.shared.update(
            scene: AmbienceScene(hour: hour, weather: AmbienceWeather(weatherName: weather.rawValue), islandLevel: snapshot.islandLevel),
            isActive: true
        )
        let tea = snapshot.stations.first { $0.id == .teaStall }?.level ?? 0
        WorldSound.whistleKettleIfOwed(hour: hour, teaStallLevel: tea, now: date, calendar: calendar)
    }
}
