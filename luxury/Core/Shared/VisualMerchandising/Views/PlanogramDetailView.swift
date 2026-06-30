import SwiftUI

struct PlanogramDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let planogram: PlanogramEntity
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(AppFonts.sansSerif(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.gold)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(planogram.title)
                            .font(AppFonts.sansSerif(size: 16, weight: .bold))
                            .foregroundStyle(AppColors.text)
                        if let desc = planogram.description {
                            Text(desc)
                                .font(AppFonts.sansSerif(size: 12))
                                .foregroundStyle(AppColors.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(AppColors.surface)
                .zIndex(1)
                
                GeometryReader { geo in
                    CachedAsyncImage(url: URL(string: planogram.fileUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .gesture(
                                MagnifyGesture()
                                    .onChanged { value in
                                        let delta = value.magnification / lastScale
                                        lastScale = value.magnification
                                        let newScale = scale * delta
                                        scale = min(max(newScale, 1), 5)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    }
                            )
                            .frame(width: geo.size.width, height: geo.size.height)
                    } placeholder: {
                        ProgressView().tint(AppColors.gold)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
                .clipped()
            }
        }
    }
}
