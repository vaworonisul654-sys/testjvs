import Foundation

/// High-level service for Gemini Live API — bidirectional real-time translation
@MainActor
@Observable
final class GeminiLiveService {

    // MARK: - Public State

    private(set) var isSessionActive = false

    // MARK: - Callbacks

    var onTranslatedText: ((String) -> Void)?
    var onAudioData: ((Data) -> Void)?
    var onError: ((Error) -> Void)?
    var onSetupComplete: (() -> Void)?
    var onTurnComplete: (() -> Void)?
    var onUserTranscription: ((String) -> Void)?

    // MARK: - Private

    private let webSocketService = WebSocketService()
    private var hasSetupCompleted = false

    // MARK: - Public API

    /// Starts a bidirectional translation session with optional custom system instruction and history
    func startSession(sourceLanguage: Language, targetLanguage: Language, customSystemInstruction: String? = nil, history: String? = nil) {
        hasSetupCompleted = false

        guard let wsURL = AppConfiguration.geminiWebSocketURL else {
            DispatchQueue.main.async {
                self.onError?(GeminiError.apiKeyMissing)
            }
            return
        }

        webSocketService.onReceiveMessage = { [weak self] message in
            self?.handleMessage(message)
        }

        webSocketService.onDisconnect = { [weak self] error in
            DispatchQueue.main.async {
                self?.isSessionActive = false
                if let error { self?.onError?(error) }
            }
        }

        Task {
            do {
                try await webSocketService.connect(to: wsURL)

                await MainActor.run {
                    self.isSessionActive = true
                }

                let setupMessage = buildSetupMessage(
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    customSystemInstruction: customSystemInstruction,
                    history: history
                )
                try await webSocketService.sendText(setupMessage)
                AppLogger.network.info("Gemini setup sent ✅")

            } catch {
                AppLogger.network.error("Session start failed: \(error.localizedDescription)")
                await MainActor.run {
                    self.isSessionActive = false
                    self.onError?(error)
                }
            }
        }
    }

