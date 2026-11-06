import Foundation
import PofuCore
import PofuSound
import PofuWorld

/// Wires the world's sound pass (docs/design/sound-identity.md): the
/// ambience by hour and weather, the world cues and the breath pad. The
/// decisions live in `PofuSound` (pure, tested); this file only reads the
/// world and calls them.
@MainActor
enum WorldSound {
    private static var lastIslandLevel: Int?
    private static let kettleKey = "pofu.sound.kettleDay"

    /// Once at launch: the breath room's phases drive the pad.
    static func install() {
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

    static func islandLevelRose(to level: Int) {
        let rose = WorldMoments.islandLevelRose(from: lastIslandLevel, to: level)
        lastIslandLevel = level
        if rose { SoundEngine.shared.play(.levelUp) }
    }
}

extension AppModel {
    /// Tells the sound pass what the world is now. Cheap; called when Home
    /// appears, when the scene phase changes and on the 30-second tick.
    func updateWorldSound(active: Bool) {
        island.onVisitorArrived = { SoundEngine.shared.play(.doorKnock) }
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
        WorldSound.islandLevelRose(to: snapshot.islandLevel)
        let tea = snapshot.stations.first { $0.id == .teaStall }?.level ?? 0
        WorldSound.whistleKettleIfOwed(hour: hour, teaStallLevel: tea, now: date, calendar: calendar)
    }
}
