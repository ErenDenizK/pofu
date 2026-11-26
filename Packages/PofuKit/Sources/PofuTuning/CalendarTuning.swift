import Foundation

/// The island year's numbers (island calendar v1, C1): the `calendar`
/// block of `tuning.json`. Not a slider, so it is not part of
/// `TuningValues` and the tuning panel never shows it; edit the file.
/// `PofuCore.IslandYear.Rules` has an initialiser that takes these.
public struct CalendarTuning: Codable, Hashable, Sendable {
    /// Days one season lasts.
    public var seasonDays: Int
    /// Season names in the order the year turns.
    public var order: [String]
    /// Seasons with no look yet, left out of the cycle.
    public var disabled: [String]

    public init(seasonDays: Int, order: [String], disabled: [String]) {
        self.seasonDays = seasonDays
        self.order = order
        self.disabled = disabled
    }

    private struct File: Decodable {
        var calendar: CalendarTuning
    }

    /// Decodes the `calendar` block of the bundled `tuning.json`.
    public static func bundled() throws -> CalendarTuning {
        guard let url = Bundle.module.url(forResource: "tuning", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(File.self, from: Data(contentsOf: url)).calendar
    }

    /// The bundled values. A test proves the block decodes.
    public static let defaults: CalendarTuning = {
        do {
            return try bundled()
        } catch {
            preconditionFailure("tuning.json calendar does not decode: \(error)")
        }
    }()
}
