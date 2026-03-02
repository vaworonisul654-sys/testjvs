import SwiftUI
import Observation

/// Coordinates the interactive learning session with Jarvis
@MainActor
@Observable
final class MentorViewModel {
    var state: MentorState = .idle
    var audioLevel: Float = 0
    var currentResponse: String = ""
    var sessionHistory: [MentorMessage] = []
    var isAutoStarting: Bool = false
    
    // Services
    private let geminiService = GeminiLiveService()
    private let audioCaptureService = AudioCaptureService()
    private let ttsService = TTSService()
    private let mentorService = MentorService.shared
    
    private var audioStreamTask: Task<Void, Never>?
    
    enum MentorState {
        case idle
        case connecting
        case active
        case speaking
        case error(String)
    }
    
    struct MentorMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let timestamp = Date()
    }
    
    init() {
        setupCallbacks()
    }
    
    func startSession(autoStart: Bool = false) {
        var canStart = false
        if case .idle = state { canStart = true }
        if case .error = state { canStart = true }
        guard canStart else { return }
        
        state = .connecting
        currentResponse = ""
        isAutoStarting = autoStart
        
        // Use the personalized instruction from MentorService
        let instruction = mentorService.getSystemInstruction()
        
        // Start Gemini Session with mentor context
        geminiService.startSession(
            sourceLanguage: AppSettings.shared.nativeLanguage,
            targetLanguage: AppSettings.shared.learnerTargetLanguage,
            customSystemInstruction: instruction
        )
        
        Task {
            do {
                let audioStream = try audioCaptureService.startCapture()
                state = .active
                
                // Keep screen awake
                UIApplication.shared.isIdleTimerDisabled = true
                
                audioStreamTask = Task {
                    for await chunk in audioStream {
                        guard !Task.isCancelled else { break }
                        
                        await MainActor.run {
                            self.audioLevel = self.audioCaptureService.currentLevel
                        }
                        
                        // Prevent feedback loop
                        guard !self.ttsService.isSpeaking else { continue }
                        
                        self.geminiService.sendAudioChunk(chunk)
                    }
                }
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
    
    func endSession() {
        // Finalize session data before closing
        if !sessionHistory.isEmpty {
            finalizeAndSaveSession()
        }
        
        audioStreamTask?.cancel()
        audioStreamTask = nil
        
        audioCaptureService.stopCapture()
        geminiService.endSession()
        ttsService.stop()
        
        UIApplication.shared.isIdleTimerDisabled = false
        state = .idle
    }
    
    private func finalizeAndSaveSession() {
        // Create a summary from the last AI response and general history
        // In a real app, you might send one last request to Gemini for a pro summary
        let lastAIResponse = sessionHistory.first { !$0.isUser }?.text ?? ""
        let summary = lastAIResponse.prefix(200) + (lastAIResponse.count > 200 ? "..." : "")
        
        // Crude topic extraction (or default)
        let topic = "Языковая практика"
        
        mentorService.finalizeSession(
            summary: String(summary),
            successRate: 0.8, // Default for now, could be calculated from mistakes
            topics: [topic]
        )
        
        AppLogger.network.info("Session finalized and saved to LearnerProfile")
    }
    
    private func setupCallbacks() {
        geminiService.onTranslatedText = { [weak self] text in
            guard let self = self else { return }
            self.currentResponse += text
            self.state = .speaking
        }
        
        geminiService.onAudioData = { [weak self] audioData in
            guard let self = self else { return }
            self.ttsService.playGeminiAudio(audioData)
            self.state = .speaking
        }
        
        geminiService.onTurnComplete = { [weak self] in
            guard let self = self else { return }
            if !self.currentResponse.isEmpty {
                self.sessionHistory.insert(MentorMessage(text: self.currentResponse, isUser: false), at: 0)
                self.currentResponse = ""
            }
            self.state = .active
        }
        
        geminiService.onError = { [weak self] error in
            self?.state = .error(error.localizedDescription)
            self?.endSession()
        }
        
        geminiService.onSetupComplete = { [weak self] in
            guard let self = self else { return }
            // If we are auto-starting, force the AI to say its first line
            if self.isAutoStarting {
                self.geminiService.sendTextMessage("Начни.")
            }
        }
    }
}
