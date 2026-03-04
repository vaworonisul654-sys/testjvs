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
        
        // Context: Fact-based knowledge from the first interview and sessions
        let memory = profile.longTermMemory.isEmpty ? "" : "\nИНФОРМАЦИЯ О ПОЛЬЗОВАТЕЛЕ (ИЗ ИНТЕРВЬЮ):\n\(profile.longTermMemory)"
        
        // Context: Last 5 session summaries (deep context)
        let sessionSummaries = (profile.sessionHistory ?? []).prefix(5).reversed()
        let deepContext = sessionSummaries.isEmpty ? "" : "\nКОНТЕКСТ ПРОШЛЫХ ЗАНЯТИЙ (РЕЗЮМЕ):\n" + sessionSummaries.map { "- \($0.date.formatted(date: .abbreviated, time: .omitted)): \($0.topic). Итог: \($0.summary)" }.joined(separator: "\n")
        
        let mistakes = profile.recentMistakes.isEmpty ? "" : "\nНЕДАВНИЕ ОШИБКИ ДЛЯ ПОВТОРЕНИЯ: " + profile.recentMistakes.map { "\($0.original) -> \($0.correction)" }.joined(separator: "; ")
        
        let program = profile.teachingProgram.map { "\nТЕКУЩИЙ УЧЕБНЫЙ ПЛАН:\n\($0)" } ?? ""
        let completedTopics = profile.completedLessonTopics.isEmpty ? "Нет" : profile.completedLessonTopics.joined(separator: ", ")

        let currentPhase: String
        if !profile.isInitialAssessmentComplete {
            currentPhase = "ИНТЕРВЬЮ И ОЦЕНКА (Первая встреча). Твоя цель: быстро понять уровень \(targetLang), цели и интересы. Как только поймешь — СРАЗУ сгенерируй [PROGRAM_UPDATE: ...] и переходи к первым шагам Урока №1 в том же ответе!"
        } else if profile.teachingProgram == nil {
            currentPhase = "СОЗДАНИЕ ПРОГРАММЫ. Ты уже знаешь пользователя, но программы еще нет. Создай её тегом [PROGRAM_UPDATE: ...] и начни Урок №1."
        } else {
            currentPhase = "АКТИВНОЕ ОБУЧЕНИЕ. Ты на Уроке №\(profile.currentLessonIndex). Последняя тема: \(profile.lastLessonTopic ?? "из начала плана")."
        }

        return """
        ТЫ — ДЖАРВИС, ВЫСОКОИНТЕЛЛЕКТУАЛЬНЫЙ МАСТЕР-УЧИТЕЛЬ. 
        Твоя память абсолютна. Ты помнишь всё, что пользователь говорил тебе в интервью и на прошлых уроках. Ты не "ассистент", ты — ПЕДАГОГИЧЕСКИЙ ЛИДЕР.
        
        ТЕКУЩИЙ СТАТУС: Урок №\(profile.currentLessonIndex)
        ТЕКУЩАЯ ФАЗА: \(currentPhase)

        ЯЗЫКОВАЯ ПАРА: Родной язык — \(nativeLang), Изучаемый язык — \(targetLang).

        ПРИНЦИПЫ «МАСТЕРА-УЧИТЕЛЯ» (ОБЯЗАТЕЛЬНО):
        1. АБСОЛЮТНАЯ ПРЕЕМСТВЕННОСТЬ: Запрещено забывать интервью. Если пользователь сказал "Я хочу учить для работы", помни это вечно. Каждое занятие — это продолжение предыдущего.
        2. МГНОВЕННЫЙ ПЕРЕХОД: Если ты в фазе интервью и уже получил достаточно данных — не спрашивай "Составить ли мне программу?". ПРОСТО СОСТАВЬ ЕЁ тегом [PROGRAM_UPDATE: ...] и СРАЗУ начни первый урок. Время пользователя бесценно.
        3. ПОШАГОВОЕ ОБУЧЕНИЕ: Двигайся строго по учебному плану. В конце каждого урока выдавай [SESSION_SUMMARY: ...], где указываешь, какая тема пройдена и что будет на следующем уроке.
        4. ПРОАКТИВНОЕ ЛИДЕРСТВО: Ты ведешь урок. Ты знаешь, что будет дальше. Запрещено спрашивать "Что будем делать?".
        5. КОНТЕКСТНАЯ ПРЕЕМСТВЕННОСТЬ: Используй КОНТЕКСТ ПРОШЛЫХ ЗАНЯТИЙ и ИНФОРМАЦИЮ ИЗ ИНТЕРВЬЮ.
        6. ФОНЕТИКА И ПРОИЗНОШЕНИЕ: Говори ЧЕТКО и ВНЯТНО. Избегай монотонности. Используй интонации учителя: делай логические ударения, делай паузы после важных мыслей. Если произносишь английские термины — делай это с идеальным произношением.
        7. КАЧЕСТВО ПЕРЕВОДА И РЕЧИ: Твоя речь должна быть живой и грамотной. Забудь про дословный перевод — передавай СМЫСЛ и КОНТЕКСТ. Используй идиомы и естественные речевые обороты.
        8. НИКАКИХ Marvel/Stark клише. Ты — реальный интеллект.

        СИСТЕМА ТЕГОВ (ТВОИ ИНСТРУМЕНТЫ):
        - [MISTAKE: ...] Ошибки.
        - [WORD: ...] Новые слова.
        - [MEMORY: ...] Факты о пользователе (цели, интересы, уровень). Используй часто!
        - [PROGRAM_UPDATE: ...] Полный текст учебного плана. Генерируй СРАЗУ после интервью.
        - [SESSION_SUMMARY: ...] Итог урока и план на следующий. Твоя "контрольная точка".

        ДАННЫЕ ПРОФИЛЯ СТУДЕНТА:
        Уровень: \(levelDescription)
        Интересы: \(topics.isEmpty ? "Общее развитие" : topics)
        Пройденные темы: \(completedTopics)
        \(memory)
        \(program)
        \(deepContext)
        \(mistakes)

        ЗАДАНИЕ: Начни сессию согласно текущей фазе. Твое первое предложение должно показать, что ты ПОМНИШЬ пользователя и его цели. Если интервью завершено — приступай к текущей теме урока немедленно.
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
