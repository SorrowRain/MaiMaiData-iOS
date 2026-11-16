import SwiftUI

struct CoverZoomView: View {
    @Environment(\.dismiss) private var dismiss
    let song: SongData

    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var saveStatus: String?
    @State private var showShare = false

    private var activeImage: UIImage? {
        loadedImage ?? CoverImageCache.shared.cachedMemoryImage(for: song)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Group {
                    if let img = activeImage {
                        ZoomableImageScrollView(image: img)
                            .padding(16)
                            .accessibilityLabel("\(song.title) 封面，可双击或双指缩放")
                    } else if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("正在加载曲绘…")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image("mmd_song_jacket_placeholder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Text("曲绘加载失败，请检查网络连接")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                }

                if let message = saveStatus {
                    VStack {
                        Spacer()
                        StatusToast(text: message)
                    }
                    .onAppear {
                        Task {
                            try? await Task.sleep(for: .seconds(2.5))
                            saveStatus = nil
                        }
                    }
                }
            }
            .navigationTitle(song.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if let img = activeImage {
                        Button {
                            showShare = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.white)
                        }
                        .accessibilityLabel("分享封面")

                        Button("保存") {
                            Task { await saveToPhotos(img) }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .accessibilityLabel("保存封面到相册")
                    }
                }
            }
            .task {
                if let cached = CoverImageCache.shared.cachedMemoryImage(for: song) {
                    loadedImage = cached
                } else if let fetched = await CoverImageCache.shared.loadCover(song: song) {
                    loadedImage = fetched
                }
                isLoading = false
            }
            .sheet(isPresented: $showShare) {
                if let img = activeImage {
                    ShareSheet(items: [img])
                }
            }
        }
    }

    private func saveToPhotos(_ image: UIImage) async {
        do {
            try await PhotoLibrarySaver.save(image)
            saveStatus = "曲绘已保存到相册"
        } catch {
            saveStatus = error.localizedDescription
        }
    }
}
