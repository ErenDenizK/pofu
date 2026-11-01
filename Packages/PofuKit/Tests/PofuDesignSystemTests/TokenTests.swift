import Foundation
import Testing
import PofuDesignSystem

/// Guards the hand-ported Swift tokens against the design source of truth,
/// `design/tokens/pofu-tokens.json`.
@Suite("Design tokens")
struct TokenTests {
    struct TokenFile: Decodable {
        struct Mode: Decodable {
            var light: String
            var dark: String
        }

        var primitives: [String: String]
        var semantic: [String: Mode]
    }

    static func loadTokens() throws -> TokenFile {
        // Tests/PofuDesignSystemTests/TokenTests.swift → repository root.
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = root.appendingPathComponent("design/tokens/pofu-tokens.json")
        return try JSONDecoder().decode(TokenFile.self, from: Data(contentsOf: url))
    }

    static func hex(_ string: String) -> UInt32? {
        UInt32(string.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16)
    }

    @Test func everyPrimitiveMatchesTheTokenFile() throws {
        let tokens = try Self.loadTokens()
        #expect(Set(PofuPrimitive.allCases.map(\.rawValue)) == Set(tokens.primitives.keys))
        for primitive in PofuPrimitive.allCases {
            let expected = try #require(tokens.primitives[primitive.rawValue].flatMap(Self.hex))
            #expect(primitive.hex == expected, "\(primitive.rawValue)")
        }
    }

    @Test func everySemanticTokenMatchesTheTokenFile() throws {
        let tokens = try Self.loadTokens()
        #expect(Set(PofuSemanticColor.allCases.map(\.rawValue)) == Set(tokens.semantic.keys))
        for token in PofuSemanticColor.allCases {
            let mode = try #require(tokens.semantic[token.rawValue])
            #expect(token.light.rawValue == mode.light, "\(token.rawValue) light")
            #expect(token.dark.rawValue == mode.dark, "\(token.rawValue) dark")
        }
    }

    @Test func hexComponentsDecodeExactly() {
        let violet = PofuRGB(hex: 0x6C4FD8)
        #expect(violet.red == Double(0x6C) / 255)
        #expect(violet.green == Double(0x4F) / 255)
        #expect(violet.blue == Double(0xD8) / 255)
        #expect(violet.mixed(with: violet, amount: 0.5) == violet)
    }
}
