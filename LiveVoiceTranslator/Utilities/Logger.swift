import Foundation
import os

/// Unified app logging using os.Logger
enum AppLogger {
    static let audio   = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LiveVoiceTranslator", category: "Audio")
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LiveVoiceTranslator", category: "Network")
    static let tts     = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LiveVoiceTranslator", category: "TTS")
    static let ui      = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LiveVoiceTranslator", category: "UI")
    static let general = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LiveVoiceTranslator", category: "General")
}
