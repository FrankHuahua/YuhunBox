import SwiftUI

enum ShikigamiRarity: String, CaseIterable, Identifiable {
    case all = "全部"
    case ur = "UR"
    case sp = "SP"
    case ssr = "SSR"
    case sr = "SR"
    case r = "R"
    case n = "N"
    case linked = "联动"

    var id: String { rawValue }

    var tint: Color {
        switch self {
        case .all: return .secondary
        case .ur: return .red
        case .sp: return .purple
        case .ssr: return .orange
        case .sr: return .blue
        case .r: return .green
        case .n: return .secondary
        case .linked: return .pink
        }
    }
}

struct ShikigamiSkillInfo: Hashable {
    let name: String
    let cost: String
    let summary: String
}

struct ShikigamiRecord: Identifiable, Hashable {
    var id: String { "\(rarity.rawValue)-\(name)" }
    let name: String
    let rarity: ShikigamiRarity
    var release: String = ""
    var roles: [String] = []
    var attack = "—"
    var hp = "—"
    var defense = "—"
    var speed = "—"
    var crit = "—"
    var skills: [ShikigamiSkillInfo] = []
    var verified = false

    var sourceURL: URL? {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        return URL(string: "https://wiki.biligame.com/yys/\(encoded)")
    }
}

struct ShikigamiCatalogView: View {
    @State private var query = ""
    @State private var rarity: ShikigamiRarity = .all

