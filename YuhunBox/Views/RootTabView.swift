import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("总览", systemImage: "seal.fill") }

            SoulInventoryView()
                .tabItem { Label("御魂", systemImage: "circle.hexagongrid.fill") }

            TeamListView()
                .tabItem { Label("队伍", systemImage: "person.3.fill") }

            AdvisorView()
                .tabItem { Label("顾问", systemImage: "sparkles") }
        }
    }
}


