//
//  SFSDispatchView.swift
//  luxury
//
//  Created by Kaushiki Rai on 29/05/26.
//

import SwiftUI

struct SFSDispatchView: View {
    let order: PurchasedItemEntity
    @Environment(FulfillmentViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var expectedQty: Int = 3
    @State private var deliveredQty: Int = 3
    @State private var isSubmitting: Bool = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Confirm Dispatch")
                        .font(AppFonts.serif(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColors.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ORDER DETAILS")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Order ID")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                    Spacer()
                                    Text(order.id.uuidString.prefix(8).uppercased())
                                        .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                
                                Divider().background(AppColors.border)
                                
                                HStack {
                                    Text("Product")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                    Spacer()
                                    Text(order.productName ?? "Premium Timepiece")
                                        .font(AppFonts.serif(size: 15, weight: .medium))
                                        .foregroundStyle(AppColors.text)
                                        .multilineTextAlignment(.trailing)
                                }
                                
                                Divider().background(AppColors.border)
                                
                                HStack {
                                    Text("SKU")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                    Spacer()
                                    Text(order.productSku ?? "N/A")
                                        .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                                        .foregroundStyle(AppColors.gold)
                                }
                            }
                            .padding(20)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("DELIVERY QUANTITY CONFIGURATION")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            VStack(spacing: 20) {
                                HStack {
                                    Text("Expected Qty")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.text)
                                    Spacer()
                                    Stepper("\(expectedQty)", value: $expectedQty, in: 1...10)
                                        .font(AppFonts.sansSerif(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                        .onChange(of: expectedQty) { _, newValue in
                                            if deliveredQty > newValue {
                                                deliveredQty = newValue
                                            }
                                        }
                                }
                                
                                Divider().background(AppColors.border)
                                
                                HStack {
                                    Text("Delivered Qty")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.text)
                                    Spacer()
                                    Stepper("\(deliveredQty)", value: $deliveredQty, in: 0...expectedQty)
                                        .font(AppFonts.sansSerif(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(20)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DISPATCH IMPACT SUMMARY")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(AppColors.error)
                                    Text("Deduct \(deliveredQty) units from stock levels immediately")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.text)
                                }
                                
                                if expectedQty > deliveredQty {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise.circle.fill")
                                            .foregroundStyle(AppColors.success)
                                        Text("Release \(expectedQty - deliveredQty) units back to available stock")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.text)
                                    }
                                }
                            }
                            .padding(20)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                        }
                        
                        CustomButton(
                            title: "Confirm Dispatch & Update Stock",
                            isLoading: isSubmitting
                        ) {
                            submitDispatch()
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    private func submitDispatch() {
        isSubmitting = true
        Task {
            let success = await viewModel.dispatchOrder(
                order: order,
                expectedQty: expectedQty,
                deliveredQty: deliveredQty
            )
            
            await MainActor.run {
                isSubmitting = false
                if success {
                    dismiss()
                }
            }
        }
    }
}
