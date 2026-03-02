import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = AppSettings.shared
    @State private var step = 1
    @State private var selectedLevel: Double = 1.0
    
    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.027, blue: 0.059).ignoresSafeArea()
            
            // Background glow
            Circle()
                .fill(emerald.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(y: -200)
            
            VStack(spacing: 30) {
                if step == 1 {
                    welcomeStep
                } else if step == 2 {
                    nativeLanguageStep
                } else if step == 3 {
                    targetLanguageStep
                } else if step == 4 {
                    proficiencyLevelStep
                } else {
                    notificationsStep
                }
            }
            .padding(30)
            .multilineTextAlignment(.center)
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .stroke(emerald.opacity(0.2), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "cpu")
                    .font(.system(size: 60))
                    .foregroundStyle(emerald)
                    .shadow(color: emerald.opacity(0.5), radius: 10)
            }
            
            Text("Я — Джарвис")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Ваш персональный ИИ-наставник. Я помогу вам не просто переводить, а по-настоящему выучить любой язык.")
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal)
            
            Spacer()
            
            mainButton(title: "Начать знакомство") {
                withAnimation { step = 2 }
            }
        }
    }
    
    private var nativeLanguageStep: some View {
        VStack(spacing: 20) {
            Text("Ваш родной язык")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Я определил его как \(settings.nativeLanguage.nameInRussian). Всё верно?")
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(0.7))
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Language.allCases) { lang in
                        LanguageRow(language: lang, isSelected: settings.nativeLanguage == lang) {
                            settings.nativeLanguage = lang
                        }
                    }
                }
            }
            .frame(maxHeight: 400)
            
            Spacer()
            
            mainButton(title: "Далее") {
                withAnimation { step = 3 }
            }
        }
    }
    
    private var targetLanguageStep: some View {
        VStack(spacing: 20) {
            Text("Что будем учить?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Выберите язык, который вы хотите освоить под моим руководством.")
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(0.7))
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Language.allCases) { lang in
                        if lang != settings.nativeLanguage {
                            LanguageRow(language: lang, isSelected: settings.learnerTargetLanguage == lang) {
                                settings.learnerTargetLanguage = lang
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 400)
            
            Spacer()
            
            mainButton(title: "Далее") {
                withAnimation { step = 4 }
            }
        }
    }
    
    private var proficiencyLevelStep: some View {
        VStack(spacing: 20) {
            Text("Оцените ваш уровень")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Как хорошо вы уже знаете \(settings.learnerTargetLanguage.nameInRussian)? Я настрою программу индивидуально под вас.")
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 16) {
                LevelRow(title: "Начинающий", subtitle: "Учу с нуля или знаю пару слов (A1)", level: 1.0, selectedLevel: selectedLevel) { selectedLevel = 1.0 }
                LevelRow(title: "Элементарный", subtitle: "Могу поддержать простой диалог (A2)", level: 2.0, selectedLevel: selectedLevel) { selectedLevel = 2.0 }
                LevelRow(title: "Средний", subtitle: "Понимаю речь, могу общаться (B1)", level: 3.0, selectedLevel: selectedLevel) { selectedLevel = 3.0 }
                LevelRow(title: "Выше среднего", subtitle: "Свободно говорю на многие темы (B2)", level: 4.0, selectedLevel: selectedLevel) { selectedLevel = 4.0 }
                LevelRow(title: "Продвинутый", subtitle: "Почти как носитель (C1-C2)", level: 5.0, selectedLevel: selectedLevel) { selectedLevel = 5.0 }
            }
            .padding(.top, 10)
            
            Spacer()
            
            mainButton(title: "Далее") {
                // Update profile
                LearnerProfileManager.shared.currentProfile.overallLevel = selectedLevel
                LearnerProfileManager.shared.save()
                withAnimation { step = 5 }
            }
        }
    }
    
    private var notificationsStep: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundStyle(emerald)
                .shadow(color: emerald.opacity(0.5), radius: 10)
            
            Text("Ежедневная практика")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 10)
            
            Text("Для быстрого результата важна регулярность. Я буду напоминать вам зайти на короткий урок каждый день в 10:00 утра.")
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal)
            
            Spacer()
            
            mainButton(title: "Начать обучение") {
                NotificationManager.shared.requestAuthorization { _ in
                    // Complete onboarding regardless of permission grant to avoid blocking the user
                    DispatchQueue.main.async {
                        settings.isOnboardingComplete = true
                        dismiss()
                    }
                }
            }
            
            Button("Пропустить") {
                settings.isOnboardingComplete = true
                dismiss()
            }
            .font(.system(size: 16))
            .foregroundStyle(.white.opacity(0.5))
            .padding(.top, 8)
        }
    }
    
    private func mainButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(emerald)
                )
        }
    }
}

private struct LevelRow: View {
    let title: String
    let subtitle: String
    let level: Double
    let selectedLevel: Double
    let action: () -> Void
    
    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    
    var isSelected: Bool {
        abs(level - selectedLevel) < 0.1
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isSelected ? emerald : .white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(emerald)
                } else {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? emerald.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? emerald.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct LanguageRow: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void
    
    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(language.flag)
                Text(language.nameInRussian)
                    .foregroundStyle(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(emerald)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? emerald.opacity(0.1) : .white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? emerald.opacity(0.5) : .white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    WelcomeView()
}
