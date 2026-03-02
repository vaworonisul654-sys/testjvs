import SwiftUI
import UIKit

/// The main ViewModel coordinating audio capture, Gemini API, and TTS
@MainActor
@Observable
final class TranslatorViewModel {

    // MARK: - Published State

    var state: TranslatorState = .idle
    var sourceLanguage: Language = .english
    var targetLanguage: Language = .russian
    var messages: [TranslationMessage] = []
    var currentTranslation: String = ""
    var audioLevel: Float = 0

    // MARK: - Services

    private let audioCaptureService = AudioCaptureService()
    private let geminiService = GeminiLiveService()
    private let ttsService = TTSService()

    // MARK: - Private

    private var audioStreamTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        setupGeminiCallbacks()
        observeSettings()
    }

    private func observeSettings() {
        _ = withObservationTracking {
            AppSettings.shared.voiceGender
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.handleVoiceGenderChange()
                self?.observeSettings() // Re-subscribe for next change
            }
        }
    }

    private func handleVoiceGenderChange() {
        guard state.isActive else { return }
        
        AppLogger.network.info("Voice gender changed. Restarting session to apply new voice...")
        
        // Quick restart to apply new voice configuration
        audioStreamTask?.cancel()
        audioStreamTask = nil
        
        audioCaptureService.stopCapture()
        geminiService.endSession()
        ttsService.stop()
        
        // Clear current translation to avoid duplication during restart
        currentTranslation = ""
        
        Task {
            await startRecording()
        }
    }

    // MARK: - Public API

    var isAPIKeyConfigured: Bool {
        AppConfiguration.isAPIKeyConfigured
    }

    func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func toggleRecording() {
        switch state {
        case .recording, .translating, .connecting:
            stopRecording()
        case .idle, .error:
            Task { await startRecording() }
        }
    }

    func startRecording() async {
        state = .idle
        guard state == .idle else { return }

        guard AppConfiguration.isAPIKeyConfigured else {
            state = .error("API ключ не настроен.\nДобавьте GEMINI_API_KEY в Debug.xcconfig")
            return
        }

        let granted = await audioCaptureService.requestPermission()
        guard granted else {
            state = .error("Нет доступа к микрофону.\nРазрешите в Настройках.")
            return
        }

        state = .connecting
        currentTranslation = ""

        geminiService.startSession(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )

        do {
            let audioStream = try audioCaptureService.startCapture()
            state = .recording

            // 🔦 Keep screen awake during voice session
            UIApplication.shared.isIdleTimerDisabled = true

            audioStreamTask = Task {
                for await chunk in audioStream {
                    guard !Task.isCancelled else { break }
                    await MainActor.run {
                        self.audioLevel = self.audioCaptureService.currentLevel
                    }

                    // ⚡ DON'T send audio while TTS is playing — prevents feedback loop
                    guard !self.ttsService.isSpeaking else { continue }

                    self.geminiService.sendAudioChunk(chunk)
                }
            }
        } catch {
            state = .error("Не удалось начать запись:\n\(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioStreamTask?.cancel()
        audioStreamTask = nil

        audioCaptureService.stopCapture()
        geminiService.endSession()
        ttsService.stop()

        if !currentTranslation.isEmpty && currentTranslation != "🔊 Воспроизведение перевода..." {
            let message = TranslationMessage(
                originalText: "🎤 Голосовой ввод",
                translatedText: currentTranslation,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
            messages.insert(message, at: 0)
        }

        audioLevel = 0
        currentTranslation = ""
        state = .idle
        
        // 🔋 Allow screen to sleep again
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func clearHistory() {
        messages.removeAll()
    }

    // MARK: - Private

    private func setupGeminiCallbacks() {
        geminiService.onSetupComplete = { [weak self] in
            guard self != nil else { return }
            AppLogger.network.info("Gemini session ready")
        }

        geminiService.onTranslatedText = { [weak self] text in
            guard let self = self else { return }
            self.currentTranslation += text
            self.state = .translating
        }

        geminiService.onAudioData = { [weak self] audioData in
            guard let self = self else { return }
            self.ttsService.playGeminiAudio(audioData)
            if self.currentTranslation.isEmpty {
                self.currentTranslation = "🔊 Воспроизведение перевода..."
            }
            self.state = .translating
        }

        geminiService.onTurnComplete = { [weak self] in
            guard let self = self else { return }
            AppLogger.network.info("Turn complete")
            // Reset for next phrase after playback finishes
            if self.state == .translating {
                self.state = .recording
            }
            // Save to history
            if !self.currentTranslation.isEmpty && self.currentTranslation != "🔊 Воспроизведение перевода..." {
                let message = TranslationMessage(
                    originalText: "🎤 Голосовой ввод",
                    translatedText: self.currentTranslation,
                    sourceLanguage: self.sourceLanguage,
                    targetLanguage: self.targetLanguage
                )
                self.messages.insert(message, at: 0)
            }
            self.currentTranslation = ""
        }

        geminiService.onError = { [weak self] error in
            guard let self = self else { return }
            AppLogger.network.error("Gemini error: \(error.localizedDescription)")
            if self.state.isActive {
                self.stopRecording()
                self.state = .error(error.localizedDescription)
            }
        }
    }
}
