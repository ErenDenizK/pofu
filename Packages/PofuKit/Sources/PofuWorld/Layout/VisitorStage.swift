import Foundation
import PofuCore

/// The parts of a visit a tap can land on (experience v1 §5.1, §5.3).
public enum VisitorPart: String, CaseIterable, Hashable, Sendable {
    /// The visitor: a tap greets them (a heart).
    case visitor
    /// The wrapped parcel: a tap opens it.
    case gift
    /// The thing of theirs that needs a tap (a kite in a tree).
    case help
    /// The quiet day's letter: a tap opens the invitation sheet.
    case letter
}

/// The art the visit's pieces swap to by name once Codex has painted them;
/// until then the scene draws code-drawn stand-ins under the same names.
public enum VisitorArt {
    /// The seed that drifts the visitor down to the front-lip spot.
    public static let dandelion = "visitor-dandelion"
    /// The wrapped gift parcel.
    public static let giftParcel = "gift-parcel-closed"
    /// The quiet day's letter.
    public static let guestLetter = "guest-letter-envelope"
}

/// How the visitor arrives on the island.
public enum VisitorArrivalStyle: Hashable, Sendable {
    /// Before the harbor: down on a dandelion seed to the front-lip spot.
    case dandelion
    /// Once the harbor exists: Gezgin lands them at the pier.
    case pier
}

/// The visitor's place in the world and the arrival beat (experience v1
/// §5.3), pure and unit-tested. The arrival runs in the Moment state for at
/// most `momentSeconds`: the camera pans to the slot first (`panLead`), then
/// the visitor drifts or steps in (`arrivalSeconds`).
public enum VisitorStage {
    /// The longest the arrival may hold the frame rate up, in seconds.
    public static let momentSeconds = 2.0
    /// The camera's head start on the visitor, in seconds.
    public static let panLead = 0.4
    /// How long the drift or the landing takes, in seconds.
    public static let arrivalSeconds = 1.6

    /// One piece of a visit placed in the world.
    public struct Placed: Hashable, Sendable, Identifiable {
        public var part: VisitorPart
        /// Its feet, in world units.
        public var feet: WorldPoint

        public var id: String { part.rawValue }

        /// The tap box around the feet.
        public var hitBox: WorldBox {
            let box = VisitorStage.hitBox(of: part)
            return WorldBox(minX: feet.x + box.minX, minY: feet.y + box.minY, maxX: feet.x + box.maxX, maxY: feet.y + box.maxY)
        }

        /// Larger is nearer (`IslandLayout.depth(ofY:)`).
        public var depth: Double { IslandLayout.depth(ofY: feet.y) }
    }

    /// Where the parcel lies beside the visitor.
    static let giftOffset = WorldPoint(x: -20, y: 3)
    /// Where the help target stands beside the visitor.
    static let helpOffset = WorldPoint(x: 32, y: -2)
    /// The quiet day's letter lies at the front-lip spot (nobody is
    /// visiting).
    public static let letterSpot = VisitorSlots.v1

    /// A part's tap box, relative to its feet.
    static func hitBox(of part: VisitorPart) -> WorldBox {
        switch part {
        case .visitor: WorldBox(minX: -14, minY: -32, maxX: 14, maxY: 4)
        case .gift: WorldBox(minX: -11, minY: -18, maxX: 11, maxY: 4)
        case .help: WorldBox(minX: -13, minY: -36, maxX: 13, maxY: 4)
        case .letter: WorldBox(minX: -13, minY: -24, maxX: 13, maxY: 4)
        }
    }

    /// The visitor's feet: their slot, beside the favourite station's
    /// worker for a festival or an invitation.
    public static func feet(of visitor: VisitorSnapshot) -> WorldPoint {
        VisitorSlots.point(for: visitor.slot, favourite: visitor.bonusStation)
    }

    /// Whether the visitor stands in the world. A stay-over visitor sleeps
    /// in the guest room at night: only its window shows (H4).
    public static func isStanding(_ visitor: VisitorSnapshot, isBedtime: Bool) -> Bool {
        !(visitor.reason == .stayOver && isBedtime)
    }

    /// A stay-over visitor lights the guest room's window at night
    /// (`HD2DLayer`'s `guestNight`).
    public static func isGuestNight(_ visitor: VisitorSnapshot?) -> Bool {
        visitor?.reason == .stayOver && visitor?.state != .departed
    }

    /// Everything of today's visit that stands in the world, back to
    /// front.
    ///
    /// - Parameters:
    ///   - visitor: Today's visitor; `nil` on a quiet day.
    ///   - invitationOpen: A quiet day's letter waits for a pick.
    ///   - isBedtime: At night the parcel waits (nothing can be opened) and a
    ///     stay-over visitor sleeps.
    public static func parts(visitor: VisitorSnapshot?, invitationOpen: Bool, isBedtime: Bool) -> [Placed] {
        guard let visitor else {
            return invitationOpen ? [Placed(part: .letter, feet: letterSpot)] : []
        }
        let feet = Self.feet(of: visitor)
        var result: [Placed] = []
        if isStanding(visitor, isBedtime: isBedtime) {
            result.append(Placed(part: .visitor, feet: feet))
        }
        if visitor.gift != nil, !visitor.giftOpened, !isBedtime {
            result.append(Placed(part: .gift, feet: WorldPoint(x: feet.x + giftOffset.x, y: feet.y + giftOffset.y)))
        }
        if visitor.reason == .help, !visitor.helped, isStanding(visitor, isBedtime: isBedtime) {
            result.append(Placed(part: .help, feet: WorldPoint(x: feet.x + helpOffset.x, y: feet.y + helpOffset.y)))
        }
        return result.sorted { $0.depth < $1.depth }
    }

