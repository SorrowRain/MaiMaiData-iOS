import SwiftUI

struct RatingToolsView: View {
    @Environment(DataStore.self) private var store

    @State private var path = NavigationPath()
    @State private var isProfileExpanded = false
    @State private var toast = ToastState()
    @State private var syncErrorMessage: String?

    private enum ToolRoute: Hashable {
        case prober
        case versionCheck
        case levelCheck
        case calculator
        case accountManagement
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                ZStack(alignment: .top) {
                    VStack(spacing: AppTheme.cardSpacing) {
                        ratingSummaryCard
                            .zIndex(20)
                        recordsAndProgressSection
                        calculatorsSection
                    }
                    .padding(.horizontal, AppTheme.pagePadding)
                    .padding(.vertical, AppTheme.Space.m)

                    if isProfileExpanded {
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .zIndex(10)
                            .onTapGesture {
                                withAnimation(.snappy(duration: 0.18, extraBounce: 0)) {
                                    isProfileExpanded = false
                                }
                            }
                    }
                }
            }
            .appPageBackground()
            .sensoryFeedback(.selection, trigger: store.activeProfileId)
            .navigationTitle("Rating 与查分")
            .navigationBarTitleDisplayMode(.inline)
            .statusToast(toast)
            .errorAlert("同步失败", message: $syncErrorMessage)
            .onDisappear {
                var tx = Transaction()
                tx.disablesAnimations = true
                withTransaction(tx) {
                    isProfileExpanded = false
                }
            }
            .navigationDestination(for: ToolRoute.self) { route in
                switch route {
                case .prober:
                    ProberView()
                case .versionCheck:
                    VersionCheckView()
                case .levelCheck:
                    LevelCheckView()
                case .calculator:
                    RatingCalculatorView()
                case .accountManagement:
                    AccountManagementView()
                }
            }
            .navigationDestination(for: SongDetailRoute.self) { route in
                SongDetailView(song: route.song, initialDifficulty: route.initialDifficulty)
            }
            .navigationDestination(for: SongData.self) { song in
                SongDetailView(song: song)
            }
        }
    }

    // MARK: - 1. Player & Rating Summary Card

    private var ratingSummaryCard: some View {
        let summary = store.best35AndBest15()
        let isLoggedIn = store.isLoggedIn

        return AppCard(padding: AppTheme.cardPadding, tint: AppTheme.accent) {
            VStack(alignment: .leading, spacing: AppTheme.Space.m) {
                HStack(alignment: .center, spacing: AppTheme.Space.s) {
                    if store.activeProfile != nil {
                        Button {
                            withAnimation(.snappy(duration: 0.18, extraBounce: 0)) {
                                isProfileExpanded.toggle()
                            }
                        } label: {
                            HStack(alignment: .center, spacing: 6) {
                                Text(store.displayPlayerName)
                                    .font(AppTheme.Typography.cardTitle)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .transaction { $0.animation = nil }

                                Image(systemName: "chevron.down")
                                    .font(AppTheme.Typography.captionBold)
                                    .foregroundStyle(.secondary)
                                    .rotationEffect(.degrees(isProfileExpanded ? 180 : 0))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("当前玩家 \(store.displayPlayerName)，点击切换成绩档案")
                    } else {
                        Text("未添加档案")
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    if isLoggedIn {
                        AppInlineButton(
                            title: "同步成绩",
                            icon: "arrow.clockwise",
                            isLoading: store.isSyncingRecords
                        ) {
                            Task { await syncRecords() }
                        }
                    } else {
                        AppInlineButton(
                            title: "添加档案",
                            icon: "person.crop.circle.badge.plus"
                        ) {
                            path.append(ToolRoute.accountManagement)
                        }
                    }
                }

                Button {
                    if isProfileExpanded {
                        withAnimation(.snappy(duration: 0.18, extraBounce: 0)) {
                            isProfileExpanded = false
                        }
                        return
                    }
                    path.append(isLoggedIn ? ToolRoute.prober : ToolRoute.accountManagement)
                } label: {
                    HStack(spacing: AppTheme.Space.s) {
                        AppMetricTile(
                            title: "总 Rating",
                            value: isLoggedIn ? "\(summary.totalRating)" : "—",
                            highlight: isLoggedIn
                        )
                        AppMetricTile(
                            title: "旧版本 B35",
                            value: isLoggedIn ? "\(summary.b35Rating)" : "—"
                        )
                        AppMetricTile(
                            title: "现行版本 B15",
                            value: isLoggedIn ? "\(summary.b15Rating)" : "—"
                        )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isLoggedIn ? "查看 Best 50 成绩详情" : "前往添加成绩档案")
            }
        }
        .overlay(alignment: .topLeading) {
            if isProfileExpanded, let activeProfile = store.activeProfile {
                floatingProfileDropdown(activeProfileId: activeProfile.id)
                    .padding(.top, 50)
                    .padding(.leading, AppTheme.cardPadding)
                    .transition(
                        .scale(scale: 0.95, anchor: .topLeading)
                        .combined(with: .opacity)
                    )
            }
        }
    }

    private func floatingProfileDropdown(activeProfileId: UUID) -> some View {
        AppFloatingPanel {
            VStack(spacing: 0) {
                ForEach(Array(store.profiles.enumerated()), id: \.element.id) { idx, profile in
                    if idx > 0 {
                        Divider()
                    }
                    let isCurrent = (profile.id == activeProfileId)

                    Button {
                        withAnimation(.snappy(duration: 0.18, extraBounce: 0)) {
                            isProfileExpanded = false
                        }
                        guard !isCurrent else { return }
                        store.switchProfile(to: profile.id)
                        toast.show("已切换至 \(profile.displayTitle)", duration: 1.6)
                    } label: {
                        ScoreProfileRowLabel(profile: profile, isSelected: isCurrent)
                            .padding(.horizontal, AppTheme.Space.m)
                            .frame(minHeight: 46)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .appInsetRowHighlight(isCurrent)
                }

                Divider()

                Button {
                    var tx = Transaction()
                    tx.disablesAnimations = true
                    withTransaction(tx) {
                        isProfileExpanded = false
                    }
                    path.append(ToolRoute.accountManagement)
                } label: {
                    AppInsetRow(title: "管理成绩档案", showsChevron: true)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 244)
    }

    private func syncRecords() async {
        do {
            try await store.syncActiveProfileRecords()
            toast.show("成绩已同步", duration: 1.8)
        } catch let error as MaimaiAPIError {
            syncErrorMessage = error.recoveryMessage
        } catch {
            syncErrorMessage = error.localizedDescription
        }
    }

    // MARK: - 2. Records & Plate Progress Section

    private var recordsAndProgressSection: some View {
        AppSectionCard(title: "成绩与牌子进度") {
            AppInsetGroup {
                VStack(spacing: 0) {
                    NavigationLink(value: ToolRoute.prober) {
                        AppInsetRow(
                            icon: "trophy.fill",
                            iconColor: AppTheme.accent,
                            title: "Best 50"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()

                    NavigationLink(value: ToolRoute.versionCheck) {
                        AppInsetRow(
                            icon: "square.grid.3x3.fill",
                            iconColor: AppTheme.Palette.ratingPurple,
                            title: "牌子进度表"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()

                    NavigationLink(value: ToolRoute.levelCheck) {
                        AppInsetRow(
                            icon: "slider.horizontal.3",
                            iconColor: AppTheme.Palette.ratingOrange,
                            title: "等级进度表"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 3. Calculators Section

    private var calculatorsSection: some View {
        AppSectionCard(title: "算分与推分工具") {
            AppInsetGroup {
                NavigationLink(value: ToolRoute.calculator) {
                    AppInsetRow(
                        icon: "function",
                        iconColor: AppTheme.Palette.ratingBlue,
                        title: "Rating 计算器"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
