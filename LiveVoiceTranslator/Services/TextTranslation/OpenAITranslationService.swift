import Foundation

/// OpenAI text translation service — uses GPT-4o-mini for fast real-time translation
final class OpenAITranslationService {

    // MARK: - Config

    private static let apiKey: String = {
        // Read from Info.plist (set via xcconfig)
        guard let key = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String,
              !key.isEmpty,
              key != "YOUR_OPENAI_KEY_HERE" else {
            return ""
        }
        return key
    }()

    static var isConfigured: Bool { !apiKey.isEmpty }

    private static let endpoint = "https://api.openai.com/v1/chat/completions"
    private static let model = "gpt-4o-mini"

    // MARK: - Translation

    /// Translates text using GPT-4o-mini. Returns the translated string.
    func translate(
        text: String,
        from sourceLanguage: Language,
        to targetLanguage: Language
    ) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ""
        }

        guard Self.isConfigured else {
            throw TranslationError.apiKeyMissing
        }

        let systemPrompt = """
        You are an expert linguist and professional translator from \(sourceLanguage.displayName) to \(targetLanguage.displayName).

        ACCURACY REQUIREMENTS:
        - Every translation must be grammatically perfect in \(targetLanguage.displayName).
        - Apply correct grammar: declensions, conjugations, cases, gender agreement, articles, verb tenses.
        - Understand slang, colloquialisms, abbreviations, and informal speech — translate their MEANING, not literal words.
        - Use natural idiomatic expressions in \(targetLanguage.displayName) — never translate word-by-word.
        - Respect formal/informal registers and adapt appropriately.
        - Preserve formatting, punctuation, and tone.
        - If input is a single word, translate just that word with correct form.

        OUTPUT: Only the translation. No explanations, no notes, no alternatives.
        """

        let body: [String: Any] = [
            "model": Self.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.1,
            "max_tokens": 512
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body),
              let url = URL(string: Self.endpoint) else {
            throw TranslationError.requestFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Self.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 8

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.requestFailed
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            throw TranslationError.apiError("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw TranslationError.parseFailed
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors

enum TranslationError: LocalizedError {
    case apiKeyMissing
    case requestFailed
    case apiError(String)
    case parseFailed

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:    return "OpenAI API ключ не настроен."
        case .requestFailed:    return "Ошибка сетевого запроса."
        case .apiError(let msg): return "OpenAI: \(msg)"
        case .parseFailed:      return "Не удалось разобрать ответ."
        }
    }
}
