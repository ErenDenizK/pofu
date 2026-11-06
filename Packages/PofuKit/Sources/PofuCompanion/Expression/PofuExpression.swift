import Foundation

/// How Pofu feels on his face. A small, fixed vocabulary: each mood is a
/// handful of rig parts laid over the base art (`PofuExpression.parts(for:)`).
///
/// ADR-0017: Pofu never suffers at a lock, so there is no sad or guilty
/// mood. `worried` is a small, gentle frown for a quiet world; it never
/// droops the ears or tears up.
public enum PofuMood: String, CaseIterable, Hashable, Sendable {
    case calm
    case happy
    case sleepy
    case proud
    case curious
    case worried
    case relieved
}

/// A cut of the approved rig masters (`design/art/masters/pofu-*`) as a
/// small image, made by `tools/art/pofu_rig_patches.py`.
public enum PofuFacePart: String, CaseIterable, Hashable, Sendable {
    case mouthSmirk = "mouth-smirk"
    case mouthOpen = "mouth-open"
    case mouthO = "mouth-o"
    case mouthWorried = "mouth-worried"
    case earsDroop = "ears-droop"
    case pawsWave = "paws-wave"

    /// The bundled PNG's name.
    public var resourceName: String { "pofu-part-\(rawValue)" }

    /// Where the patch sits on the art, as fractions of the base art's
    /// size (x right, y down), measured by the cutting script. A patch may
    /// reach outside the art (ears above the head).
    public var placement: PofuFacePlacement {
        switch self {
        case .mouthSmirk, .mouthOpen, .mouthO, .mouthWorried:
            PofuFacePlacement(x: 0.4360, y: 0.4500, width: 0.1724, height: 0.1431)
        case .earsDroop:
            PofuFacePlacement(x: -0.0002, y: -0.0732, width: 1.0192, height: 0.3871)
        case .pawsWave:
            PofuFacePlacement(x: -0.0132, y: 0.4806, width: 0.5038, height: 0.3407)
        }
    }

    /// Parts that replace one another: a face has one mouth.
    public var isMouth: Bool {
        switch self {
        case .mouthSmirk, .mouthOpen, .mouthO, .mouthWorried: true
        default: false
        }
    }
}

public struct PofuFacePlacement: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
}

/// The mood-to-face rules, pure so they are tested on any platform.
public enum PofuExpression {
    /// The parts that make up `mood`, bottom to top.
    public static func parts(for mood: PofuMood) -> [PofuFacePart] {
        switch mood {
        case .calm: []
        case .happy: [.mouthOpen, .pawsWave]
        case .sleepy: [.earsDroop]
        case .proud: [.mouthSmirk]
        case .curious: [.mouthO]
        case .worried: [.mouthWorried]
        case .relieved: [.earsDroop, .mouthSmirk]
        }
    }

    /// The least the upper lids close at rest in `mood`: drowsy eyes for
    /// sleepy, soft for relieved. Blinks still go over this.
    public static func restingLidClosure(for mood: PofuMood) -> Double {
        switch mood {
        case .sleepy: 0.42
        case .relieved: 0.16
        default: 0
        }
    }

    /// The face's opacity for `part` at `mood` change: the parts of the
    /// mood fade in, the others out (the view animates it).
    public static func opacity(of part: PofuFacePart, in mood: PofuMood) -> Double {
        parts(for: mood).contains(part) ? 1 : 0
    }

    /// Whether `parts` is a face that can be drawn: one mouth at most, no repeats.
    public static func isValid(_ parts: [PofuFacePart]) -> Bool {
        parts.filter(\.isMouth).count <= 1 && Set(parts).count == parts.count
    }
}

extension CompanionPose {
    /// The pose with the upper lids closed at least `floor`.
    func withLidFloor(_ floor: Double) -> CompanionPose {
        var copy = self
        copy.lidClosure = max(lidClosure, floor)
        return copy
    }
}
