//
//  SAHandoverView.swift
//  luxury
//
//  Created by AI on 01/06/26.
//

import SwiftUI

struct SAHandoverView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = FulfillmentViewModel()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button(action: { router.pop() }) {
                        Image(systemName: "chevron.left")
                            .font(AppFonts.sansSerif(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.gold)
                    }
                    Text("Client Handover (SFS)")
                        .font(AppFonts.sansSerif(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.gold)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(AppColors.gold)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Text(errorMessage)
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.error)
                            .multilineTextAlignment(.center)
                        Button(action: { viewModel.fetchOrders() }) {
                            Text("Retry")
                                .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                .foregroundStyle(AppColors.background)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(AppColors.gold)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(24)
                    Spacer()
                } else {
                    // SA only cares about "Ready to Pick" for handover
                    let orders = viewModel.orders.filter { $0.status.lowercased() == "ready to pick" }
                    if orders.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "bag")
                                .font(AppFonts.sansSerif(size: 48))
                                .foregroundStyle(AppColors.tertiary)
                            Text("No Orders Ready for Handover")
                                .font(AppFonts.serif(size: 18, weight: .medium))
                                .foregroundStyle(AppColors.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(orders) { order in
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("ORDER ID: \(String(order.id.uuidString.prefix(8)).uppercased())")
                                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                                .foregroundStyle(AppColors.gold)
                                                .kerning(1)
                                            
                                            Spacer()
                                            
                                            Text(dateFormatter.string(from: order.reservedDate))
                                                .font(AppFonts.sansSerif(size: 11))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        
                                        Text(order.productName ?? "Premium Timepiece")
                                            .font(AppFonts.serif(size: 18, weight: .medium))
                                            .foregroundStyle(AppColors.text)
                                            .multilineTextAlignment(.leading)
                                        
                                        HStack {
                                            Text("SKU: \(order.productSku ?? "N/A")")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                            
                                            Spacer()
                                            
                                            StatusBadge(text: LocalizedStringKey("Ready for Pickup"), status: .success)
                                        }
                                        
                                        Button(action: {
                                            Task {
                                                // Assuming a qty of 1 for simplicity in handover UI, though real SFS can have varying qtys
                                                _ = await viewModel.dispatchOrder(order: order, expectedQty: 1, deliveredQty: 1)
                                            }
                                        }) {
                                            Text("Mark as Delivered")
                                                .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                                .foregroundStyle(AppColors.background)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(AppColors.gold)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        .padding(.top, 8)
                                    }
                                    .padding(16)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.gold15, lineWidth: 0.5)
                                    )
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.fetchOrders()
        }
    }
}
