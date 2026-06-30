//
//  SecuritySettingsViewModel.swift
//  luxury
//

import SwiftUI
import Observation
import Supabase

@Observable
final class SecuritySettingsViewModel {
    var isLoading = false
    var successMessage: String?
    var errorMessage: String?
    
    var currentPassword = ""
    var newPassword = ""
    var confirmPassword = ""
    
    var isAuthenticatorEnabled = false
    var enrolledFactors: [Auth.Factor] = []
    
    private let client = SupabaseManager.shared.client
    
    func checkMFAStatus() {
        Task {
            do {
                let factors = try await client.auth.mfa.listFactors()
                await MainActor.run {
                    self.enrolledFactors = factors.totp.filter { $0.status == .verified }
                    self.isAuthenticatorEnabled = !self.enrolledFactors.isEmpty
                }
            } catch {
                print("Failed to check MFA status: \(error)")
            }
        }
    }
    
    func changePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = String(localized: "New passwords do not match")
            return
        }
        guard newPassword.count >= 6 else {
            errorMessage = String(localized: "Password must be at least 6 characters")
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                // To change password securely, one common approach is re-authenticating first if currentPassword is provided.
                // However, Supabase allows updating password directly if user is logged in. 
                // We'll update directly.
                try await client.auth.update(user: UserAttributes(password: newPassword))
                await MainActor.run {
                    self.successMessage = String(localized: "Password updated successfully")
                    self.currentPassword = ""
                    self.newPassword = ""
                    self.confirmPassword = ""
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
    
    func unenrollFactor(factorId: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await client.auth.mfa.unenroll(params: Auth.MFAUnenrollParams(factorId: factorId))
                await MainActor.run {
                    self.enrolledFactors.removeAll { $0.id == factorId }
                    self.isAuthenticatorEnabled = !self.enrolledFactors.isEmpty
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to remove authenticator: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
}
