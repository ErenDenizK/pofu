import Foundation
import PofuDesignSystem

// The island's tally of today's resists: wax seals pressed on the earth face
// to the right of Pofu's round door (home-layout H1). The new ones stamp in
// one by one (`DoorStamp`); the rest are simply there. At rest the layer is a
// still picture (0 Hz); it only runs while seals are pressing.

/// Today's seals and which of them are new.
public struct ResistSealTally: Equatable, Sendable {
    /// Resists today (what the island shows, capped at `maxShown`).
    public var total: Int
    /// The newest `fresh` seals press in; the rest are already there.
    public var fresh: Int
    /// When the pressing began; `nil` at rest.
    public var start: Date?
    /// Screenshots pin the clock here (seconds since `start`).
    public var pinnedTime: TimeInterval?

    public static let none = ResistSealTally(total: 0)
    /// Seals at rest are a little transparent, like any earth detail.
    public static let restOpacity = 0.85

    public init(total: Int, fresh: Int = 0, start: Date? = nil) {
        self.total = total
        self.fresh = fresh
        self.start = start
    }

    public var shown: Int { min(max(total, 0), DoorStamp.maxSeals) }
    /// The `+N` on the last seal when there are more than the island shows.
    public var overflow: Int { max(total - DoorStamp.maxSeals, 0) }
    private func elapsed(at date: Date) -> TimeInterval {
        pinnedTime ?? date.timeIntervalSince(start ?? date)
    }

    var freshShown: Int { min(max(fresh, 0), shown) }

    /// Whether anything is pressing at `date`.
    public func isAnimating(at date: Date) -> Bool {
        guard start != nil, freshShown > 0, pinnedTime == nil else { return false }
        return elapsed(at: date) < DoorStamp.duration
    }

    /// Seal `index`'s press at `date`, `0...1`; `1` for a seal that is
    /// already there or when nothing is playing. With Reduce Motion a new
    /// seal fades in instead (no press).
    public func press(of index: Int, at date: Date) -> Double {
        guard start != nil, freshShown > 0 else { return 1 }
        let first = shown - freshShown
        guard index >= first else { return 1 }
        let time = elapsed(at: date)
        let stamp = DoorStamp(resists: freshShown)
        return stamp.sealProgress(of: index - first, at: time)
    }

    public func fade(at date: Date) -> Double {
        guard start != nil, freshShown > 0 else { return 1 }
        return DoorStamp(resists: freshShown).fadeProgress(at: elapsed(at: date))
    }

    /// The tiny dust puff of seal `index`, `0...1`, `0` outside its moment.
    public func dust(of index: Int, at date: Date) -> Double {
        guard start != nil, freshShown > 0 else { return 0 }
        let first = shown - freshShown
        guard index >= first else { return 0 }
        let stamp = DoorStamp(resists: freshShown)
        let t = (elapsed(at: date) - stamp.sealStart(of: index - first) - DoorStamp.sealInterval / 2) / 0.35
        return t > 0 && t < 1 ? t : 0
    }
}

/// Where the seals sit on the earth face, in world units from H1.
public enum ResistSealLayout {
    /// Pofu's round door (`home-layout` H1).
    public static let anchor = WorldPoint(x: -107, y: 80)

    /// Slot `index`: a necklace under the round door, a lower half-ellipse
    /// from its left shoulder to its right (lead, 2026-11-06: an arc beside
    /// the door spilled onto Mochi's door). Slot 0 is the left end.
    public static func offset(of index: Int) -> (dx: Double, dy: Double) {
        let slot = min(max(index, 0), DoorStamp.maxSeals - 1)
        let degrees = 200.0 + 20.0 * Double(slot)
        let radians = degrees * .pi / 180
        return (dx: 70 * cos(radians), dy: -40 * sin(radians))
    }

    public static func point(of index: Int) -> WorldPoint {
        let o = offset(of: index)
        return WorldPoint(x: anchor.x + o.dx, y: anchor.y + o.dy)
    }

    /// A seal's side in points: 24 to 28 whatever the camera.
    public static func side(scale: Double) -> Double {
        min(max(28 * scale, 24), 28)
    }
}

#if canImport(SwiftUI)
import SwiftUI

extension EnvironmentValues {
    /// Today's resist seals on the island; none when nothing is wired.
    @Entry public var resistSeals: ResistSealTally = .none
}

/// The layer: screen-space, projected from the world anchor, never takes
/// touches. Drawn inside the world's grade like any earth detail.
struct ResistSealsLayer: View {
    let tally: ResistSealTally
    let pose: CameraPose
    let offset: CGSize
    let size: CGSize
    let night: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let animating = tally.isAnimating(at: Date())
        TimelineView(.animation(paused: !animating)) { context in
            ZStack {
                ForEach(0..<tally.shown, id: \.self) { index in
                    seal(index, at: context.date)
                        .transition(.opacity)
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
        .animation(.easeOut(duration: 0.8), value: tally.total)
        .allowsHitTesting(false)
    }

    private func seal(_ index: Int, at date: Date) -> some View {
        let p = pose.project(ResistSealLayout.point(of: index), width: Double(size.width))
        let centre = CGPoint(x: p.x + Double(offset.width), y: p.y + Double(offset.height))
        let side = CGFloat(ResistSealLayout.side(scale: pose.scale))
        let press = reduceMotion ? tally.fade(at: date) : tally.press(of: index, at: date)
        let eased = reduceMotion ? press : Self.settle(press)
        let dust = reduceMotion ? 0 : tally.dust(of: index, at: date)
        return ZStack {
            ResistWaxSeal(night: night)
                .frame(width: side, height: side)
                .scaleEffect(reduceMotion ? 1 : 1 + 0.5 * (1 - eased))
                .opacity(ResistSealTally.restOpacity * min(press * 4, 1))
            if dust > 0 {
                ForEach(0..<6, id: \.self) { k in
                    let angle = Double(k) / 6 * 2 * .pi
                    Circle()
                        .fill(Color(red: 0.91, green: 0.82, blue: 0.69))
                        .frame(width: 3.5, height: 3.5)
                        .offset(x: cos(angle) * (side * 0.5 + 9 * dust), y: sin(angle) * (side * 0.3 + 6 * dust))
                        .opacity(0.8 * (1 - dust))
                }
            }
            if tally.overflow > 0, index == DoorStamp.maxSeals - 1 {
                Circle()
                    .fill(Color(red: 0.71, green: 0.28, blue: 0.23))
                    .frame(width: side * 0.86, height: side * 0.86)
                    .opacity(press >= 1 ? ResistSealTally.restOpacity : 0)
                Text(verbatim: "+\(tally.overflow)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
                    .opacity(press >= 1 ? 1 : 0)
            }
        }
        .position(centre)
    }

    /// A press that overshoots a little before it rests.
    private static func settle(_ t: Double) -> Double {
        let c = 1.7
        let u = t - 1
        return 1 + (c + 1) * u * u * u + c * u * u
    }
}
#endif
