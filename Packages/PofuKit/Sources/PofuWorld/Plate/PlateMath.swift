import Foundation
import PofuDesignSystem

/// The pure math of plate-first islands (docs/design/plate-islands.md §1.1):
/// taps on polygons, draw order behind occluders, the character light read
/// from the plate's light map, and the contact pad's tone.
public enum PlateMath {
    /// Even-odd point in polygon.
    public static func contains(_ polygon: [PlatePoint], _ p: PlatePoint) -> Bool {
        guard polygon.count >= 3 else { return false }
        var inside = false
        var j = polygon.count - 1
        for i in 0..<polygon.count {
            let a = polygon[i], b = polygon[j]
            if (a.y > p.y) != (b.y > p.y) {
                let x = a.x + (p.y - a.y) / (b.y - a.y) * (b.x - a.x)
                if p.x < x {
                    inside.toggle()
                }
            }
            j = i
        }
        return inside
    }

    /// The tap object under `p`: of those containing it, the nearest (the
    /// largest foot y) wins.
    public static func hit(_ island: PlateIsland, at p: PlatePoint, light: String = "day", stage: Int = 0) -> PlateIsland.Object? {
        island.objects
            .filter { $0.tap && $0.isPresent(light: light, stage: stage) && contains($0.polygon, p) }
            .max { $0.footY < $1.footY }
    }

    /// A polygon's bounding box.
    public static func bounds(_ polygon: [PlatePoint]) -> PlateRect {
        let xs = polygon.map(\.x), ys = polygon.map(\.y)
        return PlateRect(minX: xs.min() ?? 0, minY: ys.min() ?? 0, maxX: xs.max() ?? 0, maxY: ys.max() ?? 0)
    }

    /// The occluders drawn over a character: those it stands behind (its
    /// feet above their foot line) and overlaps.
    public static func occluders(over character: (footY: Double, box: PlateRect), in island: PlateIsland, light: String = "day", stage: Int = 0) -> [PlateIsland.Object] {
        island.objects.filter { object in
            guard object.occluder, object.isPresent(light: light, stage: stage) else { return false }
            let box = object.box ?? bounds(object.polygon)
            return character.footY < object.footY && box.overlaps(character.box)
        }
    }

    // MARK: Light

    /// The light-map colour at `p`, bilinear between cell centres.
    public static func light(at p: PlatePoint, map: [[String]], plateSize: PlateRect) -> PofuRGB {
        let rows = map.count
        let cols = map.first?.count ?? 0
        guard rows > 0, cols > 0, plateSize.width > 0, plateSize.height > 0 else { return PofuRGB(red: 1, green: 1, blue: 1) }
        let fx = min(max(p.x / plateSize.width * Double(cols) - 0.5, 0), Double(cols - 1))
        let fy = min(max(p.y / plateSize.height * Double(rows) - 0.5, 0), Double(rows - 1))
        let x0 = Int(fx), y0 = Int(fy)
        let x1 = min(x0 + 1, cols - 1), y1 = min(y0 + 1, rows - 1)
        let tx = fx - Double(x0), ty = fy - Double(y0)
        func c(_ r: Int, _ q: Int) -> PofuRGB { rgb(map[r][q]) }
        let top = c(y0, x0).mixed(with: c(y0, x1), amount: tx)
        let bottom = c(y1, x0).mixed(with: c(y1, x1), amount: tx)
        return top.mixed(with: bottom, amount: ty)
    }

    /// A `#rrggbb` colour; white when it does not parse.
    public static func rgb(_ hex: String) -> PofuRGB {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return PofuRGB(red: 1, green: 1, blue: 1) }
        return PofuRGB(hex: value)
    }

    static func linear(_ c: Double) -> Double {
        c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    static func luminance(_ c: PofuRGB) -> Double {
        0.2126 * linear(c.red) + 0.7152 * linear(c.green) + 0.0722 * linear(c.blue)
    }

    /// A character's gain from the plate's light where it stands: the
    /// lit grass's luminance against the island's open lawn (`reference`),
    /// grey (the lawn's green is its paint, not its light). The plate is
    /// final by day, so anywhere within 80 % of the open lawn's light the
    /// character keeps its paint (1); deeper in a lee it darkens, to 0.78.
    public static func characterGain(light: PofuRGB, reference: PofuRGB) -> Double {
        let r = luminance(reference)
        guard r > 1e-6 else { return 1 }
        let ratio = luminance(light) / r
        return ratio >= 0.8 ? 1 : max(sqrt(ratio / 0.8), 0.78)
    }

    /// The contact pad's multiply colour: the plate's own shadow tone over
    /// its lit tone, per channel in linear light, clamped 0.15...1 and
    /// returned in sRGB (as `pilot.contact_pad`). `depth` scales the shadow's linear light first:
    /// 1 is the lawn's own shadow, less is a deeper one in the same hue (the occlusion core under
    /// a character).
    public static func contactRatio(lit: PofuRGB, shadow: PofuRGB, depth: Double = 1) -> PofuRGB {
        func ratio(_ s: Double, _ l: Double) -> Double {
            let r = min(max(linear(s) * depth / max(linear(l), 1e-4), 0.15), 1)
            if r >= 1 { return 1 }
            return r <= 0.0031308 ? r * 12.92 : 1.055 * pow(r, 1 / 2.4) - 0.055
        }
        return PofuRGB(red: ratio(shadow.red, lit.red), green: ratio(shadow.green, lit.green), blue: ratio(shadow.blue, lit.blue))
    }

    /// The scale that makes an island `widths` screen widths wide.
    public static func framing(islandWidthUnits: Double, widths: Double, screenWidthPoints: Double) -> Double {
        islandWidthUnits > 0 ? widths * screenWidthPoints / islandWidthUnits : 1
    }

    /// The island's textures fit the 9 MB budget (ASTC, one byte a pixel). It was 8 MB for the
    /// original take; the plate upscaled x2 alone is 6.3 MB (8.27 MB with the rest) (`tools/plate/ingest.py`).
    public static func budgetOK(_ island: PlateIsland) -> Bool {
        island.textureBytes <= 9_000_000
    }

    /// A sky-set state's textures (the set, the island cut for the Map, the occluders) fit the same
    /// budget: while a sky set draws, the plate and its backdrop are not loaded.
    public static func budgetOK(_ sky: SkySet) -> Bool {
        sky.textureBytes <= 9_000_000
    }
}
