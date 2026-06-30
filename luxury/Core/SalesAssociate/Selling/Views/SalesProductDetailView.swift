//
//  ProductDetailView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct SalesProductDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SalesAssociateAppState.self) private var saAppState
    @Environment(Router.self) private var router
    let catalog: CatalogEntity
    var client: Client? = nil
    
    @State private var viewModel = SalesProductDetailViewModel()
    
    var inStock: Bool {
        viewModel.stockCount > 0
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ProductImageGalleryView(imageUrls: catalog.productImages)
                            .padding(.top, 10)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(catalog.brand.uppercased())
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                                .padding(.bottom, 6)
                            
                            Text(catalog.name)
                                .font(AppFonts.serif(size: 26, weight: .medium))
                                .foregroundStyle(AppColors.text)
                                .lineSpacing(4)
                                .padding(.bottom, 10)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(CurrencyManager.shared.format(amount: catalog.amount))
                                    .font(AppFonts.serif(size: 30, weight: .semibold))
                                    .foregroundStyle(AppColors.gold)
                                Text("incl. \((0.03).formatted(.percent)) GST")
                                    .font(AppFonts.sansSerif(size: 11))
                                    .foregroundStyle(AppColors.secondary)
                            }
                            .padding(.bottom, 14)
                            
                            HStack(spacing: 8) {
                                if viewModel.isStockLoading {
                                    ProgressView().tint(AppColors.gold)
                                } else {
                                    StatusBadge(text: inStock ? "● In Stock (\(viewModel.stockCount))" : "● Out of Stock", status: inStock ? .success : .warning)
                                }
                            }
                            .padding(.bottom, 16)
                            
                            if !catalog.description.isEmpty {
                                Text(catalog.description)
                                    .font(AppFonts.sansSerif(size: 13, weight: .light))
                                    .foregroundStyle(AppColors.secondary)
                                    .lineSpacing(6)
                                    .padding(.bottom, 20)
                            }
                            if viewModel.isLoadingRecommendations {
                                ProgressView().tint(AppColors.gold).padding(.bottom, 32)
                            } else if !viewModel.recommendations.isEmpty {
                                Text("OFTEN PAIRED WITH")
                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.8)
                                    .padding(.bottom, 11)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.recommendations) { rec in
                                            Button(action: { router.push(SARoute.catalogDetail(rec)) }) {
                                                RecommendationCard(catalog: rec)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(.bottom, 32)
                            }
                            
                            VStack(spacing: 0) {
                                Divider().background(AppColors.gold15).padding(.bottom, 12)
                                CustomButton(
                                    title: "Add to Cart",
                                    icon: AnyView(Image(systemName: "cart.badge.plus").font(AppFonts.sansSerif(size: 14, weight: .semibold))),
                                    action: { 
                                        let item = CatalogItem(
                                            id: catalog.id,
                                            catalogId: catalog.catalogId,
                                            name: catalog.name,
                                            description: catalog.description,
                                            brand: catalog.brand,
                                            category: catalog.category.rawValue,
                                            amount: catalog.amount,
                                            barCode: catalog.barCode,
                                            status: catalog.status.rawValue,
                                            createdAt: nil,
                                            productImages: catalog.productImages
                                        )
                                        if let attachedClient = client {
                                            let storeClient = StoreClient(
                                                id: attachedClient.id,
                                                name: attachedClient.name,
                                                email: attachedClient.email ?? "",
                                                phone: attachedClient.phone,
                                                dob: nil,
                                                tier: attachedClient.tier.rawValue,
                                                productsPurchased: nil,
                                                createdAt: attachedClient.createdAt,
                                                updatedAt: nil
                                            )
                                            POSViewModel.shared.attachClient(storeClient)
                                        }
                                        POSViewModel.shared.addToCart(item)
                                        saAppState.selectedTab = .pos
                                        dismiss()
                                    }
                                )
                                .padding(.bottom, 40)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                    }
                }
            }
        }
        .navigationTitle("Catalog")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.backward")
                        .font(AppFonts.sansSerif(size: 16, weight: .medium))
                        .foregroundStyle(AppColors.gold)
                }
            }
        }
        .onAppear {
            viewModel.fetchRecommendations(for: catalog)
        }
    }
}

struct RecommendationCard: View {
    let catalog: CatalogEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Rectangle().fill(AppColors.surface2).frame(height: 80)
                if let firstImage = catalog.productImages?.first, let url = URL(string: firstImage) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .empty:
                            ProgressView().tint(AppColors.gold)
                        default:
                            Image(systemName: "photo").foregroundStyle(AppColors.gold.opacity(0.35))
                        }
                    }
                    .frame(height: 80).clipped()
                } else {
                    Image(systemName: "photo").foregroundStyle(AppColors.gold.opacity(0.35))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(catalog.brand.uppercased())
                    .font(AppFonts.sansSerif(size: 9))
                    .foregroundStyle(AppColors.gold)
                    .kerning(1)
                    .lineLimit(1)
                Text(catalog.name)
                    .font(AppFonts.serif(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.text)
                    .lineLimit(1)
                Text(CurrencyManager.shared.format(amount: catalog.amount))
                    .font(AppFonts.serif(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .frame(width: 140)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.gold15, lineWidth: 0.5))
    }
}
