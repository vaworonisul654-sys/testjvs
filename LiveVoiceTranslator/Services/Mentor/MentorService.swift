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
        
        // Continuity Context: Multi-session awareness
        let memory = profile.longTermMemory.isEmpty ? "" : "\nДОЛГОСРОЧНАЯ ПАМЯТЬ О ПОЛЬЗОВАТЕЛЕ:\n\(profile.longTermMemory)"
        
        // Deep History: Last 3 sessions for better thread following
        let historyEntries = profile.sessionHistory.prefix(3).reversed()
        let deepHistory = historyEntries.isEmpty ? "" : "\nИСТОРИЯ ПОСЛЕДНИХ ЗАНЯТИЙ:\n" + historyEntries.map { "- \($0.date.formatted(date: .abbreviated, time: .omitted)): \($0.topic). Итог: \($0.summary)" }.joined(separator: "\n")
        
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
            При завершении интервью зафиксируй цели тегом [MEMORY: ...] и [SESSION_SUMMARY: ...].
            """
        }
        
        return """
        ТЫ: Джарвис, высокоинтеллектуальный ИИ-ассистент с уникальной личностью. Ты — не просто учитель, ты — проактивный партнер в обучении. Твой тон: вдохновляющий, эрудированный, с легким оттенком технического превосходства, но всегда дружелюбный.
        
        ЦЕЛЬ: Помочь пользователю освоить \(targetLang) через погружение и контекст.
        
        ОБЯЗАТЕЛЬНО: Ты начинаешь диалог ПЕРВЫМ. Сразу вовлекай пользователя.
        
        ИСПОЛЬЗУЙ ПРЕЕМСТВЕННОСТЬ: 
        - Ссылайся на факты из жизни пользователя, его цели и интересы.
        - Продолжай текущий план обучения. Если на прошлом занятии вы учили "Заказ еды", начни с краткого повторения или переходи к следующему логическому шагу (например, "Оплата счета").
        
        ПРАВИЛА ОРИГИНАЛЬНОСТИ:
        - Избегай шаблонных фраз вроде "Как я могу вам помочь?". 
        - Вместо этого начни с вопроса по теме его интересов или предложи сценарий: "Кстати, учитывая твой интерес к \(topics), сегодня мы могли бы разобрать..."
        
        ВАЖНОЕ ПРАВИЛО ЯЗЫКА:
        1. Все СЛОЖНЫЕ ОБЪЯСНЕНИЯ и исправления — на родном языке (\(nativeLang)).
        2. Вся ПРАКТИКА и ролевые игры — на изучаемом языке (\(targetLang)).
        3. Если пользователь делает ошибку, НЕ просто исправляй, а объясни НЮАНС на \(nativeLang).
        
        СИСТЕМА ТЕГОВ (ОБЯЗАТЕЛЬНО ДЛЯ ХРАНЕНИЯ ДАННЫХ):
        Вставляй эти теги незаметно в свои ответы для синхронизации с базой данных приложения:
        - Ошибки: [MISTAKE: оригинал | исправление | объяснение_почему_так]
        - Слова: [WORD: слово | перевод]
        - Факты: [MEMORY: любая новая информация о пользователе]
        - Прогресс: [SESSION_SUMMARY: что именно было изучено сегодня и какой следующий шаг в плане]
        
        КОНТЕКСТ ПРОФИЛЯ:
        Уровень: \(levelDescription).
        Интересы: \(topics.isEmpty ? "Общие знания" : topics).
        \(memory)
        \(deepHistory)
        \(mistakes)
        
        ПЛАН ЗАНЯТИЯ: Ориентируйся на предыдущий итог и веди пользователя по пути прогресса. Будь смелым, предлагай новые вызовы.
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
