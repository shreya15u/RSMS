//
//  CorporateAdminSettingsView.swift
//  luxury
//
//  Created by Aditya Chauhan on 25/05/26.
//

import SwiftUI

struct CorporateAdminSettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var currencyManager = CurrencyManager.shared
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    CustomHeader(title: "Settings")
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            
                            // MARK: - Security
                            VStack(alignment: .leading, spacing: 16) {
                                Text("SECURITY")
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                    .padding(.horizontal, 24)
                                
                                NavigationLink(destination: SecuritySettingsView()) {
                                    HStack {
                                        Image(systemName: "lock.shield.fill")
                                            .font(AppFonts.sansSerif(size: 18))
                                            .foregroundStyle(AppColors.gold)
                                        Text("Security Settings")
                                            .font(AppFonts.sansSerif(size: 15))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(AppFonts.sansSerif(size: 12))
                                            .foregroundStyle(AppColors.tertiary)
                                    }
                                    .padding(16)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 24)
                            }
                            
                            // MARK: - Preferences
                            VStack(alignment: .leading, spacing: 16) {
                                Text("PREFERENCES")
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("Global Currency")
                                            .font(AppFonts.sansSerif(size: 14))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Picker("Currency", selection: $currencyManager.currentCurrency) {
                                            ForEach(currencyManager.availableCurrencies, id: \.self) { code in
                                                Text("\(code) (\(currencyManager.symbol(for: code)))").tag(code)
                                            }
                                        }
                                        .tint(AppColors.gold)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                .padding(.horizontal, 24)
                            }
                            
                            CustomButton(title: "Logout", action: { showLogoutAlert = true })
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 24)
                    }
                }
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Logout", role: .destructive) {
                    coordinator.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}
