import Foundation

/// Every sound Pofu can make (docs/design/sound-identity.md §2). Callers
/// name a moment; the pitch and the file are decided here, so every tonal
/// sound stays inside the one key (D major pentatonic).
public enum SoundCue: Hashable, Sendable {
    /// A seed pops: `pitchIndex` climbs the pentatonic ladder (D5 up).
    case seedPop(pitchIndex: Int)
    /// A cell blooms: `step` steps up the ladder from D4, as
    /// `PentatonicLadder.midi(step:)`.
    case bloom(step: Int)
    /// A streak rises: `level` 2 and up; higher levels start higher.
    case comboRise(level: Int)
    case piecePickup
    case pieceSnap
    case pieceDrop
    case piecePutBack
    case deal
    /// A seed lands in Pofu's cheeks.
    case cheek
    case roundEnd
    /// Home's collect: Pofu swallows the puff.
    case collect
    case skipChime
    case pofuHop
    case gulp
    /// The Pofu motif, four kalimba notes: an island level rises.
    case levelUp
    /// A resident arrives: two soft knocks.
    case doorKnock
    /// The tea stall's kettle comes to the whistle (morning).
    case kettle
    /// The flow game's wheel catches.
    case waterWheel
    /// Flow: water reaches a mouth.
    case waterSplash
    /// Flow: the last connection, the full pour.
    case waterPour

    /// Which tuned volume the cue follows (`TuningValues.Sound`).
    public enum Group: Sendable { case seeds, pieces, pofu }

    public var group: Group {
        switch self {
        case .seedPop, .bloom, .comboRise: .seeds
        case .piecePickup, .pieceSnap, .pieceDrop, .piecePutBack, .deal: .pieces
        case .cheek, .roundEnd, .collect, .skipChime, .pofuHop, .gulp,
             .levelUp, .doorKnock, .kettle, .waterWheel, .waterSplash, .waterPour: .pofu
        }
    }

    /// The pre-rendered file (without extension) in `Resources/`.
    public var assetName: String {
        switch self {
        case .seedPop(let index): "seed-pop-\(SoundPitch.seedPopIndex(index))"
        case .bloom(let step): "bloom-\(SoundPitch.bloomIndex(step) < 10 ? "0" : "")\(SoundPitch.bloomIndex(step))"
        case .comboRise(let level): "combo-rise-\(SoundPitch.comboIndex(level))"
        case .piecePickup: "piece-pickup"
        case .pieceSnap: "piece-snap"
        case .pieceDrop: "piece-drop"
        case .piecePutBack: "piece-putback"
        case .deal: "deal"
        case .cheek: "cheek"
        case .roundEnd: "round-end"
        case .collect: "collect"
        case .skipChime: "skip-chime"
        case .pofuHop: "pofu-hop"
        case .gulp: "gulp"
        case .levelUp: "level-up"
        case .doorKnock: "door-knock"
        case .kettle: "kettle"
        case .waterWheel: "water-wheel"
        case .waterSplash: "water-splash"
        case .waterPour: "water-pour"
        }
    }

    /// Every file the app bundle must carry.
    public static let allAssetNames: [String] = {
        var names = (0..<SoundPitch.seedPopCount).map { SoundCue.seedPop(pitchIndex: $0).assetName }
        names += (0...SoundPitch.maxBloomStep).map { SoundCue.bloom(step: $0).assetName }
        names += (0..<SoundPitch.comboCount).map { SoundCue.comboRise(level: $0 + 2).assetName }
        let rest: [SoundCue] = [.piecePickup, .pieceSnap, .pieceDrop, .piecePutBack, .deal, .cheek,
                                
                                .roundEnd, .collect, .skipChime, .pofuHop, .gulp, .levelUp, .doorKnock,
                                .kettle, .waterWheel, .waterSplash, .waterPour]
        return names + rest.map(\.assetName)
    }()
}

/// Pentatonic-safe pitch mapping: whatever index a caller passes, the
/// result is a rendered note of D E F# A B.
public enum SoundPitch {
    /// D5 E5 F#5 A5 B5.
    public static let seedPopCount = 5
    /// Two octaves of the ladder from D4: 11 notes, steps 0...10.
    public static let maxBloomStep = 10
    /// Combo levels 2, 3 and 4+.
    public static let comboCount = 3

    public static func seedPopIndex(_ index: Int) -> Int {
        min(max(0, index), seedPopCount - 1)
    }

    public static func bloomIndex(_ step: Int) -> Int {
        min(max(0, step), maxBloomStep)
    }

    public static func comboIndex(_ level: Int) -> Int {
        min(max(2, level), comboCount + 1) - 2
    }

    /// The MIDI note of a ladder step (D4 is step 0).
    public static func midi(step: Int) -> Int {
        let degrees = [62, 64, 66, 69, 71]
        let step = bloomIndex(step)
        return degrees[step % degrees.count] + 12 * (step / degrees.count)
    }

    /// The ladder step of a MIDI note from `PentatonicLadder` (62 is
    /// step 0). Notes off the scale snap down to the nearest scale note.
    public static func bloomStep(midi: Int) -> Int {
        let offsets = [0, 2, 4, 7, 9]
        let offset = max(0, midi - 62)
        let degree = offsets.lastIndex { $0 <= offset % 12 } ?? 0
        return min(offset / 12 * offsets.count + degree, maxBloomStep)
    }
}
