import SwiftUI

@main
struct MaimaiDataApp: App {
    @State private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(store)
                .task {
                    await store.bootstrap()
                }
        }
    }
}
