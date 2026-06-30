import SwiftUI
import Observation
import Supabase

@Observable
final class AuthViewModel {
    var isSignUp = false
    var name = ""
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?
    var showResetSuccess = false
    
    private let authService = AuthService()
    private let profileService = ProfileService()
    
    func authenticate(onSuccess: @escaping () -> Void) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty && !trimmedPassword.isEmpty else {
            errorMessage = String(localized: "Please enter both email and password.")
            return
        }
        
        if isSignUp {
            errorMessage = String(localized: "Sign up is by invitation only.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signIn(email: trimmedEmail, password: trimmedPassword)
                SystemLogService.shared.logAction(category: .access, severity: .info, message: "User logged in: \(trimmedEmail)")
                
                await MainActor.run {
                    isLoading = false
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loginSocial(provider: String, onSuccess: @escaping () -> Void) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                // Social login mock handling
                await MainActor.run {
                    isLoading = false
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func resetPassword() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = String(localized: "Please enter your email address.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.resetPassword(email: trimmedEmail)
                SystemLogService.shared.logAction(category: .access, severity: .info, message: "Password reset requested for: \(trimmedEmail)")
                await MainActor.run {
                    isLoading = false
                    showResetSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
