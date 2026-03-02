import Foundation

/// Supported languages — dialects merged, agent auto-detects specific variant
enum Language: String, CaseIterable, Identifiable, Codable {

    // MARK: - Global
    case english    = "en"
    case russian    = "ru"
    case spanish    = "es"
    case french     = "fr"
    case german     = "de"
    case chinese    = "zh"
    case japanese   = "ja"
    case korean     = "ko"
    case arabic     = "ar"
    case portuguese = "pt"
    case italian    = "it"
    case turkish    = "tr"

    // MARK: - Southeast Asian
    case vietnamese = "vi"
    case thai       = "th"      // All Thai dialects (Central, Northern, Isan, Southern)

    // MARK: - South Asian — one entry, agent auto-detects language
    case indian     = "in"      // Hindi, Bengali, Tamil, Telugu, Marathi, Urdu, Gujarati, Kannada, Malayalam, Punjabi, etc.
    case nepali     = "ne"
    case sinhala    = "si"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:    return "English"
        case .russian:    return "Русский"
        case .spanish:    return "Español"
        case .french:     return "Français"
        case .german:     return "Deutsch"
        case .chinese:    return "中文"
        case .japanese:   return "日本語"
        case .korean:     return "한국어"
        case .arabic:     return "العربية"
        case .portuguese: return "Português"
        case .italian:    return "Italiano"
        case .turkish:    return "Türkçe"
        case .vietnamese: return "Tiếng Việt"
        case .thai:       return "ภาษาไทย"
        case .indian:     return "भारतीय भाषा"
        case .nepali:     return "नेपाली"
        case .sinhala:    return "සිංහල"
        }
    }

    var nameInRussian: String {
        switch self {
        case .english:    return "Английский"
        case .russian:    return "Русский"
        case .spanish:    return "Испанский"
        case .french:     return "Французский"
        case .german:     return "Немецкий"
        case .chinese:    return "Китайский"
        case .japanese:   return "Японский"
        case .korean:     return "Корейский"
        case .arabic:     return "Арабский"
        case .portuguese: return "Португальский"
        case .italian:    return "Итальянский"
        case .turkish:    return "Турецкий"
        case .vietnamese: return "Вьетнамский"
        case .thai:       return "Тайский"
        case .indian:     return "Индийский"
        case .nepali:     return "Непальский"
        case .sinhala:    return "Сингальский"
        }
    }

    var flag: String {
        switch self {
        case .english:    return "🇺🇸"
        case .russian:    return "🇷🇺"
        case .spanish:    return "🇪🇸"
        case .french:     return "🇫🇷"
        case .german:     return "🇩🇪"
        case .chinese:    return "🇨🇳"
        case .japanese:   return "🇯🇵"
        case .korean:     return "🇰🇷"
        case .arabic:     return "🇸🇦"
        case .portuguese: return "🇧🇷"
        case .italian:    return "🇮🇹"
        case .turkish:    return "🇹🇷"
        case .vietnamese: return "🇻🇳"
        case .thai:       return "🇹🇭"
        case .indian:     return "🇮🇳"
        case .nepali:     return "🇳🇵"
        case .sinhala:    return "🇱🇰"
        }
    }

    var voiceLocale: String {
        switch self {
        case .english:    return "en-US"
        case .russian:    return "ru-RU"
        case .spanish:    return "es-ES"
        case .french:     return "fr-FR"
        case .german:     return "de-DE"
        case .chinese:    return "zh-CN"
        case .japanese:   return "ja-JP"
        case .korean:     return "ko-KR"
        case .arabic:     return "ar-SA"
        case .portuguese: return "pt-BR"
        case .italian:    return "it-IT"
        case .turkish:    return "tr-TR"
        case .vietnamese: return "vi-VN"
        case .thai:       return "th-TH"
        case .indian:     return "hi-IN"
        case .nepali:     return "ne-NP"
        case .sinhala:    return "si-LK"
        }
    }
    
    static func detectSystemLanguage() -> Language {
        let locale = Locale.current.language.languageCode?.identifier ?? "en"
        return Language(rawValue: locale) ?? .english
    }
}
