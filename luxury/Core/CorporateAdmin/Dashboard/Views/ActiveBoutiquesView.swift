//
//  ActiveBoutiquesView.swift
//  luxury
//

import SwiftUI

struct ActiveBoutiquesView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = GlobalAnalyticsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeader(title: "Active Boutiques")
            
            if viewModel.isLoading && viewModel.boutiquePerformance.isEmpty {
                Spacer()
                ProgressView()
                    .tint(AppColors.gold)
                    .scaleEffect(1.5)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(viewModel.boutiquePerformance) { boutique in
                            Button(action: {
                                router.push(CARoute.boutiqueDetail(boutique))
                            }) {
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
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }
                .refreshable {
                    viewModel.fetchData()
                }
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            viewModel.fetchData()
        }
    }
}
