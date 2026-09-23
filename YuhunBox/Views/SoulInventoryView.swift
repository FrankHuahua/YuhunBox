import PhotosUI
import SwiftUI

struct SoulInventoryView: View {
    @EnvironmentObject private var store: AppStore
    @State private var searchText = ""
    @State private var selectedSlot: SoulSlot?
    @State private var selectedSet: SoulSet?
    @State private var editorSoul: SoulPiece?
    @State private var showOCRImport = false

    private var filteredSouls: [SoulPiece] {
        store.souls.filter { soul in
            let matchesSearch = searchText.isEmpty
                || soul.set.rawValue.localizedCaseInsensitiveContains(searchText)
                || soul.mainStat.type.title.localizedCaseInsensitiveContains(searchText)
                || soul.note.localizedCaseInsensitiveContains(searchText)
            return matchesSearch
                && (selectedSlot == nil || soul.slot == selectedSlot)
                && (selectedSet == nil || soul.set == selectedSet)
        }
        .sorted {
            if $0.slot == $1.slot { return $0.createdAt > $1.createdAt }
            return $0.slot.rawValue < $1.slot.rawValue
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                navigationStrip
                filterBar
                if filteredSouls.isEmpty {
                    EmptyState(
                        symbol: "circle.hexagongrid",
                        title: store.souls.isEmpty ? "御魂匣还是空的" : "没有匹配结果",
                        detail: store.souls.isEmpty ? "点击右上角录入，或从游戏截图识别。" : "试试清除位置、套装或搜索条件。"
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(filteredSouls) { soul in
                            Button { editorSoul = soul } label: {
                                SoulRow(soul: soul)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { store.deleteSoul(soul) } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(AppTheme.page)
            .navigationTitle("御魂")
            .searchable(text: $searchText, prompt: "套装、属性或备注")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { showOCRImport = true } label: {
                        Image(systemName: "text.viewfinder")
                    }
                    .accessibilityLabel("从截图识别")
                    Button { editorSoul = SoulEditorView.blankSoul } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("录入御魂")
                }
            }
            .sheet(item: $editorSoul) { soul in
                SoulEditorView(soul: soul) { store.upsert($0) }
            }
            .sheet(isPresented: $showOCRImport) {
                SoulScreenshotImportView { store.upsert($0) }
            }
        }
    }

    private var navigationStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button { editorSoul = SoulEditorView.blankSoul } label: {
                    ModuleNavLabel(title: "录入御魂", detail: "填写主副属性", symbol: "plus.circle.fill", tint: .crimson)
                }
                Button { showOCRImport = true } label: {
                    ModuleNavLabel(title: "截图识别", detail: "设备端 OCR", symbol: "text.viewfinder", tint: .saffron)
                }
                NavigationLink { LoadoutSimulatorView() } label: {
                    ModuleNavLabel(title: "配装模拟", detail: "自动挑选六件套", symbol: "slider.horizontal.3", tint: .orange)
                }
                NavigationLink { UpgradeQueueView() } label: {
                    ModuleNavLabel(title: "强化清单", detail: "查看高潜胚子", symbol: "checklist", tint: .purple)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background(AppTheme.page)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Button("全部位置") { selectedSlot = nil }
                    ForEach(SoulSlot.allCases) { slot in
                        Button(slot.title) { selectedSlot = slot }
                    }
                } label: {
                    filterLabel(selectedSlot?.title ?? "全部位置", active: selectedSlot != nil)
                }

                Menu {
                    Button("全部套装") { selectedSet = nil }
                    ForEach(SoulSet.allCases) { set in
                        Button(set.rawValue) { selectedSet = set }
                    }
                } label: {
                    filterLabel(selectedSet?.rawValue ?? "全部套装", active: selectedSet != nil)
                }

                if selectedSlot != nil || selectedSet != nil {
                    Button {
                        selectedSlot = nil
                        selectedSet = nil
                    } label: {
                        Label("清除", systemImage: "xmark.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(AppTheme.page)
    }

    private func filterLabel(_ text: String, active: Bool) -> some View {
        HStack(spacing: 5) {
            Text(text)
            Image(systemName: "chevron.down").font(.caption2)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(active ? Color.white : Color.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(active ? Color.crimson : AppTheme.card, in: Capsule())
    }
}

struct SoulEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var soul: SoulPiece
    let onSave: (SoulPiece) -> Void

    static let blankSoul = SoulPiece(
        set: .fortuneCat,
        slot: .two,
        level: 0,
        mainStat: SoulStat(type: .speed, value: 0),
        substats: []
    )

    init(soul: SoulPiece, onSave: @escaping (SoulPiece) -> Void) {
        _soul = State(initialValue: soul)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    Picker("御魂套装", selection: $soul.set) {
                        ForEach(SoulSet.allCases) { set in Text(set.rawValue).tag(set) }
                    }
                    Picker("位置", selection: $soul.slot) {
                        ForEach(SoulSlot.allCases) { slot in Text(slot.title).tag(slot) }
                    }
                    Stepper("强化等级  +\(soul.level)", value: $soul.level, in: 0...15, step: 3)
                    Toggle("锁定这件御魂", isOn: $soul.isLocked)
                }

                Section("主属性") {
                    Picker("属性", selection: $soul.mainStat.type) {
                        ForEach(allowedMainStats) { stat in Text(stat.title).tag(stat) }
                    }
                    HStack {
                        Text("数值")
                        Spacer()
                        TextField("0", value: $soul.mainStat.value, format: .number.precision(.fractionLength(0...1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(soul.mainStat.type.isPercent ? "%" : "")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    ForEach($soul.substats) { $stat in
                        HStack {
                            Picker("副属性", selection: $stat.type) {
                                ForEach(StatType.allCases) { type in Text(type.title).tag(type) }
                            }
                            .labelsHidden()
                            Spacer()
                            TextField("0", value: $stat.value, format: .number.precision(.fractionLength(0...1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                            if stat.type.isPercent { Text("%").foregroundStyle(.secondary) }
                            Button(role: .destructive) {
                                soul.substats.removeAll { $0.id == stat.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    if soul.substats.count < 4 {
                        Button {
                            let unused = StatType.allCases.first { type in !soul.substats.contains(where: { $0.type == type }) } ?? .speed
                            soul.substats.append(SoulStat(type: unused, value: 0))
                        } label: {
                            Label("添加副属性", systemImage: "plus.circle")
                        }
                    }
                } header: {
                    Text("副属性")
                } footer: {
                    Text("评分会参考副属性的有效次数，不需要填写“+”号。")
                }

                Section("备注") {
                    TextField("例如：给镰鼬备用", text: $soul.note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(soul.createdAt.timeIntervalSinceNow > -3 ? "录入御魂" : "编辑御魂")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(soul)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: soul.slot) { _ in
                if !allowedMainStats.contains(soul.mainStat.type) {
                    soul.mainStat = SoulStat(type: allowedMainStats[0], value: 0)
                }
            }
        }
    }

    private var allowedMainStats: [StatType] {
        switch soul.slot {
        case .one: return [.flatAttack]
        case .three: return [.flatDefense]
        case .five: return [.flatHP]
        case .two: return [.attackPercent, .defensePercent, .hpPercent, .speed]
        case .four: return [.attackPercent, .defensePercent, .hpPercent, .effectHit, .effectResist]
        case .six: return [.attackPercent, .defensePercent, .hpPercent, .critRate, .critDamage]
        }
    }
}

struct SoulScreenshotImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var draft: SoulPiece?
    @State private var recognizedLines: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    let onSave: (SoulPiece) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                if isLoading {
                    ProgressView("正在设备上识别…")
                        .frame(maxHeight: .infinity)
                } else if let draft {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(.green)
                        Text("识别到 \(draft.displayName)")
                            .font(.headline)
                        Text("已读取 \(recognizedLines.count) 行文字。保存前请核对套装、位置和属性数值。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 30)

                    SoulRow(soul: draft)
                        .appCard()

                    Button {
                        onSave(draft)
                        dismiss()
                    } label: {
                        Text("确认并加入御魂匣")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text("重新选择截图")
                    }
                    Spacer()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(Color.crimson)
                        Text("从御魂详情截图识别")
                            .font(.title3.weight(.bold))
                        Text("建议截图中完整包含御魂名称、位置、主属性和副属性。识别仅在设备上完成。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 48)

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("选择截图", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    Spacer()
                }
            }
            .padding(20)
            .navigationTitle("截图识别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
            .alert("识别失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("知道了", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "未知错误")
            }
            .onChange(of: selectedItem) { item in
                guard let item else { return }
                recognize(item)
            }
        }
    }

    private func recognize(_ item: PhotosPickerItem) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw ScreenshotOCRError.invalidImage
                }
                let lines = try await ScreenshotOCRService.recognize(data: data)
                await MainActor.run {
                    recognizedLines = lines
                    draft = ScreenshotOCRService.draft(from: lines)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

