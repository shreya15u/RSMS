//
//  CatalogsView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 21/05/26.
//

import SwiftUI

struct CatalogsView: View {
    @Environment(Router.self) private var router
    @Environment(CatalogsViewModel.self) private var viewModel
    
    var body: some View {
        @Bindable var bindableViewModel = viewModel
        
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    // Placeholder for alignment
                    Color.clear.frame(width: 44, height: 44)
                    
                    Spacer()
                    
                    Text("Catalogs")
                        .font(AppFonts.serif(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Add Button in top right
                    Button(action: {
                        router.push(CARoute.catalogForm(editCatalog: nil))
                    }) {
                        Image(systemName: "plus")
                            .font(AppFonts.sansSerif(size: 20))
                            .foregroundStyle(AppColors.gold)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.secondary)
                    TextField("Search catalog...", text: $bindableViewModel.searchText)
                        .font(AppFonts.sansSerif(size: 15))
                        .foregroundStyle(.white)
                        .tint(AppColors.gold)
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppColors.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(AppColors.gold)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    Text(errorMessage)
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button("Retry") {
                        viewModel.fetchData()
                    }
                    .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
                    .padding(.top, 16)
                    Spacer()
                } else if viewModel.filteredCatalogs.isEmpty {
                    Spacer()
                    Image(systemName: "box.truck.badge.clock.fill")
                        .font(AppFonts.sansSerif(size: 40))
                        .foregroundStyle(AppColors.secondary)
                        .padding(.bottom, 16)
                    Text(viewModel.searchText.isEmpty ? "No catalogs found." : "No matching catalogs.")
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.secondary)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredCatalogs) { catalog in
                                Button(action: {
                                    router.push(CARoute.catalogDetail(catalog))
                                }) {
                                    CatalogItemRow(catalog: catalog, availableStock: viewModel.stockLevels[catalog.id, default: 0])
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .refreshable {
                        viewModel.fetchData()
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.fetchData()
        }
    }
}

struct CatalogItemRow: View {
    let catalog: CatalogEntity
    let availableStock: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(catalog.name)
                        .font(AppFonts.serif(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                    Text(catalog.brand)
                        .font(AppFonts.sansSerif(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.gold)
                        .kerning(1.2)
                }
                
                Spacer()
                
                Text(CurrencyManager.shared.format(amount: catalog.amount))
                    .font(AppFonts.sansSerif(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.text)
            }
            
            Divider().background(AppColors.border)
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(AppFonts.sansSerif(size: 10))
                        .foregroundStyle(AppColors.secondary)
                    Text(LocalizedStringKey(catalog.category.rawValue))
                        .font(AppFonts.sansSerif(size: 12))
                        .foregroundStyle(AppColors.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "shippingbox.fill")
                        .font(AppFonts.sansSerif(size: 10))
                        .foregroundStyle(availableStock > 0 ? AppColors.success : AppColors.error)
                    Text("\(availableStock) in stock")
                        .font(AppFonts.sansSerif(size: 12, weight: .semibold))
                        .foregroundStyle(availableStock > 0 ? AppColors.success : AppColors.error)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.gold15, lineWidth: 1)
        )
    }
}
