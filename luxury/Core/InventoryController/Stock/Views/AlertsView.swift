//
//  AlertsView.swift
//  luxury
//
//  Created by Kaushiki Rai on 27/05/26.
//

import SwiftUI

struct AlertsView: View {
    @Environment(StockViewModel.self) private var viewModel
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Inventory Alerts", showBackButton: true, backAction: { dismiss() }, isInline: true)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if viewModel.alerts.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bell.slash")
                                    .font(AppFonts.sansSerif(size: 48))
                                    .foregroundStyle(AppColors.secondary)
                                Text("No pending alerts")
                                    .font(AppFonts.serif(size: 20, weight: .medium))
                                    .foregroundStyle(.white)
                                Text("All inventory levels are within normal limits.")
                                    .font(AppFonts.sansSerif(size: 14))
                                    .foregroundStyle(AppColors.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                            .padding(.horizontal, 24)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                        } else {
                            ForEach(viewModel.alerts) { alert in
                                Button(action: {
                                    router.push(ICRoute.stockDetail(alert))
                                }) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            StatusBadge(text: LocalizedStringKey(alert.urgency.rawValue), status: alert.status)
                                            Spacer()
                                            Text(alert.timeRaised)
                                                .font(AppFonts.sansSerif(size: 11))
                                                .foregroundStyle(AppColors.tertiary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(alert.itemName)
                                                .font(AppFonts.serif(size: 18, weight: .semibold))
                                                .foregroundStyle(AppColors.text)
                                                .multilineTextAlignment(.leading)
                                            Text("SKU: \(alert.sku)")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        
                                        HStack {
                                            Label(alert.location, systemImage: "mappin.and.ellipse")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                            Spacer()
                                            Button(action: {
                                                withAnimation {
                                                    viewModel.resolveAlert(alert)
                                                }
                                            }) {
                                                Text("Resolve")
                                                    .font(AppFonts.sansSerif(size: 12, weight: .bold))
                                                    .foregroundStyle(.black)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 6)
                                                    .background(AppColors.gold)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    .padding(16)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Inventory Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    let mockViewModel = StockViewModel()
    mockViewModel.alerts = [
        InventoryAlert(
            itemName: "Rolex Submariner Date 126610LN",
            sku: "RLX-126610",
            currentQty: 0,
            status: .error,
            location: "Vault Room A",
            alertType: "Out of Stock",
            timeRaised: "10 mins ago",
            urgency: .critical
        ),
        InventoryAlert(
            itemName: "Omega Seamaster 300M",
            sku: "OMG-300M",
            currentQty: 1,
            status: .warning,
            location: "Showcase C",
            alertType: "Low Stock",
            timeRaised: "1 hour ago",
            urgency: .warning
        )
    ]
    return AlertsView()
        .environment(mockViewModel)
        .environment(Router())
}
