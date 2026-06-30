//
//  ForgotPasswordViewModel.swift
//  luxury
//

import SwiftUI
import Observation
import Supabase

@Observable
final class ForgotPasswordViewModel {
    var email = ""
    var otp = ""
    var newPassword = ""
    var confirmPassword = ""
    
    var step: Step = .email
    var isLoading = false
    var errorMessage: String?
    
    enum Step {
        case email
        case otp
        case newPassword
        case complete
    }
    
    private let client = SupabaseManager.shared.client
    
    func sendResetEmail() {
        guard !email.isEmpty else {
            errorMessage = String(localized: "Please enter your email")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await client.auth.resetPasswordForEmail(email)
                await MainActor.run {
                    self.step = .otp
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func verifyOTP() {
        guard !otp.isEmpty else {
            errorMessage = String(localized: "Please enter the OTP sent to your email")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await client.auth.verifyOTP(
                    email: email,
                    token: otp,
                    type: .recovery
                )
                await MainActor.run {
                    self.step = .newPassword
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Invalid or expired OTP: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func updatePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = String(localized: "Passwords do not match")
            return
        }
        guard newPassword.count >= 6 else {
            errorMessage = String(localized: "Password must be at least 6 characters")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await client.auth.update(user: UserAttributes(password: newPassword))
                await MainActor.run {
                    self.step = .complete
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to update password: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
}
