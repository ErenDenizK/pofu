import Foundation

/// The far picture (WP10; world presentation v2 §6.2): Home's island on the Map and in a flight is a snapshot of the
/// mid composite (`PlateCompositor`: base and looks), rendered once at half size whenever the state changes and cached
/// by `PlateCompositor.snapshotKey`. It is by construction the same picture as mid, the player's own station looks
/// included, so the island never swaps between two paintings as the camera rises; only the Home sky fades toward the
/// Map. A state that is not matted to its island (night 8 and 9) keeps its Map cut (`PlateIsland.mapIslandArt`).
public enum FarSnapshot {
    /// The snapshot's pixels per plate pixel: half the composite's (the base ships 2 texture px per plate px).
    public static let pixelsPerPlatePixel = 1.0
    /// How many states the cache keeps: the one on screen and the one fading in (each up to 1020 x 806 px RGBA, 3.3 MB).
    public static let capacity = 2

    /// The last render's wall time, in milliseconds, and how many renders ran (the frame budget on the Map).
    @MainActor public static var lastRenderMilliseconds: Double?
    @MainActor public static var renders = 0
}

#if os(iOS)
import PofuCore
import SwiftUI
import UIKit

/// The far pictures rendered so far, by state.
@MainActor
final class FarSnapshotCache {
    static let shared = FarSnapshotCache()

    private var images: [PlateCompositor.SnapshotKey: UIImage] = [:]
    private var order: [PlateCompositor.SnapshotKey] = []

    func image(_ key: PlateCompositor.SnapshotKey) -> UIImage? {
        images[key]
    }

    /// The state's far picture, rendered now if it is not cached; `nil` for a state that is not matted.
    @discardableResult
    func render(_ compositor: PlateCompositor) -> UIImage? {
        let key = compositor.snapshotKey
        if let image = images[key] { return image }
        let plate = compositor.plate
        guard let crop = plate.plate.plateCrop(light: plate.light, stage: plate.stage) else { return nil }
        let start = CFAbsoluteTimeGetCurrent()
        let renderer = ImageRenderer(content: FarComposite(compositor: compositor, crop: crop))
        renderer.scale = FarSnapshot.pixelsPerPlatePixel
        renderer.isOpaque = false
        guard let image = renderer.uiImage else { return nil }
        FarSnapshot.lastRenderMilliseconds = (CFAbsoluteTimeGetCurrent() - start) * 1000
        FarSnapshot.renders += 1
        images[key] = image
        order.removeAll { $0 == key }
        order.append(key)
        while order.count > FarSnapshot.capacity {
            images[order.removeFirst()] = nil
        }
        return image
    }
}

/// The composite in plate pixels over the plate's crop: the base, then the looks back to front.
private struct FarComposite: View {
    let compositor: PlateCompositor
    let crop: PlateRect

    var body: some View {
        let plate = compositor.plate
        ZStack(alignment: .topLeading) {
            Image(plate.plate.drawnPlateArt(light: plate.light, stage: plate.stage), bundle: .module)
                .resizable().interpolation(.high)
                .frame(width: crop.width, height: crop.height)
            ForEach(compositor.looks) { look in
                let a = plate.plate(WorldPoint(x: look.box.minX, y: look.box.minY))
                let b = plate.plate(WorldPoint(x: look.box.maxX, y: look.box.maxY))
                Image(look.art, bundle: .module).resizable().interpolation(.high)
                    .frame(width: b.x - a.x, height: b.y - a.y)
                    .offset(x: a.x - crop.minX, y: a.y - crop.minY)
            }
        }
        .frame(width: crop.width, height: crop.height, alignment: .topLeading)
    }
}

/// Home's island toward the Map: the far picture over the plate's crop box, or the live composite while the picture
/// is not rendered yet (the same pixels, at more cost).
struct FarPicture: View {
    let compositor: PlateCompositor
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize

    @State private var shot: Shot?

    private struct Shot: Equatable {
        var key: PlateCompositor.SnapshotKey
        var image: UIImage
    }

    var body: some View {
        let key = compositor.snapshotKey
        ZStack(alignment: .topLeading) {
            if let shot, shot.key == key {
                let box = compositor.plate.plateImageBox
                let s = pose.scale
                let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: Double(size.width))
                let w = box.width * s, h = box.height * s
                Image(uiImage: shot.image).resizable().interpolation(.high)
                    .frame(width: CGFloat(w), height: CGFloat(h))
                    .position(x: CGFloat(a.x + w / 2) + offset.width, y: CGFloat(a.y + h / 2) + offset.height)
            } else {
                CompositeIsland(compositor: compositor, build: nil, pose: pose, size: size, offset: offset)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .task(id: key) {
            if let image = FarSnapshotCache.shared.render(compositor) {
                shot = Shot(key: key, image: image)
            }
        }
    }
}

/// The live composite: the base, then every station on it back to front (`PlateLookPiece`).
struct CompositeIsland: View {
    let compositor: PlateCompositor
    let build: BuildFrame?
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize
    /// The water's moment (WP13), or `nil`: the plate's water stays as painted.
    var water: WaterFrame?

    var body: some View {
        let plate = compositor.plate
        ZStack(alignment: .topLeading) {
            PlateImage(name: plate.plate.drawnPlateArt(light: plate.light, stage: plate.stage), box: plate.plateImageBox, pose: pose, size: size, offset: offset)
            if let water, WorldShaders.isAvailable {
                ForEach(PlateRegionEffects.water(of: plate), id: \.id) { region in
                    PlateWaterPatch(plate: plate, water: region, frame: water, pose: pose, size: size, offset: offset)
                }
            }
            ForEach(compositor.stationsBackToFront, id: \.self) { station in
                PlateLookPiece(compositor: compositor, station: station, build: build, pose: pose, size: size, offset: offset)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }
}
#endif
