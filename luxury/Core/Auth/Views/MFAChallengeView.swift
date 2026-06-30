import SwiftUI
import Supabase

struct MFAChallengeView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var verifyCode: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    private let authService = AuthService()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "lock.shield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(AppColors.gold)
                
                Text("Two-Factor Authentication")
                    .font(AppFonts.sansSerif(size: 24, weight: .bold))
                    .foregroundStyle(AppColors.text)
                
                Text("Please enter the 6-digit code from your authenticator app.")
                    .font(AppFonts.sansSerif(size: 16, weight: .regular))
                    .foregroundStyle(AppColors.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Security code", text: $verifyCode)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 24)
                
                if let error = errorMessage {
                    Text(error)
                        .font(AppFonts.sansSerif(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.error)
                }
                
                Button(action: verifyCodeWithServer) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(AppColors.background)
                        } else {
                            Text("Verify Code")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(verifyCode.count == 6 ? AppColors.gold : AppColors.secondary)
                    .foregroundStyle(AppColors.background)
                    .font(AppFonts.sansSerif(size: 16, weight: .bold))
                    .clipShape(Capsule())
                }
                .disabled(verifyCode.count != 6 || isLoading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                Button("Logout") {
                    coordinator.logout()
                }
                .foregroundStyle(AppColors.error)
                .padding(.bottom, 32)
            }
            .background(AppColors.background)
        }
    }
    
    private func verifyCodeWithServer() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                let factors = try await SupabaseManager.shared.client.auth.mfa.listFactors()
                let verifiedFactors = factors.totp.filter { $0.status == .verified }
                
                if verifiedFactors.isEmpty {
                    errorMessage = String(localized: "No verified factor found.")
                    isLoading = false
                    return
                }
                
                var success = false
                // Try each factor, starting from the most recently added
                for factor in verifiedFactors.reversed() {
                    do {
                        let challenge = try await SupabaseManager.shared.client.auth.mfa.challenge(params: Auth.MFAChallengeParams(factorId: factor.id))
                        let _ = try await SupabaseManager.shared.client.auth.mfa.verify(params: Auth.MFAVerifyParams(factorId: factor.id, challengeId: challenge.id, code: verifyCode))
                        success = true
                        break
                    } catch {
                        // Failed for this factor, continue to next
                        continue
                    }
                }
                
                if success {
                    let session = await authService.getCurrentSession()
                    await coordinator.routingService.updateRoute(for: session)
                } else {
                    errorMessage = String(localized: "Invalid code. Please try again.")
                }
            } catch {
                errorMessage = String(localized: "Failed to list MFA factors. Please try again.")
            }
            isLoading = false
        }
    }
}
