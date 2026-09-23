import SwiftUI
import UniformTypeIdentifiers

struct ToolboxLandingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showOCR = false
    @State private var showTeamImport = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("工具箱")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                Text("把高频操作集中在一页，少跳转、快完成。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: columns, spacing: 12) {
                NavigationLink { LoadoutSimulatorView() } label: {
                    toolCard("配装模拟", "从库存自动凑套装", "slider.horizontal.3", .crimson)
                }
                NavigationLink { SpeedTimelineView() } label: {
                    toolCard("速度轴", "检查队伍出手顺序", "arrow.up.arrow.down", .saffron)
                }
                Button { showOCR = true } label: {
                    toolCard("截图识别", "读取游戏御魂截图", "text.viewfinder", .orange)
                }
                Button { showTeamImport = true } label: {
                    toolCard("扫码导入", "恢复分享的队伍", "qrcode.viewfinder", .green)
                }
                NavigationLink { BackupRestoreView() } label: {
                    toolCard("备份恢复", "迁移全部本地数据", "externaldrive.fill", .blue)
                }
                NavigationLink { UpgradeQueueView() } label: {
                    toolCard("强化清单", "集中查看高潜胚子", "checklist", .purple)
                }
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showOCR) { SoulScreenshotImportView { store.upsert($0) } }
        .sheet(isPresented: $showTeamImport) { TeamImportView { store.importTeam($0) } }
    }

    private func toolCard(_ title: String, _ detail: String, _ symbol: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(title).font(.headline).foregroundStyle(.primary)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .leading)
        .padding(15)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.055), lineWidth: 1)
        }
    }
}

struct LoadoutSimulatorView: View {
    @EnvironmentObject private var store: AppStore
    @State private var goal: BuildGoal = .firstSpeed
    @State private var onlyLocked = false

    private var candidates: [SoulPiece] {
        onlyLocked ? store.souls.filter(.isLocked) : store.souls
    }

    private var suggestion: LoadoutSuggestion? {
        SoulAdvisor.suggestLoadout(from: candidates, for: goal)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "模拟目标")
                    Picker("目标", selection: $goal) {
                        ForEach(BuildGoal.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Toggle("只使用已锁定御魂", isOn: $onlyLocked)
                        .font(.subheadline)
                }
                .appCard()

                if let suggestion {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.dominantSet.map { "($0.rawValue)四件套" } ?? "散件过渡")
                                    .font(.title3.weight(.bold))
                                Text(suggestion.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            GradeBadge(
                                grade: suggestion.averageScore >= 72 ? "A" : suggestion.averageScore >= 58 ? "B" : "C",
                                score: suggestion.averageScore
                            )
                        }
                    }
                    .appCard()

                    VStack(spacing: 0) {
                        ForEach(Array(suggestion.pieces.indices), id: .self) { index in
                            SoulRow(soul: suggestion.pieces[index].soul, score: suggestion.pieces[index])
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                            if index < suggestion.pieces.count - 1 { Divider().padding(.leading, 70) }
                        }
                    }
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        Label("模拟说明", systemImage: "info.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.saffron)
                        Text("模拟器按套装完整度、位置和当前养成方向评分自动选取，不会修改库存。实战前仍需结合式神面板、技能和队伍速度轴。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .appCard()
                } else {
                    EmptyState(
                        symbol: "slider.horizontal.3",
                        title: "没有可用于模拟的御魂",
                        detail: onlyLocked ? "当前没有已锁定御魂，关闭筛选或先锁定候选。" : "先录入御魂，再回来生成六件套。"
                    )
                    .appCard()
                }
            }
            .padding(16)
        }
        .background(AppTheme.page)
        .navigationTitle("配装模拟")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { goal = store.preferences.primaryGoal }
    }
}

