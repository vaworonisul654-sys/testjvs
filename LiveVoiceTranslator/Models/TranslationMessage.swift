import Foundation

/// Represents a single translation message in the conversation
struct TranslationMessage: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let originalText: String
    let translatedText: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let isFromUser: Bool // true = user spoke, false = incoming (future: conference mode)

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        originalText: String,
        translatedText: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        isFromUser: Bool = true
    ) {
        self.id = id
        self.timestamp = timestamp
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.isFromUser = isFromUser
    }
}
