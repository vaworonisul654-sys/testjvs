import SwiftUI

/// Persists user preferences for the application
@MainActor
@Observable
final class AppSettings {
    var voiceGender: VoiceGender = .female {
        didSet {
            UserDefaults.standard.set(voiceGender.rawValue, forKey: "voice_gender")
        }
    }
    
    var isOnboardingComplete: Bool = false {
        didSet {
            UserDefaults.standard.set(isOnboardingComplete, forKey: "onboarding_complete")
        }
    }
    
    var nativeLanguage: Language = .english {
        didSet {
            UserDefaults.standard.set(nativeLanguage.rawValue, forKey: "native_language")
        }
    }
    
    var learnerTargetLanguage: Language = .russian {
        didSet {
            UserDefaults.standard.set(learnerTargetLanguage.rawValue, forKey: "learner_target_language")
        }
    }
    
    static let shared = AppSettings()
    
    private init() {
        // Voice Gender
        if let stored = UserDefaults.standard.string(forKey: "voice_gender"),
           let gender = VoiceGender(rawValue: stored) {
            self.voiceGender = gender
        }
        
        // Onboarding
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboarding_complete")
        
        // Native Language (Default to system language)
        if let stored = UserDefaults.standard.string(forKey: "native_language"),
           let lang = Language(rawValue: stored) {
            self.nativeLanguage = lang
        } else {
            self.nativeLanguage = Language.detectSystemLanguage()
        }
        
        // Learner Target Language
        if let stored = UserDefaults.standard.string(forKey: "learner_target_language"),
           let lang = Language(rawValue: stored) {
            self.learnerTargetLanguage = lang
        }
    }
    
    enum VoiceGender: String, CaseIterable, Identifiable {
        case male = "male"
        case female = "female"
        
        var id: String { self.rawValue }
        
        var localizedName: String {
            switch self {
            case .male: return "Мужской"
            case .female: return "Женский"
            }
        }
    }
}
