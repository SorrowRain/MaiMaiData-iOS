import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            SongListView()
                .background(
                    TabCrossfadeBridge(selectedTab: selectedTab)
                        .frame(width: 0, height: 0)
                )
                .tabItem {
                    Label("曲库", systemImage: "music.note.list")
                }
                .tag(0)

            RatingToolsView()
                .tabItem {
                    Label("Rating与查分", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("设置与数据", systemImage: "gearshape")
                }
                .tag(2)
        }
        .tint(AppTheme.accent)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}
