//
//  StockDetailView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct StockDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StockViewModel.self) private var viewModel
    let alert: InventoryAlert
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Inventory Details", showBackButton: true, backAction: { dismiss() }, isInline: true)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(alert.itemName)
                                .font(AppFonts.serif(size: 32, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineSpacing(4)
                            
                            Text(alert.sku)
                                .font(AppFonts.sansSerif(size: 12))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                            
                            StatusBadge(text: alert.currentQty == 0 ? LocalizedStringKey("Out of Stock") : LocalizedStringKey("\(alert.currentQty) In Boutique"), status: alert.status)
                                .padding(.top, 4)
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 1) {
                            DetailInfoRow(label: "Available", value: "\(alert.currentQty)")
                            DetailInfoRow(label: "Location", value: alert.location)
                            DetailInfoRow(label: "Alert Type", value: alert.alertType)
                            DetailInfoRow(label: "Time Raised", value: alert.timeRaised)
                            DetailInfoRow(label: "Urgency", value: alert.urgency.rawValue)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("RECENT MOVEMENTS")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 1) {
                                MovementRow(type: "Sale", qty: "-1", date: "Today, 11:45 AM")
                                MovementRow(type: "Transfer In", qty: "+12", date: "Yesterday, 04:20 PM")
                                MovementRow(type: "Count Adjustment", qty: "-2", date: "12 May 2026")
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                if viewModel.alerts.contains(where: { $0.id == alert.id }) {
                    VStack {
                        CustomButton(title: "Resolve Alert", icon: AnyView(Image(systemName: "checkmark.circle")), action: {
                            withAnimation {
                                viewModel.resolveAlert(alert)
                            }
                            dismiss()
                        })
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    .background(AppColors.background)
                }
            }
        }
        .navigationTitle("Inventory Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct DetailInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppFonts.sansSerif(size: 13))
                .foregroundStyle(AppColors.secondary)
            Spacer()
            Text(value)
                .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.surface)
    }
}

private struct MovementRow: View {
    let type: String
    let qty: String
    let date: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(type)
                    .font(AppFonts.sansSerif(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(date)
                    .font(AppFonts.sansSerif(size: 12))
                    .foregroundStyle(AppColors.tertiary)
            }
            Spacer()
            Text(qty)
                .font(AppFonts.serif(size: 18, weight: .bold))
                .foregroundStyle(qty.hasPrefix("+") ? AppColors.success : AppColors.error)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.surface)
    }
}

#Preview {
    StockDetailView(alert: InventoryAlert(
        itemName: "Rolex Submariner Date 126610LN",
        sku: "RLX-126610",
        currentQty: 0,
        status: .error,
        location: "Vault Room A",
        alertType: "Out of Stock",
        timeRaised: "10 mins ago",
        urgency: .critical
    ))
    .environment(StockViewModel())
}
