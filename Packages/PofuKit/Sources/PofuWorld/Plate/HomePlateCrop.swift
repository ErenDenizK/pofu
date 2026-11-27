import Foundation
import PofuCore
#if canImport(SwiftUI)
import SwiftUI
#endif

/// A crop of the island's own painting, for a sheet's header (the Today
/// card): the Home plate of the hour and island level, scaled to fill its
/// frame and cut to the island's top, where the painting is richest. A live
/// look at the same painting Home shows, never a second drawing of it.
public struct HomePlateCrop {
    public let islandLevel: Int
    public let hour: Int
    public let isBedtime: Bool
    /// The Home stations' levels (`HomePlate.stationLevels`): the looks the player built, drawn over the base.
    public let stationLevels: [StationID: Int]

    public init(islandLevel: Int, hour: Int, isBedtime: Bool = false, stationLevels: [StationID: Int] = [:]) {
        self.islandLevel = islandLevel
        self.hour = hour
        self.isBedtime = isBedtime
        self.stationLevels = stationLevels
    }

    /// The painting's asset name for this hour and level, or `nil` below the
    /// plate's lowest level (or without a shipped plate).
    public static func artName(islandLevel: Int, hour: Int, isBedtime: Bool = false, plate: HomePlate? = HomePlate.shipped) -> String? {
        guard let plate,
              let state = HomePlate.state(
                  in: plate.plate, islandLevel: islandLevel, hour: Double(hour),
                  weather: WeatherConditions(), isBedtime: isBedtime
              )
        else { return nil }
        return plate.plate.plateArt(light: state.light, stage: state.stage)
    }

    /// The box the painting's image covers on the plate (`PlateIsland.plateCrop`: a matted plate ships cropped to
    /// its island), or the whole plate.
    static func imageBox(islandLevel: Int, hour: Int, isBedtime: Bool = false, plate: HomePlate) -> PlateRect {
        guard let state = HomePlate.state(
            in: plate.plate, islandLevel: islandLevel, hour: Double(hour), weather: WeatherConditions(), isBedtime: isBedtime
        ) else { return plate.plate.plateSize }
        return plate.plate.plateCrop(light: state.light, stage: state.stage) ?? plate.plate.plateSize
    }

    /// Where the crop is centred vertically, as a fraction of the plate's height: the island's
    /// upper half, above the water's edge.
    public static let focusY = 0.42

    /// The share of the plate's width cut off each side: the painting fades out over its
    /// outermost ~4.5% on both edges, and a header must never show that feather.
    public static let edgeTrim = 0.05

    /// The image's size when it fills a frame of `size`, and its offset so that `focusY` of the
    /// plate sits at the frame's middle (never past an edge).
    static func fill(plateWidth: Double, plateHeight: Double, in size: CGSize) -> (image: CGSize, y: CGFloat) {
        let k = max(Double(size.width) / max(plateWidth * (1 - 2 * edgeTrim), 1), Double(size.height) / max(plateHeight, 1))
        let image = CGSize(width: plateWidth * k, height: plateHeight * k)
        let wanted = Double(size.height) / 2 - focusY * image.height
        let y = min(0, max(wanted, Double(size.height) - image.height))
        return (image, CGFloat(y))
    }
}

#if canImport(SwiftUI)
extension HomePlateCrop: View {
    /// A look's picture, multiplied by its grade where it is painted in another light.
    @ViewBuilder
    private static func lookImage(_ look: PlateCompositor.Look) -> some View {
        if let grade = look.grade {
            Image(look.art, bundle: .module).resizable().interpolation(.high)
                .colorMultiply(Color(red: grade.red, green: grade.green, blue: grade.blue))
        } else {
            Image(look.art, bundle: .module).resizable().interpolation(.high)
        }
    }

    public var body: some View {
        if let plate = HomePlate.shipped,
           Self.artName(islandLevel: islandLevel, hour: hour, isBedtime: isBedtime, plate: plate) != nil,
           let state = HomePlate.state(
               in: plate.plate, islandLevel: islandLevel, hour: Double(hour), weather: WeatherConditions(), isBedtime: isBedtime
           ) {
            // The drawn base (the plate with its stations erased where the state has one), then the looks of the
            // stations the player built: the same composite Home draws (`PlateCompositor`).
            let drawn = HomePlate(plate: plate.plate, light: state.light, stage: state.stage)
            let compositor = PlateCompositor(plate: drawn, levels: stationLevels)
            let baseName = plate.plate.drawnPlateArt(light: drawn.key, stage: state.stage)
            GeometryReader { proxy in
                let full = plate.plate.plateSize
                let fit = Self.fill(plateWidth: full.width, plateHeight: full.height, in: proxy.size)
                // The image covers `box` of the plate (a matted plate is cropped to its island): placed there.
                let box = Self.imageBox(islandLevel: islandLevel, hour: hour, isBedtime: isBedtime, plate: plate)
                let k = fit.image.width / CGFloat(full.width)
                let left = (proxy.size.width - fit.image.width) / 2
                ZStack(alignment: .topLeading) {
                    Image(baseName, bundle: .module)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: CGFloat(box.width) * k, height: CGFloat(box.height) * k)
                        .offset(x: left + CGFloat(box.minX) * k, y: fit.y + CGFloat(box.minY) * k)
                    ForEach(compositor.looks) { look in
                        let a = drawn.plate(WorldPoint(x: look.box.minX, y: look.box.minY))
                        let b = drawn.plate(WorldPoint(x: look.box.maxX, y: look.box.maxY))
                        Self.lookImage(look)
                            .frame(width: CGFloat(b.x - a.x) * k, height: CGFloat(b.y - a.y) * k)
                            .offset(x: left + CGFloat(a.x) * k, y: fit.y + CGFloat(a.y) * k)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                .clipped()
            }
            .accessibilityHidden(true)
        }
    }
}
#endif
