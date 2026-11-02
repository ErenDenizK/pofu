/// Compile-time switches for work in progress. Each is on or off in both
/// builds (Pofu and PofuLive) alike unless its comment says otherwise.
enum FeatureFlags {
    /// Home shows Pofu's island (`IslandScene`, iteration W2) instead of
    /// the room. On in both builds; turning it off restores the room.
    static let islandHome = true

    /// Home is `WorldHome` (app–game boundary §6): the wellbeing pill, the
    /// calm chip, the gear, the Today card and one contextual action, with
    /// the visit queue, Collect and Build on the game model. Off in both
    /// builds until the gate's dogfood week ends: the gate comes first, and
    /// the founder's Home must not change under him mid-week.
    static let worldHome = false
}
