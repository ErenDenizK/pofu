import Foundation
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

    public init(islandLevel: Int, hour: Int, isBedtime: Bool = false) {
        self.islandLevel = islandLevel
        self.hour = hour
        self.isBedtime = isBedtime
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
    public var body: some View {
        if let plate = HomePlate.shipped,
           let name = Self.artName(islandLevel: islandLevel, hour: hour, isBedtime: isBedtime, plate: plate) {
            GeometryReader { proxy in
                let fit = Self.fill(plateWidth: plate.plate.plateSize.width, plateHeight: plate.plate.plateSize.height, in: proxy.size)
                Image(name, bundle: .module)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: fit.image.width, height: fit.image.height)
                    .position(x: proxy.size.width / 2, y: fit.y + fit.image.height / 2)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
            .accessibilityHidden(true)
        }
    }
}
#endif
