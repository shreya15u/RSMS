//
//  ProductSelectionSheet.swift
//  luxury
//
//  Created by Nalinish Ranjan on 25/05/26.
//

import SwiftUI

struct ProductSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: RFIDViewModel
    let onSelect: (CatalogEntity) -> Void
    
    @State private var searchText = ""
    
    var filteredCatalogs: [CatalogEntity] {
        if searchText.isEmpty {
            return viewModel.catalogs
        } else {
            return viewModel.catalogs.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText) ||
                $0.catalogId.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    CustomHeader(title: "Select Product", showBackButton: true, backAction: { dismiss() }, isInline: true)
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.tertiary)
                        TextField("Search products...", text: $searchText)
                            .foregroundStyle(AppColors.text)
                            .tint(AppColors.gold)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppColors.tertiary)
                            }
                        }
                    }
                    .padding(12)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(AppColors.gold)
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        Spacer()
                        Text(error)
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.error)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    } else if filteredCatalogs.isEmpty {
                        Spacer()
                        Text("No products found")
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.secondary)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredCatalogs) { catalog in
                                    Button(action: {
                                        dismiss()
                                        onSelect(catalog)
                                    }) {
                                        HStack(spacing: 16) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(catalog.brand.uppercased())
                                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                                    .foregroundStyle(AppColors.gold)
                                                    .kerning(1.2)
                                                
                                                Text(catalog.name)
                                                    .font(AppFonts.serif(size: 16, weight: .medium))
                                                    .foregroundStyle(AppColors.text)
                                                    .lineLimit(1)
                                                
                                                Text("ID: \(catalog.catalogId)")
                                                    .font(AppFonts.sansSerif(size: 12))
                                                    .foregroundStyle(AppColors.tertiary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(AppColors.tertiary)
                                                .font(AppFonts.sansSerif(size: 14))
                                        }
                                        .padding(16)
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppColors.surface2, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .onAppear {
                if viewModel.catalogs.isEmpty {
                    viewModel.fetchCatalogs()
                }
            }
        }
    }
}
