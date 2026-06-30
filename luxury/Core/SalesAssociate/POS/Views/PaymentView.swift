//
//  PaymentView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct PaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Router.self) private var router
    @State private var selectedMethod: TenderMode = .card
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Payment")
                            .font(AppFonts.serif(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                        
                        VStack(spacing: 8) {
                            Text("TOTAL DUE")
                                .font(AppFonts.sansSerif(size: 11))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            Text(CurrencyManager.shared.format(amount: 1606179.0))
                                .font(AppFonts.serif(size: 40, weight: .semibold))
                                .foregroundStyle(AppColors.gold)
                                .kerning(-1)
                            
                            HStack(spacing: 7) {
                                Text("Unknown Client")
                                    .font(AppFonts.sansSerif(size: 11, weight: .medium))
                                    .foregroundStyle(AppColors.secondary)
                                StatusBadge(text: LocalizedStringKey("Platinum"), status: .success)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(AppColors.gold08)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.top, 2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        Text("PAYMENT METHOD")
                            .font(AppFonts.sansSerif(size: 10))
                            .foregroundStyle(AppColors.secondary)
                            .kerning(1.5)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10)
                        
                        HStack(spacing: 8) {
                            let methods: [TenderMode] = [.card, .upi, .split]
                            ForEach(methods, id: \.self) { method in
                                let isSelected = selectedMethod == method
                                Text(LocalizedStringKey(method.rawValue))
                                    .font(AppFonts.sansSerif(size: 12, weight: isSelected ? .medium : .light))
                                    .foregroundStyle(isSelected ? AppColors.background : AppColors.secondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(isSelected ? AppColors.gold : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.clear : AppColors.gold15, lineWidth: 0.5))
                                    .onTapGesture {
                                        withAnimation { selectedMethod = method }
                                    }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)
                        
                        VStack(spacing: 10) {
                            if selectedMethod == .card {
                                HStack {
                                    Text("XXXX  XXXX  XXXX  XXXX")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.tertiary)
                                        .kerning(3)
                                    Spacer()
                                    Image(systemName: "creditcard")
                                        .foregroundStyle(AppColors.tertiary)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                
                                HStack(spacing: 10) {
                                    Text("MM / YY")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.tertiary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 16)
                                        .frame(height: 50)
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                    
                                    Text("CVV")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.tertiary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 16)
                                        .frame(height: 50)
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                }
                                
                                Text("Cardholder Name")
                                    .font(AppFonts.sansSerif(size: 14))
                                    .foregroundStyle(AppColors.tertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .frame(height: 50)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                            } else if selectedMethod == .upi {
                                HStack {
                                    Text("UPI ID or Mobile Number")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.tertiary)
                                    Spacer()
                                    Text("Verify")
                                        .font(AppFonts.sansSerif(size: 11, weight: .medium))
                                        .foregroundStyle(AppColors.gold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(AppColors.gold08)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.gold15, lineWidth: 0.5))
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                            } else if selectedMethod == .split {
                                let splits = [("Credit Card", 1200000.0), ("Gift Voucher", 406179.0)]
                                ForEach(splits, id: \.0) { split in
                                    HStack {
                                        Text(split.0)
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.text)
                                        Spacer()
                                        Text(CurrencyManager.shared.format(amount: split.1))
                                            .font(AppFonts.serif(size: 15, weight: .semibold))
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 50)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
                
                VStack(spacing: 10) {
                    Divider().background(AppColors.gold15).padding(.bottom, 4)
                    
                    Button(action: {
                        router.push(SARoute.receipt)
                    }) {
                        Text("Process Payment · \(CurrencyManager.shared.format(amount: 1606179.0))")
                            .font(AppFonts.sansSerif(size: 15, weight: .medium))
                            .foregroundStyle(AppColors.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColors.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    
                    HStack(spacing: 5) {
                        Image(systemName: "lock.fill")
                            .font(AppFonts.sansSerif(size: 10))
                            .foregroundStyle(AppColors.tertiary)
                        Text("Secure payment authorization · PCI-DSS ready")
                            .font(AppFonts.sansSerif(size: 11))
                            .foregroundStyle(AppColors.tertiary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .background(AppColors.background)
            }
        }
        .navigationTitle("Cart")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
