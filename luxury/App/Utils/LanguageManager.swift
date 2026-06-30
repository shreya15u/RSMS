import SwiftUI

/// A manager to handle app-wide language overrides.
@Observable
final class LanguageManager {
    static let shared = LanguageManager()
    
    var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
            
            // Apply global override so String(localized:) in ViewModels also works
            if selectedLanguage.isEmpty {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.set([selectedLanguage], forKey: "AppleLanguages")
            }
            UserDefaults.standard.synchronize()
        }
    }
    
    init() {
        self.selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? ""
    }
    
    var currentLocale: Locale {
        if selectedLanguage.isEmpty {
            return Locale.current
        } else {
            return Locale(identifier: selectedLanguage)
        }
    }
    
    func setLanguage(_ languageCode: String) {
        selectedLanguage = languageCode
    }
}
