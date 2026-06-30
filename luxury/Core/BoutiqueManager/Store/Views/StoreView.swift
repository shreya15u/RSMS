//
//  StoreView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct StoreView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = StoreViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Store Operations")
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("PENDING APPROVALS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                Button(action: { router.presentFullScreen(BMRoute.transferApproval) }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Stock Transfers")
                                                .font(AppFonts.serif(size: 18, weight: .medium))
                                                .foregroundStyle(.white)
                                            Text("\(viewModel.pendingTransfersCount) Requests awaiting approval")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    .padding(20)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { router.push(BMRoute.endlessAisleRequests) }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Endless Aisle Requests")
                                                .font(AppFonts.serif(size: 18, weight: .medium))
                                                .foregroundStyle(.white)
                                            Text("Review and authorize boutique transfers")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    .padding(20)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { router.push(BMRoute.cycleCountSignoff) }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Inventory Audit Approval")
                                                .font(AppFonts.serif(size: 18, weight: .medium))
                                                .foregroundStyle(.white)
                                            Text("\(viewModel.pendingCycleCountsCount) Audit ready for review")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    .padding(20)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    if let bId = viewModel.boutiqueId {
                                        router.push(BMRoute.planogramGallery(boutiqueId: bId))
                                    } else {
                                        // Fallback if not loaded
                                        router.push(BMRoute.planogramGallery(boutiqueId: UUID()))
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Visual Merchandising")
                                                .font(AppFonts.serif(size: 18, weight: .medium))
                                                .foregroundStyle(.white)
                                            Text("View active store planograms")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    .padding(20)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 24)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text("INVENTORY CONTROLS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)

                            VStack(spacing: 12) {
                                Button(action: { router.push(BMRoute.stockReconciliation) }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Stock Reconciliation")
                                                .font(AppFonts.serif(size: 18, weight: .medium))
                                                .foregroundStyle(.white)
                                            Text("Scan barcodes or QR codes to resolve quantity mismatches")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    .padding(20)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        if !viewModel.activeCampaigns.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("ACTIVE CAMPAIGNS")
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                    .padding(.horizontal, 24)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.activeCampaigns) { campaign in
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(campaign.title)
                                                    .font(AppFonts.serif(size: 16, weight: .medium))
                                                    .foregroundStyle(.white)
                                                    .lineLimit(1)
                                                
                                                HStack {
                                                    Text(campaign.boutique)
                                                        .font(AppFonts.sansSerif(size: 12))
                                                        .foregroundStyle(AppColors.secondary)
                                                    Spacer()
                                                    Text((campaign.discountPercentage / 100).formatted(.percent))
                                                        .font(AppFonts.sansSerif(size: 13, weight: .semibold))
                                                        .foregroundStyle(AppColors.gold)
                                                }
                                            }
                                            .padding(16)
                                            .frame(width: 220)
                                            .background(AppColors.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }

                    }
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            viewModel.loadLocalEvents()
            viewModel.fetchPendingTransfersCount()
            Task {
                await viewModel.fetchActiveCampaigns()
                await viewModel.fetchPendingAuditsCount()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
