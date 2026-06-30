//
//  ICCatalogDetailView.swift
//  luxury
//
//  Created for Inventory Controller
//

import SwiftUI

struct ICCatalogDetailView: View {
    let catalog: CatalogEntity
    let stockCount: Int
    
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(catalog.name)
                        .font(AppFonts.serif(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.text)
                    
                    HStack {
                        Text(catalog.brand)
                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.gold)
                            .kerning(1.5)
                        
                        Spacer()
                        
                        Text(LocalizedStringKey(catalog.status.rawValue)).textCase(.uppercase)
                            .font(AppFonts.sansSerif(size: 10, weight: .bold))
                            .foregroundStyle(statusTextColor(for: catalog.status))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusBackgroundColor(for: catalog.status))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Catalog Details") {
                LabeledContent("Catalog ID", value: catalog.catalogId)
                LabeledContent("Category", value: catalog.category.rawValue)
                LabeledContent("Description", value: catalog.description)
                LabeledContent("Local Stock", value: "\(stockCount)")
                LabeledContent("Amount", value: CurrencyManager.shared.format(amount: catalog.amount))
                LabeledContent("Barcode", value: catalog.barCode)
            }
            
            if let images = catalog.productImages, !images.isEmpty {
                Section("Product Images") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(images.enumerated()), id: \.offset) { _, url in
                                if let parsedURL = URL(string: url) {
                                    CachedAsyncImage(url: parsedURL) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        } else if phase.error != nil {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppColors.surface)
                                                .frame(width: 100, height: 100)
                                                .overlay(Image(systemName: "photo").foregroundStyle(AppColors.secondary))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppColors.surface)
                                                .frame(width: 100, height: 100)
                                                .overlay(ProgressView())
                                        }
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.surface)
                                        .frame(width: 100, height: 100)
                                        .overlay(Image(systemName: "photo").foregroundStyle(AppColors.secondary))
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Catalog Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
    
    private func statusTextColor(for status: CatalogStatus) -> Color {
        switch status {
        case .active: return AppColors.success
        case .paused: return AppColors.gold
        case .archived: return AppColors.error
        }
    }
    
    private func statusBackgroundColor(for status: CatalogStatus) -> Color {
        statusTextColor(for: status).opacity(0.1)
    }
}
