import Foundation
import SwiftUI

enum SoulSlot: Int, CaseIterable, Codable, Identifiable {
    case one = 1, two, three, four, five, six

    var id: Int { rawValue }
    var title: String { "\(rawValue)号位" }
}

enum StatType: String, CaseIterable, Codable, Identifiable {
    case attackPercent
    case defensePercent
    case hpPercent
    case speed
    case critRate
    case critDamage
    case effectHit
    case effectResist
    case flatAttack
    case flatDefense
    case flatHP

    var id: String { rawValue }

    var title: String {
        switch self {
        case .attackPercent: return "攻击加成"
        case .defensePercent: return "防御加成"
        case .hpPercent: return "生命加成"
        case .speed: return "速度"
        case .critRate: return "暴击"
        case .critDamage: return "暴击伤害"
        case .effectHit: return "效果命中"
        case .effectResist: return "效果抵抗"
        case .flatAttack: return "攻击"
        case .flatDefense: return "防御"
        case .flatHP: return "生命"
        }
    }

    var isPercent: Bool {
        switch self {
        case .attackPercent, .defensePercent, .hpPercent, .critRate, .critDamage, .effectHit, .effectResist:
            return true
        default:
            return false
        }
    }

    var shortTitle: String {
        switch self {
        case .attackPercent: return "攻加"
        case .defensePercent: return "防加"
        case .hpPercent: return "生加"
        case .critRate: return "暴击"
        case .critDamage: return "爆伤"
        case .effectHit: return "命中"
        case .effectResist: return "抵抗"
        default: return title
        }
    }

    func formatted(_ value: Double) -> String {
        isPercent ? String(format: "%.1f%%", value) : String(format: value.rounded() == value ? "%.0f" : "%.1f", value)
    }
}

enum SoulSet: String, CaseIterable, Codable, Identifiable {
    case broken = "散件"
    case fortuneCat = "招财猫"
    case azureBasan = "火灵"
    case shadow = "破势"
    case kyokotsu = "狂骨"
    case seductress = "针女"
    case watcher = "心眼"
    case seaMoon = "海月火玉"
    case hiddenThought = "隐念"
    case soulTaker = "伤魂鸟"
    case tombGuard = "镇墓兽"
    case snowSpirit = "雪幽魂"
    case temptress = "魅妖"
    case bellHaunt = "钟灵"
    case returnSoul = "返魂香"
    case treeNymph = "木魅"
    case soulEdge = "薙魂"
    case mirrorLady = "镜姬"
    case jizo = "地藏像"
    case pearl = "珍珠"
    case clam = "蚌精"
    case sharedPotential = "共潜"
    case paintedBuddha = "涂佛"
    case memoryFire = "遗念火"
    case aonyobo = "青女房"
    case sunMaiden = "日女巳时"
    case treeSpirit = "树妖"
    case netCutter = "网切"
    case soldier = "兵主部"
    case yinMorra = "阴摩罗"

    var id: String { rawValue }

    var bonus: String {
        switch self {
        case .fortuneCat, .azureBasan, .memoryFire: return "供火 / 节奏"
        case .shadow, .watcher, .kyokotsu, .seductress, .seaMoon, .hiddenThought, .netCutter, .soldier: return "输出"
        case .snowSpirit, .temptress, .bellHaunt, .returnSoul: return "控制"
        case .treeNymph, .soulEdge, .mirrorLady, .jizo, .clam, .sharedPotential, .aonyobo: return "生存 / 对策"
        case .pearl, .treeSpirit: return "治疗 / 护盾"
        case .paintedBuddha: return "增益"
        case .soulTaker, .tombGuard, .yinMorra: return "特殊输出"
        case .sunMaiden: return "推条"
        case .broken: return "自由搭配"
        }
    }

    var tint: Color {
        let palette: [Color] = [.saffron, .crimson, .teal, .indigo, .purple, .orange]
        let index = SoulSet.allCases.firstIndex(of: self) ?? 0
        return palette[index % palette.count]
    }
}

struct SoulStat: Codable, Hashable, Identifiable {
    var id = UUID()
    var type: StatType
    var value: Double
}

struct SoulPiece: Codable, Hashable, Identifiable {
    var id = UUID()
    var set: SoulSet
    var slot: SoulSlot
    var level: Int
    var mainStat: SoulStat
    var substats: [SoulStat]
    var isLocked = false
    var note = ""
    var createdAt = Date()

