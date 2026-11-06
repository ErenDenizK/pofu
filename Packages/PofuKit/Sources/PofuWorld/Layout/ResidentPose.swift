import Foundation
import PofuCore

/// A resident's pose: edits of the base art on its own canvas, so they swap in place (batches 03, 20,
/// 29 and 41). A pose a resident has no art for falls back (`Resident.art(for:)`).
public enum ResidentPose: String, CaseIterable, Sendable {
    /// The base art.
    case rest
    /// At work: Mochi holds a glass of tea, Fındık a wooden gear.
    case work
    /// Wide-eyed, ears up (Mochi only so far).
    case surprised
    /// Both eyes beaming.
    case eyesHappy = "eyes-happy"
    /// Both eyes gently shut: asleep.
    case eyesClosed = "eyes-closed"
    /// Beaming, the whole body (batch 41): a level-up, a visitor.
    case happy
    /// Drowsy, ears down: night and bedtime.
    case sleepy
    /// Chest out: the ceremony for their station is done.
    case proud

    /// The poses to try, best first: the reactions fall back to the older eye poses, then the base.
    var fallbacks: [ResidentPose] {
        switch self {
        case .happy: [.happy, .eyesHappy]
        case .sleepy: [.sleepy, .eyesClosed]
        default: [self]
        }
    }
}

/// What happened that shows on a resident's face, and the pose it asks for (home progression 4.4: the
/// island answers the player). Events are short: the pose lasts `seconds`, then the idle pose returns.
public enum ResidentEvent: Hashable, Sendable {
    /// Their station just levelled up (the build moment's hop).
    case stationLevelledUp
    /// Today's visitor has arrived.
    case visitorArrived
    /// The level-up ceremony for their station is over.
    case ceremonyDone
    /// The first resident the player tapped today.
    case firstTapOfDay

    public var pose: ResidentPose {
        switch self {
        case .stationLevelledUp, .visitorArrived: .happy
        case .ceremonyDone: .proud
        case .firstTapOfDay: .surprised
        }
    }

    /// How long the pose is held.
    public var seconds: Double {
        switch self {
        case .stationLevelledUp: 1.6
        case .visitorArrived: 4
        case .ceremonyDone: 6
        case .firstTapOfDay: 1.6
        }
    }
}

/// The reactions now on the island, by cast id (`ResidentID.rawValue`, "simit", "goat"): each lapses by
/// itself. Also keeps the day of the last resident tap, for the first tap of the day. Pure value, so the
/// mood rules are tested on any platform.
public struct ResidentReactions: Sendable {
    private var entries: [String: (event: ResidentEvent, until: Date)] = [:]
    private var lastTapDay: Date?

    public init() {}

    /// `event` shows on each of `ids` from `now` for its duration; a later event replaces an earlier one.
    public mutating func add(_ event: ResidentEvent, for ids: [String], at now: Date) {
        for id in ids {
            entries[id] = (event, now.addingTimeInterval(event.seconds))
        }
    }

    /// The event showing on `id` at `now`, if one is.
    public func event(of id: String, at now: Date) -> ResidentEvent? {
        guard let entry = entries[id], now < entry.until else { return nil }
        return entry.event
    }

    /// The player tapped `id`: surprised if it is the first tap of the calendar day.
    /// - Returns: Whether it was the first tap today.
    @discardableResult
    public mutating func noteTap(on id: String, at now: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: now)
        guard lastTapDay != day else { return false }
        lastTapDay = day
        add(.firstTapOfDay, for: [id], at: now)
        return true
    }

    /// The cast ids a station's ceremony or level-up shows on: its resident (and the harbor's
    /// Simit and goat, who stand at the cart and the pier).
    public static func cast(of station: StationID) -> [String] {
        var ids = IslandLayout.residents.filter { $0.station == station }.map { $0.id.rawValue }
        switch station {
        case .bagelCart: ids.append("simit")
        case .pier: ids.append("goat")
        default: break
        }
        return ids
    }

    /// Every resident and cast member: who a visitor's arrival cheers.
    public static var everyone: [String] {
        IslandLayout.residents.map { $0.id.rawValue } + ["simit", "goat"]
    }
}

extension IslandLayout.Resident {
    /// The baked sprite for `pose`: `mochi-work`, `findik-eyes-closed`; the base art where the resident
    /// has none.
    public func art(for pose: ResidentPose) -> String {
        guard pose != .rest else { return art }
        for candidate in pose.fallbacks {
            let name = "\(art)-\(candidate.rawValue)"
            if WorldArt.sprite(name) != nil { return name }
        }
        return art
    }

    /// The pose a resident wears: what just happened to them (`event`) while it lasts, else drowsy at
    /// bedtime, at work while the camera is on them or their station, else the base.
    public func idlePose(isBedtime: Bool, isFocused: Bool, event: ResidentEvent? = nil) -> ResidentPose {
        if let event { return event.pose }
        if isBedtime { return .sleepy }
        return isFocused ? .work : .rest
    }
}

extension BuildMoment {
    /// The station's resident during a build: startled as the new art pops in, then beaming through
    /// their hop (`ResidentEvent.stationLevelledUp`). `nil` before the pop, after the hop and with Reduce Motion (no hop, no start).
    public func residentPose(at t: Double) -> ResidentPose? {
        guard let swap = time(of: .swap), let hop = time(of: .residentHop), let back = time(of: .sheetBack) else { return nil }
        if t >= swap, t < hop { return .surprised }
        if t >= hop, t < back { return .happy }
        return nil
    }
}
