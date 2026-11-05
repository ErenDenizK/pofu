import Foundation

/// Ids written before the English rename (2026-11-03). Saves and event logs
/// hold station and island ids as strings, so decoding maps the old Turkish
/// values to the new ones; encoding always writes the new ones.
/// The full map is `docs/development/rename-map.md`.
enum LegacyIds {
    static let islands: [String: String] = ["aycicegi": "home", "iskele": "harbor"]
    static let stations: [String: String] = ["cay": "teaStall", "simit": "bagelCart"]
}

extension IslandID {
    /// Reads a plain string (and `{"rawValue": ...}`, the shape an older
    /// build may have written); old Turkish ids become the English ones.
    public init(from decoder: any Decoder) throws {
        let raw = try decodeIdString(from: decoder)
        self.init(rawValue: LegacyIds.islands[raw] ?? raw)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension StationID {
    /// Reads a plain string (and `{"rawValue": ...}`, the shape an older
    /// build may have written); old Turkish ids become the English ones.
    public init(from decoder: any Decoder) throws {
        let raw = try decodeIdString(from: decoder)
        self.init(rawValue: LegacyIds.stations[raw] ?? raw)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

private enum RawValueKey: String, CodingKey {
    case rawValue
}

private func decodeIdString(from decoder: any Decoder) throws -> String {
    if let single = try? decoder.singleValueContainer(), let value = try? single.decode(String.self) {
        return value
    }
    return try decoder.container(keyedBy: RawValueKey.self).decode(String.self, forKey: .rawValue)
}

/// The station islands retired on 2026-11-05 (game plan §2): Yıldız, Kaplıca
/// and Kitap. A save written before then may hold their arrivals and
/// station levels; `StationLedger` drops them on decoding and refunds the
/// seeds their levels cost into the jar, so nothing paid for is lost.
enum RetiredIds {
    static let islands: Set<IslandID> = ["yildiz", "kaplica", "kitap"]

    /// The retired stations' level prices (levels 1 to 5), as they were.
    static let stationCosts: [StationID: [Int]] = [
        "observatory": [45, 70, 100, 135, 170],
        "fireflies": [55, 80, 110, 145, 180],
        "hammock": [65, 90, 120, 155, 190],
        "spring": [50, 75, 105, 140, 175],
        "hamam": [60, 85, 115, 150, 185],
        "serbet": [70, 95, 125, 160, 195],
        "readingTree": [55, 80, 110, 145, 180],
        "bookHouse": [65, 90, 120, 155, 190],
        "press": [75, 100, 130, 165, 200],
    ]
}
