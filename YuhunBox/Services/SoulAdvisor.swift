import Foundation

enum SoulAdvisor {
    static func evaluate(_ soul: SoulPiece, for goal: BuildGoal) -> SoulScore {
        let mainScore = mainStatScore(soul, goal: goal)
        let subScore = soul.substats.reduce(0.0) { partial, stat in
            partial + normalizedRolls(stat) * weight(for: stat.type, goal: goal)
        }
        let setScore = setAffinity(soul.set, goal: goal)
        let potential = max(0, (15 - soul.level) / 3) * 2
        let rawScore = min(100, Int((mainScore + subScore + setScore).rounded()) + potential)

        let grade: String
        switch rawScore {
        case 86...: grade = "S"
        case 72...: grade = "A"
        case 58...: grade = "B"
        case 42...: grade = "C"
        default: grade = "D"
        }

        let action = upgradeAction(score: rawScore, level: soul.level)
        let strongest = soul.substats
            .sorted { weight(for: $0.type, goal: goal) * normalizedRolls($0) > weight(for: $1.type, goal: goal) * normalizedRolls($1) }
            .first
        let reason = reasonText(mainScore: mainScore, strongest: strongest, goal: goal, potential: potential)

        return SoulScore(soul: soul, goal: goal, score: rawScore, grade: grade, action: action, reason: reason)
    }

    static func ranked(_ souls: [SoulPiece], for goal: BuildGoal) -> [SoulScore] {
        souls.map { evaluate($0, for: goal) }.sorted {
            if $0.score == $1.score { return $0.soul.level < $1.soul.level }
            return $0.score > $1.score
        }
    }

    static func insights(for souls: [SoulPiece]) -> [AccountInsight] {
        guard !souls.isEmpty else {
            return [AccountInsight(kind: .warning, title: "还没有御魂数据", detail: "先手动录入或从截图识别几件御魂，顾问才能判断账号方向。", symbol: "tray")]
        }

        let speedCandidates = souls.filter { $0.value(for: .speed) >= 10 }
        let doubleCrit = souls.filter { piece in
            piece.value(for: .critRate) > 0 && piece.value(for: .critDamage) > 0
        }
        let hitSlotFour = souls.filter { $0.slot == .four && $0.mainStat.type == .effectHit }
        let critDamageSix = souls.filter { $0.slot == .six && $0.mainStat.type == .critDamage }
        let unraised = souls.filter { $0.level < 15 }
        let promising = unraised.filter { piece in
            BuildGoal.allCases.map { evaluate(piece, for: $0).score }.max() ?? 0 >= 65
        }

        var output: [AccountInsight] = []
        if let fastest = souls.max(by: { $0.value(for: .speed) < $1.value(for: .speed) }), fastest.value(for: .speed) > 0 {
            output.append(AccountInsight(
                kind: speedCandidates.count >= 3 ? .strength : .opportunity,
                title: "速度胚子 \(speedCandidates.count) 件",
                detail: "当前副属性速度最高为 +\(Int(fastest.value(for: .speed)))。优先保留二号位速度主属性和四条腿速度胚子。",
                symbol: "hare.fill"
            ))
        }

        output.append(AccountInsight(
            kind: doubleCrit.count >= 4 ? .strength : .opportunity,
            title: "双暴胚子 \(doubleCrit.count) 件",
            detail: doubleCrit.count >= 4 ? "输出御魂储备健康，可以开始按套装和速度精修。" : "双暴底胚偏少，先把带暴击+爆伤的未强化御魂锁定并逐级试强。",
            symbol: "scope"
        ))

        if hitSlotFour.isEmpty {
            output.append(AccountInsight(kind: .warning, title: "缺少四号位命中主属性", detail: "控制式神成型会受限。刷到后即使副属性一般，也建议先留一套功能装。", symbol: "exclamationmark.triangle.fill"))
        }
        if critDamageSix.isEmpty {
            output.append(AccountInsight(kind: .warning, title: "缺少六号位爆伤主属性", detail: "爆伤输出方向暂不宜投入太多资源，先以六号位暴击完成满暴。", symbol: "burst.fill"))
        }
        if !promising.isEmpty {
            output.append(AccountInsight(kind: .opportunity, title: "有 \(promising.count) 件值得继续强化", detail: "它们在至少一个养成方向达到 A/B 高段，建议每次只强化 3 级并重新评估。", symbol: "hammer.fill"))
        }
        return output
    }

    static func summary(for souls: [SoulPiece]) -> String {
        let maxed = souls.filter(\.isMaxLevel).count
        let locked = souls.filter(\.isLocked).count
        return "已录入 \(souls.count) 件，+15 御魂 \(maxed) 件，已锁定 \(locked) 件"
    }

