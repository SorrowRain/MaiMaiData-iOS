import SwiftUI

struct RatingToolsView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    @State private var path = NavigationPath()
    @State private var showProfilePopover = false
    @State private var syncToast: String?
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
                VStack(spacing: AppTheme.cardSpacing) {
                    ratingSummaryCard
                    recordsAndProgressSection
                    calculatorsSection
                }
                .padding(.horizontal, AppTheme.pagePadding)
                .padding(.vertical, AppTheme.Space.m)
            }
            .appPageBackground()
            .sensoryFeedback(.selection, trigger: store.activeProfileId)
            .navigationTitle("Rating 与查分")
            .navigationBarTitleDisplayMode(.inline)
            .statusToast(syncToast)
            .errorAlert("同步失败", message: $syncErrorMessage)
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
                    if let activeProfile = store.activeProfile {
                        Button {
                            showProfilePopover = true
                        } label: {
                            HStack(alignment: .center, spacing: 6) {
                                Text(store.displayPlayerName)
                                    .font(AppTheme.Typography.cardTitle)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Image(systemName: "chevron.up.chevron.down")
                                    .font(AppTheme.Typography.caption2Bold)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("当前玩家 \(store.displayPlayerName)，点击切换成绩档案")
                        .popover(isPresented: $showProfilePopover, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                            profileSwitcherPopover(activeProfileId: activeProfile.id)
                                .presentationCompactAdaptation(.popover)
                        }
                    } else {
                        Text("未添加档案")
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    if store.serverRegion != .cn {
                        AppCapsuleLabel(
                            text: "\(store.serverRegion.shortName)新规",
                            style: .compact
                        )
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
    }

    private func profileSwitcherPopover(activeProfileId: UUID) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(store.profiles.enumerated()), id: \.element.id) { idx, profile in
                if idx > 0 {
                    Divider().padding(.leading, AppTheme.Space.m)
                }
                let isCurrent = (profile.id == activeProfileId)
                let rowFill = isCurrent
                    ? AppTheme.accent.opacity(colorScheme == .dark ? 0.14 : 0.07)
                    : Color.clear

                Button {
                    showProfilePopover = false
                    guard !isCurrent else { return }
                    store.switchProfile(to: profile.id)
                    Task {
                        withAnimation {
                            syncToast = "已切换至 \(profile.displayTitle)"
                        }
                        await dismissToast($syncToast, after: 1.6, animated: true)
                    }
                } label: {
                    ScoreProfileRowLabel(profile: profile, isSelected: isCurrent)
                        .padding(.horizontal, AppTheme.Space.m)
                        .frame(minHeight: 46)
                        .background(rowFill)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Divider()

            Button {
                showProfilePopover = false
                path.append(ToolRoute.accountManagement)
            } label: {
                HStack(spacing: AppTheme.Space.s) {
                    Image(systemName: "slider.horizontal.3")
                        .font(AppTheme.Typography.captionBold)
                    Text("管理成绩档案")
                        .font(AppTheme.Typography.rowTitle)
                    Spacer()
                }
                .foregroundStyle(AppTheme.accentText)
                .padding(.horizontal, AppTheme.Space.m)
                .frame(minHeight: 46)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 236)
    }

    private func syncRecords() async {
        do {
            try await store.syncActiveProfileRecords()
            withAnimation {
                syncToast = "成绩已同步"
            }
            await dismissToast($syncToast, after: 2, animated: true)
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

                    Divider().padding(.leading, 58)

                    NavigationLink(value: ToolRoute.versionCheck) {
                        AppInsetRow(
                            icon: "square.grid.3x3.fill",
                            iconColor: AppTheme.Palette.ratingPurple,
                            title: "牌子进度表"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 58)

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
