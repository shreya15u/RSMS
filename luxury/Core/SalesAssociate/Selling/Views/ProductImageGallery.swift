//
//  ProductImageGallery.swift
//  luxury
//
//  Created by Kaushiki Rai on 25/05/26.
//

import SwiftUI

struct ProductImageGalleryView: View {
    let imageUrls: [String]?

    @State private var currentIndex = 0

    private var urls: [URL] {
        (imageUrls ?? []).filter { !$0.isEmpty }.compactMap { URL(string: $0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if urls.isEmpty {
                emptyState
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                        ZoomableImageView(url: url).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 300)
                .background(AppColors.surface)
                .onAppear {
                    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(AppColors.gold)
                    UIPageControl.appearance().pageIndicatorTintColor = UIColor(AppColors.gold).withAlphaComponent(0.3)
                }
            }
        }
    }

    private var emptyState: some View {
        ZStack {
            Rectangle().fill(AppColors.surface).frame(height: 300)
            VStack(spacing: 10) {
                Image(systemName: "photo")
                    .font(AppFonts.sansSerif(size: 28))
                    .foregroundStyle(AppColors.gold.opacity(0.4))
                Text("NO IMAGE")
                    .font(AppFonts.sansSerif(size: 10))
                    .foregroundStyle(AppColors.tertiary)
                    .kerning(2)
            }
        }
    }
}

struct ZoomableImageView: View {
    let url: URL

    @State private var scale:      CGFloat = 1.0
    @State private var lastScale:  CGFloat = 1.0
    @State private var offset:     CGSize  = .zero
    @State private var lastOffset: CGSize  = .zero

    private let maxScale: CGFloat = 4.0
    private let minScale: CGFloat = 1.0

    var body: some View {
        CachedAsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Rectangle().fill(AppColors.surface2)
                    ProgressView().progressViewStyle(.circular).tint(AppColors.gold).scaleEffect(1.2)
                }
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { newScale in 
                                let proposedScale = lastScale * newScale
                                scale = min(max(proposedScale, minScale), maxScale) 
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale <= minScale { resetZoom() }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: scale > 1.0 ? 0 : 10000)
                            .onChanged { value in
                                guard scale > 1.0 else { return }
                                offset = CGSize(
                                    width:  lastOffset.width  + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                guard scale > 1.0 else { return }
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(duration: 0.35)) {
                            if scale > 1.0 { resetZoom() } else { scale = 2.5; lastScale = 2.5 }
                        }
                    }
            case .failure:
                ZStack {
                    Rectangle().fill(AppColors.surface2)
                    Image(systemName: "photo")
                        .font(AppFonts.sansSerif(size: 28))
                        .foregroundStyle(AppColors.gold.opacity(0.4))
                }
            @unknown default:
                EmptyView()
            }
        }
        .frame(height: 300)
        .clipped()
    }

    private func resetZoom() {
        scale = minScale; lastScale = minScale; offset = .zero; lastOffset = .zero
    }
}
