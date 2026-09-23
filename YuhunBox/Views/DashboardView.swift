import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var selectedSection: AppSection
    @State private var showSettings = false

    private var topCandidates: [SoulScore] {
        Array(SoulAdvisor.ranked(store.souls, for: store.preferences.primaryGoal).prefix(3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    spotlight
                    metrics
                    toolStrip
                    focusSection
                    insightsSection
                    recentFeed
                }
                .padding(16)
            }
            .background(AppTheme.page)
            .navigationTitle("御魂匣")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    private var spotlight: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("当前养成方向").font(.caption).foregroundStyle(.secondary)
                    Text(store.preferences.primaryGoal.title).font(.title2.weight(.bold))
                    Text(store.preferences.primaryGoal.subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: store.preferences.primaryGoal.symbol)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.pink)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.pink.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            HStack {
                Picker("养成方向", selection: $store.preferences.primaryGoal) {
                    ForEach(BuildGoal.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
                Spacer()
                Button("查看建议") { selectedSection = .advisor }
                    .buttonStyle(.borderedProminent)
            }
        }
        .appCard()
    }

    private var metrics: some View {
        HStack(spacing: 10) {
            MetricTile(title: "御魂", value: "\(store.souls.count)", symbol: "circle.hexagongrid.fill", tint: .saffron)
            MetricTile(title: "队伍", value: "\(store.teams.count)", symbol: "person.3.fill", tint: .crimson)
            MetricTile(title: "待强化", value: "\(store.souls.filter { $0.level < 15 }.count)", symbol: "hammer.fill", tint: .orange)
        }
    }

    private var toolStrip: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeading(title: "常用工具", detail: "左右滑动")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    NavigationLink { LoadoutSimulatorView() } label: {
                        ModuleNavLabel(title: "配装模拟", detail: "自动选择六件套", symbol: "slider.horizontal.3", tint: .crimson)
                    }
                    NavigationLink { SpeedTimelineView() } label: {
                        ModuleNavLabel(title: "速度轴", detail: "检查行动顺序", symbol: "arrow.up.arrow.down", tint: .saffron)
                    }
                    NavigationLink { BackupRestoreView() } label: {
                        ModuleNavLabel(title: "备份恢复", detail: "导出本地数据", symbol: "externaldrive.fill", tint: .green)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder private var focusSection: some View {
        VStack(spacing: 11) {
            SectionHeading(title: "优先强化", detail: store.preferences.primaryGoal.title)
            if topCandidates.isEmpty {
                EmptyState(symbol: "circle.hexagongrid", title: "还没有御魂", detail: "录入后会显示最值得强化的候选。")
                    .appCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(topCandidates.indices), id: \.self) { index in
                        SoulRow(soul: topCandidates[index].soul, score: topCandidates[index])
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
        VStack(spacing: 11) {
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

    private var recentFeed: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeading(title: "最近队伍", detail: "\(store.teams.count) 套")
                if store.teams.isEmpty {
                    EmptyState(symbol: "person.3", title: "还没有预设", detail: "进入“队伍”页新建或导入预设。").appCard()
                } else {
                    ForEach(store.teams.sorted(by: { $0.updatedAt > $1.updatedAt }).prefix(4)) { team in
                        NavigationLink { TeamDetailView(teamID: team.id) } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(team.title).font(.headline).foregroundStyle(.primary)
                                    Text("\(team.scene.isEmpty ? "未分类" : team.scene) · \(team.members.count) 名式神")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .appCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionHeading(title: "最近录入", detail: "\(store.souls.count) 件")
                ForEach(store.souls.sorted(by: { $0.createdAt > $1.createdAt }).prefix(5)) { soul in
                    SoulRow(soul: soul).appCard()
                }
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

struct SettingsView: View {
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
                Section("工具") {
                    NavigationLink { BackupRestoreView() } label: {
                        Label("备份与恢复", systemImage: "externaldrive.fill")
                    }
                    NavigationLink { SpeedTimelineView() } label: {
                        Label("速度轴检查", systemImage: "arrow.up.arrow.down")
                    }
                }
                Section("数据") {
                    Button("恢复示例数据") { store.restoreSamples() }
                    Button("清除全部本地数据", role: .destructive) { confirmClear = true }
                }
                Section {
                    Text("数据默认只保存在当前设备。御魂评分用于筛选胚子，不代表游戏中的唯一最优解。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
            .confirmationDialog("确定清除全部数据？", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("清除", role: .destructive) { store.clearAll() }
            } message: { Text("该操作无法撤销，建议先导出备份。") }
        }
    }
}

