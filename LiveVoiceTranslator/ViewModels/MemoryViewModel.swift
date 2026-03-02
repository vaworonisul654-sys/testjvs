import SwiftUI
import Observation

/// ViewModel for managing saved translation templates (Memory)
@Observable
final class MemoryViewModel {
    var items: [MemoryItem] = []
    
    // Creation State
    var sourceLanguage: Language = .english
    var targetLanguage: Language = .russian
    var sourceText: String = ""
    var translatedText: String = ""
    var isTranslating: Bool = false
    var errorMessage: String?
    var isShowingCreation: Bool = false
    
    private let translationService = OpenAITranslationService()
    private let ttsService = TTSService()
    private let storageKey = "com.jarvis.memory_items"
    private let maxItems = 10
    
    init() {
        loadItems()
    }
    
    // MARK: - Actions
    
    func translate() async {
        guard !sourceText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        await MainActor.run {
            isTranslating = true
            errorMessage = nil
            translatedText = ""
        }
        
        do {
            let result = try await translationService.translate(
                text: sourceText,
                from: sourceLanguage,
                to: targetLanguage
            )
            await MainActor.run {
                self.translatedText = result
                self.isTranslating = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isTranslating = false
            }
        }
    }
    
    func saveItem() {
        guard items.count < maxItems else {
            errorMessage = "Достигнут лимит: максимум \(maxItems) шаблонов."
            return
        }
        
        guard !sourceText.isEmpty && !translatedText.isEmpty else { return }
        
        let newItem = MemoryItem(
            originalText: sourceText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        
        items.insert(newItem, at: 0)
        saveToStorage()
        
        // Reset and close
        isShowingCreation = false
        sourceText = ""
        translatedText = ""
    }
    
    func deleteItem(at indexSet: IndexSet) {
        items.remove(atOffsets: indexSet)
        saveToStorage()
    }
    
    func deleteItem(_ item: MemoryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
            saveToStorage()
        }
    }
    
    func playItem(_ item: MemoryItem) {
        ttsService.speak(item.translatedText, language: item.targetLanguage)
    }
    
    func playCurrentPreview() {
        guard !translatedText.isEmpty else { return }
        ttsService.speak(translatedText, language: targetLanguage)
    }
    
    func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
        
        let tempText = sourceText
        sourceText = translatedText
        translatedText = tempText
    }
    
    // MARK: - Persistence
    
    private func saveToStorage() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([MemoryItem].self, from: data) {
            self.items = decoded
        }
    }
}
