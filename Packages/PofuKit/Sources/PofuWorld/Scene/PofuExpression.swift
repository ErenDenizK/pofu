import Foundation
import PofuCompanion
import PofuCore

/// What Pofu feels in the world, as a `PofuMood` (the face itself is in
/// PofuCompanion: `PofuExpression`). Pure, so the rules are tested.
///
/// ADR-0017: no mood here is sad or guilty. A low band shows him curled up
/// and drowsy (sleepy), or at most a little worried; it never droops his
/// ears or blames the player.
public enum PofuMoodSource {
    /// The mood for this moment. What just happened (`event`, shared with
    /// the residents) wins, then the night, the day's visitor, then the
    /// wellbeing band.
    public static func mood(
        band: WellbeingBand,
        isBedtime: Bool,
        calmIsFull: Bool,
        visitorPresent: Bool,
        event: ResidentEvent? = nil
    ) -> PofuMood {
        switch event {
        case .ceremonyDone: return .proud
        case .stationLevelledUp, .visitorArrived, .tapped: return .happy
        case .firstTapOfDay: return .curious
        case nil: break
        }
        if isBedtime || band == .curledUp { return .sleepy }
        if calmIsFull { return .relieved }
        if visitorPresent { return .curious }
        switch band {
        case .cozy: return .happy
        case .content, .tired: return .calm
        case .unwell: return .worried
        case .curledUp: return .sleepy
        }
    }
}
