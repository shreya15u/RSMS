//
//  StaffPerformanceReportView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct StaffPerformanceReportView: View {
    @State private var viewModel = StaffPerformanceViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("INDIVIDUAL METRICS")
                            .font(AppFonts.sansSerif(size: 11, weight: .bold))
                            .foregroundStyle(AppColors.secondary)
                            .kerning(1.5)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.staffMetrics, id: \.id) { metric in
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(metric.name)
                                            .font(AppFonts.serif(size: 18, weight: .medium))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text(metric.commission)
                                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    
                                    HStack(spacing: 24) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("CONVERSION")
                                                .font(AppFonts.sansSerif(size: 8, weight: .bold))
                                                .foregroundStyle(AppColors.tertiary)
                                            Text(metric.conversion)
                                                .font(AppFonts.sansSerif(size: 13, weight: .semibold))
                                                .foregroundStyle(.white)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("INTERACTIONS")
                                                .font(AppFonts.sansSerif(size: 8, weight: .bold))
                                                .foregroundStyle(AppColors.tertiary)
                                            Text("\(metric.interactions)")
                                                .font(AppFonts.sansSerif(size: 13, weight: .semibold))
                                                .foregroundStyle(.white)
                                        }
                                        Spacer()
                                    }
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
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Staff Performance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.fetchData()
        }
    }
}
