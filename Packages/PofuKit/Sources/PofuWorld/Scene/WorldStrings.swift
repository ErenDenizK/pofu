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
}
#endif
