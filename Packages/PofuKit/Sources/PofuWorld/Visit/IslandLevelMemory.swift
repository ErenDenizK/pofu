import Foundation

/// The island level the player last saw painted, kept across launches (the
/// pattern of `WorldHomeModel`'s cheek-line defaults). When the world's level
/// is above it, the island grew while the app was closed: the visit carries
/// the news and the scene lands on the old painting until the player takes
/// the news beat's button ("Ada büyüdü").
///
/// A first launch has nothing stored: the true level is presented at once and
/// no news is made.
@MainActor
public final class IslandLevelMemory {
    nonisolated static let key = "pofu.home.islandLevel.lastPresented"

    private let defaults: UserDefaults?
    private var inMemory: Int?

    /// - Parameter defaults: Where the level is remembered; `nil` keeps it in
    ///   memory (tests, screenshots).
    public init(defaults: UserDefaults? = nil) {
        self.defaults = defaults
        if let stored = defaults?.object(forKey: Self.key) as? Int, stored >= 1 {
            inMemory = stored
        }
    }

    /// The last level the scene presented; `nil` on a first launch.
    public var lastPresented: Int? {
        inMemory
    }

    /// The scene presents `level` (the moment began, or the level was shown at once).
    public func record(_ level: Int) {
        inMemory = level
        defaults?.set(level, forKey: Self.key)
    }

    /// The visit's news: the island grew since the player last saw it. Never
    /// on a first launch, and once per level (recording the level ends it).
    public func news(worldLevel level: Int) -> VisitNews? {
        guard let last = inMemory, level > last else { return nil }
        return .stageGrew(level)
    }
}

/// The level of the painting the scene draws. It trails the world's level
/// until the moment's cross-fade begins: the painting never runs ahead of the
/// world, and a moment ends with the two equal.
public struct IslandLevelStage: Hashable, Sendable {
    /// The level the scene presents; `nil` follows the world (a first
    /// launch, a state nothing has held back).
    public private(set) var presented: Int?

    public init(presented: Int? = nil) {
        self.presented = presented
    }

    /// The level to draw for a world at `level`: the presented one, never
    /// above the world's.
    public func shown(worldLevel level: Int) -> Int {
        min(presented ?? level, level)
    }

    /// The painting is behind a world at `level`.
    public func lags(behind level: Int) -> Bool {
        shown(worldLevel: level) < level
    }

    /// The scene presents `level`.
    public mutating func present(_ level: Int) {
        presented = level
    }
}