    static func suggestLoadout(from souls: [SoulPiece], for goal: BuildGoal) -> LoadoutSuggestion? {
        let scores = ranked(souls, for: goal)
        guard !scores.isEmpty else { return nil }

        var chosen: [SoulScore] = []
        var dominantSet: SoulSet?

        let fourPieceCandidates: [(set: SoulSet, pieces: [SoulScore], total: Int)] = SoulSet.allCases
            .filter { $0 != .broken }
            .compactMap { set in
                let setScores = scores.filter { $0.soul.set == set }
                let bestBySlot = Dictionary(grouping: setScores, by: { $0.soul.slot })
                    .compactMap { $0.value.max(by: { $0.score < $1.score }) }
                    .sorted { $0.score > $1.score }
                guard bestBySlot.count >= 4 else { return nil }
                let four = Array(bestBySlot.prefix(4))
                return (set, four, four.reduce(0) { $0 + $1.score })
            }

        if let bestSet = fourPieceCandidates.max(by: { $0.total < $1.total }) {
            dominantSet = bestSet.set
            chosen = bestSet.pieces
        }

        let occupiedSlots = Set(chosen.map { $0.soul.slot })
        for slot in SoulSlot.allCases where !occupiedSlots.contains(slot) {
            if let best = scores.first(where: { $0.soul.slot == slot }) {
                chosen.append(best)
            }
        }

        chosen.sort { $0.soul.slot.rawValue < $1.soul.slot.rawValue }
        let average = chosen.isEmpty ? 0 : chosen.reduce(0) { $0 + $1.score } / chosen.count
        let note: String
        if let dominantSet {
            note = "优先组成 \(dominantSet.rawValue) 四件套，其余位置使用当前评分最高的散件。"
        } else {
            note = "库存暂时无法组成合适的四件套，先按各位置最高分做过渡配置。"
        }
        return LoadoutSuggestion(goal: goal, pieces: chosen, dominantSet: dominantSet, averageScore: average, note: note)
    }

    private static func mainStatScore(_ soul: SoulPiece, goal: BuildGoal) -> Double {
        if soul.slot == .one || soul.slot == .three || soul.slot == .five { return 12 }

        switch (soul.slot, goal, soul.mainStat.type) {
        case (.two, .firstSpeed, .speed): return 32
        case (.two, .effectHit, .speed): return 27
        case (.two, .critOutput, .attackPercent), (.two, .critDamage, .attackPercent): return 27
        case (.four, .effectHit, .effectHit): return 32
        case (.four, .survival, .hpPercent), (.four, .survival, .defensePercent): return 27
        case (.four, .critOutput, .attackPercent), (.four, .critDamage, .attackPercent): return 27
        case (.six, .critOutput, .critRate): return 32
        case (.six, .critDamage, .critDamage): return 32
        case (.six, .survival, .hpPercent), (.six, .survival, .defensePercent): return 27
        default: return 8
        }
    }

    private static func weight(for stat: StatType, goal: BuildGoal) -> Double {
        switch goal {
        case .firstSpeed:
            return [.speed: 6.0, .effectResist: 1.8, .hpPercent: 1.3, .defensePercent: 0.8][stat] ?? 0.2
        case .critOutput:
            return [.critRate: 3.8, .critDamage: 2.6, .attackPercent: 2.2, .speed: 1.0][stat] ?? 0.2
        case .critDamage:
            return [.critRate: 4.2, .critDamage: 2.8, .attackPercent: 2.0, .speed: 0.8][stat] ?? 0.2
        case .effectHit:
            return [.effectHit: 3.5, .speed: 3.1, .hpPercent: 1.3, .effectResist: 1.0][stat] ?? 0.2
        case .survival:
            return [.hpPercent: 2.5, .defensePercent: 2.0, .effectResist: 2.2, .speed: 1.8][stat] ?? 0.3
        }
    }

    private static func normalizedRolls(_ stat: SoulStat) -> Double {
        let averageRoll: Double
        switch stat.type {
        case .speed: averageRoll = 2.7
        case .critRate: averageRoll = 2.8
        case .critDamage: averageRoll = 3.8
        case .effectHit, .effectResist: averageRoll = 3.8
        case .attackPercent, .defensePercent, .hpPercent: averageRoll = 2.8
        case .flatAttack: averageRoll = 27
        case .flatDefense: averageRoll = 5
        case .flatHP: averageRoll = 110
        }
        return min(6, stat.value / averageRoll)
    }

    private static func setAffinity(_ set: SoulSet, goal: BuildGoal) -> Double {
        switch goal {
        case .firstSpeed:
            return [.fortuneCat, .azureBasan, .broken].contains(set) ? 8 : 3
        case .critOutput, .critDamage:
            return [.shadow, .watcher, .kyokotsu, .seductress, .seaMoon, .hiddenThought, .netCutter, .soldier].contains(set) ? 8 : 2
        case .effectHit:
            return [.snowSpirit, .temptress, .bellHaunt, .returnSoul].contains(set) ? 8 : 2
        case .survival:
            return [.jizo, .clam, .treeNymph, .soulEdge, .sharedPotential, .pearl].contains(set) ? 8 : 3
        }
    }

    private static func upgradeAction(score: Int, level: Int) -> String {
        if level >= 15 { return score >= 65 ? "成品保留" : "整理候选" }
        let next = min(15, ((level / 3) + 1) * 3)
        switch score {
        case 78...: return "优先强化至 +\(next)"
        case 62...: return "试强至 +\(next)"
        case 48...: return level >= 9 ? "暂缓投入" : "可观察一轮"
        default: return "不建议继续强化"
        }
    }

    private static func reasonText(mainScore: Double, strongest: SoulStat?, goal: BuildGoal, potential: Int) -> String {
        var fragments: [String] = []
        fragments.append(mainScore >= 27 ? "主属性契合" : "主属性一般")
        if let strongest, weight(for: strongest.type, goal: goal) >= 1.8 {
            fragments.append("\(strongest.type.shortTitle) \(strongest.type.formatted(strongest.value)) 是主要价值")
        }
        if potential >= 6 { fragments.append("仍有较多强化空间") }
        return fragments.joined(separator: "，") + "。"
    }
}

