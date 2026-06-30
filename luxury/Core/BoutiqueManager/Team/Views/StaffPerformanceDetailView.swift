//
//  StaffPerformanceDetailView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct StaffPerformanceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let member: BMStaffMember
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(spacing: 16) {
                            ZStack {
                                if let avatarUrl = member.avatarUrl, let url = URL(string: avatarUrl) {
                                    CachedAsyncImage(url: url) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        AppColors.gold08
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppColors.gold50, lineWidth: 1))
                                } else {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(AppColors.gold08)
                                        .frame(width: 80, height: 80)
                                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppColors.gold50, lineWidth: 1))
                                    
                                    Text(member.initials)
                                        .font(AppFonts.serif(size: 32, weight: .semibold))
                                        .foregroundStyle(AppColors.gold)
                                }
                            }
                            
                            VStack(spacing: 4) {
                                Text(member.name)
                                    .font(AppFonts.serif(size: 28, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("Senior Client Advisor")
                                    .font(AppFonts.sansSerif(size: 14))
                                    .foregroundStyle(AppColors.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("PERFORMANCE INSIGHTS")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 16) {
                                MetricCard(title: "Revenue", value: member.rev, subtitle: "\(member.pct.formatted(.percent.precision(.fractionLength(0)))) of Target", icon: "chart.line.uptrend.xyaxis")
                                MetricCard(title: "Conversion", value: (0.32).formatted(.percent.precision(.fractionLength(0))), subtitle: "+\((0.04).formatted(.percent.precision(.fractionLength(0)))) vs Avg", icon: "person.2.fill")
                                MetricCard(title: "Clients", value: "\(member.clients)", subtitle: "Active Today", icon: "person.text.rectangle")
                                MetricCard(title: "ATV", value: "\(CurrencyManager.shared.symbol)42,500", subtitle: "Avg Transaction", icon: "cart.fill")
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        if let resumeUrl = member.resumeUrl, let url = URL(string: resumeUrl) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("RESUME")
                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                    .padding(.horizontal, 24)
                                
                                CachedAsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    HStack {
                                        Spacer()
                                        ProgressView().tint(AppColors.gold)
                                        Spacer()
                                    }
                                    .frame(height: 200)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("RECENT SALES")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 1) {
                                SaleRow(item: "Royal Oak 41mm", amount: "\(CurrencyManager.shared.symbol)3,45,000", time: "2h ago")
                                SaleRow(item: "Serpenti Bracelet", amount: "\(CurrencyManager.shared.symbol)1,20,000", time: "4h ago")
                                SaleRow(item: "Leather Tote Black", amount: "\(CurrencyManager.shared.symbol)85,000", time: "Yesterday")
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Team")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct SaleRow: View {
    let item: String
    let amount: String
    let time: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item)
                    .font(AppFonts.sansSerif(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(time)
                    .font(AppFonts.sansSerif(size: 11))
                    .foregroundStyle(AppColors.secondary)
            }
            Spacer()
            Text(amount)
                .font(AppFonts.serif(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.gold)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.surface)
    }
}
