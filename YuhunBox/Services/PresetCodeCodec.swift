import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import UIKit

enum PresetCodeError: LocalizedError {
    case unsupportedFormat
    case corrupted

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat: return "这不是御魂匣支持的预设码。"
        case .corrupted: return "预设码内容不完整或已经损坏。"
        }
    }
}

enum PresetCodeCodec {
    private static let prefix = "YHX1:"

    static func encode(_ team: TeamPreset) throws -> String {
        let envelope = PresetEnvelope(version: 1, team: team)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(envelope)
        return prefix + base64URL(data)
    }

    static func decode(_ value: String) throws -> TeamPreset {
        let compact = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard compact.hasPrefix(prefix) else { throw PresetCodeError.unsupportedFormat }
        let encoded = String(compact.dropFirst(prefix.count))
        guard let data = dataFromBase64URL(encoded) else { throw PresetCodeError.corrupted }
        do {
            let envelope = try JSONDecoder.appDecoder.decode(PresetEnvelope.self, from: data)
            guard envelope.version == 1 else { throw PresetCodeError.unsupportedFormat }
            return envelope.team
        } catch let error as PresetCodeError {
            throw error
        } catch {
            throw PresetCodeError.corrupted
        }
    }

    static func qrImage(for text: String, scale: CGFloat = 9) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }

        let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func dataFromBase64URL(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - base64.count % 4) % 4
        base64 += String(repeating: "=", count: padding)
        return Data(base64Encoded: base64)
    }
}

private struct PresetEnvelope: Codable {
    let version: Int
    let team: TeamPreset
}

