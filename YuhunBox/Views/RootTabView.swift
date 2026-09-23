import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case home, souls, teams, advisor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "首页"
        case .souls: return "御魂"
        case .teams: return "队伍"
        case .advisor: return "顾问"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .souls: return "circle.hexagongrid.fill"
        case .teams: return "person.3.fill"
        case .advisor: return "sparkles"
        }
    }
}

struct RootTabView: View {
    @State private var selectedSection: AppSection = .home
    @State private var showQuickCreate = false

    var body: some View {
        selectedView
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ImmersiveTabBar(selectedSection: $selectedSection) { showQuickCreate = true }
            }
            .sheet(isPresented: $showQuickCreate) {
                QuickCreateView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .tint(Color.crimson)
            .preferredColorScheme(.dark)
    }

    @ViewBuilder private var selectedView: some View {
        switch selectedSection {
        case .home: DashboardView(selectedSection: $selectedSection)
        case .souls: SoulInventoryView()
        case .teams: TeamListView()
        case .advisor: AdvisorView()
        }
    }
}

private struct ImmersiveTabBar: View {
    @Binding var selectedSection: AppSection
    let onCreate: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            tabButton(.home)
            tabButton(.souls)
            Button(action: onCreate) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.cyan)
                        .frame(width: 47, height: 34)
                        .offset(x: -3)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.pink)
                        .frame(width: 47, height: 34)
                        .offset(x: 3)
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white)
                        .frame(width: 43, height: 32)
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.black)
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("快捷创建")
            tabButton(.teams)
            tabButton(.advisor)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial)
        .background(Color.ink.opacity(0.94))
        .overlay(alignment: .top) { Divider().overlay(Color.white.opacity(0.08)) }
    }

    private func tabButton(_ section: AppSection) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) { selectedSection = section }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: section.symbol)
                    .font(.system(size: 18, weight: selectedSection == section ? .bold : .medium))
                Text(section.title)
                    .font(.caption2.weight(selectedSection == section ? .bold : .medium))
            }
            .foregroundStyle(selectedSection == section ? Color.white : Color.white.opacity(0.50))
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct QuickCreateView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var editorSoul: SoulPiece?
    @State private var editorTeam: TeamPreset?
    @State private var showOCR = false
    @State private var showTeamImport = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    action("录入御魂", "手动填写属性", "plus.circle.fill", .crimson) {
                        editorSoul = SoulEditorView.blankSoul
                    }
                    action("截图识别", "本地 OCR 读取", "text.viewfinder", .saffron) {
                        showOCR = true
                    }
                    action("新建队伍", "保存阵容与配速", "person.3.fill", .purple) {
                        editorTeam = TeamEditorView.blankTeam
                    }
                    action("扫码导入", "识别阵容二维码", "qrcode.viewfinder", .green) {
                        showTeamImport = true
                    }
                    NavigationLink { LoadoutSimulatorView() } label: {
                        actionLabel("配装模拟", "自动挑选六件套", "slider.horizontal.3", .orange)
                    }
                    NavigationLink { SpeedTimelineView() } label: {
                        actionLabel("速度轴", "检查行动顺序", "timeline.selection", .blue)
                    }
                }
                .padding(16)
            }
            .background(AppTheme.page)
            .navigationTitle("快捷操作")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("完成") { dismiss() } } }
            .sheet(item: $editorSoul) { soul in SoulEditorView(soul: soul) { store.upsert($0) } }
            .sheet(item: $editorTeam) { team in TeamEditorView(team: team) { store.upsert($0) } }
            .sheet(isPresented: $showOCR) { SoulScreenshotImportView { store.upsert($0) } }
            .sheet(isPresented: $showTeamImport) { TeamImportView { store.importTeam($0) } }
        }
    }

    private func action(_ title: String, _ detail: String, _ symbol: String, _ tint: Color, perform: @escaping () -> Void) -> some View {
        Button(action: perform) { actionLabel(title, detail, symbol, tint) }
            .buttonStyle(.plain)
    }

    private func actionLabel(_ title: String, _ detail: String, _ symbol: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            Text(title).font(.headline).foregroundStyle(.primary)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 125, alignment: .leading)
        .padding(15)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

