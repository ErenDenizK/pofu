/// Compile-time switches for work in progress. Each is on or off in both
/// builds (Pofu and PofuLive) alike unless its comment says otherwise.
enum FeatureFlags {
    /// Home shows Pofu's island (`IslandScene`, iteration W2) instead of
    /// the room. On in both builds; turning it off restores the room.
    static let islandHome = true
}
