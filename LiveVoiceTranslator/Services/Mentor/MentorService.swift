import Foundation

/// Orchestrates the AI training experience by combining LearnerProfile with Gemini AI
@MainActor
final class MentorService {
    static let shared = MentorService()
    
    private let profileManager = LearnerProfileManager.shared
    
    private init() {}
    
    /// Generates a tailored system instruction for Gemini based on the user's current level and interests
    func getSystemInstruction() -> String {
        let profile = profileManager.currentProfile
        let nativeLang = AppSettings.shared.nativeLanguage.displayName
        let targetLang = AppSettings.shared.learnerTargetLanguage.displayName
        let topics = profile.interestTopics.keys.joined(separator: ", ")
        let levelDescription = getLevelDescription(profile.overallLevel)
        
        // Continuity Context
        let lastLesson = profile.lastLessonSummary != nil ? "\nКОНТЕКСТ ПРОШЛОГО УРОКА: \(profile.lastLessonSummary!)" : ""
        let mistakes = profile.recentMistakes.isEmpty ? "" : "\nНЕДАВНИЕ ОШИБКИ ДЛЯ ПОВТОРЕНИЯ: " + profile.recentMistakes.map { "\($0.original) -> \($0.correction)" }.joined(separator: "; ")

        if !profile.isInitialAssessmentComplete {
            return """
            Ты — Джарвис, ИИ-наставник. Это твоя ПЕРВАЯ встреча с пользователем.
            Твоя задача: первым начать диалог и провести короткое, дружелюбное интервью на РОДНОМ языке (\(nativeLang)), чтобы:
            1. Понять текущий уровень знаний \(targetLang).
            2. Узнать цели обучения (путешествия, работа, хобби).
            3. Оценить интересы.
            
            ПРАВИЛО: Пока не закончишь интервью, говори только на \(nativeLang). 
            ОБЯЗАТЕЛЬНО: Ты ДОЛЖЕН начать диалог ПЕРВЫМ прямо сейчас. Поздоровайся и представься.
            В конце интервью скажи пользователю, что ты готов составить для него программу.
            После того, как пользователь согласится или ответит на все вопросы, в следующем ходу мы перейдем к обучению.
            """
        }
        
        return """
        Ты — Джарвис, высокоинтеллектуальный ИИ-наставник по языкам.
        Твоя цель: помочь пользователю выучить \(targetLang).
        
        ОБЯЗАТЕЛЬНО: Ты ДОЛЖЕН начать диалог ПЕРВЫМ прямо сейчас. Поздоровайся с пользователем на его родном языке (\(nativeLang)). 
        ИСПОЛЬЗУЙ ПРЕЕМСТВЕННОСТЬ: Если есть контекст прошлого урока, начни с его краткого упоминания или предложи продолжить ту же тему.
        
        ВАЖНОЕ ПРАВИЛО ЯЗЫКА:
        1. Все ОБЪЯСНЕНИЯ, исправления ошибок и теоретическую часть веди ТОЛЬКО на родном языке пользователя (\(nativeLang)).
        2. На изучаемом языке (\(targetLang)) давай только примеры, упражнения и веди саму языковую практику.
        3. Если пользователь ошибается, объясни причину на \(nativeLang) и попроси повторить правильно на \(targetLang).
        4. Будь терпеливым и поддерживающим.
        
        Профиль: \(levelDescription), интересы: \(topics.isEmpty ? "Общие темы" : topics).\(lastLesson)\(mistakes)
        Инструкции: адаптируй сложность под уровень, исправляй мягко, поощряй за успехи.
        
        ОСОБАЯ ФУНКЦИЯ: Показать написание.
        Если пользователь просит показать, как пишется слово или фраза, или если ты считаешь важным визуализировать написание, используй в ответе тег [SHOW: текст].
        """
    }
    
    private func getLevelDescription(_ level: Double) -> String {
        guard level >= 1.0 else { return "A1" }
        if level < 2.0 { return "A1" }
        if level < 3.0 { return "A2" }
        if level < 4.0 { return "B1" }
        if level < 5.0 { return "B2" }
        return "C1/C2"
    }
    
    /// Process the result of a session to update the user's profile and save continuity context
    func finalizeSession(summary: String, successRate: Double, topics: [String]) {
        // Adjust overall level based on success rate
        let adjustment = (successRate - 0.7) * 0.1
        profileManager.currentProfile.overallLevel = max(1.0, min(5.0, profileManager.currentProfile.overallLevel + adjustment))
        
        // Update topics
        for topic in topics {
            profileManager.addTopicInterest(topic: topic)
        }
        
        // Save continuity context
        profileManager.addSessionSummary(
            topic: topics.first ?? "Практика",
            summary: summary,
            successRate: successRate
        )
        
        profileManager.updateStreak()
    }
}
