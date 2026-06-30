import SwiftUI
import Supabase

struct MFASetupView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var qrCodeImage: UIImage?
    @State private var secret: String = ""
    @State private var factorId: String = ""
    @State private var verifyCode: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    let isFromSettings: Bool
    private let authService = AuthService()
    
    init(isFromSettings: Bool = false) {
        self.isFromSettings = isFromSettings
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Secure Your Account")
                        .font(AppFonts.sansSerif(size: 28, weight: .bold))
                        .foregroundStyle(AppColors.text)
                        .padding(.top, 40)
                    
                    Text("We require two-factor authentication for all staff members. Scan this QR code with Google Authenticator or Apple Passwords.")
                        .font(AppFonts.sansSerif(size: 16, weight: .regular))
                        .foregroundStyle(AppColors.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    if let image = qrCodeImage {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                    } else if isLoading {
                        ProgressView()
                            .frame(height: 200)
                    }
                    
                    if !secret.isEmpty {
                        Text("Secret: \(secret)")
                            .font(AppFonts.sansSerif(size: 12, weight: .regular))
                            .foregroundStyle(AppColors.secondary)
                            .textSelection(.enabled)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter 6-digit code")
                            .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.text)
                        
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
                    
                    Button(action: verifyFactor) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(AppColors.background)
                            } else {
                                Text("Verify & Continue")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(verifyCode.count == 6 ? AppColors.gold : AppColors.secondary)
                        .foregroundStyle(AppColors.background)
                        .font(AppFonts.sansSerif(size: 16, weight: .bold))
                        .clipShape(Capsule())
                    }
                    .disabled(verifyCode.count != 6 || isLoading || factorId.isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    if !isFromSettings {
                        Button("Logout") {
                            coordinator.logout()
                        }
                        .foregroundStyle(AppColors.error)
                        .padding(.top, 16)
                    }
                }
            }
            .background(AppColors.background)
            .onAppear(perform: setupMFA)
            .toolbar {
                if isFromSettings {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(AppFonts.sansSerif(size: 16))
                        .foregroundStyle(AppColors.gold)
                    }
                }
            }
        }
    }
    
    private func setupMFA() {
        guard factorId.isEmpty else { return }
        Task {
            isLoading = true
            do {
                // First, check if there are any unverified factors and unenroll them
                // because we can't retrieve the secret for an existing unverified factor.
                let factors = try await SupabaseManager.shared.client.auth.mfa.listFactors()
                let unverifiedFactors = factors.totp.filter { $0.status == .unverified }
                
                for factor in unverifiedFactors {
                    try await SupabaseManager.shared.client.auth.mfa.unenroll(params: Auth.MFAUnenrollParams(factorId: factor.id))
                }
                
                // Now enroll a new factor
                let friendlyName = "\(UIDevice.current.name.replacingOccurrences(of: " ", with: ""))_\(Int(Date().timeIntervalSince1970) % 10000)"
                let response = try await SupabaseManager.shared.client.auth.mfa.enroll(params: Auth.MFATotpEnrollParams(issuer: "RSMS", friendlyName: friendlyName))
                factorId = response.id
                secret = response.totp?.secret ?? ""
                
                // Construct a clean, compliant URI to avoid MS Authenticator issues
                let session = await authService.getCurrentSession()
                let email = session?.user.email ?? "User"
                let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? email
                let cleanUri = "otpauth://totp/RSMS:\(encodedEmail)?secret=\(secret)&issuer=RSMS"
                
                qrCodeImage = generateQRCode(from: cleanUri)
            } catch {
                errorMessage = String(localized: "Failed to load MFA setup: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    private func verifyFactor() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                let cleanCode = verifyCode.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
                let challengeResponse = try await SupabaseManager.shared.client.auth.mfa.challenge(params: Auth.MFAChallengeParams(factorId: factorId))
                let _ = try await SupabaseManager.shared.client.auth.mfa.verify(params: Auth.MFAVerifyParams(factorId: factorId, challengeId: challengeResponse.id, code: cleanCode))
                
                // Refresh session & route
                let session = await authService.getCurrentSession()
                await coordinator.routingService.updateRoute(for: session)
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            // Use 'L' (Low) error correction for less dense, faster-scanning QR codes
            filter.setValue("L", forKey: "inputCorrectionLevel")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let context = CIContext()
                if let cgImage = context.createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        return nil
    }
}
