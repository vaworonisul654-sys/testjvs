import Foundation

/// Defines the user's progress, strengths, and weaknesses for personalized learning
struct LearnerProfile: Codable {
    var totalSessions: Int = 0
    var overallLevel: Double = 1.0 // 1.0 (Beginner) to 5.0 (Advanced)
    var interestTopics: [String: Double] = [:] // Topic: Weight (0.0 to 1.0)
    var vocabularyStats: [String: WordMastery] = [:] // Word: Mastery info
    var pronunciationScores: [String: Double] = [:] // Language: Average score
    var preferredTeachingStyle: TeachingStyle = .balanced
    
    // Dashboard Metrics
    var vocabularyScore: Double = 0.2
    var pronunciationScore: Double = 0.2
    var grammarScore: Double = 0.2
    var fluencyScore: Double = 0.2
    
    var streakCount: Int = 0
    var lastPracticeDate: Date?
    var recentMistakes: [Mistake] = []
    
    // Educational Continuity
    var lastLessonSummary: String?
    var sessionHistory: [SessionSummary] = []
    
    var isInitialAssessmentComplete: Bool = false
    
    struct SessionSummary: Codable, Identifiable {
        let id: UUID
        let date: Date
        let topic: String
        let summary: String
        let successRate: Double
    }
    
    struct WordMastery: Codable {
        var attempts: Int = 0
        var successes: Int = 0
        var lastAttempt: Date = Date()
        var successRate: Double { attempts == 0 ? 0 : Double(successes) / Double(attempts) }
    }
    
    struct Mistake: Codable, Identifiable {
        let id: UUID
        let original: String
        let correction: String
        let explanation: String
        let date: Date
        
        init(original: String, correction: String, explanation: String) {
            self.id = UUID()
            self.original = original
            self.correction = correction
            self.explanation = explanation
            self.date = Date()
        }
    }
    
    enum TeachingStyle: String, Codable {
        case supportive, strict, balanced
    }
}

/// Manages the persistence and updates of the LearnerProfile
final class LearnerProfileManager {
    static let shared = LearnerProfileManager()
    private let profileKey = "jarvis_learner_profile"
    
    var currentProfile: LearnerProfile
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(LearnerProfile.self, from: data) {
            self.currentProfile = profile
        } else {
            self.currentProfile = LearnerProfile()
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(currentProfile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }
    
    func setAssessmentComplete() {
        currentProfile.isInitialAssessmentComplete = true
        save()
    }
    
    func updateStreak() {
        let calendar = Calendar.current
        let today = Date()
        
        guard let lastDate = currentProfile.lastPracticeDate else {
            currentProfile.streakCount = 1
            currentProfile.lastPracticeDate = today
            save()
            return
        }
        
        if calendar.isDateInYesterday(lastDate) {
            currentProfile.streakCount += 1
            currentProfile.lastPracticeDate = today
        } else if !calendar.isDateInToday(lastDate) {
            currentProfile.streakCount = 1
            currentProfile.lastPracticeDate = today
        }
        save()
    }
    
    func addMistake(original: String, correction: String, explanation: String) {
        let mistake = LearnerProfile.Mistake(original: original, correction: correction, explanation: explanation)
        currentProfile.recentMistakes.insert(mistake, at: 0)
        if currentProfile.recentMistakes.count > 10 {
            currentProfile.recentMistakes.removeLast()
        }
        save()
    }
    
    func updateMetrics(vocabulary: Double? = nil, pronunciation: Double? = nil, grammar: Double? = nil, fluency: Double? = nil) {
        if let v = vocabulary { currentProfile.vocabularyScore = v }
        if let p = pronunciation { currentProfile.pronunciationScore = p }
        if let g = grammar { currentProfile.grammarScore = g }
        if let f = fluency { currentProfile.fluencyScore = f }
        save()
    }
    
    func updateWord(word: String, wasSuccessful: Bool) {
        var mastery = currentProfile.vocabularyStats[word] ?? LearnerProfile.WordMastery()
        mastery.attempts += 1
        if wasSuccessful { mastery.successes += 1 }
        mastery.lastAttempt = Date()
        currentProfile.vocabularyStats[word] = mastery
        save()
    }
    
    func addTopicInterest(topic: String, weight: Double = 0.1) {
        let currentWeight = currentProfile.interestTopics[topic] ?? 0.0
        currentProfile.interestTopics[topic] = min(1.0, currentWeight + weight)
        save()
    }
    
    func updatePronunciation(language: String, score: Double) {
        let currentScore = currentProfile.pronunciationScores[language] ?? 0.5
        // Moving average to smooth spikes
        currentProfile.pronunciationScores[language] = (currentScore * 0.7) + (score * 0.3)
        save()
    }
    
    func addSessionSummary(topic: String, summary: String, successRate: Double) {
        let session = LearnerProfile.SessionSummary(
            id: UUID(),
            date: Date(),
            topic: topic,
            summary: summary,
            successRate: successRate
        )
        currentProfile.sessionHistory.insert(session, at: 0)
        currentProfile.lastLessonSummary = summary
        
        // Limit history size
        if currentProfile.sessionHistory.count > 20 {
            currentProfile.sessionHistory.removeLast()
        }
        
        currentProfile.totalSessions += 1
        save()
    }
}
