//
//  BoutiqueConfigView.swift
//  luxury
//
//  Created by Aditya Chauhan on 18/05/26.
//

import SwiftUI

struct BoutiqueConfigView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = BoutiqueConfigViewModel()
    
    var body: some View {
        @Bindable var vm = viewModel
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Boutique Config")
                
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.tertiary)
                        
                        TextField("Search boutiques…", text: $vm.searchText)
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.text)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.gold15, lineWidth: 0.5)
                    )
                    .padding(.horizontal, 24)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(viewModel.filteredBoutiques) { boutique in
                                Button(action: { router.push(CARoute.boutiqueConfigDetail(boutique)) }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(boutique.name)
                                                .font(AppFonts.serif(size: 17, weight: .medium))
                                                .foregroundStyle(.white)
                                            Text("\(boutique.city) · \(boutique.managerName)")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(AppFonts.sansSerif(size: 12))
                                            .foregroundStyle(AppColors.tertiary)
                                    }
                                    .padding(18)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
                .padding(.top, 20)
            }
        }
    }
}

struct BoutiqueConfigDetailView: View {
    @Environment(Router.self) private var router
    @State private var boutique: CorporateBoutique
    var onUpdate: (CorporateBoutique) -> Void
    
    init(boutique: CorporateBoutique, onUpdate: @escaping (CorporateBoutique) -> Void) {
        _boutique = State(initialValue: boutique)
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 16) {

                    Text("Configuration")
                        .font(AppFonts.serif(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(boutique.name)
                                .font(AppFonts.serif(size: 32, weight: .bold))
                                .foregroundStyle(AppColors.gold)
                            Text("\(boutique.city) · \(boutique.managerName)")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.secondary)
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CONTACT INFORMATION")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                InfoRow(label: "Manager Email", value: boutique.managerEmail)
                                InfoRow(label: "Manager Phone", value: boutique.managerPhone)
                                InfoRow(label: "Address", value: boutique.address)
                            }
                            .padding(20)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("OPERATIONAL LIMITS")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                LimitRow(label: "Max SA Discount", value: (0.10).formatted(.percent.precision(.fractionLength(0))))
                                LimitRow(label: "Refund Threshold", value: CurrencyManager.shared.format(amount: 50000))
                                LimitRow(label: "Write-off Limit", value: CurrencyManager.shared.format(amount: 25000))
                            }
                            .padding(20)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                        }
                        
                        CustomButton(title: "Return", action: {
                            router.pop()
                        })
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(AppFonts.sansSerif(size: 9, weight: .bold))
                .foregroundStyle(AppColors.secondary)
                .kerning(1)
            Text(value)
                .font(AppFonts.sansSerif(size: 14))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LimitRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppFonts.sansSerif(size: 13))
                .foregroundStyle(AppColors.secondary)
            Spacer()
            Text(value)
                .font(AppFonts.serif(size: 15, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}
