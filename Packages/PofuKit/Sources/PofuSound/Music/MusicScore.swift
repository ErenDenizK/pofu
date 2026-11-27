import Foundation

/// The three voices of a cell (music-system-v1 D5). Each is its own stem,
/// the same length, sample-aligned.
public enum MusicStem: String, CaseIterable, Codable, Hashable, Sendable {
    case lead, bed, pulse
}

/// Which island's tune. Raw values are the `%%pofu island` names in
/// `design/music/score/`. Only Home has a tune so far.
public enum MusicIsland: String, CaseIterable, Codable, Hashable, Sendable {
    case home, koke, caglayan, revontuli, emanet, mehtap
}

/// The island's own season, mirroring `PofuCore.Season` by raw value (this
/// module does not link the core). It picks the lead's instrument.
public enum MusicSeason: String, CaseIterable, Codable, Hashable, Sendable {
    case spring, summer, autumn, winter

    /// The lead the spec asks for in this season (music-system-v1 section 6).
    /// Only the instruments in `music.json` can sound: until they are
    /// rendered (MU4) every season plays the lead the tune has.
    public var leadInstrument: String {
        switch self {
        case .spring: "kalimba"
        case .summer: "nylon_pluck"
        case .autumn: "felt_keys"
        case .winter: "music_box"
        }
    }
}

/// `Resources/Music/music.json`: the cells the renderer wrote
/// (`tools/music/render.py stems`) and the files of each.
public struct MusicIndex: Codable, Equatable, Sendable {
    public struct Cell: Codable, Equatable, Sendable {
        /// The cell's length, tail included.
        public var seconds: Double
        public var stems: [String: String]
    }

    public struct Tune: Codable, Equatable, Sendable {
        public var island: String
        public var time: String
        /// The lead's instrument, as rendered.
        public var lead: String
        public var bpm: Int
        /// The cells in the order the director plays them; the last is the ending.
        public var order: [String]
        public var cells: [String: Cell]
    }

    public var tunes: [String: Tune]

    public init(tunes: [String: Tune] = [:]) {
        self.tunes = tunes
    }

    /// The tune for an island's day or night, if one is written.
    public func tune(island: MusicIsland, time: String) -> (name: String, tune: Tune)? {
        let name = "\(island.rawValue)-\(time)"
        return tunes[name].map { (name, $0) }
    }

    public static let empty = MusicIndex()

    public static func decode(_ data: Data) throws -> MusicIndex {
        try JSONDecoder().decode(MusicIndex.self, from: data)
    }

    /// The bundled index (`Resources/Music/music.json`).
    public static func bundled() throws -> MusicIndex {
        guard let url = MusicAssets.url(for: "music", withExtension: "json") else { throw CocoaError(.fileNoSuchFile) }
        return try decode(Data(contentsOf: url))
    }
}

/// Where the rendered stems live in the module bundle.
enum MusicAssets {
    static func url(for name: String, withExtension ext: String) -> URL? {
        Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Resources/Music")
    }

    /// A stem file's URL from the name `music.json` gives it (`home-day-a-lead.m4a`).
    static func url(forFile file: String) -> URL? {
        let name = (file as NSString).deletingPathExtension
        return url(for: name, withExtension: (file as NSString).pathExtension)
    }
}
