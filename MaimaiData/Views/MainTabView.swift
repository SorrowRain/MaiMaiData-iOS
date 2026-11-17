import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            SongListView()
                .modifier(TabEntranceModifier(isActive: selectedTab == 0, initiallyVisible: true))
                .tabItem {
                    Label("曲库", systemImage: "music.note.list")
                }
                .tag(0)

            RatingToolsView()
                .modifier(TabEntranceModifier(isActive: selectedTab == 1, initiallyVisible: false))
                .tabItem {
                    Label("Rating与查分", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(1)

            SettingsView()
                .modifier(TabEntranceModifier(isActive: selectedTab == 2, initiallyVisible: false))
                .tabItem {
                    Label("设置与数据", systemImage: "gearshape")
                }
                .tag(2)
        }
        .tint(AppTheme.accent)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}

private struct TabEntranceModifier: ViewModifier {
    let isActive: Bool
    @State private var visible: Bool

    init(isActive: Bool, initiallyVisible: Bool) {
        self.isActive = isActive
        _visible = State(initialValue: initiallyVisible)
    }

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .onAppear {
                if isActive && !visible {
                    withAnimation(.easeOut(duration: 0.18)) {
                        visible = true
                    }
                }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    withAnimation(.easeOut(duration: 0.18)) {
                        visible = true
                    }
                } else {
                    visible = false
                }
            }
    }
}