    /// The game event a tap on `part` sends, if any. A greeted visitor
    /// does not count another heart; the letter opens a sheet instead.
    public static func event(for part: VisitorPart, visitor: VisitorSnapshot?) -> GameEvent.Kind? {
        switch part {
        case .visitor: visitor.flatMap { $0.state == .greeted ? nil : .greetedVisitor }
        case .gift: .openedGift
        case .help: .helped
        case .letter: nil
        }
    }

    // MARK: - The greeting's answer

    /// How far over the visitor's feet the greeting's heart floats, in the
    /// visitor's own units (the visitor stands 30 tall).
    public static let heartLift = 34.0

    /// Where the greeting's heart floats, in world units: over a greeted
    /// visitor who stands in the world (`parts`, from `parts(...)` or
    /// `PlateLife.visitorParts`), drawn at `scale` (1 on the sprite
    /// island, the plate's resident scale on the plate). `nil` before the
    /// greeting, on a quiet day and while a stay-over guest sleeps. It
    /// stays for the rest of the visit: the visitor has been greeted today.
    public static func greetingHeart(parts: [Placed], visitor: VisitorSnapshot?, scale: Double = 1) -> WorldPoint? {
        guard visitor?.state == .greeted, let feet = parts.first(where: { $0.part == .visitor })?.feet else { return nil }
        return WorldPoint(x: feet.x, y: feet.y - heartLift * scale)
    }

    /// The parts as tap targets for the one resolver.
    public static func hitTargets(visitor: VisitorSnapshot?, invitationOpen: Bool, isBedtime: Bool) -> [HitTarget] {
        parts(visitor: visitor, invitationOpen: invitationOpen, isBedtime: isBedtime).map {
            HitTarget(kind: .visitor($0.part), worldBox: $0.hitBox, depth: $0.depth)
        }
    }

    // MARK: - The invitation

    /// Who the quiet day's letter lists: the residents the player has met
    /// who can visit, in story order (Gezgin's postcard and the home
    /// residents are not on it). A resident with no painted `visitor-<id>` art is not
    /// on it: the game shows no stand-in (route R3).
    public static func inviteChoices(met: [ResidentID]) -> [ResidentID] {
        VisitorSchedule.standardRoster.map(\.resident).filter { met.contains($0) && WorldArt.sprite("visitor-\($0.rawValue)") != nil }
    }

    // MARK: - The arrival

    /// How the visitor comes: down on a dandelion seed before the harbor
    /// (V1), landed at the pier by Gezgin after it.
    public static func arrivalStyle(for slot: VisitSlot) -> VisitorArrivalStyle {
        slot == .v1 ? .dandelion : .pier
    }

    /// A key that names this visit for the once-only arrival beat.
    public static func arrivalKey(of visitor: VisitorSnapshot) -> String {
        "\(visitor.resident.rawValue)-\(visitor.reason.rawValue)-\(visitor.slot.rawValue)"
    }

    /// Whether this visit still has an arrival to play: the player has not
    /// greeted them yet.
    public static func hasArrival(_ visitor: VisitorSnapshot) -> Bool {
        visitor.state == .arriving || visitor.state == .present
    }

    /// Where the visitor is drawn, as an offset from their feet, and how
    /// visible, `elapsed` seconds after the arrival began. Settled (zero
    /// offset, fully visible) from `arrivalSeconds` on, and before the
    /// camera has panned they are not yet there.
    public static func arrival(style: VisitorArrivalStyle, elapsed: Double) -> (dx: Double, dy: Double, opacity: Double, seed: Double) {
        let t = elapsed - panLead
        guard t > 0 else { return (0, 0, 0, 0) }
        let p = min(t / arrivalSeconds, 1)
        guard p < 1 else { return (0, 0, 1, 0) }
        let ease = 1 - pow(1 - p, 3)
        let left = 1 - ease
        switch style {
        case .dandelion:
            // Down on a seed, swaying a little, the seed letting go at the
            // end.
            let sway = sin(p * .pi * 3) * 7 * left
            return (34 * left + sway, -96 * left * left, min(p / 0.15, 1), min(max(1 - (p - 0.85) / 0.15, 0), 1))
        case .pier:
            // Stepping in from the right with two small hops.
            let hop = abs(sin(p * .pi * 3)) * 5 * left
            return (72 * left, -hop, min(p / 0.2, 1), 0)
        }
    }

    /// The visitor's idle bob, in world units: only in the Ambient state;
    /// settled it is exactly zero (the frame stays cached).
    public static func idleBob(at time: Double, isAmbient: Bool) -> Double {
        isAmbient ? -abs(sin(time * 2.2)) * 1.4 : 0
    }
}
