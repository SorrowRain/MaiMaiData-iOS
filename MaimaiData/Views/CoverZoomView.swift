import SwiftUI

/// Shared full-screen photo preview used by the cover zoom and Best50 preview sheets.
/// Owns the black backdrop, dark toolbar, share/save actions and save toast.
struct PhotoPreviewScaffold<Placeholder: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let image: UIImage?
    var imagePadding: CGFloat = AppTheme.Space.m
    var accessibilityLabel: String?
    var shareAccessibilityLabel: String = "分享图片"
    var saveAccessibilityLabel: String?

    @ViewBuilder let placeholder: () -> Placeholder

    @State private var saveStatus: String?
    @State private var showShare = false

    init(
        title: String,
        image: UIImage?,
        imagePadding: CGFloat = AppTheme.Space.m,
        accessibilityLabel: String? = nil,
        shareAccessibilityLabel: String = "分享图片",
        saveAccessibilityLabel: String? = nil,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.title = title
        self.image = image
        self.imagePadding = imagePadding
        self.accessibilityLabel = accessibilityLabel
        self.shareAccessibilityLabel = shareAccessibilityLabel
        self.saveAccessibilityLabel = saveAccessibilityLabel
        self.placeholder = placeholder
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image {
                    ZoomableImageScrollView(image: image)
                        .padding(imagePadding)
                        .accessibilityLabel(accessibilityLabel ?? title)
                } else {
                    placeholder()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if let image {
                        Button {
                            showShare = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.white)
                        }
                        .accessibilityLabel(shareAccessibilityLabel)

                        Button("保存") {
                            Task { await saveToPhotos(image) }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .accessibilityLabel(saveAccessibilityLabel ?? "保存")
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let saveStatus {
                    StatusToast(text: saveStatus)
                        .onAppear {
                            Task { await dismissToast($saveStatus, after: 2.5) }
                        }
                }
            }
            .sheet(isPresented: $showShare) {
                if let image {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    private func saveToPhotos(_ image: UIImage) async {
        do {
            try await PhotoLibrarySaver.save(image)
            saveStatus = "已保存到系统相册"
        } catch {
            saveStatus = error.localizedDescription
        }
    }
}

struct CoverZoomView: View {
    let song: SongData

    @State private var loadedImage: UIImage?
    @State private var isLoading = true

    private var activeImage: UIImage? {
        loadedImage ?? CoverImageCache.shared.cachedMemoryImage(for: song)
    }

    var body: some View {
        PhotoPreviewScaffold(
            title: song.title,
            image: activeImage,
            imagePadding: AppTheme.Space.l,
            accessibilityLabel: "\(song.title) 封面，可双击或双指缩放",
            shareAccessibilityLabel: "分享封面",
            saveAccessibilityLabel: "保存封面到相册"
        ) {
            coverPlaceholder
        }
        .task {
            if let cached = CoverImageCache.shared.cachedMemoryImage(for: song) {
                loadedImage = cached
            } else if let fetched = await CoverImageCache.shared.loadCover(song: song) {
                loadedImage = fetched
            }
            isLoading = false
        }
    }

    @ViewBuilder
    private var coverPlaceholder: some View {
        if isLoading {
            VStack(spacing: AppTheme.Space.m) {
                ProgressView()
                    .tint(.white)
                Text("正在加载曲绘…")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
        } else {
            VStack(spacing: AppTheme.Space.m) {
                Image("mmd_song_jacket_placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.chip, style: .continuous))
                Text("曲绘加载失败，请检查网络连接")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
    }
}
