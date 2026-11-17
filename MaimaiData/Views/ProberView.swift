import SwiftUI

private struct B50PreviewItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ProberView: View {
    @Environment(DataStore.self) private var store

    @State private var selectedTab = 0 // 0 = B35, 1 = B15
    @State private var showLoginSheet = false
    @State private var errorMessage: String?
    @State private var isRenderingB50 = false
    @State private var b50PreviewItem: B50PreviewItem?

    var body: some View {
        let split = store.best35AndBest15()
        let b35Sum = split.b35.reduce(0) { $0 + $1.computedRating }
        let b15Sum = split.b15.reduce(0) { $0 + $1.computedRating }
        let targetList = store.sortedRecords(isNewVersion: selectedTab == 1)
        let cutoff = selectedTab == 0 ? 35 : 15

        ScrollView {
            LazyVStack(spacing: AppTheme.itemSpacing) {
                headerPickerCard(b35Sum: b35Sum, b15Sum: b15Sum, isMatching: split.isMatching)

                if targetList.isEmpty {
                    if store.currentCookie.isEmpty && store.currentUsername.isEmpty {
                        ContentUnavailableView {
                            Label("尚未登录水鱼查分器", systemImage: "person.crop.circle.badge.exclamationmark")
                        } description: {
                            Text("登录水鱼查分器后即可查看 B35 / B15 成绩并生成 Best50 图")
                        } actions: {
                            AppInlineButton(title: "前往登录", icon: "person.badge.key.fill") {
                                showLoginSheet = true
                            }
                        }
                        .padding(.top, 48)
                    } else {
                        ContentUnavailableView(
                            "暂无成绩数据",
                            systemImage: "tray",
                            description: Text("下拉刷新从水鱼查分器拉取最新成绩")
                        )
                        .padding(.top, 48)
                    }
                } else {
                    ForEach(Array(targetList.enumerated()), id: \.element.id) { idx, record in
                        if idx == cutoff {
                            HStack(spacing: AppTheme.Space.s) {
                                VStack { Divider() }
                                Text("以下不计入 Best\(cutoff)")
                                    .font(AppTheme.Typography.captionSemibold)
                                    .foregroundStyle(.secondary)
                                VStack { Divider() }
                            }
                            .padding(.vertical, 6)
                        }

                        let song = store.songsById[record.songId]
                        if let song {
                            NavigationLink(value: song) {
                                ProberRecordRow(rank: idx + 1, record: record, song: song)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ProberRecordRow(rank: idx + 1, record: record, song: nil)
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.pagePadding)
            .padding(.vertical, AppTheme.Space.m)
        }
        .refreshable {
            await refreshRecords()
        }
        .appPageBackground()
        .navigationTitle("总 Rating \(b35Sum + b15Sum)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Task { await generateBest50Image(b35: split.b35, b15: split.b15) }
                } label: {
                    if isRenderingB50 {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text("生成中…")
                                .font(AppTheme.Typography.caption)
                        }
                    } else {
                        Label("生成 B50", systemImage: "photo.on.rectangle.angled")
                    }
                }
                .disabled(isRenderingB50 || (split.b35.isEmpty && split.b15.isEmpty))
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginSheet()
        }
        .sheet(item: $b50PreviewItem) { item in
            B50PreviewSheet(image: item.image)
        }
        .errorAlert("提示", message: $errorMessage)
        .task {
            if store.records.isEmpty && !store.currentCookie.isEmpty {
                await refreshRecords()
            }
        }
    }

    private func headerPickerCard(b35Sum: Int, b15Sum: Int, isMatching: Bool) -> some View {
        AppCard(padding: 12, tint: AppTheme.accent) {
            VStack(alignment: .leading, spacing: 10) {
                Picker("版本分区", selection: $selectedTab) {
                    Text("旧版本 B35 (\(b35Sum))").tag(0)
                    Text("现行版本 B15 (\(b15Sum))").tag(1)
                }
                .pickerStyle(.segmented)

                if !isMatching && !store.records.isEmpty {
                    Label("部分成绩未匹配到当前曲库，建议在「设置与数据」中更新曲库", systemImage: "exclamationmark.triangle.fill")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func refreshRecords() async {
        do {
            try await store.fetchRecordsWithCurrentCookie()
        } catch is CancellationError {
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            return
        } catch MaimaiAPIError.unauthorized {
            try? await Task.sleep(for: .milliseconds(350))
            showLoginSheet = true
        } catch {
            let msg = "成绩刷新失败：\(error.localizedDescription)\n已有成绩已保留，请稍后重试。"
            try? await Task.sleep(for: .milliseconds(350))
            errorMessage = msg
        }
    }

    private func generateBest50Image(b35: [ProberRecord], b15: [ProberRecord]) async {
        isRenderingB50 = true
        defer { isRenderingB50 = false }
        if let image = await Best50Renderer.render(
            playerName: store.displayPlayerName,
            songsById: store.songsById,
            b35: b35,
            b15: b15
        ) {
            b50PreviewItem = B50PreviewItem(image: image)
        } else {
            errorMessage = "无法生成 Best50 图片，请先拉取成绩"
        }
    }
}

private struct ProberRecordRow: View {
    let rank: Int
    let record: ProberRecord
    let song: SongData?

    var body: some View {
        let diff = record.difficulty
        AppCard(padding: 12, tint: diff.color) {
            HStack(spacing: AppTheme.Space.m) {
                SongCoverBadgeView(
                    song: song,
                    size: .compact,
                    borderColor: diff.boardDarkColor
                )

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        AppCapsuleLabel(
                            text: "#\(rank)",
                            tint: .secondary,
                            font: .caption.weight(.bold).monospacedDigit(),
                            backgroundOpacity: 0.07,
                            horizontalPadding: 6,
                            verticalPadding: 2,
                            foreground: .secondary
                        )

                        Text(record.title)
                            .font(AppTheme.Typography.songTitle)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        ChartTypeBadge(isDX: record.type == MaimaiConstants.chartTypeDX, compact: true)
                    }

                    HStack(spacing: 7) {
                        DifficultyLevelBadge(
                            difficulty: diff,
                            text: String(format: "%.1f", record.ds)
                        )

                        Text(String(format: "%.4f%%", record.achievements))
                            .font(AppTheme.Typography.captionMetaBold)
                            .foregroundStyle(.primary)

                        Image(record.rankAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 16)

                        if let fc = record.fcAssetName {
                            Image(fc)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 18)
                        }
                        if let fs = record.fsAssetName {
                            Image(fs)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 18)
                        }

                        Spacer(minLength: 0)

                        Text("Ra \(record.computedRating)")
                            .font(AppTheme.Typography.captionMetaBold)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
        }
    }
}

private struct B50PreviewSheet: View {
    let image: UIImage

    var body: some View {
        PhotoPreviewScaffold(
            title: "Best 50 预览",
            image: image,
            accessibilityLabel: "Best50 成绩图，可双击或双指缩放预览",
            shareAccessibilityLabel: "分享 Best50 图片"
        ) {
            EmptyView()
        }
    }
}
