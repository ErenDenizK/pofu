#if os(iOS)
import Foundation

/// The flow game's copy, English with Turkish in the package's string
/// catalog. Short and warm; no score, no timer, no "wrong".
enum FlowStrings {
    static var leave: String { String(localized: "Leave the water for later", bundle: .module) }
    static var undo: String { String(localized: "Undo", bundle: .module) }
    static var hint: String { String(localized: "Hint", bundle: .module) }
    static var done: String { String(localized: "Done", bundle: .module) }
    static var doneTitle: String { String(localized: "The water found its way home.", bundle: .module) }
    /// A board solved, while it pours before the next one slides in.
    static var boardDone: String { String(localized: "The water reached the pool.", bundle: .module) }
    static var boardAccessibility: String {
        String(localized: "The stream. Turn each stone until the water reaches the pool.", bundle: .module)
    }

    static func board(_ number: Int, of total: Int) -> String {
        String(localized: "Board \(number) of \(total)", bundle: .module)
    }

    static func targets(_ wet: Int, of total: Int) -> String {
        String(localized: "\(wet) of \(total) wet", bundle: .module)
    }

    static func targetsAccessibility(_ wet: Int, of total: Int) -> String {
        String(localized: "\(wet) of \(total) targets wet", bundle: .module)
    }

    static func hintCaption(helper: String) -> String {
        String(localized: "\(helper) points at a stone.", bundle: .module)
    }

    static var damla: String { String(localized: "Damla", bundle: .module) }
    static var pofu: String { String(localized: "Pofu", bundle: .module) }

    // MARK: VoiceOver

    static func kindName(_ kind: FlowTileKind) -> String {
        switch kind {
        case .straight: String(localized: "Straight", bundle: .module)
        case .bend: String(localized: "Bend", bundle: .module)
        case .split: String(localized: "Split", bundle: .module)
        case .source: String(localized: "Spring", bundle: .module)
        case .mouth: String(localized: "Mouth", bundle: .module)
        case .wheel: String(localized: "Wheel", bundle: .module)
        case .gate: String(localized: "Gate", bundle: .module)
        case .rock: String(localized: "Rock", bundle: .module)
        case .grass: String(localized: "Grass", bundle: .module)
        }
    }

    static func sideName(_ side: String) -> String {
        switch side {
        case "north": String(localized: "north", bundle: .module)
        case "east": String(localized: "east", bundle: .module)
        case "south": String(localized: "south", bundle: .module)
        default: String(localized: "west", bundle: .module)
        }
    }

    static var wetWord: String { String(localized: "wet", bundle: .module) }
    static var dryWord: String { String(localized: "dry", bundle: .module) }

    static func opens(_ sides: [String]) -> String {
        let list = sides.map(sideName).joined(separator: ", ")
        return String(localized: "opens \(list)", bundle: .module)
    }

    static func tile(_ tile: FlowTile, wet: Bool, cell: FlowCell) -> String {
        let name = kindName(tile.kind)
        let opening = opens(tile.openings.names)
        let state = wet ? wetWord : dryWord
        return String(localized: "\(name), \(opening), \(state), row \(cell.row + 1) column \(cell.column + 1)", bundle: .module)
    }

    static func reaches(_ kind: FlowTileKind) -> String {
        kind == .wheel
            ? String(localized: "Water reaches the wheel", bundle: .module)
            : String(localized: "Water reaches the pool", bundle: .module)
    }
}
#endif
