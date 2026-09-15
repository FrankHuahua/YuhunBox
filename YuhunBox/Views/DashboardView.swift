import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showSettings = false

    private var topCandidates: [SoulScore] {
        Array(SoulAdvisor.ranked(store.souls, for: store.preferences.primaryGoal).prefix(3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    hero
                    metrics
                    focusSection
                    insightsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(AppTheme.page)
            .navigationTitle("御魂匣")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    AppMark(size: 34)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("今日养成方向")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.saffron)
                    Text(store.preferences.primaryGoal.title)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    Text(store.preferences.primaryGoal.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
                Image(systemName: store.preferences.primaryGoal.symbol)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.saffron)
            }

            Picker("养成方向", selection: $store.preferences.primaryGoal) {
                ForEach(BuildGoal.allCases) { goal in
                    Text(goal.title).tag(goal)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(20)
        .background(AppTheme.heroGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .stroke(Color.saffron.opacity(0.14), lineWidth: 22)
                .frame(width: 120, height: 120)
                .offset(x: 34, y: 48)
                .allowsHitTesting(false)
        }
    }

    private var metrics: some View {
        HStack(spacing: 10) {
            MetricTile(title: "御魂库存", value: "\(store.souls.count)", symbol: "circle.hexagongrid.fill", tint: .crimson)
            MetricTile(title: "队伍预设", value: "\(store.teams.count)", symbol: "person.3.fill", tint: .indigo)
            MetricTile(title: "待强化", value: "\(store.souls.filter { $0.level < 15 }.count)", symbol: "hammer.fill", tint: .orange)
        }
    }

    @ViewBuilder private var focusSection: some View {
        VStack(spacing: 12) {
            SectionHeading(title: "优先关注", detail: store.preferences.primaryGoal.title)
            if topCandidates.isEmpty {
                EmptyState(symbol: "circle.hexagongrid", title: "还没有御魂", detail: "录入御魂后，这里会显示最值得强化的候选。")
                    .appCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(topCandidates.indices), id: \.self) { index in
                        let score = topCandidates[index]
                        SoulRow(soul: score.soul, score: score)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                        if index < topCandidates.count - 1 { Divider().padding(.leading, 70) }
                    }
                }
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    @ViewBuilder private var insightsSection: some View {
        let insights = SoulAdvisor.insights(for: store.souls)
        VStack(spacing: 12) {
            SectionHeading(title: "账号快照", detail: SoulAdvisor.summary(for: store.souls))
            ForEach(insights.prefix(2)) { insight in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: insight.symbol)
                        .frame(width: 34, height: 34)
                        .background(insightColor(insight.kind).opacity(0.12), in: Circle())
                        .foregroundStyle(insightColor(insight.kind))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title).font(.subheadline.weight(.semibold))
                        Text(insight.detail).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .appCard()
            }
        }
    }

    private func insightColor(_ kind: AccountInsight.Kind) -> Color {
        switch kind {
        case .strength: return .green
        case .opportunity: return .orange
        case .warning: return .red
        }
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            Form {
                Section("账号") {
                    Picker("养成阶段", selection: $store.preferences.accountStage) {
                        ForEach(["新手期", "养成中期", "阵容完善期", "御魂精修期"], id: \.self) { Text($0) }
                    }
                }
                Section("数据") {
                    Button("恢复示例数据") { store.restoreSamples() }
                    Button("清除全部本地数据", role: .destructive) { confirmClear = true }
                }
                Section {
                    Text("数据只保存在当前设备。御魂评分用于筛选胚子，不代表游戏中的唯一最优解。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
            .confirmationDialog("确定清除全部数据？", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("清除", role: .destructive) { store.clearAll() }
            } message: {
                Text("该操作无法撤销。")
            }
        }
    }
}

