import SwiftUI

@main
struct YuhunBoxApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .tint(Color.crimson)
        }
    }
}