    private var filtered: [ShikigamiRecord] {
        ShikigamiCatalog.records.filter { item in
            let matchesRarity = rarity == .all || item.rarity == rarity
            let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesQuery = keyword.isEmpty
                || item.name.localizedCaseInsensitiveContains(keyword)
                || item.roles.contains(where: { $0.localizedCaseInsensitiveContains(keyword) })
                || (keyword == "SP不知火" && item.name == "不知火")
            return matchesRarity && matchesQuery
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    versionNotice
                    rarityPicker

                    if filtered.isEmpty {
                        EmptyState(symbol: "magnifyingglass", title: "没有找到式神", detail: "试试简称、完整名称或切换稀有度。")
                            .appCard()
                    } else {
                        ForEach(filtered) { item in
                            NavigationLink { ShikigamiDetailView(item: item) } label: {
                                ShikigamiRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(AppTheme.page)
            .navigationTitle("式神图鉴")
            .searchable(text: $query, prompt: "搜索式神或定位")
        }
    }

    private var versionNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("十周年资料集", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                Spacer()
                Text("2026.09")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text("已收录当前可查式神名录；石长姬、百羽凤凰火已加入。当前公开名录没有“SP不知火”，搜索该名称会定位到 SSR 不知火。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCard()
    }

    private var rarityPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ShikigamiRarity.allCases) { value in
                    Button {
                        rarity = value
                    } label: {
                        Text(value.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(rarity == value ? Color.white : Color.secondary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(rarity == value ? value.tint : AppTheme.card, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ShikigamiRow: View {
    let item: ShikigamiRecord

    var body: some View {
        HStack(spacing: 13) {
            Text(String(item.name.prefix(1)))
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(item.rarity.tint.opacity(0.82), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(item.name).font(.headline)
                    Text(item.rarity.rawValue)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(item.rarity.tint)
                }
                Text(item.roles.isEmpty ? (item.verified ? "基础资料" : "名录已收录 · 详细数据待校验") : item.roles.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if item.verified {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).font(.caption)
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .appCard(padding: 13)
    }
}

private struct ShikigamiDetailView: View {
    let item: ShikigamiRecord

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                stats
                skills
                source
            }
            .padding(16)
        }
        .background(AppTheme.page)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Text(String(item.name.prefix(1)))
                .font(.title2.weight(.black))
                .frame(width: 64, height: 64)
                .background(item.rarity.tint.opacity(0.85), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.name).font(.title3.weight(.bold))
                    Text(item.rarity.rawValue).font(.caption.weight(.bold)).foregroundStyle(item.rarity.tint)
                }
                if !item.release.isEmpty { Text("实装：\(item.release)").font(.caption).foregroundStyle(.secondary) }
                if !item.roles.isEmpty { Text(item.roles.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer()
        }
        .appCard()
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "基础属性", detail: item.verified ? "满级觉醒" : "待校验")
            HStack {
                stat("攻击", item.attack)
                stat("生命", item.hp)
                stat("防御", item.defense)
                stat("速度", item.speed)
                stat("暴击", item.crit)
            }
            if !item.verified {
                Text("为避免版本变更造成错误，尚未核验的数值不使用推测数据。可通过下方资料源查看并在后续数据包中更新。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .appCard()
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 5) {
            Text(value).font(.caption.weight(.bold)).minimumScaleFactor(0.7).lineLimit(1)
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var skills: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "技能详情", detail: item.skills.isEmpty ? "待校验" : "简要机制")
            if item.skills.isEmpty {
                Text("该式神已收录进名录，技能机制仍在逐条校验。为了不把旧版本或攻略猜测写进图鉴，本版暂不展示未经核验的技能文本。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(item.skills.enumerated()), id: \.offset) { index, skill in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(index + 1). \(skill.name)").font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(skill.cost).font(.caption).foregroundStyle(.secondary)
                        }
                        Text(skill.summary).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    if index < item.skills.count - 1 { Divider() }
                }
            }
        }
        .appCard()
    }

    @ViewBuilder private var source: some View {
        if let url = item.sourceURL {
            Link(destination: url) {
                Label("查看并核对最新资料", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

enum ShikigamiCatalog {
    static let records: [ShikigamiRecord] = {
        let groups: [(ShikigamiRarity, String)] = [
            (.ur, "妖刀姬·绯夜猎刃"),
            (.sp, "百羽凤凰火、天火命铃彦姬、蚀月吸血姬、灼华桃花妖、瑶音紧那罗、晴思日和坊、时曜泷夜叉姬、云间不见岳、妙主九命猫、梦引蝴蝶精、梦山白藏主、鲸汐千姬、福悦座敷童子、晨晖惠比寿、龙吟铃鹿御前、遥念烟烟罗、心友犬神、神酿星熊童子、流光追月神、修罗鬼童丸、寻森小鹿男、纺愿缘结神、渺念萤草、本真三尾狐、梦寻山兔、神堕八岐大蛇、大夜摩天阎魔、心狩鬼女红叶、神启荒、禅心云外镜、夜溟彼岸花、蝉冰雪女、空相面灵气、绘世花鸟卷、因幡辉夜姬、聆海金鱼姬、浮世青行灯、缚骨清姬、麓铭大岳丸、待宵姑获鸟、初翎山风、稻荷神御馔津、苍风一目连、赤影妖刀姬、御怨般若、骁浪荒川之主、烬天玉藻前、鬼王酒吞童子、天剑韧心鬼切、少羽大天狗、炼狱茨木童子"),
            (.ssr, "石长姬、咲耶、不相狐禅、毗沙门天、思金神、市加美、葛叶、神无月、雪御前、平将门、荒骷髅、卑弥呼、歌留多、泷、猫川、祸津神、龙珏、封阳君、鬼金羊、月读、言灵、孔雀明王、天照、伊邪那美、铃彦姬、不见岳、须佐之男、寻香行、季、帝释天、阿修罗、食灵、饭笥、鬼童丸、缘结神、铃鹿御前、紧那罗、千姬、不知火、大岳丸、泷夜叉姬、云外镜、面灵气、鬼切、白藏主、八岐大蛇、辉夜姬、荒、彼岸花、山风、雪童子、玉藻前、御馔津、大天狗、酒吞童子、荒川之主、阎魔、两面佛、小鹿男、茨木童子、青行灯、妖刀姬、一目连、花鸟卷"),
            (.sr, "湍津姬、桃花妖、雪女、鬼使白、鬼使黑、孟婆、犬神、骨女、鬼女红叶、跳跳哥哥、傀儡师、海坊主、判官、凤凰火、吸血姬、妖狐、妖琴师、食梦貘、清姬、镰鼬、姑获鸟、二口女、白狼、樱花妖、惠比寿、络新妇、般若、青坊主、万年竹、夜叉、黑童子、白童子、烟烟罗、金鱼姬、鸩、以津真天、匣中少女、小松丸、书翁、百目鬼、追月神、日和坊、薰、弈、猫掌柜、人面树、於菊虫、一反木绵、入殓师、化鲸、海忍、久次良、蟹姬、纸舞、星熊童子、风狸、蝎女、入内雀、饴细工、川猿、灵海蝶、迦楼罗、粉婆婆、慧明灯、盗人神、鲛人行"),
            (.r, "三尾狐、座敷童子、鲤鱼精、九命猫、狸猫、河童、童男、童女、饿鬼、巫蛊师、鸦天狗、食发鬼、武士之灵、雨女、跳跳妹妹、兵俑、丑时之女、独眼小僧、铁鼠、椒图、管狐、山兔、萤草、蝴蝶精、山童、首无、觉、青蛙瓷器、古笼火、兔丸、数珠、小袖之手、虫师、天井下、垢尝"),
            (.n, "赤舌、天邪鬼红、天邪鬼绿、天邪鬼黄、天邪鬼青、帚神、涂壁、寄生魂、唐纸伞妖、提灯小僧、灯笼鬼、盗墓小鬼"),
            (.linked, "卖药郎、奴良陆生、鬼灯、阿香、蜜桃芥子、犬夜叉、杀生丸、桔梗、朽木露琪亚、黑崎一护、灶门炭治郎、灶门祢豆子、坂田银时、神乐定春、初音未来、镜音铃连")
        ]

        var values = groups.flatMap { rarity, names in
            names.split(separator: "、").map { ShikigamiRecord(name: String($0), rarity: rarity) }
        }

        let details = verifiedDetails
        values = values.map { details[$0.name] ?? $0 }
        return values.sorted { lhs, rhs in
            if lhs.verified != rhs.verified { return lhs.verified && !rhs.verified }
            if lhs.rarity.rawValue != rhs.rarity.rawValue {
                let order: [ShikigamiRarity] = [.ur, .sp, .ssr, .sr, .r, .n, .linked]
                return (order.firstIndex(of: lhs.rarity) ?? 99) < (order.firstIndex(of: rhs.rarity) ?? 99)
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }()

    private static let verifiedDetails: [String: ShikigamiRecord] = [
        "石长姬": ShikigamiRecord(
            name: "石长姬", rarity: .ssr, release: "2026-09-09", roles: ["还原", "护盾", "群体输出"],
            attack: "S", hp: "S", defense: "S", speed: "120", crit: "S",
            skills: [
                ShikigamiSkillInfo(name: "普攻", cost: "0 火", summary: "对敌方单体进行三段攻击。"),
                ShikigamiSkillInfo(name: "还原", cost: "0 火", summary: "记录开场初始属性，并可令目标回到初始状态；适合处理形态、层数与部分开局效果。"),
                ShikigamiSkillInfo(name: "磐长花", cost: "被动 / 主动", summary: "开场将初始生命凝成四朵磐长花；致命伤害时消耗花恢复生命，并为友方提供基于初始攻击的保护。输出技能造成群体伤害，并对选中目标追加伤害。")
            ], verified: true
        ),
        "百羽凤凰火": ShikigamiRecord(
            name: "百羽凤凰火", rarity: .sp, release: "2026-09", roles: ["复活", "印记", "群体输出"],
            skills: [
                ShikigamiSkillInfo(name: "唤羽", cost: "0 火", summary: "攻击单体后失去自身最大生命；满级提高伤害。"),
                ShikigamiSkillInfo(name: "未熄羽", cost: "被动 / 施放", summary: "无法被常规治疗；阵亡后化为余烬并获得复活机会，通过淬火印记造成持续伤害，也可为队友生成羽茧护盾。"),
                ShikigamiSkillInfo(name: "百羽衔火", cost: "主动", summary: "先攻击选中目标，再对敌方全体造成多段伤害，同时损耗自身生命；满级伤害不触发敌方御魂。")
            ], verified: true
        ),
        "不知火": ShikigamiRecord(
            name: "不知火", rarity: .ssr, release: "2019-04-29", roles: ["普攻体系", "结界", "双形态"],
            attack: "3457", hp: "12532", defense: "397", speed: "117", crit: "10%",
            skills: [
                ShikigamiSkillInfo(name: "初舞 / 终舞", cost: "0 火", summary: "初始形态以火蝶进行两段普攻；进入离殇形态后替换为伤害更高的终舞。"),
                ShikigamiSkillInfo(name: "离影 / 离歌", cost: "0 火", summary: "围绕生命阈值切换离殇形态；初始形态为队友提供抵抗，离殇形态提升自身输出与行动能力。"),
                ShikigamiSkillInfo(name: "星火满天 / 烬染不夜", cost: "主动", summary: "星火结界强化友方普攻体系并提供增益；离殇形态下替换为群体输出技能。")
            ], verified: true
        )
    ]
}

