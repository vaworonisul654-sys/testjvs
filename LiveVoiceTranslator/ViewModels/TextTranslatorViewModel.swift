import SwiftUI
import Combine

/// ViewModel for text translation — debounces input and translates via OpenAI
@Observable
final class TextTranslatorViewModel {

    // MARK: - State

    var sourceText: String = "" {
        didSet { scheduleTranslation() }
    }
    var translatedText: String = ""
    var isTranslating = false
    var errorMessage: String?
    var sourceLanguage: Language = .english
    var targetLanguage: Language = .russian

    // MARK: - Private

    private let service = OpenAITranslationService()
    private var translationTask: Task<Void, Never>?
    private var debounceWorkItem: DispatchWorkItem?

    // MARK: - Public

    var isAPIKeyConfigured: Bool {
        OpenAITranslationService.isConfigured
    }

    func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp

        // Swap texts too
        let tempText = sourceText
        sourceText = translatedText
        translatedText = tempText
    }

    func clearAll() {
        sourceText = ""
        translatedText = ""
        errorMessage = nil
    }

    func copyTranslation() {
        guard !translatedText.isEmpty else { return }
        UIPasteboard.general.string = translatedText
    }

    // MARK: - Private

    private func scheduleTranslation() {
        // Cancel previous
        debounceWorkItem?.cancel()
        translationTask?.cancel()

        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            translatedText = ""
            isTranslating = false
            return
        }

        // Debounce 150ms — fast response while typing
        let workItem = DispatchWorkItem { [weak self] in
            self?.performTranslation(text: text)
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }

    private func performTranslation(text: String) {
        isTranslating = true
        errorMessage = nil

        translationTask = Task { @MainActor in
            do {
                let result = try await service.translate(
                    text: text,
                    from: sourceLanguage,
                    to: targetLanguage
                )
                // Only update if source hasn't changed (user might be typing more)
                if self.sourceText.trimmingCharacters(in: .whitespacesAndNewlines) == text {
                    self.translatedText = result
                    self.isTranslating = false
                }
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = error.localizedDescription
                    self.isTranslating = false
                }
            }
        }
    }
}
