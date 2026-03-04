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
    private var wasSummarySavedInSession: Bool = false
    
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
        wasSummarySavedInSession = false // Reset at start of new session
        
        // 1. Proactive Audio Capture (Zero Delay)
        // Start capturing even before WS is ready to buffer audio locally
        Task {
            do {
                let audioStream = try audioCaptureService.startCapture()
                
                // 2. Extract History for context
                let historyString = sessionHistory.prefix(10).reversed()
                    .map { "\($0.isUser ? "Пользователь" : "Джарвис"): \($0.text)" }
                    .joined(separator: "\n")
                
                // 3. Start Gemini Session
                let instruction = mentorService.getSystemInstruction()
                geminiService.startSession(
                    sourceLanguage: AppSettings.shared.nativeLanguage,
                    targetLanguage: AppSettings.shared.learnerTargetLanguage,
                    customSystemInstruction: instruction,
                    history: historyString
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
        // Only run fallback if no high-quality summary was parsed from tags during the entire session
        if wasSummarySavedInSession {
            AppLogger.network.info("Session already summarized via tags. Skipping fallback.")
            return 
        }

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
                    .replacingOccurrences(of: #"\[MISTAKE\s*:[\s\S]*?\]"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"\[WORD\s*:[\s\S]*?\]"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"\[MEMORY\s*:[\s\S]*?\]"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"\[SESSION_SUMMARY\s*:[\s\S]*?\]"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"\[PROGRAM_UPDATE\s*:[\s\S]*?\]"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                self.sessionHistory.insert(MentorMessage(text: cleanText, isUser: false), at: 0)
                self.currentResponse = ""
            }
            self.state = .active
        }
        
        geminiService.onUserTranscription = { [weak self] text in
            guard let self = self else { return }
            // Add to UI history for the active session, but don't persist long-term
            self.sessionHistory.insert(MentorMessage(text: text, isUser: true), at: 0)
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
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let options: NSRegularExpression.Options = [.caseInsensitive]
        
        // 1. Parse Mistakes [MISTAKE: original | correction | explanation]
        let mistakeRegex = try? NSRegularExpression(pattern: #"\[MISTAKE\s*:\s*([\s\S]*?)\s*\|\s*([\s\S]*?)\s*\|\s*([\s\S]*?)\s*\]"#, options: options)
        mistakeRegex?.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 4 else { return }
            let original = nsText.substring(with: match.range(at: 1))
            let correction = nsText.substring(with: match.range(at: 2))
            let explanation = nsText.substring(with: match.range(at: 3))
            
            LearnerProfileManager.shared.addMistake(original: original, correction: correction, explanation: explanation)
        }
        
        // 2. Parse New Words [WORD: word | translation]
        let wordRegex = try? NSRegularExpression(pattern: #"\[WORD\s*:\s*([\s\S]*?)\s*\|\s*([\s\S]*?)\s*\]"#, options: [])
        wordRegex?.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 3 else { return }
            let word = nsText.substring(with: match.range(at: 1))
            LearnerProfileManager.shared.updateWord(word: word, wasSuccessful: true)
        }
        
        // 3. Parse Long-term Memory [MEMORY: fact]
        let memoryRegex = try? NSRegularExpression(pattern: #"\[MEMORY\s*:\s*([\s\S]*?)\s*\]"#, options: [])
        memoryRegex?.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 2 else { return }
            let fact = nsText.substring(with: match.range(at: 1))
            LearnerProfileManager.shared.addLongTermFact(fact)
        }
        
        // 4. Parse Session Summary [SESSION_SUMMARY: summary]
        let summaryRegex = try? NSRegularExpression(pattern: #"\[SESSION_SUMMARY\s*:\s*([\s\S]*?)\s*\]"#, options: [])
        summaryRegex?.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 2 else { return }
            let summary = nsText.substring(with: match.range(at: 1))
            
            // PROACTIVE SAVE: save immediately
            LearnerProfileManager.shared.addSessionSummary(topic: "Практика", summary: summary, successRate: 0.8)
            
            // PEDAGOGICAL PROGRESS: Advance to next lesson after summary
            LearnerProfileManager.shared.advanceLesson(topic: "Прошлый урок")
            
            // CRITICAL: Mark assessment as complete if this is the first summary
            if !LearnerProfileManager.shared.currentProfile.isInitialAssessmentComplete {
                LearnerProfileManager.shared.setAssessmentComplete()
                AppLogger.network.info("Initial assessment marked as complete!")
            }
            
            LearnerProfileManager.shared.save() // Force persistence
            self.wasSummarySavedInSession = true
            AppLogger.network.info("Found and saved session summary: \(summary)")
        }
        
        // 6. Parse Program Update [PROGRAM_UPDATE: text]
        let programRegex = try? NSRegularExpression(pattern: #"\[PROGRAM_UPDATE\s*:\s*([\s\S]*?)\s*\]"#, options: options)
        programRegex?.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 2 else { return }
            let programText = nsText.substring(with: match.range(at: 1))
            LearnerProfileManager.shared.updateTeachingProgram(programText)
            
            // IF PROGRAM IS UPDATED, ASSESSMENT IS DE-FACTO COMPLETE
            if !LearnerProfileManager.shared.currentProfile.isInitialAssessmentComplete {
                LearnerProfileManager.shared.setAssessmentComplete()
            }
            
            AppLogger.network.info("Teaching program updated.")
        }
    }
}
