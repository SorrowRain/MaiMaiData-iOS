import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            SongListView()
                .tabItem {
                    Label("曲库", systemImage: "music.note.list")
                }

            RatingToolsView()
                .tabItem {
                    Label("Rating与查分", systemImage: "chart.bar.doc.horizontal")
                }

            SettingsView()
                .tabItem {
                    Label("设置与数据", systemImage: "gearshape")
                }
        }
        .tint(AppTheme.accent)
    }
}
