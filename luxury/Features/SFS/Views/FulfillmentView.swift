//
//  FulfillmentView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 22/05/26.
//

import SwiftUI

struct FulfillmentView: View {
    @Environment(Router.self) private var router
    @Environment(FulfillmentViewModel.self) private var viewModel
    
    @State private var dispatchingOrder: PurchasedItemEntity? = nil
    
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
                CustomHeader(title: "SFS Orders", showBackButton: true, backAction: { router.pop() }, isInline: true)
                
                HStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.selectedSegment = 0
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text("NEW REQ")
                                .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                .foregroundStyle(viewModel.selectedSegment == 0 ? AppColors.gold : AppColors.secondary)
                            Rectangle()
                                .fill(viewModel.selectedSegment == 0 ? AppColors.gold : Color.clear)
                                .frame(height: 2)
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("New Requests Tab")
                    .accessibilityAddTraits(viewModel.selectedSegment == 0 ? [.isSelected] : [])
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.selectedSegment = 1
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text("DONE")
                                .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                .foregroundStyle(viewModel.selectedSegment == 1 ? AppColors.gold : AppColors.secondary)
                            Rectangle()
                                .fill(viewModel.selectedSegment == 1 ? AppColors.gold : Color.clear)
                                .frame(height: 2)
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Completed Orders Tab")
                    .accessibilityAddTraits(viewModel.selectedSegment == 1 ? [.isSelected] : [])
                }
                .padding(.top, 8)
                .background(AppColors.background)
                
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
                    let orders = viewModel.filteredOrders
                    if orders.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: viewModel.selectedSegment == 0 ? "shippingbox" : "checkmark.circle")
                                .font(AppFonts.sansSerif(size: 48))
                                .foregroundStyle(AppColors.tertiary)
                            Text(viewModel.selectedSegment == 0 ? "No Pending SFS Orders" : "No Completed SFS Orders")
                                .font(AppFonts.serif(size: 18, weight: .medium))
                                .foregroundStyle(AppColors.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(orders) { order in
                                    VStack(alignment: .leading, spacing: 12) {
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
                                                
                                                if order.status.lowercased() == "delivered" {
                                                    StatusBadge(text: LocalizedStringKey("Delivered"), status: .success)
                                                } else if order.status.lowercased() == "ready to pick" {
                                                    StatusBadge(text: LocalizedStringKey("Ready to Pick"), status: .success)
                                                } else if order.status.lowercased() == "secured" {
                                                    StatusBadge(text: LocalizedStringKey("Secured"), status: .neutral)
                                                } else {
                                                    StatusBadge(text: LocalizedStringKey("Pending"), status: .warning)
                                                }
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if order.status.lowercased() == "pending" {
                                                router.push(ICRoute.sfsVerification(order))
                                            }
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityAddTraits(order.status.lowercased() == "pending" ? [.isButton] : [])
                                        .accessibilityHint(order.status.lowercased() == "pending" ? "Double tap to verify order" : "")
                                        
                                        if order.status.lowercased() == "pending" {
                                            Button(action: {
                                                Task {
                                                    _ = await viewModel.updateStatusToReadyToPick(orderId: order.id)
                                                }
                                            }) {
                                                Text("Mark Ready to Pick")
                                                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                                    .foregroundStyle(AppColors.background)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 12)
                                                    .background(AppColors.gold)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            .padding(.top, 8)
                                        } else if order.status.lowercased() == "secured" {
                                            Button(action: {
                                                Task {
                                                    await viewModel.updateStatusToReadyToPick(orderId: order.id)
                                                }
                                            }) {
                                                Text("Mark Ready to Pick")
                                                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                                    .foregroundStyle(AppColors.background)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 12)
                                                    .background(AppColors.gold)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            .padding(.top, 8)
                                        } else if order.status.lowercased() == "ready to pick" {
                                            Button(action: {
                                                dispatchingOrder = order
                                            }) {
                                                Text("Confirm Dispatch & Delivery")
                                                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                                    .foregroundStyle(AppColors.background)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 12)
                                                    .background(AppColors.gold)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            .padding(.top, 8)
                                        }
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
        .sheet(item: $dispatchingOrder) { order in
            SFSDispatchView(order: order)
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium, .large])
                .environment(viewModel)
        }
    }
}
