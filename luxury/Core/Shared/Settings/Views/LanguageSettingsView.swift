import SwiftUI

struct LanguageSettingsView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    
    // Define available languages
    let availableLanguages = [
        ("System Default", ""),
        ("Arabic", "ar"),
        ("Assamese", "as"),
        ("Bengali", "bn"),
        ("Chinese (Simplified)", "zh-Hans"),
        ("Chinese (Traditional)", "zh-Hant"),
        ("English", "en"),
        ("French", "fr"),
        ("German", "de"),
        ("Gujarati", "gu"),
        ("Hindi", "hi"),
        ("Italian", "it"),
        ("Japanese", "ja"),
        ("Kannada", "kn"),
        ("Korean", "ko"),
        ("Malayalam", "ml"),
        ("Marathi", "mr"),
        ("Odia", "or"),
        ("Portuguese", "pt"),
        ("Punjabi", "pa"),
        ("Russian", "ru"),
        ("Spanish", "es"),
        ("Tamil", "ta"),
        ("Telugu", "te")
    ]
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(AppColors.surface2)
                                .frame(width: 44, height: 44)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                        }
                    }
                    Spacer()
                    Text("Language")
                        .font(AppFonts.sansSerif(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    // Invisible spacer for balance
                    Circle()
                        .frame(width: 44, height: 44)
                        .opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(availableLanguages, id: \.1) { language in
                            Button(action: {
                                languageManager.setLanguage(language.1)
                            }) {
                                HStack {
                                    Text(language.0)
                                        .font(AppFonts.sansSerif(size: 16))
                                        .foregroundStyle(languageManager.selectedLanguage == language.1 ? AppColors.gold : .white)
                                    Spacer()
                                    if languageManager.selectedLanguage == language.1 {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(AppColors.gold)
                                    }
                                }
                                .padding(16)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(languageManager.selectedLanguage == language.1 ? AppColors.gold : AppColors.gold15, lineWidth: 0.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