    /// Sends a text message (e.g., to trigger the AI to start speaking)
    func sendTextMessage(_ text: String) {
        guard isSessionActive, hasSetupCompleted else { return }
        
        let message: [String: Any] = [
            "clientContent": [
                "turns": [
                    [
                        "role": "user",
                        "parts": [
                            ["text": text]
                        ]
                    ]
                ],
                "turnComplete": true
            ]
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let json = String(data: data, encoding: .utf8) else { return }
              
        Task {
            do {
                try await webSocketService.sendText(json)
            } catch {
                AppLogger.network.error("Send text failed: \(error.localizedDescription)")
            }
        }
    }

    /// Sends audio chunk for real-time translation
    func sendAudioChunk(_ chunk: AudioChunk) {
        guard isSessionActive, hasSetupCompleted else { return }

        let message = buildRealtimeInputMessage(chunk)
        Task {
            do {
                try await webSocketService.sendText(message)
            } catch {
                AppLogger.network.error("Send audio failed: \(error.localizedDescription)")
            }
        }
    }

    /// Ends session
    func endSession() {
        webSocketService.disconnect()
        isSessionActive = false
        hasSetupCompleted = false
    }

    // MARK: - Message Building

    private func buildSetupMessage(sourceLanguage: Language, targetLanguage: Language, customSystemInstruction: String? = nil, history: String? = nil) -> String {
        var baseInstruction = customSystemInstruction ?? """
        You are a REAL-TIME BIDIRECTIONAL voice translator between \(sourceLanguage.displayName) and \(targetLanguage.displayName).

        BEHAVIOR:
        - When you hear \(sourceLanguage.displayName), immediately translate to \(targetLanguage.displayName).
        - When you hear \(targetLanguage.displayName), immediately translate to \(sourceLanguage.displayName).
        - Auto-detect which language is being spoken and translate to the OTHER one.

        DIALECT & ACCENT AUTO-DETECTION FOR ALL LANGUAGES:

        🇮🇳 भारतीय भाषा (Indian): ALL 22 scheduled languages — Hindi, Bengali, Telugu, Marathi, Tamil, Urdu, Gujarati, Kannada, Malayalam, Odia, Punjabi, Assamese, Maithili, Sanskrit, Santali, Kashmiri, Nepali, Sindhi, Konkani, Dogri, Manipuri, Bodo. Hindi dialects: Bhojpuri, Rajasthani, Chhattisgarhi, Marwari, Awadhi, Bundeli, Magahi, Haryanvi.

        🇻🇳 Tiếng Việt (Vietnamese): Northern (Hanoi, Red River Delta), Central (Huế, Đà Nẵng, Nghệ An), Southern (Hồ Chí Minh, Mekong Delta).

        🇹🇭 ภาษาไทย (Thai): Central (Bangkok), Northern/Lanna (Chiang Mai), Isan (Northeastern), Southern (Surat Thani).

        🇨🇳 中文 (Chinese): Mandarin (Beijing, Taiwan, Singapore), Cantonese (Hong Kong, Guangdong), Wu (Shanghai), Min (Fujian, Taiwan Hokkien), Hakka, Gan, Xiang.

        🇪🇸 Español (Spanish): Castilian (Spain), Latin American (Mexico, Colombia, Argentina, Chile, Peru, Cuba), Rioplatense, Caribbean, Andean.

        🇫🇷 Français (French): Metropolitan (Paris), Canadian (Québécois), Belgian, Swiss, African (West/Central Africa).

        🇵🇹 Português (Portuguese): European (Lisbon), Brazilian (São Paulo, Rio, Nordeste, Sul), African (Angolan, Mozambican).

        🇩🇪 Deutsch (German): Standard (Hochdeutsch), Austrian, Swiss, Bavarian, Low German (Plattdeutsch), Swabian, Saxon.

        🇸🇦 العربية (Arabic): Modern Standard (MSA/Fusha), Egyptian, Levantine (Syrian, Lebanese, Palestinian, Jordanian), Gulf (Saudi, Emirati, Kuwaiti, Qatari, Bahraini), Maghreb (Moroccan, Algerian, Tunisian), Iraqi, Yemeni, Sudanese.

        🇯🇵 日本語 (Japanese): Standard (Tokyo), Kansai (Osaka, Kyoto), Tohoku, Kyushu, Hokkaido, Okinawan.

        🇰🇷 한국어 (Korean): Seoul standard, Gyeongsang (Busan), Jeolla, Chungcheong, Jeju, North Korean (Pyongyang).

        🇲🇾 Bahasa Melayu (Malay): Standard (Malaysia), Johor, Kelantan, Terengganu, Sarawak, Brunei.

        🇮🇩 Bahasa Indonesia (Indonesian): Standard (Jakarta), Javanese-influenced, Sundanese-influenced, Batak-influenced, Minang-influenced.

        🇵🇭 Tagalog/Filipino: Standard (Manila), Visayan-influenced, Ilocano-influenced, Bicolano-influenced.

        🇲🇲 Burmese: Standard (Yangon), Mandalay, Rakhine, Shan-influenced.

        🇰🇭 Khmer: Standard (Phnom Penh), Battambang, Northern, Cardamom.

        🇱🇦 Lao: Vientiane, Luang Prabang, Southern.

        🇷🇺 Русский (Russian): Standard (Moscow), Southern, Ural, Siberian.

        🇮🇹 Italiano (Italian): Standard (Tuscan), Northern (Milanese, Venetian), Southern (Neapolitan, Sicilian), Roman.

        🇹🇷 Türkçe (Turkish): Istanbul standard, Anatolian, Black Sea, Southeastern.

        TRANSLATION QUALITY & PHONETICS:
        - Accuracy and NATURALNESS are the TOP PRIORITIES. Every translation must sound like a native speaker, not a machine.
        - PHONETIC CLARITY: Speak clearly and at a moderate pace. Use natural intonation. Avoid slurring.
        - Understand and correctly translate slang, colloquialisms, and informal speech into their EAR-NATURAL equivalents.
        - Apply correct grammar rules: declensions, conjugations, cases, gender agreement, articles, tenses.
        - Use idiomatic expressions in the target language — do NOT translate word-by-word.
        - Respect formal/informal registers (ты/Вы, tu/vous, tú/usted, คุณ/เธอ, etc.).
        - Handle code-switching (mixing languages in one sentence) gracefully.
        - Translate meaning, not individual words. Preserve intent, humor, and nuance.
        """

        if let conversationHistory = history, !conversationHistory.isEmpty {
            baseInstruction += "\n\nЖИВАЯ ИСТОРИЯ ТЕКУЩЕГО ДИАЛОГА (КОНТЕКСТ):\n\(conversationHistory)"
        }

        let setup: [String: Any] = [
            "setup": [
                "model": AppConfiguration.geminiModel,
                "generationConfig": [
                    "responseModalities": ["AUDIO"],
                    "speechConfig": [
                        "voiceConfig": [
                            "prebuiltVoiceConfig": [
                                "voiceName": AppSettings.shared.voiceGender == .male ? "Puck" : "Aoede"
                            ]
                        ]
                    ]
                ],
                "systemInstruction": [
                    "parts": [
                        ["text": baseInstruction]
                    ]
                ]
            ]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: setup),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    private func buildRealtimeInputMessage(_ chunk: AudioChunk) -> String {
        let message: [String: Any] = [
            "realtimeInput": [
                "mediaChunks": [
                    [
                        "mimeType": chunk.mimeType,
                        "data": chunk.base64Encoded
                    ]
                ]
            ]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    // MARK: - Response Parsing

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseResponse(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseResponse(text)
            }
        @unknown default:
            break
        }
    }

    private func parseResponse(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        // setupComplete
        if json["setupComplete"] != nil {
            hasSetupCompleted = true
            AppLogger.network.info("Gemini ready — streaming ✅")
            DispatchQueue.main.async { self.onSetupComplete?() }
            return
        }
        // serverContent (AI response)
        if let serverContent = json["serverContent"] as? [String: Any] {

            // Turn complete — model finished responding
            if let turnComplete = serverContent["turnComplete"] as? Bool, turnComplete {
                DispatchQueue.main.async { self.onTurnComplete?() }
                return
            }

            if let modelTurn = serverContent["modelTurn"] as? [String: Any],
               let parts = modelTurn["parts"] as? [[String: Any]] {

                for part in parts {
                    // Skip internal thinking
                    if let isThought = part["thought"] as? Bool, isThought {
                        continue
                    }

                    // Text transcript
                    if let text = part["text"] as? String {
                        DispatchQueue.main.async { self.onTranslatedText?(text) }
                    }

                    // Audio data — send IMMEDIATELY for instant playback
                    if let inlineData = part["inlineData"] as? [String: Any],
                       let base64Audio = inlineData["data"] as? String,
                       let audioData = Data(base64Encoded: base64Audio) {
                        DispatchQueue.main.async { self.onAudioData?(audioData) }
                    }
                }
            }
        }

        // Errors
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            AppLogger.network.error("API error: \(message)")
            DispatchQueue.main.async { self.onError?(GeminiError.apiError(message)) }
        }
    }
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case apiError(String)
    case sessionNotActive
    case setupFailed
    case apiKeyMissing

    var errorDescription: String? {
        switch self {
        case .apiError(let msg):   return "Gemini: \(msg)"
        case .sessionNotActive:    return "Сессия не активна."
        case .setupFailed:         return "Ошибка настройки."
        case .apiKeyMissing:       return "API ключ не настроен."
        }
    }
}
