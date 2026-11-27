import Foundation

/// The texture budget of rule v1 (`docs/design/texture-budget-v1.md`, ADR-0031): the texture pixels one Home
/// state may hold. Each pixel decodes to 4 bytes (8-bit RGBA, what HEIC and PNG decode to). The tools read the
/// same `texture-budget.json`, so the limit lives in one place.
public enum TextureBudget {
    /// What a decoded texture pixel weighs.
    public static let bytesPerPixel = 4

    /// Texture pixels a state may hold; 12,000,000 when the file is missing.
    public static let statePixels: Int = {
        guard
            let url = Bundle.module.url(forResource: "texture-budget", withExtension: "json")
                ?? Bundle.module.url(forResource: "texture-budget", withExtension: "json", subdirectory: "Plates"),
            let data = try? Data(contentsOf: url),
            let file = try? JSONDecoder().decode(File.self, from: data)
        else { return 12_000_000 }
        return file.statePixels
    }()

    private struct File: Decodable { var statePixels: Int }
}
