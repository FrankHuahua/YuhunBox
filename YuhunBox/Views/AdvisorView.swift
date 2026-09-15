import SwiftUI

struct AdvisorView: View {
    @EnvironmentObject private var store: AppStore
    @State private var goal: BuildGoal = .firstSpeed

    private var rankings: [SoulScore] { SoulAdvisor.ranked(store.souls, for: goal) }
    private var insights: [AccountInsight] { SoulAdvisor.insights(for: store.souls) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    goalSelector
                    directionCard
                    loadoutSection
                    insightsSection
                    rankingsSection
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(AppTheme.page)
            .navigationTitle("御魂顾问")
            .onAppear { goal = store.preferences.primaryGoal }
        }
    }

    private var goalSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "评估方向")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BuildGoal.allCases) { item in
                        Button {
                            withAnimation(.easeOut(duration: 0.18)) { goal = item }
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: item.symbol)
                                Text(item.title)
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(goal == item ? Color.white : Color.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(goal == item ? Color.crimson : AppTheme.card, in: Capsule())
                        }
                    }
                }
            }
        }
    }

    private var directionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: goal.symbol)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.saffron)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.1), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title).font(.headline).foregroundStyle(.white)
                    Text(goal.subtitle).font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
            }
            Divider().overlay(.white.opacity(0.2))
            Text(strategyText)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 7) {
                ForEach(recommendedSets, id: \.self) { set in
                    Text(set)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.saffron)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.saffron.opacity(0.12), in: Capsule())
                }
            }
        }
        .padding(18)
        .background(AppTheme.heroGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder private var loadoutSection: some View {
        VStack(spacing: 10) {
            SectionHeading(title: "推荐六件套", detail: "从当前库存自动选择")
            if let loadout = SoulAdvisor.suggestLoadout(from: store.souls, for: goal) {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loadout.dominantSet.map { "\($0.rawValue)四件套" } ?? "散件过渡")
                                .font(.headline)
                            Text(loadout.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        GradeBadge(grade: loadout.averageScore >= 72 ? "A" : loadout.averageScore >= 58 ? "B" : "C", score: loadout.averageScore)
                    }
                    .padding(14)

                    Divider()
                    ForEach(Array(loadout.pieces.indices), id: \.self) { index in
                        let piece = loadout.pieces[index]
                        SoulRow(soul: piece.soul, score: piece)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                        if index < loadout.pieces.count - 1 { Divider().padding(.leading, 70) }
                    }
                }
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                EmptyState(symbol: "square.grid.3x2", title: "还不能生成配置", detail: "至少录入一件御魂后再试。")
                    .appCard()
            }
        }
    }

    private var insightsSection: some View {
        VStack(spacing: 10) {
            SectionHeading(title: "账号方向", detail: "基于当前库存")
            ForEach(insights) { insight in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: insight.symbol)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(color(for: insight.kind))
                        .frame(width: 34, height: 34)
                        .background(color(for: insight.kind).opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title).font(.subheadline.weight(.semibold))
                        Text(insight.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                .appCard()
            }
        }
    }

    @ViewBuilder private var rankingsSection: some View {
        VStack(spacing: 10) {
            SectionHeading(title: "强化队列", detail: "按当前方向评分")
            if rankings.isEmpty {
                EmptyState(symbol: "hammer", title: "暂无候选", detail: "先去御魂页录入或识别截图。")
                    .appCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(rankings.prefix(12).indices), id: \.self) { index in
                        let score = rankings[index]
                        NavigationLink {
                            SoulAnalysisDetailView(score: score)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                SoulRow(soul: score.soul, score: score)
                                HStack(spacing: 6) {
                                    Image(systemName: index < 3 ? "flame.fill" : "arrow.up.circle")
                                    Text(score.action)
                                    Text("·")
                                    Text(score.reason).lineLimit(1)
                                }
                                .font(.caption)
                                .foregroundStyle(index < 3 ? Color.crimson : Color.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        if index < min(rankings.count, 12) - 1 { Divider().padding(.leading, 70) }
                    }
                }
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var strategyText: String {
        switch goal {
        case .firstSpeed: return "二号位必须速度主属性；其余位置优先看速度副属性，不必强求四件套。每次强化 3 级，速度未命中就及时止损。"
        case .critOutput: return "先用六号位暴击把面板补到满暴，再平衡爆伤与攻击。双暴胚子值得锁定，套装完整度高于少量面板差距。"
        case .critDamage: return "六号位爆伤成型需要大量暴击副属性。若当前六号位爆伤或双暴胚子不足，先做满暴输出过渡。"
        case .effectHit: return "四号位效果命中是核心，二号位速度保证出手。控制套装的功能性优先，生命副属性能显著提高容错。"
        case .survival: return "生命加成通常更通用；需要频繁解控的式神提高抵抗。速度决定辅助能否在关键节点行动，不要只堆面板。"
        }
    }

    private var recommendedSets: [String] {
        switch goal {
        case .firstSpeed: return ["招财猫", "火灵", "散件"]
        case .critOutput: return ["破势", "狂骨", "海月火玉"]
        case .critDamage: return ["针女", "隐念", "网切"]
        case .effectHit: return ["雪幽魂", "魅妖", "钟灵"]
        case .survival: return ["共潜", "蚌精", "薙魂"]
        }
    }

    private func color(for kind: AccountInsight.Kind) -> Color {
        switch kind {
        case .strength: return .green
        case .opportunity: return .orange
        case .warning: return .red
        }
    }
}

private struct SoulAnalysisDetailView: View {
    let score: SoulScore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle().stroke(Color.crimson.opacity(0.14), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: CGFloat(score.score) / 100)
                            .stroke(Color.crimson, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text(score.grade).font(.largeTitle.weight(.black))
                            Text("\(score.score) 分").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 126, height: 126)
                    Text(score.action).font(.title3.weight(.bold))
                    Text(score.reason).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .appCard()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: score.soul.displayName, detail: "+\(score.soul.level)")
                    statRow(score.soul.mainStat, title: "主属性")
                    Divider()
                    ForEach(score.soul.substats) { stat in statRow(stat, title: "副属性") }
                }
                .appCard()

                VStack(alignment: .leading, spacing: 8) {
                    Label("如何使用这个评分", systemImage: "info.circle.fill")
                        .font(.subheadline.weight(.semibold))
                    Text("评分用于同一养成方向下快速筛选，不替代式神技能、队伍速度轴和实战需求。未强化御魂包含潜力分，建议每提升 3 级后重新判断。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .appCard()
            }
            .padding(16)
        }
        .background(AppTheme.page)
        .navigationTitle(score.goal.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statRow(_ stat: SoulStat, title: String) -> some View {
        HStack {
            Text(title).font(.caption).foregroundStyle(.secondary).frame(width: 48, alignment: .leading)
            Text(stat.type.title)
            Spacer()
            Text(stat.type.formatted(stat.value)).font(.body.monospacedDigit().weight(.semibold))
        }
    }
}

