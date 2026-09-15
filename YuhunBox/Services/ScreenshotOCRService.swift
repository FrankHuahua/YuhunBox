import Foundation
import ImageIO
import Vision

enum ScreenshotOCRError: LocalizedError {
    case invalidImage
    case noText

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "无法读取这张图片。"
        case .noText: return "没有识别到可用的御魂文字，请换一张更清晰的截图。"
        }
    }
}

enum ScreenshotOCRService {
    static func recognize(data: Data) async throws -> [String] {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { throw ScreenshotOCRError.invalidImage }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let lines = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    ?? []
                if lines.isEmpty {
                    continuation.resume(throwing: ScreenshotOCRError.noText)
                } else {
                    continuation.resume(returning: lines)
                }
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "zh-Hant"]
            request.usesLanguageCorrection = true

            do {
                try VNImageRequestHandler(cgImage: image).perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    static func draft(from lines: [String]) -> SoulPiece {
        let joined = lines.joined(separator: " ")
        let set = SoulSet.allCases.first(where: { joined.contains($0.rawValue) }) ?? .broken
        let slot = SoulSlot.allCases.first(where: { joined.contains($0.title) }) ?? .two
        let level = firstInteger(in: joined, pattern: #"\+(\d{1,2})"#).map { min(15, $0) } ?? 0

        let parsedStats = lines.compactMap(parseStatLine)
        let main = parsedStats.first ?? SoulStat(type: defaultMainStat(for: slot), value: 0)
        let subs = Array(parsedStats.dropFirst().prefix(4))
        return SoulPiece(set: set, slot: slot, level: level, mainStat: main, substats: subs, note: "由截图识别，请核对数值")
    }

    private static func parseStatLine(_ line: String) -> SoulStat? {
        let normalized = line
            .replacingOccurrences(of: "％", with: "%")
            .replacingOccurrences(of: "暴击伤害", with: "爆伤")

        let aliases: [(String, StatType)] = [
            ("攻击加成", .attackPercent), ("防御加成", .defensePercent), ("生命加成", .hpPercent),
            ("效果命中", .effectHit), ("效果抵抗", .effectResist), ("爆伤", .critDamage),
            ("暴击", .critRate), ("速度", .speed), ("攻击", .flatAttack),
            ("防御", .flatDefense), ("生命", .flatHP)
        ]
        guard let match = aliases.first(where: { normalized.contains($0.0) }) else { return nil }
        guard let number = firstDouble(in: normalized) else { return nil }

        var type = match.1
        if normalized.contains("%") {
            if type == .flatAttack { type = .attackPercent }
            if type == .flatDefense { type = .defensePercent }
            if type == .flatHP { type = .hpPercent }
        }
        return SoulStat(type: type, value: number)
    }

    private static func firstInteger(in text: String, pattern: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard
            let match = regex.firstMatch(in: text, range: range),
            match.numberOfRanges > 1,
            let capture = Range(match.range(at: 1), in: text)
        else { return nil }
        return Int(text[capture])
    }

    private static func firstDouble(in text: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: #"[-+]?([0-9]+(?:\.[0-9]+)?)"#) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range), let valueRange = Range(match.range(at: 1), in: text) else { return nil }
        return Double(text[valueRange])
    }

    private static func defaultMainStat(for slot: SoulSlot) -> StatType {
        switch slot {
        case .one: return .flatAttack
        case .three: return .flatDefense
        case .five: return .flatHP
        case .two: return .speed
        case .four: return .attackPercent
        case .six: return .critRate
        }
    }
}

