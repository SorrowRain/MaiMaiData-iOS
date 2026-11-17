import SwiftUI

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
