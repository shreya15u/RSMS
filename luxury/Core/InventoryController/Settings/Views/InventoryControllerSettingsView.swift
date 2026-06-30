//
//  InventoryControllerSettingsView.swift
//  luxury
//

import SwiftUI

struct InventoryControllerSettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
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
                            
                            CustomButton(title: "Logout", action: { showLogoutAlert = true })
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 24)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.gold)
                    .font(AppFonts.sansSerif(size: 16))
                }
            }
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
