//
//  ForgotPasswordView.swift
//  luxury
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var viewModel = ForgotPasswordViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Recover Password")
                        .font(AppFonts.serif(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(subtitleForStep(viewModel.step))
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)
                
                VStack(spacing: 24) {
                    switch viewModel.step {
                    case .email:
                        CustomTextField(title: "EMAIL ADDRESS", placeholder: "Email address", text: $viewModel.email, keyboardType: .emailAddress)
                        
                        CustomButton(title: "Send OTP", isLoading: viewModel.isLoading) {
                            viewModel.sendResetEmail()
                        }
                        
                    case .otp:
                        CustomTextField(title: "OTP CODE", placeholder: "Enter 6-digit OTP", text: $viewModel.otp, keyboardType: .numberPad)
                        
                        CustomButton(title: "Verify OTP", isLoading: viewModel.isLoading) {
                            viewModel.verifyOTP()
                        }
                        
                    case .newPassword:
                        CustomSecureField(title: "NEW PASSWORD", placeholder: "New Password", text: $viewModel.newPassword)
                        
                        CustomSecureField(title: "CONFIRM PASSWORD", placeholder: "Confirm Password", text: $viewModel.confirmPassword)
                        
                        CustomButton(title: "Update Password", isLoading: viewModel.isLoading) {
                            viewModel.updatePassword()
                        }
                        
                    case .complete:
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(AppFonts.sansSerif(size: 64))
                                .foregroundStyle(AppColors.success)
                            
                            Text("Password successfully updated. You can now log in.")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        CustomButton(title: "Back to Login", action: { dismiss() })
                    }
                }
                .padding(.horizontal, 24)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                if viewModel.step != .complete {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.tertiary)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func subtitleForStep(_ step: ForgotPasswordViewModel.Step) -> String {
        switch step {
        case .email: return "Enter your email address and we'll send you an OTP to reset your password."
        case .otp: return "We sent an OTP to \(viewModel.email). Please enter it below."
        case .newPassword: return "Enter your new password below."
        case .complete: return "All done!"
        }
    }
}
