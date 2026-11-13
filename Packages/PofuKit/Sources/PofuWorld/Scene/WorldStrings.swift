#if os(iOS)
import Foundation
import PofuCore

/// The world's copy, localized in the package's string catalog (Turkish
/// lines from the interaction spec §12.2).
enum WorldStrings {
    static func stationName(_ id: StationID) -> String {
        switch id {
        case .garden: String(localized: "Sunflower garden", bundle: .module)
        case .teaStall: String(localized: "Tea stall", bundle: .module)
        case .pond: String(localized: "Lily pond", bundle: .module)
        case .workshop: String(localized: "Workshop", bundle: .module)
        case .windmill: String(localized: "Windmill", bundle: .module)
        default: id.rawValue.capitalized
        }
    }

    /// Who keeps the station.
    static func stationKeeper(_ id: StationID) -> String? {
        switch id {
        case .garden: String(localized: "Pofu waters it", bundle: .module)
        case .teaStall: String(localized: "Mochi, our bunny neighbour, brews here", bundle: .module)
        case .workshop: String(localized: "Fındık, our hedgehog neighbour, mends here", bundle: .module)
        default: nil
        }
    }

    /// A line of flavour for the station's sheet.
    static func stationFlavour(_ id: StationID) -> String? {
        switch id {
        case .garden: String(localized: "Sunflowers like patient days.", bundle: .module)
        case .teaStall: String(localized: "The kettle is never in a hurry.", bundle: .module)
        case .workshop: String(localized: "Something is always being mended.", bundle: .module)
        default: nil
        }
    }

    static func islandName(_ id: IslandID) -> String {
        switch id {
        case .home: "Ayçiçeği"
        case .harbor: "İskele"
        case .koke: localized("koke.name")
        case .caglayan: localized("caglayan.name")
        default: id.rawValue.capitalized
        }
    }

    /// A wonder island's state under its name: asleep, healing (stage out of
    /// four) or healed.
    static func wonderState(stage: Int) -> String {
        switch WonderState(stage: stage) {
        case .asleep: String(localized: "Asleep", bundle: .module)
        case .healed: String(localized: "Healed", bundle: .module)
        case .healing(let stage): String(localized: "Healing \(stage) of \(WonderIslands.healedStage)", bundle: .module)
        }
    }

    // MARK: Koke (the first wonder island)

    /// A catalog string looked up by a computed key.
    private static func localized(_ key: String) -> String {
        Bundle.module.localizedString(forKey: key, value: key, table: nil)
    }

    /// A line of Koke's beats, the rumour or the rest line.
    static func kokeLine(_ kind: KokeLineKind) -> String {
        localized(KokeLayout.lineKey(kind))
    }

    static func kokeSpeaker(_ speaker: KokeSpeaker) -> String {
        switch speaker {
        case .pofu: localized("koke.speaker.pofu")
        case .mochi: localized("koke.speaker.mochi")
        case .koke: localized("koke.name")
        }
    }

    // MARK: Çağlayan (the second wonder island)

    static func caglayanLine(_ kind: CaglayanLineKind) -> String {
        localized(CaglayanLayout.lineKey(kind))
    }

    static func caglayanSpeaker(_ speaker: CaglayanSpeaker) -> String {
        switch speaker {
        case .pofu: localized("koke.speaker.pofu")
        case .mochi: localized("koke.speaker.mochi")
        case .damla: localized("caglayan.speaker.damla")
        }
    }

    /// The plaque that opens the stage's flow round.
    static var caglayanPlaque: String {
        localized("caglayan.plaque")
    }

    /// VoiceOver for the pool fountain Çağlayan gave.
    static var caglayanGift: String {
        localized("caglayan.gift")
    }

    /// The paper tag over a wonder island's gift on the day it arrives.
    static func giftTag(_ gift: HomeGifts.Gift) -> String {
        switch gift {
        case .kokeMoss: kokeGift
        case .caglayanFountain: localized("caglayan.gift.tag")
        }
    }

    /// VoiceOver for the moss Koke gave.
    static var kokeGift: String {
        localized("koke.gift")
    }

