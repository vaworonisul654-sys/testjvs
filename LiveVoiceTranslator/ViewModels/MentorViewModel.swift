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
    var isDashboardPresented: Bool = false
    
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
        
        // 1. Proactive Audio Capture (Zero Delay)
        // Start capturing even before WS is ready to buffer audio locally
        Task {
            do {
                let audioStream = try audioCaptureService.startCapture()
                
                // 2. Start Gemini Session
                let instruction = mentorService.getSystemInstruction()
                geminiService.startSession(
                    sourceLanguage: AppSettings.shared.nativeLanguage,
                    targetLanguage: AppSettings.shared.learnerTargetLanguage,
                    customSystemInstruction: instruction
                )
                
                UIApplication.shared.isIdleTimerDisabled = true
                
                audioStreamTask = Task {
                    for await chunk in audioStream {
                        guard !Task.isCancelled else { break }
                        
                        await MainActor.run {
                            self.audioLevel = self.audioCaptureService.currentLevel
                        }
                        
                        // Buffer or send if ready
                        if geminiService.isSessionActive {
                            guard !self.ttsService.isSpeaking else { continue }
                            self.geminiService.sendAudioChunk(chunk)
                        }
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
                // Parse and save educational context before inserting to history
                self.parseAndProcessTags(self.currentResponse)
                
                // Clean text for UI
                let cleanText = self.currentResponse
                    .replacingOccurrences(of: #"\[MISTAKE:.*?\]"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"\[WORD:.*?\]"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"\[MEMORY:.*?\]"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"\[SESSION_SUMMARY:.*?\]"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                self.sessionHistory.insert(MentorMessage(text: cleanText, isUser: false), at: 0)
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
            // If we are auto-starting (via button press), force the AI to say its first line
            if self.isAutoStarting {
                self.geminiService.sendTextMessage("Начни.")
            }
        }
    }
    
    private func parseAndProcessTags(_ text: String) {
        // 1. Parse Mistakes [MISTAKE: original | correction | explanation]
        let mistakeRegex = try? NSRegularExpression(pattern: #"\[MISTAKE:\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\]"#, options: [])
        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        
        mistakeRegex?.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 4 else { return }
            
            if let originalRange = Range(match.range(at: 1), in: text),
               let correctionRange = Range(match.range(at: 2), in: text),
               let explanationRange = Range(match.range(at: 3), in: text) {
                
                let original = String(text[originalRange])
                let correction = String(text[correctionRange])
                let explanation = String(text[explanationRange])
                
                LearnerProfileManager.shared.addMistake(
                    original: original,
                    correction: correction,
                    explanation: explanation
                )
                AppLogger.network.info("Found and saved mistake: \(original) -> \(correction)")
            }
        }
        
        // 2. Parse New Words [WORD: word | translation]
        let wordRegex = try? NSRegularExpression(pattern: #"\[WORD:\s*(.*?)\s*\|\s*(.*?)\s*\]"#, options: [])
        wordRegex?.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 3 else { return }
            
            if let wordRange = Range(match.range(at: 1), in: text) {
                let word = String(text[wordRange])
                LearnerProfileManager.shared.updateWord(word: word, wasSuccessful: true)
                AppLogger.network.info("Found and saved word mastery: \(word)")
            }
        }
        
        // 3. Parse Long-term Memory [MEMORY: fact]
        let memoryRegex = try? NSRegularExpression(pattern: #"\[MEMORY:\s*(.*?)\s*\]"#, options: [])
        memoryRegex?.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 2 else { return }
            if let range = Range(match.range(at: 1), in: text) {
                let fact = String(text[range])
                LearnerProfileManager.shared.addLongTermFact(fact)
                AppLogger.network.info("Found and saved long-term fact: \(fact)")
            }
        }
        
        // 4. Parse Session Summary [SESSION_SUMMARY: summary]
        let summaryRegex = try? NSRegularExpression(pattern: #"\[SESSION_SUMMARY:\s*(.*?)\s*\]"#, options: [])
        summaryRegex?.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 2 else { return }
            if let range = Range(match.range(at: 1), in: text) {
                let summary = String(text[range])
                // Save it immediately as the latest lesson summary
                LearnerProfileManager.shared.addSessionSummary(topic: "Практика", summary: summary, successRate: 0.8)
                AppLogger.network.info("Found and saved session summary: \(summary)")
            }
        }
    }
}
