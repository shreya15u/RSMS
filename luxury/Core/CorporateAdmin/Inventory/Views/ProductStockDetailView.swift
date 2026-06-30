//
//  ProductStockDetailView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 22/05/26.
//

import SwiftUI

struct ProductStockDetailView: View {
    let summary: ProductInventorySummary
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(summary.product.name)
                        .font(AppFonts.serif(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.text)
                    
                    HStack {
                        Text(summary.product.catalogId)
                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.gold)
                            .kerning(1.5)
                        
                        Spacer()
                        
                        Text(LocalizedStringKey(summary.alertStatus.rawValue)).textCase(.uppercase)
                            .font(AppFonts.sansSerif(size: 10, weight: .bold))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Global Summary") {
                LabeledContent("Total Units Available", value: "\(summary.totalQuantity)")
                LabeledContent("Total Locations with Stock", value: "\(summary.locations.filter { $0.quantity > 0 }.count)")
            }
            
            Section("Stock by Location") {
                if summary.locations.isEmpty {
                    Text("No inventory records found for this product.")
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.secondary)
                } else {
                    ForEach(summary.locations) { location in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(location.storeName)
                                    .font(AppFonts.sansSerif(size: 15, weight: .semibold))
                                    .foregroundStyle(AppColors.text)
                                
                                Text(location.isAvailable ? "Available for sale" : "Not available")
                                    .font(AppFonts.sansSerif(size: 11))
                                    .foregroundStyle(location.isAvailable ? AppColors.success : AppColors.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(location.quantity)")
                                    .font(AppFonts.sansSerif(size: 18, weight: .bold))
                                    .foregroundStyle(location.quantity > 0 ? AppColors.text : AppColors.error)
                                
                                Text("units")
                                    .font(AppFonts.sansSerif(size: 11))
                                    .foregroundStyle(AppColors.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Inventory Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
    
    private var statusColor: Color {
        switch summary.alertStatus {
        case .optimal: return AppColors.success
        case .lowStock: return AppColors.gold
        case .outOfStock: return AppColors.error
        }
    }
}
