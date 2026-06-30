//
//  PurchaseOrdersView.swift
//  luxury
//
//  Created by Kaushiki Rai on 29/05/26.
//

import SwiftUI

struct PurchaseOrdersView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = ReceivingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Purchase Orders", showBackButton: true, backAction: { dismiss() }, isInline: true)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(AppColors.gold)
                        .scaleEffect(1.2)
                    Spacer()
                } else if viewModel.purchaseOrders.isEmpty {
                    Spacer()
                    Text("No Purchase Orders Found")
                        .font(AppFonts.sansSerif(size: 16))
                        .foregroundStyle(AppColors.secondary)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(viewModel.purchaseOrders) { po in
                                Button(action: {
                                    router.push(ICRoute.poDetail(po))
                                }) {
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(po.poNumber)
                                                .font(AppFonts.serif(size: 18, weight: .semibold))
                                                .foregroundStyle(AppColors.text)
                                            
                                            Text(po.supplier)
                                                .font(AppFonts.sansSerif(size: 13))
                                                .foregroundStyle(AppColors.secondary)
                                            
                                            Text("\(po.items.count) Items expected")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.tertiary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 8) {
                                            StatusBadge(
                                                text: LocalizedStringKey(po.status.rawValue),
                                                status: po.status == .fullyReceived ? .success : .warning
                                            )
                                            
                                            Text(po.createdAt, style: .date)
                                                .font(AppFonts.sansSerif(size: 11))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                    }
                                    .padding(20)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppColors.gold15, lineWidth: po.status == .fullyReceived ? 1 : 0)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .navigationTitle("Purchase Orders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.loadPurchaseOrders()
        }
    }
}

#Preview {
    PurchaseOrdersView()
        .environment(Router())
}
