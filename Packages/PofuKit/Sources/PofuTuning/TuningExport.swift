import Foundation

/// What "Dışa aktar" shares: the changed keys with their old and new
/// values, for reading at a glance, and the complete values, which the
/// agent commits as the new `tuning.json`.
public struct TuningExport: Codable, Hashable, Sendable {
    /// Marks the file as a tuning lab export.
    public var kind: String
    /// Bumped when `TuningValues` changes shape.
    public var schema: Int
    public var changed: [String: TuningChange.Pair]
    public var values: TuningValues

    public static let kindName = "pofu-tuning"
    public static let currentSchema = 1

    public init(values: TuningValues, defaults: TuningValues = .defaults) {
        kind = Self.kindName
        schema = Self.currentSchema
        changed = Dictionary(uniqueKeysWithValues: values.changes(from: defaults).map { ($0.key, TuningChange.Pair(defaultValue: $0.defaultValue, value: $0.value)) })
        self.values = values
    }

    /// Pretty-printed with sorted keys, so two exports diff cleanly.
    public func json() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(self) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    /// Reads an export back (the agent's side, and the tests).
    public static func decode(_ json: String) throws -> TuningExport {
        try JSONDecoder().decode(TuningExport.self, from: Data(json.utf8))
    }
}

extension TuningChange {
    /// A change without its key, for the export's `changed` map.
    public struct Pair: Codable, Hashable, Sendable {
        public var defaultValue: Double
        public var value: Double

        enum CodingKeys: String, CodingKey {
            case defaultValue = "default"
            case value
        }
    }
}
