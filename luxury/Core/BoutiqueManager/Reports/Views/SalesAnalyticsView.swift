//
//  SalesAnalyticsView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct SalesAnalyticsView: View {
    @State private var viewModel = SalesAnalyticsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                MetricCard(title: "Today's Sales", value: viewModel.todaySales, subtitle: "Target: \(viewModel.todayTarget)", icon: "indianrupeesign")
                                MetricCard(title: "WTD Sales", value: viewModel.wtdSales, subtitle: "Week to Date", icon: "calendar")
                            }
                            HStack(spacing: 12) {
                                MetricCard(title: "MTD Sales", value: viewModel.mtdSales, subtitle: "Month to Date", icon: "calendar.badge.clock")
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("REVENUE BY CATEGORY")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.categories, id: \.id) { category in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(category.name)
                                                .font(AppFonts.serif(size: 17, weight: .medium))
                                                .foregroundStyle(.white)
                                            Text("\(category.percentage, format: .percent.precision(.fractionLength(0))) of Total Revenue")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        Spacer()
                                        Text(category.revenue)
                                            .font(AppFonts.sansSerif(size: 15, weight: .bold))
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
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Sales Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.fetchData()
        }
    }
}
