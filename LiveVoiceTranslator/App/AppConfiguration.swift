import Foundation

/// Centralized app configuration — reads API keys from .xcconfig / Info.plist
enum AppConfiguration {

    // MARK: - Gemini API

    /// Returns the API key or nil if not configured
    static var geminiAPIKey: String? {
        guard let key = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String,
              !key.isEmpty,
              key != "YOUR_API_KEY_HERE" else {
            return nil
        }
        return key
    }

    /// Whether the API key is properly configured
    static var isAPIKeyConfigured: Bool {
        geminiAPIKey != nil
    }

    static let geminiModel = "models/gemini-2.5-flash-native-audio-preview-12-2025"

    /// Returns the WebSocket URL or nil if API key not configured
    static var geminiWebSocketURL: URL? {
        guard let apiKey = geminiAPIKey else { return nil }

        var components = URLComponents()
        components.scheme = "wss"
        components.host = "generativelanguage.googleapis.com"
        components.path = "/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent"
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        return components.url
    }

    // MARK: - Audio

    static let audioSampleRate: Double = 16_000
    static let audioChannels: Int = 1
    static let audioBitDepth: Int = 16
    static let audioChunkDurationMs: Int = 100

    // MARK: - App

    static let appName = "Jarvis Voice System"
    static let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
}
