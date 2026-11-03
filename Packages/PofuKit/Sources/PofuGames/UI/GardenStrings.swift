#if os(iOS)
import Foundation

/// The garden game's copy, in English with Turkish translations in the
/// package's string catalog. Pofu's voice: short, warm, never a score.
enum GardenStrings {
    static var title: String { String(localized: "Sunflower garden", bundle: .module) }

    static func round(_ number: Int, of total: Int) -> String {
        String(localized: "Round \(number) of \(total)", bundle: .module)
    }

    static func roundKicker(_ number: Int, of total: Int) -> String {
        String(localized: "ROUND \(number) / \(total)", bundle: .module)
    }

    static func toCheeks(_ seeds: Int) -> String {
        String(localized: "+\(seeds) to your cheeks", bundle: .module)
    }

    static func seedsThisRound(_ seeds: Int) -> String {
        String(localized: "\(seeds) seeds this round", bundle: .module)
    }

    static var nextRound: String { String(localized: "Next round", bundle: .module) }
    static var enoughForToday: String { String(localized: "Enough for today", bundle: .module) }

    static func anotherSet(_ rounds: Int) -> String {
        String(localized: "One more set · \(rounds) rounds ready", bundle: .module)
    }

    static var pause: String { String(localized: "Pause", bundle: .module) }
    static var paused: String { String(localized: "Taking a breather", bundle: .module) }
    static var resume: String { String(localized: "Keep planting", bundle: .module) }

    static func combo(_ combo: Int) -> String {
        String(localized: "Combo ×\(combo)", bundle: .module)
    }

    static var doubleBloom: String { String(localized: "Double bloom!", bundle: .module) }
    static var fullSpring: String { String(localized: "Full spring!", bundle: .module) }
    static var gardenFull: String { String(localized: "The bed is full!", bundle: .module) }

    static func roundTitle(_ result: GardenRoundResult) -> String {
        switch (result.ending, result.seeds) {
        case (_, SeedYield.maximum): String(localized: "Pofu's cheeks are stuffed.", bundle: .module)
        case (.gardenFull, _): String(localized: "The bed is full. Harvest time!", bundle: .module)
        case (.bagEmpty, _): String(localized: "The garden bloomed.", bundle: .module)
        }
    }

    static func rowsBloomed(_ lines: Int) -> String {
        String(localized: "Rows in bloom: \(lines)", bundle: .module)
    }

    static var setKicker: String { String(localized: "SET DONE", bundle: .module) }
    static var setTitle: String { String(localized: "Mochi brewed the tea.", bundle: .module) }
    static var setDetail: String { String(localized: "That's enough garden for today.", bundle: .module) }

    static func cheeksAccessibility(_ seeds: Int) -> String {
        String(localized: "Pofu, with \(seeds) seeds in his cheeks", bundle: .module)
    }

    static var boardAccessibility: String {
        String(localized: "The garden bed. Drag a plot from the tray onto the soil.", bundle: .module)
    }
}
#endif
