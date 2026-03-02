import Foundation

/// A saved translation template in the "Memory" feature
struct MemoryItem: Identifiable, Codable {
    let id: UUID
    let originalText: String
    let translatedText: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let timestamp: Date
    
    init(id: UUID = UUID(), originalText: String, translatedText: String, sourceLanguage: Language, targetLanguage: Language, timestamp: Date = Date()) {
        self.id = id
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.timestamp = timestamp
    }
}
