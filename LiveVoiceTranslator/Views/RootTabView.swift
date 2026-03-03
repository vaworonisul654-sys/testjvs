import SwiftUI
import Observation

// MARK: - Root Tab View

// MARK: - Root Tab View

/// Root tab navigation — Voice / Photo / Text
struct RootTabView: View {
    @State private var selectedTab: Tab = .voice
    @State private var settings = AppSettings.shared
    @State private var showOnboarding = false

    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    private let bgColor = Color(red: 0.02, green: 0.027, blue: 0.059)

    enum Tab: String {
        case voice, text, mentor, photo, memory
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .voice:
                    MainTranslatorView()
                case .text:
                    TextTranslatorView()
                case .mentor:
                    MentorView(autoStart: false)
                case .photo:
                    PhotoTranslatorView()
                case .memory:
                    MemoryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tab bar
            tabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showOnboarding) {
            WelcomeView()
        }
        .onAppear {
            if !settings.isOnboardingComplete {
                showOnboarding = true
            }
            NotificationManager.shared.requestAuthorization { _ in }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(tab: .voice, icon: "waveform.circle", label: "Голос")
            tabButton(tab: .text, icon: "text.bubble", label: "Текст")
            
            // Central Jarvis Button
            jarvisCoreButton
            
            tabButton(tab: .photo, icon: "camera", label: "Фото")
            tabButton(tab: .memory, icon: "cpu", label: "Память")
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 26)
        .background(
            Rectangle()
                .fill(bgColor.opacity(0.95))
                .background(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [emerald.opacity(0.06), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }

    private var jarvisCoreButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedTab = .mentor
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [emerald.opacity(0.8), emerald.opacity(0.2)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: emerald.opacity(0.5), radius: 10)
                
                Circle()
                    .stroke(emerald.opacity(0.5), lineWidth: 2)
                    .frame(width: 64, height: 64)
                    .scaleEffect(selectedTab == .mentor ? 1.1 : 1.0)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating, value: selectedTab == .mentor)
            }
            .offset(y: -20)
        }
        .frame(maxWidth: .infinity)
    }

    private func tabButton(tab: Tab, icon: String, label: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? icon + ".fill" : icon)
                    .font(.system(size: 20))
                    .foregroundStyle(selectedTab == tab ? emerald : .white.opacity(0.3))
                    .symbolEffect(.bounce, value: selectedTab == tab)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? emerald : .white.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// Removed duplicate MentorView and MentorViewModel

// Removed duplicate WelcomeView and LanguageRow

// MARK: - Photo Placeholder

struct PhotoPlaceholderView: View {
    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.027, blue: 0.059).ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    Circle().fill(emerald.opacity(0.06)).frame(width: 100, height: 100)
                    Image(systemName: "camera.viewfinder").font(.system(size: 44)).foregroundStyle(emerald.opacity(0.4))
                }
                Text("Фото перевод").font(.system(size: 20, weight: .bold)).foregroundStyle(.white.opacity(0.6))
                Text("Скоро").font(.system(size: 13)).foregroundStyle(.white.opacity(0.2))
            }
        }
    }
}

#Preview {
    RootTabView()
}

// MARK: - Mentor Dashboard UI

