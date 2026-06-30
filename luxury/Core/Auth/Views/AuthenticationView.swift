import SwiftUI

struct AuthenticationView: View {
    var onSignInSuccess: () -> Void
    
    @Environment(AppCoordinator.self) private var coordinator
    @State private var viewModel = AuthViewModel()
    @State private var showComingSoon = false
    @State private var showForgotPassword = false
    
    var body: some View {
        @Bindable var authVM = viewModel
        
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: 40)
                        
                        Text("Verify\nIdentity.")
                            .font(AppFonts.serif(size: 52, weight: .light))
                            .italic()
                            .foregroundStyle(AppColors.text)
                            .lineSpacing(-5)
                            .padding(.bottom, 16)
                        
                        Text("Enter your credentials to continue.")
                            .font(AppFonts.sansSerif(size: 13, weight: .light))
                            .foregroundStyle(AppColors.secondary)
                            .padding(.bottom, 40)
                    }
                    
                    VStack(spacing: 20) {
                        CustomTextField(
                            title: "EMAIL ADDRESS",
                            placeholder: "name@luxury.com",
                            text: $authVM.email,
                            keyboardType: .emailAddress
                        )
                        
                        CustomSecureField(
                            title: "PASSWORD",
                            placeholder: "••••••••",
                            text: $authVM.password
                        )
                    }
                    .padding(.bottom, 12)
                    
                    HStack {
                        Spacer()
                        Button(action: { showForgotPassword = true }) {
                            Text("Forgot Password?")
                                .font(AppFonts.sansSerif(size: 12, weight: .medium))
                                .foregroundStyle(AppColors.gold)
                        }
                    }
                    .padding(.bottom, 32)
                    
                    VStack(spacing: 16) {
                        if let error = authVM.errorMessage {
                            Text(error)
                                .font(AppFonts.sansSerif(size: 12))
                                .foregroundStyle(AppColors.error)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        CustomButton(
                            title: "Sign In",
                            isLoading: authVM.isLoading,
                            action: {
                                authVM.authenticate {
                                    onSignInSuccess()
                                }
                            }
                        )
                    }
                    

                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 28)
            }
        }
        .alert("Coming Soon", isPresented: $showComingSoon) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This feature will be available soon.")
        }
        .alert("Reset Link Sent", isPresented: $authVM.showResetSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A password reset link has been sent to your email address.")
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }

}

struct CustomTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                .foregroundStyle(AppColors.secondary)
                .kerning(1.5)
                .accessibilityHidden(true)
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(AppColors.tertiary))
                .font(AppFonts.sansSerif(size: 15))
                .foregroundStyle(AppColors.text)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.vertical, 16)
                .padding(.horizontal, 18)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.gold15, lineWidth: 1)
                )
                .accessibilityLabel(title)
                .accessibilityHint(placeholder)
        }
    }
}

struct CustomSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                .foregroundStyle(AppColors.secondary)
                .kerning(1.5)
                .accessibilityHidden(true)
            
            SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(AppColors.tertiary))
                .font(AppFonts.sansSerif(size: 15))
                .foregroundStyle(AppColors.text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.vertical, 16)
                .padding(.horizontal, 18)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.gold15, lineWidth: 1)
                )
                .accessibilityLabel(title)
                .accessibilityHint(placeholder)
        }
    }
}

private struct SocialButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if icon == "google.logo" {
                    Image(systemName: "g.circle.fill")
                } else {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(AppFonts.sansSerif(size: 14, weight: .medium))
            }
            .foregroundStyle(AppColors.text)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.gold15, lineWidth: 1)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}




