//
//  SecuritySettingsView.swift
//  luxury
//

import SwiftUI
import Supabase

struct SecuritySettingsView: View {
    @State private var viewModel = SecuritySettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showMFAEnrollment = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        
                        // MARK: - Change Password
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CHANGE PASSWORD")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 16) {
                                SecureField("New Password", text: $viewModel.newPassword)
                                    .padding()
                                    .background(AppColors.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.border, lineWidth: 1))
                                
                                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                                    .padding()
                                    .background(AppColors.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.border, lineWidth: 1))
                                
                                Button(action: viewModel.changePassword) {
                                    if viewModel.isLoading {
                                        ProgressView().tint(AppColors.background)
                                    } else {
                                        Text("Update Password")
                                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty ? AppColors.secondary : AppColors.gold)
                                .foregroundStyle(AppColors.background)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .disabled(viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty || viewModel.isLoading)
                            }
                            .padding(16)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                        }
                        
                        // MARK: - MFA Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("TWO-FACTOR AUTHENTICATION")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 16) {
                                if viewModel.enrolledFactors.isEmpty {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Authenticator App")
                                                .font(AppFonts.sansSerif(size: 15, weight: .medium))
                                                .foregroundStyle(.white)
                                            Text("Not configured")
                                                .font(AppFonts.sansSerif(size: 13))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        Spacer()
                                    }
                                } else {
                                    ForEach(viewModel.enrolledFactors, id: \.id) { factor in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(factor.friendlyName ?? "Authenticator App")
                                                    .font(AppFonts.sansSerif(size: 15, weight: .medium))
                                                    .foregroundStyle(.white)
                                                Text("Enabled")
                                                    .font(AppFonts.sansSerif(size: 13))
                                                    .foregroundStyle(AppColors.success)
                                            }
                                            Spacer()
                                            
                                            Button("Remove") {
                                                viewModel.unenrollFactor(factorId: factor.id)
                                            }
                                            .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                            .foregroundStyle(AppColors.error)
                                        }
                                        if factor.id != viewModel.enrolledFactors.last?.id {
                                            Divider().background(AppColors.border)
                                        }
                                    }
                                }
                                
                                Divider().background(AppColors.border)
                                
                                Button(action: {
                                    showMFAEnrollment = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(AppFonts.sansSerif(size: 16))
                                            .foregroundStyle(AppColors.gold)
                                        Text("Add Device")
                                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                            .foregroundStyle(AppColors.gold)
                                        Spacer()
                                    }
                                }
                                .padding(.top, 8)
                            }
                            .padding(16)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.error)
                                .padding(.horizontal, 24)
                        }
                        if let success = viewModel.successMessage {
                            Text(success)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.success)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.checkMFAStatus()
        }
        .fullScreenCover(isPresented: $showMFAEnrollment, onDismiss: {
            viewModel.checkMFAStatus()
        }) {
            MFASetupView(isFromSettings: true)
        }
    }
}
