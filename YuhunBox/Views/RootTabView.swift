import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case home, souls, teams, catalog, advisor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "首页"
        case .souls: return "御魂"
        case .teams: return "队伍"
        case .catalog: return "图鉴"
        case .advisor: return "顾问"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house"
        case .souls: return "circle.hexagongrid"
        case .teams: return "person.3"
        case .catalog: return "books.vertical"
        case .advisor: return "sparkles"
        }
    }

    var selectedSymbol: String {
        switch self {
        case .home: return "house.fill"
        case .souls: return "circle.hexagongrid.fill"
        case .teams: return "person.3.fill"
        case .catalog: return "books.vertical.fill"
        case .advisor: return "sparkles"
        }
    }
}

struct RootTabView: View {
    @State private var selectedSection: AppSection = .home

    var body: some View {
        TabView(selection: $selectedSection) {
            DashboardView(selectedSection: $selectedSection)
                .tag(AppSection.home)
                .tabItem { Label(AppSection.home.title, systemImage: tabSymbol(.home)) }

            SoulInventoryView()
                .tag(AppSection.souls)
                .tabItem { Label(AppSection.souls.title, systemImage: tabSymbol(.souls)) }

            TeamListView()
                .tag(AppSection.teams)
                .tabItem { Label(AppSection.teams.title, systemImage: tabSymbol(.teams)) }

            ShikigamiCatalogView()
                .tag(AppSection.catalog)
                .tabItem { Label(AppSection.catalog.title, systemImage: tabSymbol(.catalog)) }

            AdvisorView()
                .tag(AppSection.advisor)
                .tabItem { Label(AppSection.advisor.title, systemImage: tabSymbol(.advisor)) }
        }
        .tint(AppTheme.pink)
        .toolbarBackground(AppTheme.card, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .preferredColorScheme(.dark)
    }

    private func tabSymbol(_ section: AppSection) -> String {
        selectedSection == section ? section.selectedSymbol : section.symbol
    }
}

