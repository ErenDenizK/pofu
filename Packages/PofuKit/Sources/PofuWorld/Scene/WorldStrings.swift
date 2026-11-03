#if os(iOS)
import Foundation
import PofuCore

/// The world's copy, localized in the package's string catalog (Turkish
/// lines from the interaction spec §12.2).
enum WorldStrings {
    static func stationName(_ id: StationID) -> String {
        switch id {
        case .garden: String(localized: "Sunflower garden", bundle: .module)
        case .cay: String(localized: "Tea stall", bundle: .module)
        case .pond: String(localized: "Lily pond", bundle: .module)
        case .workshop: String(localized: "Workshop", bundle: .module)
        case .windmill: String(localized: "Windmill", bundle: .module)
        default: id.rawValue.capitalized
        }
    }

    /// Who keeps the station.
    static func stationKeeper(_ id: StationID) -> String? {
        switch id {
        case .garden: String(localized: "Pofu's", bundle: .module)
        case .cay: String(localized: "Mochi's", bundle: .module)
        case .workshop: String(localized: "Fındık's", bundle: .module)
        default: nil
        }
    }

    static func islandName(_ id: IslandID) -> String {
        switch id {
        case .aycicegi: "Ayçiçeği"
        case .iskele: "İskele"
        case .yildiz: "Yıldız"
        case .kaplica: "Kaplıca"
        case .kitap: "Kitap"
        default: id.rawValue.capitalized
        }
    }

    static func residentName(_ id: ResidentID) -> String {
        switch id {
        case .mochi: "Mochi"
        case .findik: "Fındık"
        default: id.rawValue.capitalized
        }
    }

    /// Three lines per resident, each said once a visit, in order.
    static func residentLines(_ id: ResidentID) -> [String] {
        switch id {
        case .mochi:
            [
                String(localized: "The tea has brewed. A glass?", bundle: .module),
                String(localized: "Steeped just right, in a tulip glass.", bundle: .module),
                String(localized: "Sit a while once the stools arrive.", bundle: .module),
            ]
        case .findik:
            [
                String(localized: "Tap tap. Fixing something.", bundle: .module),
                String(localized: "The weathervane will turn soon.", bundle: .module),
                String(localized: "Need a screw? I have a thousand.", bundle: .module),
            ]
        default:
            []
        }
    }

    static func framingName(_ framing: WorldFraming) -> String {
        switch framing {
        case .home: String(localized: "Home", bundle: .module)
        case .island: String(localized: "Island", bundle: .module)
        case .map: String(localized: "Map", bundle: .module)
        }
    }

    static func level(_ level: Int, of maxLevel: Int) -> String {
        String(localized: "Level \(level) of \(maxLevel)", bundle: .module)
    }

    static func stationAndLevel(_ station: String, level: Int) -> String {
        String(localized: "\(station) · level \(level)", bundle: .module)
    }

    /// The build's one exclamation (interaction spec §6.3).
    static func levelUp(_ level: Int) -> String {
        String(localized: "Level \(level)!", bundle: .module)
    }

    // MARK: - Home

