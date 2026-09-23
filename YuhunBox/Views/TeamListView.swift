import SwiftUI

struct TeamListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editorTeam: TeamPreset?
    @State private var showImport = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                navigationStrip
                Group {
                    if store.teams.isEmpty {
                        EmptyState(symbol: "person.3", title: "还没有队伍预设", detail: "建立常用副本或斗技队伍，也可以扫码导入别人分享的预设。")
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(store.teams.sorted(by: { $0.updatedAt > $1.updatedAt })) { team in
                                    NavigationLink {
                                        TeamDetailView(teamID: team.id)
                                    } label: {
                                        TeamCard(team: team)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button { editorTeam = team } label: { Label("编辑", systemImage: "pencil") }
                                        Button(role: .destructive) { store.deleteTeam(team) } label: { Label("删除", systemImage: "trash") }
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .background(AppTheme.page)
            .navigationTitle("队伍预设")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { showImport = true } label: { Image(systemName: "qrcode.viewfinder") }
                        .accessibilityLabel("扫码或粘贴导入")
                    Button { editorTeam = TeamEditorView.blankTeam } label: { Image(systemName: "plus") }
                        .accessibilityLabel("新建队伍")
                }
            }
            .sheet(item: $editorTeam) { team in
                TeamEditorView(team: team) { store.upsert($0) }
            }
            .sheet(isPresented: $showImport) {
                TeamImportView { store.importTeam($0) }
            }
        }
    }

    private var navigationStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button { editorTeam = TeamEditorView.blankTeam } label: {
                    ModuleNavLabel(title: "新建队伍", detail: "阵容与配速", symbol: "person.badge.plus", tint: .crimson)
                }
                Button { showImport = true } label: {
                    ModuleNavLabel(title: "扫码导入", detail: "阵容码 / 二维码", symbol: "qrcode.viewfinder", tint: .green)
                }
                NavigationLink { SpeedTimelineView() } label: {
                    ModuleNavLabel(title: "速度轴", detail: "检查行动顺序", symbol: "arrow.up.arrow.down", tint: .saffron)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background(AppTheme.page)
    }
}

private struct TeamCard: View {
    let team: TeamPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(team.title).font(.headline)
                    Label(team.scene.isEmpty ? "未分类场景" : team.scene, systemImage: "map.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }

            if team.members.isEmpty {
                Text("还未配置式神")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: -7) {
                    ForEach(team.members.prefix(6)) { member in
                        ZStack {
                            Circle().fill(member.goal == .firstSpeed ? Color.saffron : Color.crimson)
                            Text(String(member.name.prefix(1)))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(AppTheme.card, lineWidth: 2))
                    }
                    Spacer()
                    Text("\(team.members.count) 名式神")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !team.officialCode.isEmpty {
                Label("已保存官方阵容码", systemImage: "link.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.crimson)
            }
        }
        .appCard()
    }
}

struct TeamDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let teamID: UUID
    @State private var showEditor = false
    @State private var showShareQR = false
    @State private var confirmDelete = false

    private var team: TeamPreset? { store.teams.first(where: { $0.id == teamID }) }

