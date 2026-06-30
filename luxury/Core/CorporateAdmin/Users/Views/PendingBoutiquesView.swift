//
//  PendingBoutiquesView.swift
//  luxury
//
//  Created by Aditya Chauhan on 20/05/26.
//

import SwiftUI

struct PendingBoutiquesView: View {
    @Bindable var viewModel: UserManagementViewModel
    @Environment(Router.self) private var router
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Text("Pending Requests")
                        .font(AppFonts.serif(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView().tint(AppColors.gold)
                        Spacer()
                    } else if viewModel.pendingBoutiques.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray.fill")
                                .font(AppFonts.sansSerif(size: 40))
                                .foregroundStyle(AppColors.tertiary)
                            Text("No pending requests")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                ForEach(viewModel.pendingBoutiques) { boutique in
                                    Button(action: {
                                        router.push(CARoute.boutiqueDetail(boutique))
                                    }) {
                                        HStack(spacing: 16) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(boutique.name)
                                                    .font(AppFonts.serif(size: 18, weight: .medium))
                                                    .foregroundStyle(AppColors.text)
                                                Text("\(boutique.managerName) · \(boutique.managerPhone) · \(boutique.city)")
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
                        }
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.fetchData()
        }
    }
}