struct MentorDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    private let profile = LearnerProfileManager.shared.currentProfile
    
    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    private let bgColor = Color(red: 0.02, green: 0.027, blue: 0.059)
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                
                // Background glow
                Circle()
                    .fill(emerald.opacity(0.05))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(x: -150, y: -200)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Summary
                        summaryHeader
                        
                        // Radar Chart Section
                        radarChartSection
                        
                        // Detailed Metrics Grid
                        metricsGrid
                        
                        // Achievements / Streak
                        streakCard
                        
                        // Recent Mistakes
                        if !profile.recentMistakes.isEmpty {
                            mistakesSection
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Мой Прогресс")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundStyle(emerald)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private var summaryHeader: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("LEVEL")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.emerald)
                    .tracking(2)
                
                Text(getLevelText(profile.overallLevel))
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("СЕССИЙ")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                
                Text("\(profile.totalSessions)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background(glassBackground)
    }
    
    private var radarChartSection: some View {
        VStack(spacing: 20) {
            Text("КАРТА НАВЫКОВ")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(2)
            
            RadarChartView(
                metrics: [
                    profile.vocabularyScore,
                    profile.pronunciationScore,
                    profile.grammarScore,
                    profile.fluencyScore
                ],
                labels: ["Слова", "Звук", "Грамм.", "Беглость"]
            )
            .frame(height: 200)
            .padding(.vertical)
        }
        .padding()
        .background(glassBackground)
    }
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            MetricCard(title: "Слова", value: profile.vocabularyScore, icon: "textformat.abc")
            MetricCard(title: "Речь", value: profile.pronunciationScore, icon: "waveform")
            MetricCard(title: "Грамматика", value: profile.grammarScore, icon: "list.bullet.indent")
            MetricCard(title: "Беглость", value: profile.fluencyScore, icon: "bolt.fill")
        }
    }
    
    private var streakCard: some View {
        HStack {
            Image(systemName: "flame.fill")
                .font(.system(size: 30))
                .foregroundStyle(profile.streakCount > 0 ? .orange : .white.opacity(0.1))
            
            VStack(alignment: .leading) {
                Text("\(profile.streakCount) ДНЯ")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Серия занятий")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            if profile.streakCount > 0 {
                Text("🔥 Отлично!")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(glassBackground)
    }
    
    private var mistakesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("РАБОТА НАД ОШИБКАМИ")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.emerald)
                .tracking(2)
            
            ForEach(profile.recentMistakes) { mistake in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red.opacity(0.6))
                        Text(mistake.original)
                            .strikethrough()
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.emerald)
                        Text(mistake.correction)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    
                    Text(mistake.explanation)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.leading, 24)
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(glassBackground)
    }
    
    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(DesignSystem.Colors.glassWhite)
            .background(.ultraThinMaterial.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(DesignSystem.Colors.glassBorder, lineWidth: 1)
            )
    }
    
    private func getLevelText(_ level: Double) -> String {
        if level < 2.0 { return "A1" }
        if level < 3.0 { return "A2" }
        if level < 4.0 { return "B1" }
        if level < 5.0 { return "B2" }
        return "C1"
    }
}

struct MetricCard: View {
    let title: String
    let value: Double
    let icon: String
    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(emerald)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.05)).frame(height: 6)
                    Capsule().fill(emerald).frame(width: geo.size.width * CGFloat(value), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.03))
                .background(.ultraThinMaterial.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.05), lineWidth: 1))
        )
    }
}

struct RadarChartView: View {
    let metrics: [Double] // Expected 4 metrics
    let labels: [String]
    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 * 0.8
            
            ZStack {
                // Background Grids
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { r in
                    RadarShape(sides: 4, percent: r)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                        .frame(width: radius * 2, height: radius * 2)
                }
                
                // Content Shape
                RadarShape(sides: 4, metrics: metrics)
                    .fill(emerald.opacity(0.3))
                    .frame(width: radius * 2, height: radius * 2)
                
                RadarShape(sides: 4, metrics: metrics)
                    .stroke(emerald, lineWidth: 2)
                    .frame(width: radius * 2, height: radius * 2)
                
                // Labels
                ForEach(0..<4) { i in
                    let angle = (Double(i) * (2 * .pi / 4)) - (.pi / 2)
                    let x = center.x + (radius + 20) * cos(angle)
                    let y = center.y + (radius + 20) * sin(angle)
                    
                    Text(labels[i])
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .position(x: x, y: y)
                }
            }
        }
    }
}

struct RadarShape: Shape {
    let sides: Int
    var metrics: [Double] = []
    var percent: Double = 1.0
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        
        for i in 0..<sides {
            let angle = (Double(i) * (2 * .pi / Double(sides))) - (.pi / 2)
            let mValue = metrics.isEmpty ? percent : metrics[i]
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius * CGFloat(mValue),
                y: center.y + CGFloat(sin(angle)) * radius * CGFloat(mValue)
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// End of RootTabView.swift