    var displayName: String { "\(set.rawValue) · \(slot.title)" }
    var isMaxLevel: Bool { level >= 15 }

    func value(for type: StatType) -> Double {
        substats.first(where: { $0.type == type })?.value ?? 0
    }
}

enum BuildGoal: String, CaseIterable, Codable, Identifiable {
    case firstSpeed
    case critOutput
    case critDamage
    case effectHit
    case survival

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstSpeed: return "一速拉条"
        case .critOutput: return "满暴输出"
        case .critDamage: return "爆伤输出"
        case .effectHit: return "命中控制"
        case .survival: return "生存辅助"
        }
    }

    var subtitle: String {
        switch self {
        case .firstSpeed: return "速度优先，兼顾抵抗与生命"
        case .critOutput: return "暴击、爆伤与攻击加成"
        case .critDamage: return "六号位爆伤，高暴击副属性"
        case .effectHit: return "四号位命中，速度与生命"
        case .survival: return "生命、防御、抵抗与速度"
        }
    }

    var symbol: String {
        switch self {
        case .firstSpeed: return "hare.fill"
        case .critOutput: return "scope"
        case .critDamage: return "burst.fill"
        case .effectHit: return "sparkles"
        case .survival: return "shield.fill"
        }
    }
}

struct TeamMember: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var role: String
    var goal: BuildGoal
    var soulPlan: String
    var speedTarget: Int?
    var requirements: MemberRequirements? = nil
}

struct MemberRequirements: Codable, Hashable {
    var primarySet: SoulSet? = nil
    var secondarySet: SoulSet? = nil
    var slot2Main: StatType? = nil
    var slot4Main: StatType? = nil
    var slot6Main: StatType? = nil
    var speedMin: Int? = nil
    var attackMin: Int? = nil
    var hpMin: Int? = nil
    var defenseMin: Int? = nil
    var critRateMin: Double? = nil
    var critDamageMin: Double? = nil
    var effectHitMin: Double? = nil
    var effectResistMin: Double? = nil
    var notes = ""

    var summary: [String] {
        var values: [String] = []
        if let primarySet { values.append(primarySet.rawValue) }
        if let secondarySet { values.append(secondarySet.rawValue) }
        let mains = [slot2Main, slot4Main, slot6Main]
            .map { $0?.shortTitle ?? "不限" }
            .joined(separator: " / ")
        if slot2Main != nil || slot4Main != nil || slot6Main != nil {
            values.append("主属性 \(mains)")
        }
        if let speedMin { values.append("速度≥\(speedMin)") }
        if let attackMin { values.append("攻击≥\(attackMin)") }
        if let hpMin { values.append("生命≥\(hpMin)") }
        if let defenseMin { values.append("防御≥\(defenseMin)") }
        if let critRateMin { values.append("暴击≥\(critRateMin.formattedPercent)") }
        if let critDamageMin { values.append("爆伤≥\(critDamageMin.formattedPercent)") }
        if let effectHitMin { values.append("命中≥\(effectHitMin.formattedPercent)") }
        if let effectResistMin { values.append("抵抗≥\(effectResistMin.formattedPercent)") }
        if !notes.isEmpty { values.append(notes) }
        return values
    }
}

struct TeamPreset: Codable, Hashable, Identifiable {
    var id = UUID()
    var title: String
    var scene: String
    var members: [TeamMember]
    var officialCode = ""
    var notes = ""
    var updatedAt = Date()
}

struct UserPreferences: Codable, Hashable {
    var primaryGoal: BuildGoal = .firstSpeed
    var accountStage = "养成中期"
}

struct SoulScore: Identifiable, Hashable {
    let id = UUID()
    let soul: SoulPiece
    let goal: BuildGoal
    let score: Int
    let grade: String
    let action: String
    let reason: String
}

struct AccountInsight: Identifiable, Hashable {
    enum Kind: String, Hashable {
        case strength, opportunity, warning
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let detail: String
    let symbol: String
}

struct LoadoutSuggestion: Identifiable, Hashable {
    let id = UUID()
    let goal: BuildGoal
    let pieces: [SoulScore]
    let dominantSet: SoulSet?
    let averageScore: Int
    let note: String
}

extension Color {
    static let crimson = AppTheme.pink
    static let saffron = AppTheme.cyan
    static let ink = Color(red: 0.018, green: 0.022, blue: 0.035)
}

private extension Double {
    var formattedPercent: String {
        String(format: rounded() == self ? "%.0f%%" : "%.1f%%", self)
    }
}

