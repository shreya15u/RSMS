//
//  ShrinkReportView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct ShrinkReportView: View {
    @State private var viewModel = ShrinkReportViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        @Bindable var bindableViewModel = viewModel
        
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // KPI Summary
                let columns = [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ]
                LazyVGrid(columns: columns, spacing: 16) {
                    InventoryKPIBox(
                        title: "Total Units",
                        value: "\(viewModel.totalItemsCount)",
                        icon: "cube.box.fill",
                        color: AppColors.text
                    )
                    
                    InventoryKPIBox(
                        title: "Total Value",
                        value: CurrencyManager.shared.formatCompact(amount: viewModel.totalInventoryValue),
                        icon: "shippingbox.fill",
                        color: AppColors.gold
                    )
                    
                    InventoryKPIBox(
                        title: "Low Stock",
                        value: "\(viewModel.lowStockCount)",
                        icon: "exclamationmark.triangle.fill",
                        color: AppColors.gold
                    )
                    
                    InventoryKPIBox(
                        title: "Out of Stock",
                        value: "\(viewModel.outOfStockCount)",
                        icon: "xmark.octagon.fill",
                        color: AppColors.error
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Search & Filter Bar
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.secondary)
                        TextField("Search by SKU or Name...", text: $bindableViewModel.searchText)
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
                    .frame(height: 48)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Filter Menu
                    Menu {
                        Button("All", action: { bindableViewModel.filterStatus = nil })
                        ForEach(StockAlertStatus.allCases, id: \.self) { status in
                            Button(status.rawValue) {
                                bindableViewModel.filterStatus = status
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(AppFonts.sansSerif(size: 20))
                            .foregroundStyle(viewModel.filterStatus == nil ? AppColors.secondary : AppColors.gold)
                            .frame(width: 48, height: 48)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Content
                if viewModel.isLoading && viewModel.summaries.isEmpty {
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
                        viewModel.fetchInventory()
                    }
                    .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
                    .padding(.top, 16)
                    Spacer()
                } else if viewModel.filteredSummaries.isEmpty {
                    Spacer()
                    Image(systemName: "shippingbox.fill")
                        .font(AppFonts.sansSerif(size: 40))
                        .foregroundStyle(AppColors.secondary)
                        .padding(.bottom, 16)
                    Text("No inventory records found.")
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.secondary)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredSummaries) { summary in
                                InventorySummaryRow(summary: summary)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .refreshable {
                        viewModel.fetchInventory()
                    }
                }
            }
        }
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.fetchInventory()
        }
    }
}

private struct InventoryKPIBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(AppFonts.sansSerif(size: 14))
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(AppFonts.sansSerif(size: 24, weight: .bold))
                .foregroundStyle(AppColors.text)
            
            Text(title)
                .font(AppFonts.sansSerif(size: 11, weight: .medium))
                .foregroundStyle(AppColors.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.gold15, lineWidth: 1)
        )
    }
}

private struct InventorySummaryRow: View {
    let summary: ProductInventorySummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.product.name)
                        .font(AppFonts.serif(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                    Text("\(summary.product.catalogId) • \(summary.product.brand)")
                        .font(AppFonts.sansSerif(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.gold)
                        .kerning(1.2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(summary.totalQuantity)")
                        .font(AppFonts.sansSerif(size: 20, weight: .bold))
                        .foregroundStyle(statusColor)
                    
                    Text(LocalizedStringKey(summary.alertStatus.rawValue))
                        .font(AppFonts.sansSerif(size: 10, weight: .bold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(summary.alertStatus == .optimal ? AppColors.gold15 : statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        switch summary.alertStatus {
        case .optimal: return AppColors.success
        case .lowStock: return AppColors.gold
        case .outOfStock: return AppColors.error
        }
    }
}