    var body: some View {
        Group {
            if let team {
                ScrollView {
                    VStack(spacing: 20) {
                        header(team)
                        members(team)
                        codeSection(team)
                        if !team.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 9) {
                                SectionHeading(title: "备注")
                                Text(team.notes).font(.subheadline).foregroundStyle(.secondary)
                            }
                            .appCard()
                        }
                    }
                    .padding(16)
                }
                .background(AppTheme.page)
                .navigationTitle(team.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button { showEditor = true } label: { Image(systemName: "pencil") }
                        Menu {
                            Button(role: .destructive) { confirmDelete = true } label: { Label("删除队伍", systemImage: "trash") }
                        } label: { Image(systemName: "ellipsis.circle") }
                    }
                }
                .sheet(isPresented: $showEditor) {
                    TeamEditorView(team: team) { store.upsert($0) }
                }
                .sheet(isPresented: $showShareQR) {
                    PresetQRView(team: team)
                }
                .confirmationDialog("删除“\(team.title)”？", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("删除", role: .destructive) {
                        store.deleteTeam(team)
                        dismiss()
                    }
                }
            } else {
                EmptyState(symbol: "questionmark.folder", title: "找不到该预设", detail: "它可能已经被删除。")
            }
        }
    }

    private func header(_ team: TeamPreset) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.heroGradient)
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundStyle(Color.saffron)
            }
            .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 5) {
                Text(team.title).font(.title3.weight(.bold))
                Text(team.scene.isEmpty ? "未分类场景" : team.scene).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .appCard()
    }

    private func members(_ team: TeamPreset) -> some View {
        VStack(spacing: 0) {
            SectionHeading(title: "出战顺序", detail: "\(team.members.count) 人")
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            if team.members.isEmpty {
                Text("点击右上角编辑并添加式神")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(24)
            } else {
                ForEach(Array(team.members.indices), id: \.self) { index in
                    let member = team.members[index]
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 26)
                                .background(index == 0 ? Color.crimson : Color.secondary, in: Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(member.name).font(.headline)
                                    Text(member.role).font(.caption).foregroundStyle(.secondary)
                                }
                                Text(member.soulPlan.isEmpty ? member.goal.title : member.soulPlan)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let speed = member.speedTarget {
                                TagView(text: "速 \(speed)", tint: index == 0 ? .crimson : .secondary)
                            }
                        }
                        if let requirements = member.requirements, !requirements.summary.isEmpty {
                            Text(requirements.summary.joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(Color.saffron)
                                .padding(.leading, 38)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    if index < team.members.count - 1 { Divider().padding(.leading, 54) }
                }
            }
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func codeSection(_ team: TeamPreset) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "阵容码")
            if !team.officialCode.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("官方原始码").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text(team.officialCode)
                        .font(.caption.monospaced())
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
            }
            HStack {
                Button { showShareQR = true } label: {
                    Label("显示二维码", systemImage: "qrcode")
                }
                .buttonStyle(.borderedProminent)

                if let code = try? PresetCodeCodec.encode(team) {
                    ShareLink(item: code, subject: Text(team.title), message: Text("用御魂匣导入这套队伍预设")) {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }
            Text("YHX2 二维码包含完整预设与属性门槛；官方码格式未公开时仅原样保存，不会虚构队伍详情。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .appCard()
    }
}

struct TeamEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var team: TeamPreset
    let onSave: (TeamPreset) -> Void

    static let blankTeam = TeamPreset(title: "", scene: "", members: [])

    init(team: TeamPreset, onSave: @escaping (TeamPreset) -> Void) {
        _team = State(initialValue: team)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("队伍信息") {
                    TextField("预设名称", text: $team.title)
                    TextField("场景，例如：斗技 / 魂土", text: $team.scene)
                }

                Section {
                    ForEach(Array(team.members.indices), id: \.self) { index in
                        memberEditor(index)
                    }
                    .onMove { source, destination in team.members.move(fromOffsets: source, toOffset: destination) }
                    .onDelete { team.members.remove(atOffsets: $0) }

                    if team.members.count < 6 {
                        Button {
                            team.members.append(TeamMember(name: "", role: "", goal: .survival, soulPlan: "", speedTarget: nil, requirements: nil))
                        } label: {
                            Label("添加式神", systemImage: "person.badge.plus")
                        }
                    }
                } header: {
                    HStack {
                        Text("式神与配速")
                        Spacer()
                        EditButton().textCase(nil)
                    }
                } footer: {
                    Text("长按右侧把手调整出战顺序。速度留空表示不限制。")
                }

                Section("官方阵容码（可选）") {
                    TextField("粘贴游戏内阵容码", text: $team.officialCode, axis: .vertical)
                        .font(.caption.monospaced())
                        .lineLimit(2...5)
                }

                Section("备注") {
                    TextField("操作要点、技能要求等", text: $team.notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(team.title.isEmpty ? "新建预设" : "编辑预设")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if team.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            team.title = team.scene.isEmpty ? "未命名队伍" : team.scene
                        }
                        onSave(team)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func memberEditor(_ index: Int) -> some View {
        DisclosureGroup {
            TextField("式神名称", text: $team.members[index].name)
            TextField("职责，例如：一速 / 输出", text: $team.members[index].role)
            Picker("养成方向", selection: $team.members[index].goal) {
                ForEach(BuildGoal.allCases) { goal in Text(goal.title).tag(goal) }
            }
            TextField("御魂方案，例如：招财 · 速生生", text: $team.members[index].soulPlan)
            TextField("目标速度（可选）", text: speedBinding(for: index))
                .keyboardType(.numberPad)
            Toggle("填写御魂与属性要求", isOn: requirementsEnabledBinding(for: index))
            if team.members[index].requirements != nil {
                Picker("四件套", selection: optionalRequirementBinding(for: index, keyPath: \.primarySet)) {
                    Text("不限").tag(SoulSet?.none)
                    ForEach(SoulSet.allCases) { set in Text(set.rawValue).tag(Optional(set)) }
                }
                Picker("两件套", selection: optionalRequirementBinding(for: index, keyPath: \.secondarySet)) {
                    Text("不限").tag(SoulSet?.none)
                    ForEach(SoulSet.allCases) { set in Text(set.rawValue).tag(Optional(set)) }
                }
                Picker("二号位主属性", selection: optionalRequirementBinding(for: index, keyPath: \.slot2Main)) {
                    Text("不限").tag(StatType?.none)
                    ForEach(StatType.allCases) { stat in Text(stat.title).tag(Optional(stat)) }
                }
                Picker("四号位主属性", selection: optionalRequirementBinding(for: index, keyPath: \.slot4Main)) {
                    Text("不限").tag(StatType?.none)
                    ForEach(StatType.allCases) { stat in Text(stat.title).tag(Optional(stat)) }
                }
                Picker("六号位主属性", selection: optionalRequirementBinding(for: index, keyPath: \.slot6Main)) {
                    Text("不限").tag(StatType?.none)
                    ForEach(StatType.allCases) { stat in Text(stat.title).tag(Optional(stat)) }
                }
                TextField("最低速度", text: integerRequirementBinding(for: index, keyPath: \.speedMin))
                    .keyboardType(.numberPad)
                TextField("最低攻击", text: integerRequirementBinding(for: index, keyPath: \.attackMin))
                    .keyboardType(.numberPad)
                TextField("最低生命", text: integerRequirementBinding(for: index, keyPath: \.hpMin))
                    .keyboardType(.numberPad)
                TextField("最低防御", text: integerRequirementBinding(for: index, keyPath: \.defenseMin))
                    .keyboardType(.numberPad)
                TextField("最低暴击 %", text: decimalRequirementBinding(for: index, keyPath: \.critRateMin))
                    .keyboardType(.decimalPad)
                TextField("最低爆伤 %", text: decimalRequirementBinding(for: index, keyPath: \.critDamageMin))
                    .keyboardType(.decimalPad)
                TextField("最低命中 %", text: decimalRequirementBinding(for: index, keyPath: \.effectHitMin))
                    .keyboardType(.decimalPad)
                TextField("最低抵抗 %", text: decimalRequirementBinding(for: index, keyPath: \.effectResistMin))
                    .keyboardType(.decimalPad)
                TextField("额外要求", text: stringRequirementBinding(for: index, keyPath: \.notes), axis: .vertical)
                    .lineLimit(1...3)
            }
        } label: {
            HStack {
                Text("\(index + 1)").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                Text(team.members[index].name.isEmpty ? "待填写式神" : team.members[index].name)
                    .fontWeight(.medium)
            }
        }
    }

    private func speedBinding(for index: Int) -> Binding<String> {
        Binding(
            get: { team.members[index].speedTarget.map(String.init) ?? "" },
            set: { team.members[index].speedTarget = Int($0.filter(\.isNumber)) }
        )
    }

    private func requirementsEnabledBinding(for index: Int) -> Binding<Bool> {
        Binding(
            get: { team.members[index].requirements != nil },
            set: { enabled in
                team.members[index].requirements = enabled ? (team.members[index].requirements ?? MemberRequirements()) : nil
            }
        )
    }

    private func optionalRequirementBinding<Value>(for index: Int, keyPath: WritableKeyPath<MemberRequirements, Value?>) -> Binding<Value?> {
        Binding(
            get: { team.members[index].requirements?[keyPath: keyPath] },
            set: { value in
                var requirements = team.members[index].requirements ?? MemberRequirements()
                requirements[keyPath: keyPath] = value
                team.members[index].requirements = requirements
            }
        )
    }

    private func integerRequirementBinding(for index: Int, keyPath: WritableKeyPath<MemberRequirements, Int?>) -> Binding<String> {
        Binding(
            get: { team.members[index].requirements?[keyPath: keyPath].map(String.init) ?? "" },
            set: { value in
                var requirements = team.members[index].requirements ?? MemberRequirements()
                requirements[keyPath: keyPath] = Int(value.filter(\.isNumber))
                team.members[index].requirements = requirements
            }
        )
    }

    private func decimalRequirementBinding(for index: Int, keyPath: WritableKeyPath<MemberRequirements, Double?>) -> Binding<String> {
        Binding(
            get: { team.members[index].requirements?[keyPath: keyPath].map { String(format: "%g", $0) } ?? "" },
            set: { value in
                var requirements = team.members[index].requirements ?? MemberRequirements()
                requirements[keyPath: keyPath] = Double(value.replacingOccurrences(of: ",", with: "."))
                team.members[index].requirements = requirements
            }
        )
    }

    private func stringRequirementBinding(for index: Int, keyPath: WritableKeyPath<MemberRequirements, String>) -> Binding<String> {
        Binding(
            get: { team.members[index].requirements?[keyPath: keyPath] ?? "" },
            set: { value in
                var requirements = team.members[index].requirements ?? MemberRequirements()
                requirements[keyPath: keyPath] = value
                team.members[index].requirements = requirements
            }
        )
    }
}

