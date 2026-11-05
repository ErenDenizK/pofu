/// A resident's pose: edits of the base art on its own canvas, so they swap in place (batches 03, 20
/// and 29). A pose a resident has no art for falls back to the base (`Resident.art(for:)`).
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
}

extension IslandLayout.Resident {
    /// The baked sprite for `pose`: `mochi-work`, `findik-eyes-closed`; the base art where the resident
    /// has none.
    public func art(for pose: ResidentPose) -> String {
        guard pose != .rest else { return art }
        let name = "\(art)-\(pose.rawValue)"
        return WorldArt.sprite(name) == nil ? art : name
    }

    /// The pose a resident wears when nothing is happening to them: asleep at bedtime, at work while the
    /// camera is on them or their station, else the base.
    public func idlePose(isBedtime: Bool, isFocused: Bool) -> ResidentPose {
        if isBedtime { return .eyesClosed }
        return isFocused ? .work : .rest
    }
}

extension BuildMoment {
    /// The station's resident during a build: startled as the new art pops in, then beaming through
    /// their hop. `nil` before the pop, after the hop and with Reduce Motion (no hop, no start).
    public func residentPose(at t: Double) -> ResidentPose? {
        guard let swap = time(of: .swap), let hop = time(of: .residentHop), let back = time(of: .sheetBack) else { return nil }
        if t >= swap, t < hop { return .surprised }
        if t >= hop, t < back { return .eyesHappy }
        return nil
    }
}
