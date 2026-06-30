//
//  ClientInsightsView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct ClientInsightsView: View {
    @State private var viewModel = ClientInsightsViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(Router.self) private var router
    
    var onDirectoryTap: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        HStack(spacing: 12) {
                            Button(action: {
                                onDirectoryTap?()
                            }) {
                                MetricCard(title: "Total Clients", value: "\(viewModel.totalClients)", subtitle: "Active Profiles", icon: "person.2.fill")
                            }
                            .buttonStyle(.plain)
                            MetricCard(title: "Avg Lifetime Value", value: viewModel.avgLTV, subtitle: "Per Client Average", icon: "chart.line.uptrend.xyaxis")
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("TIER BREAKDOWN")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.tierBreakdown, id: \.id) { metric in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(metric.tier)
                                                .font(AppFonts.serif(size: 18, weight: .medium))
                                                .foregroundStyle(.white)
                                            Text("\(metric.count) Clients")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        Spacer()
                                        Text(metric.revenue)
                                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    .padding(20)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppColors.gold15, lineWidth: 0.5)
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.top, 12)
                    

                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .navigationTitle("Client Insights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            viewModel.fetchData()
        }
    }
}