struct SpeedTimelineView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedTeamID: UUID?

    private var selectedTeam: TeamPreset? {
        guard let selectedTeamID else { return store.teams.first }
        return store.teams.first(where: { $0.id == selectedTeamID }) ?? store.teams.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if store.teams.isEmpty {
                    EmptyState(symbol: "person.3", title: "还没有队伍", detail: "先新建一套队伍并填写目标速度。")
                        .appCard()
                } else {
                    Picker("选择队伍", selection: $selectedTeamID) {
                        ForEach(store.teams) { team in
                            Text(team.title).tag(Optional(team.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()

                    if let team = selectedTeam {
                        timeline(team)
                        warnings(team)
                    }
                }
            }
            .padding(16)
        }
        .background(AppTheme.page)
        .navigationTitle("速度轴检查")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedTeamID == nil { selectedTeamID = store.teams.first?.id }
        }
    }

    private func timeline(_ team: TeamPreset) -> some View {
        let sorted = team.members
            .filter { $0.speedTarget != nil }
            .sorted { ($0.speedTarget ?? 0) > ($1.speedTarget ?? 0) }

        return VStack(alignment: .leading, spacing: 0) {
            SectionHeading(title: "预计行动顺序", detail: "(sorted.count) 人已配速")
                .padding(16)

            if sorted.isEmpty {
                Text("请在队伍编辑页填写目标速度。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(24)
            } else {
                ForEach(Array(sorted.enumerated()), id: .element.id) { index, member in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(index == 0 ? AppTheme.accentGradient : LinearGradient(colors: [AppTheme.elevated], startPoint: .top, endPoint: .bottom))
                            Text("(index + 1)")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 34, height: 34)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(member.name.isEmpty ? "未命名式神" : member.name)
                                .font(.headline)
                            Text(member.role.isEmpty ? member.goal.title : member.role)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(member.speedTarget.map(String.init) ?? "—")
                            .font(.title3.monospacedDigit().weight(.bold))
                        if index < sorted.count - 1, let current = member.speedTarget, let next = sorted[index + 1].speedTarget {
                            Text("-(current - next)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    if index < sorted.count - 1 { Divider().padding(.leading, 62) }
                }
            }
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder private func warnings(_ team: TeamPreset) -> some View {
        let speeds = team.members.compactMap(.speedTarget)
        let duplicated = Set(speeds).count != speeds.count
        let missing = team.members.filter { $0.speedTarget == nil }.count

        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(title: "检查结果")
            if duplicated {
                warning("存在相同目标速度", "同速时实际行动顺序可能受式神基础速度等因素影响。", "exclamationmark.triangle.fill", .orange)
            }
            if missing > 0 {
                warning("(missing) 名式神未填速度", "补齐速度后才能完整检查行动顺序。", "questionmark.circle.fill", .saffron)
            }
            if !duplicated && missing == 0 && !speeds.isEmpty {
                warning("速度轴信息完整", "当前没有同速冲突，仍建议进战斗实测拉条与推条效果。", "checkmark.circle.fill", .green)
            }
        }
    }

    private func warning(_ title: String, _ detail: String, _ symbol: String, _ tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .appCard()
    }
}

struct UpgradeQueueView: View {
    @EnvironmentObject private var store: AppStore
    @State private var goal: BuildGoal = .firstSpeed

    private var queue: [SoulScore] {
        SoulAdvisor.ranked(store.souls.filter { $0.level < 15 }, for: goal)
            .filter { $0.score >= 58 }
    }

    var body: some View {
        List {
            Section {
                Picker("养成方向", selection: $goal) {
                    ForEach(BuildGoal.allCases) { Text($0.title).tag($0) }
                }
            }
            Section("建议继续强化") {
                if queue.isEmpty {
                    Text("当前没有 B 级以上的未满级候选。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(queue) { item in
                        SoulRow(soul: item.soul, score: item)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.page)
        .navigationTitle("强化清单")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { goal = store.preferences.primaryGoal }
    }
}

struct BackupRestoreView: View {
    @EnvironmentObject private var store: AppStore
    @State private var document = BackupDocument()
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var pendingImport: Data?
    @State private var confirmImport = false
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "externaldrive.badge.icloud")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.saffron)
                    Text("本地数据备份")
                        .font(.title2.weight(.bold))
                    Text("导出文件包含御魂、队伍与偏好设置。可保存到“文件”或通过隔空投送迁移到另一台设备。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCard()

                Button {
                    do {
                        document = BackupDocument(data: try store.exportData())
                        showExporter = true
                    } catch {
                        message = "导出失败：(error.localizedDescription)"
                    }
                } label: {
                    Label("导出完整备份", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    showImporter = true
                } label: {
                    Label("从文件恢复", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Text("恢复会覆盖当前设备上的全部数据。建议在恢复前先导出一次现有数据。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(16)
        }
        .background(AppTheme.page)
        .navigationTitle("备份与恢复")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $showExporter,
            document: document,
            contentType: .json,
            defaultFilename: "御魂匣备份-(Date.now.formatted(.dateTime.year().month().day()))"
        ) { result in
            if case .failure(let error) = result { message = "导出失败：(error.localizedDescription)" }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                pendingImport = try Data(contentsOf: url)
                confirmImport = true
            } catch {
                message = "读取失败：(error.localizedDescription)"
            }
        }
        .confirmationDialog("恢复这份备份？", isPresented: $confirmImport, titleVisibility: .visible) {
            Button("覆盖并恢复", role: .destructive) {
                guard let pendingImport else { return }
                do {
                    try store.importData(pendingImport)
                    message = "恢复完成：已导入 (store.souls.count) 件御魂和 (store.teams.count) 套队伍。"
                    self.pendingImport = nil
                } catch {
                    message = "备份格式无效：(error.localizedDescription)"
                }
            }
            Button("取消", role: .cancel) { pendingImport = nil }
        } message: {
            Text("当前御魂、队伍和偏好设置会被替换。")
        }
        .alert("御魂匣", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("知道了", role: .cancel) { message = nil }
        } message: {
            Text(message ?? "")
        }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

