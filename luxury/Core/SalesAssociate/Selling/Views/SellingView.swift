//
//  SellingView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct SellingView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = SellingViewModel()

    var body: some View {
        VStack(spacing: 0) {
                header
                filters
                catalogGrid
            }
        .background(AppColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.fetchData() }
    }

    private var header: some View {
        HStack {
            Text("Catalog")
                .font(AppFonts.serif(size: 32, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 14)
    }

    private var filters: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").foregroundStyle(AppColors.tertiary)
                TextField("Search by name or SKU…", text: $viewModel.searchText)
                    .font(AppFonts.sansSerif(size: 14))
                    .foregroundStyle(AppColors.text)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryChip(title: "All", active: viewModel.selectedCategory == nil) {
                        viewModel.selectedCategory = nil
                    }
                    ForEach(viewModel.categories, id: \.self) { cat in
                        categoryChip(title: cat.rawValue, active: viewModel.selectedCategory == cat) {
                            viewModel.selectedCategory = cat
                        }
                    }
                }
            }
            .padding(.bottom, 4)

        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private func categoryChip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Text(title)
            .font(AppFonts.sansSerif(size: 11, weight: active ? .medium : .light))
            .foregroundStyle(active ? AppColors.background : AppColors.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(active ? AppColors.gold : Color.clear)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(active ? Color.clear : AppColors.gold15, lineWidth: 0.5))
            .onTapGesture { withAnimation { action() } }
    }

    private var catalogGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(viewModel.filteredCatalogs) { catalog in
                    let inStock = (viewModel.availableStock[catalog.id] ?? 0) > 0
                    Button(action: { router.push(SARoute.catalogDetail(catalog)) }) {
                        CatalogGridCard(catalog: catalog, inStock: inStock)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
        .refreshable {
            viewModel.fetchData()
        }
    }
}

private struct CatalogGridCard: View {
    let catalog: CatalogEntity
    let inStock: Bool

    private let imageHeight: CGFloat = 150
    private let textHeight:  CGFloat = 88

    private var firstURL: URL? {
        catalog.productImages?.first.flatMap { URL(string: $0) }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    AppColors.surface2
                    if let url = firstURL {
                        CachedAsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: w, height: imageHeight)
                                    .clipped()
                            case .empty:
                                ProgressView().tint(AppColors.gold)
                            default:
                                Image(systemName: "photo")
                                    .font(AppFonts.sansSerif(size: 28))
                                    .foregroundStyle(AppColors.gold.opacity(0.35))
                            }
                        }
                    } else {
                        Image(systemName: "photo")
                            .font(AppFonts.sansSerif(size: 28))
                            .foregroundStyle(AppColors.gold.opacity(0.35))
                    }
                }
                .frame(width: w, height: imageHeight)
                .clipped()

                VStack(alignment: .leading, spacing: 3) {
                    Text(catalog.brand.uppercased())
                        .font(AppFonts.sansSerif(size: 9, weight: .bold))
                        .foregroundStyle(AppColors.gold)
                        .kerning(1.5)
                        .lineLimit(1)
                    Text(catalog.name)
                        .font(AppFonts.serif(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(CurrencyManager.shared.format(amount: catalog.amount))
                        .font(AppFonts.serif(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.gold)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(inStock ? AppColors.success : AppColors.error)
                            .frame(width: 6, height: 6)
                        Text(inStock ? "In Stock" : "Out of Stock")
                            .font(AppFonts.sansSerif(size: 9))
                            .foregroundStyle(inStock ? AppColors.success : AppColors.error)
                            .lineLimit(1)
                    }
                }
                .padding(10)
                .frame(width: w, height: textHeight, alignment: .topLeading)
                .clipped()
            }
            .frame(width: w, height: imageHeight + textHeight)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
        }
        .frame(height: imageHeight + textHeight)
    }
}

#Preview {
    NavigationStack {
        SellingView()
    }
    .environment(Router())
}