    static func residentName(_ id: ResidentID) -> String {
        switch id {
        case .mochi: "Mochi"
        case .findik: "Fındık"
        case .keeper: String(localized: "resident.keeper", defaultValue: "The bees' keeper", bundle: .module)
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

    // MARK: The place control (experience v1 §1.2)
    // New strings use `defaultValue:`; PR C adds them to the catalog.
    // Turkish: place.out "Uzaklaş", place.home "Eve dön", place.pofu "Pofu",
    // place.archipelago "Takımada", place.menu "Git".

    /// VoiceOver for the control when a tap zooms out.
    static var placeOut: String {
        String(localized: "place.out", defaultValue: "Zoom out", bundle: .module)
    }

    /// VoiceOver for the control on the Archipelago: a tap flies home.
    static var placeHome: String {
        String(localized: "place.home", defaultValue: "Back home", bundle: .module)
    }

    /// The menu's entry for Pofu (his corner of the home island).
    static var placePofu: String {
        String(localized: "place.pofu", defaultValue: "Pofu", bundle: .module)
    }

    /// The menu's entry for the sea.
    static var placeArchipelago: String {
        String(localized: "place.archipelago", defaultValue: "Archipelago", bundle: .module)
    }

    /// The menu's accessibility hint.
    static var placeMenu: String {
        String(localized: "place.menu", defaultValue: "Go to", bundle: .module)
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

    /// Why a station waits: the island level that raises its cap ("Ada
    /// seviyesi 3'te açılır").
    static func capReason(islandLevel: Int) -> String {
        String(localized: "Opens at island level \(islandLevel)", bundle: .module)
    }

    /// The next island level's short line, never a timer: "Ada 6 için: 2
    /// seviye daha", or the days still to pass when the levels are built.
    /// Once nothing is left, the line says the level is ready.
    static func nextIslandLevel(_ requirement: IslandLevelRequirement) -> String {
        switch GoalLine(requirement) {
        case .ready(let island):
            String(localized: "Island \(island) is ready", bundle: .module)
        case .levels(let island, let left):
            String(localized: "For island \(island): \(left) more levels", bundle: .module)
        case .days(let island, let left):
            String(localized: "For island \(island): \(left) more days", bundle: .module)
        }
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
        case .bell:
            String(
                localized: "bell.line",
                defaultValue: "Koke's awake, Çağlayan's flowing. A bell far off played my song. One note too many.",
                bundle: .module
            )
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
        case .bell: String(localized: "bell.action", defaultValue: "I heard it too", bundle: .module)
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

    /// Pofu's line when no beat waits (`HomeDailyLine`).
    static func dailyLine(_ line: HomeDailyLine) -> String {
        switch line {
        case .night(variant: 0): String(localized: "The island's asleep. Seeds pile up by morning.", bundle: .module)
        case .night: String(localized: "The neighbours turned in. See you at breakfast.", bundle: .module)
        case .giftArrived: String(localized: "A gift reached the island today. Spot it?", bundle: .module)
        case .letGo(let count): String(localized: "We let \(count) go today. Mostly your doing.", bundle: .module)
        case .guest: String(localized: "We've got a guest. Say hi?", bundle: .module)
        case .morning(variant: 0): String(localized: "Morning. Tea's brewing, the island's up.", bundle: .module)
        case .morning: String(localized: "Buried a seed. Forgot where. Classic hamster.", bundle: .module)
        case .midday(variant: 0): String(localized: "The sunflowers watch the sun. I watch you.", bundle: .module)
        case .midday: String(localized: "Yawned twice today. Very productive.", bundle: .module)
        case .evening(variant: 0): String(localized: "Evening. The island went orange. No filter.", bundle: .module)
        case .evening: String(localized: "Evening tea's on me. You sit.", bundle: .module)
        }
    }

    /// The seeds a build took, under its "Level n!".
    static func buildSpent(_ seeds: Int) -> String {
        String(localized: "−\(seeds) seeds", bundle: .module)
    }

    /// A wonder island's stop: what a tap does today.
    static func wonderToday(_ today: WonderToday) -> String {
        switch today {
        case .tapHelps: String(localized: "A tap helps it today", bundle: .module)
        case .doneForToday: String(localized: "Done for today. Back tomorrow", bundle: .module)
        case .needsSkip: String(localized: "Skip one reach today first", bundle: .module)
        case .sleeping: String(localized: "Asleep for the night. Come in the morning", bundle: .module)
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
            return String(localized: "The door's been quiet today.", bundle: .module)
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
            return String(localized: "Today · the door's quiet · \(today.guardedAtLeast) min", bundle: .module)
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

    static var play: String {
        String(localized: "Play", bundle: .module)
    }

    static var settings: String {
        String(localized: "Settings", bundle: .module)
    }

    // MARK: Visitors and the quiet day's letter (experience v1 §5)
    // New strings use `defaultValue:` and live in the catalog with Turkish:
    // visitor.label "%@, ziyaretçi", visitor.greet "Merhaba de",
    // visitor.gift "Hediye paketi", visitor.gift.hint "Aç",
    // visitor.help "Yardım bekliyor", visitor.help.hint "Yardım et",
    // visitor.letter "Sessiz gün mektubu", visitor.letter.hint "Yarın kimin geleceğini seç".

    /// VoiceOver for the visitor: who has come.
    static func visitorLabel(_ resident: ResidentID) -> String {
        String(format: String(localized: "visitor.label", defaultValue: "%@, a visitor", bundle: .module), residentName(resident))
    }

    /// VoiceOver announcement of an arrival.
    static func visitorArrived(_ resident: ResidentID) -> String {
        String(format: String(localized: "visitor.arrived", defaultValue: "%@ has come to visit", bundle: .module), residentName(resident))
    }

    static var visitorGreetHint: String {
        String(localized: "visitor.greet", defaultValue: "Say hello", bundle: .module)
    }

    static var giftLabel: String {
        String(localized: "visitor.gift", defaultValue: "Gift parcel", bundle: .module)
    }

    static var giftHint: String {
        String(localized: "visitor.gift.hint", defaultValue: "Open it", bundle: .module)
    }

    static var helpLabel: String {
        String(localized: "visitor.help", defaultValue: "Needs a hand", bundle: .module)
    }

    static var helpHint: String {
        String(localized: "visitor.help.hint", defaultValue: "Help", bundle: .module)
    }

    static var letterLabel: String {
        String(localized: "visitor.letter", defaultValue: "Quiet-day letter", bundle: .module)
    }

    static var letterHint: String {
        String(localized: "visitor.letter.hint", defaultValue: "Choose who comes tomorrow", bundle: .module)
    }

    static var inviteTitle: String {
        String(localized: "invite.title", defaultValue: "Who should we invite tomorrow?", bundle: .module)
    }

    static var inviteSubtitle: String {
        String(localized: "invite.subtitle", defaultValue: "Anyone you have met. It costs nothing and never runs out.", bundle: .module)
    }

    static var inviteEmpty: String {
        String(localized: "invite.empty", defaultValue: "You have not met anyone yet. Visitors will come.", bundle: .module)
    }

    static var inviteClose: String {
        String(localized: "invite.close", defaultValue: "Not now", bundle: .module)
    }

    /// The button's VoiceOver label: "Invite Sumi".
    static func invite(_ name: String) -> String {
        String(format: String(localized: "invite.pick", defaultValue: "Invite %@", bundle: .module), name)
    }

    /// VoiceOver label and hint of a part of the visit.
    static func visitorPart(_ part: VisitorPart, visitor: VisitorSnapshot?) -> (label: String, hint: String) {
        switch part {
        case .visitor: (label: visitor.map { visitorLabel($0.resident) } ?? "", hint: visitorGreetHint)
        case .gift: (label: giftLabel, hint: giftHint)
        case .help: (label: helpLabel, hint: helpHint)
        case .letter: (label: letterLabel, hint: letterHint)
        }
    }
}
#endif