    /// Calm as the chips show it: one decimal, in the user's locale.
    static func calm(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    /// Pofu's line for a visit beat (app–game boundary §6.2).
    static func beatLine(_ beat: VisitBeat) -> String {
        switch beat {
        case .care:
            String(localized: "I'm not feeling great. Shall we put the phone down for a bit?", bundle: .module)
        case .collect(let pouch):
            String(localized: "While you were away, the island gathered \(pouch.total.units) seeds.", bundle: .module)
        case .news(.stageGrew):
            String(localized: "Look: the island grew overnight!", bundle: .module)
        case .news(.islandArrived):
            String(localized: "Look: a new island drifted close overnight!", bundle: .module)
        case .build(let station, let level):
            String(localized: "\(stationName(station)) → level \(level) · Ready", bundle: .module)
        case .weeklyRecap:
            String(localized: "Our week is ready.", bundle: .module)
        }
    }

    /// The beat's one primary action.
    static func beatAction(_ beat: VisitBeat) -> String {
        switch beat {
        case .care: String(localized: "Okay", bundle: .module)
        case .collect: String(localized: "Collect", bundle: .module)
        case .news: String(localized: "See the island", bundle: .module)
        case .build: String(localized: "Build", bundle: .module)
        case .weeklyRecap: String(localized: "Take a look", bundle: .module)
        }
    }

    /// What Pofu says when tapped in the settled state, in a fixed order.
    static func settledLine(_ index: Int) -> String {
        switch index % WorldHomeModel.settledLineCount {
        case 0: String(localized: "Watering the sunflowers.", bundle: .module)
        case 1: String(localized: "Mochi's tea is on.", bundle: .module)
        default: String(localized: "The island hums along.", bundle: .module)
        }
    }

    static var settled: String {
        String(localized: "The island works without you.", bundle: .module)
    }

    static func wellbeing(_ band: WellbeingBand) -> String {
        switch band {
        case .cozy: String(localized: "In good spirits", bundle: .module)
        case .content: String(localized: "Content", bundle: .module)
        case .tired: String(localized: "A bit tired", bundle: .module)
        case .unwell: String(localized: "Not so well", bundle: .module)
        case .curledUp: String(localized: "Curled up", bundle: .module)
        }
    }

    static func wellbeingLabel(_ band: WellbeingBand) -> String {
        String(localized: "Pofu's mood: \(wellbeing(band))", bundle: .module)
    }

    static func calmChip(_ value: Double) -> String {
        String(localized: "Calm ×\(calm(value))", bundle: .module)
    }

    static func calmLabel(_ value: Double, growing: Bool, full: Bool) -> String {
        if full {
            return String(localized: "Calm ×\(calm(value)), full", bundle: .module)
        }
        if growing {
            return String(localized: "Calm ×\(calm(value)), growing", bundle: .module)
        }
        return calmChip(value)
    }

    static func todayLine(_ today: TodaySummary) -> String {
        if today.reaches == 0 {
            return String(localized: "No reaches yet today.", bundle: .module)
        }
        return String(localized: "Skipped \(today.skips) of \(today.reaches) today", bundle: .module)
    }

    static func guarded(_ today: TodaySummary) -> String {
        String(localized: "at least \(today.guardedAtLeast) / \(today.dailyHourMinutes) min", bundle: .module)
    }

    static func guardedLabel(_ today: TodaySummary) -> String {
        String(localized: "Time in guarded apps: at least \(today.guardedAtLeast) of \(today.dailyHourMinutes) minutes", bundle: .module)
    }

    static func seeds(_ count: Int) -> String {
        String(localized: "\(count) seeds", bundle: .module)
    }

    // MARK: - The Living Diorama

    /// Pofu's one exclamation when his cheeks are huge (once a day).
    static var cheeksHuge: String {
        String(localized: "My cheeks are huge!", bundle: .module)
    }

    static func collectAction(_ seeds: Int) -> String {
        String(localized: "Collect · \(seeds)", bundle: .module)
    }

    static func collectLabel(_ seeds: Int) -> String {
        String(localized: "Collect, \(seeds) seeds", bundle: .module)
    }

    static var jarLabel: String {
        String(localized: "Seed jar", bundle: .module)
    }

    static func jarValue(_ seeds: Int) -> String {
        String(localized: "\(seeds) seeds in the jar", bundle: .module)
    }

    static var jarHint: String {
        String(localized: "Collects the seeds in Pofu's cheeks", bundle: .module)
    }

    static var lanternLabel: String {
        String(localized: "Calm lantern", bundle: .module)
    }

    static var potsLabel: String {
        String(localized: "Skip pots", bundle: .module)
    }

    /// Pofu's accessibility value: his mood and what his cheeks hold.
    static func pofuValue(band: WellbeingBand, uncollected: Int) -> String {
        guard uncollected > 0 else { return wellbeing(band) }
        let cheeks = String(localized: "\(uncollected) seeds in his cheeks", bundle: .module)
        return "\(wellbeing(band)), \(cheeks)"
    }

    static func collected(_ seeds: Int, jar: Int) -> String {
        String(localized: "\(seeds) seeds collected. \(jar) in the jar.", bundle: .module)
    }

    /// The glance: "Today 3/4 · 15 min".
    static func glance(_ today: TodaySummary) -> String {
        if today.reaches == 0 {
            return String(localized: "Today · no reaches yet · \(today.guardedAtLeast) min", bundle: .module)
        }
        return String(localized: "Today \(today.skips)/\(today.reaches) · \(today.guardedAtLeast) min", bundle: .module)
    }

    static var openToday: String {
        String(localized: "Open Today", bundle: .module)
    }

    static var repairBanner: String {
        String(localized: "A guard isn't working.", bundle: .module)
    }

    static var repairAction: String {
        String(localized: "Fix", bundle: .module)
    }

    static var settings: String {
        String(localized: "Settings", bundle: .module)
    }
}
#endif
