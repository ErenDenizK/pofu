import Foundation

/// A hand-made board as shipped in `flow-boards.json`.
public struct FlowBoardRecord: Codable, Hashable, Sendable {
    public let id: String
    public let island: String
    public let stage: Int
    public let order: Int
    /// Which art and sound set draws it (`water`, `light`, `thread`).
    public let skin: String
    public let rows: [String]

    public var board: FlowBoard? { FlowBoard(rows: rows) }
}

/// The bundled boards, and how an island opens a round for a stage.
public enum FlowLibrary {
    /// Çağlayan's island id, as the boards file spells it.
    public static let caglayan = "caglayan"

    public static let records: [FlowBoardRecord] = {
        guard let url = Bundle.module.url(forResource: "flow-boards", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let records = try? JSONDecoder().decode([FlowBoardRecord].self, from: data)
        else { return [] }
        return records
    }()

    public static func boards(island: String, stage: Int) -> [FlowBoardRecord] {
        records.filter { $0.island == island && $0.stage == stage }.sorted { $0.order < $1.order }
    }

    /// The round for `stage` (1...4) of `island`: its boards in order. Nil
    /// when the island has no boards for that stage.
    public static func round(island: String = caglayan, stage: Int) -> FlowRound? {
        let boards = boards(island: island, stage: stage).compactMap(\.board)
        return boards.isEmpty ? nil : FlowRound(boards: boards)
    }

    public static func skin(island: String = caglayan, stage: Int) -> FlowSkin {
        FlowSkin(rawValue: boards(island: island, stage: stage).first?.skin ?? "") ?? .water
    }
}

/// Maps tile kinds to art and sound sets; the model never knows the skin.
public enum FlowSkin: String, Sendable, Codable {
    case water, light, thread
}
