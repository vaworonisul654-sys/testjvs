import SwiftUI

/// Main screen — Premium Emerald Glassmorphism Design
struct MainTranslatorView: View {
    @State private var viewModel = TranslatorViewModel()
    @State private var backgroundPhase: CGFloat = 0
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Deep obsidian-emerald fluid gradient background
            animatedBackground

            VStack(spacing: 0) {
                // Title
                ZStack {
                    headerSection
                    
                    HStack {
                        Spacer()
                        Button { showSettings = true } label: {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.05))
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.1), lineWidth: 1)
                                    )
                                
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, Constants.UI.horizontalMargin)
                }
                .padding(.top, 12)

                // Language selector
                languageHeader
                    .padding(.top, 8)

                // Warnings / errors
                if !viewModel.isAPIKeyConfigured {
                    apiKeyBanner
                        .padding(.horizontal, Constants.UI.horizontalMargin)
                        .padding(.top, 10)
                }

                if case .error(let msg) = viewModel.state {
                    errorBanner(msg)
                        .padding(.horizontal, Constants.UI.horizontalMargin)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Live card
                if viewModel.state.isActive || !viewModel.currentTranslation.isEmpty {
                    liveTranslationCard
                        .padding(.horizontal, Constants.UI.horizontalMargin)
                        .padding(.bottom, 10)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                // Chat area + Orb
                ZStack(alignment: .bottom) {
                    translationArea
                    
                    if !viewModel.state.isActive && viewModel.messages.isEmpty {
                        // Orb is placed inside empty state via translationArea
                    } else {
                        // Floating orb when active or has messages
                        recordSection
                            .padding(.bottom, 30)
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.state)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                backgroundPhase = 1
            }
        }
        .onDisappear {
            viewModel.stopRecording()
        }
    }

    // MARK: - Animated Background

    private var animatedBackground: some View {
        ZStack {
            // Base layer: deep obsidian-black
            Color(red: 0.01, green: 0.02, blue: 0.04)
                .ignoresSafeArea()

            // Emerald fluid gradient — moving
            Canvas { context, size in
                // 1. Large sapphire-teal glow — top right
                let gradient1 = Gradient(colors: [
                    Color(red: 0.05, green: 0.25, blue: 0.20).opacity(0.7),
                    Color(red: 0.02, green: 0.10, blue: 0.08).opacity(0.3),
                    Color.clear
                ])
                let center1 = CGPoint(
                    x: size.width * (0.8 + sin(backgroundPhase * .pi * 2) * 0.15),
                    y: size.height * (0.15 + cos(backgroundPhase * .pi * 2) * 0.1)
                )
                context.fill(
                    Circle().path(in: CGRect(
                        x: center1.x - 300, y: center1.y - 300,
                        width: 600, height: 600
                    )),
                    with: .radialGradient(gradient1,
                        center: center1,
                        startRadius: 0, endRadius: 350)
                )

                // 2. Deep Emerald glow — middle left
                let gradient2 = Gradient(colors: [
                    Color(red: 0.0, green: 0.88, blue: 0.56).opacity(0.12),
                    Color.clear
                ])
                let center2 = CGPoint(
                    x: size.width * (0.2 - cos(backgroundPhase * .pi * 2) * 0.1),
                    y: size.height * (0.5 + sin(backgroundPhase * .pi * 2) * 0.15)
                )
                context.fill(
                    Circle().path(in: CGRect(
                        x: center2.x - 400, y: center2.y - 400,
                        width: 800, height: 800
                    )),
                    with: .radialGradient(gradient2,
                        center: center2,
                        startRadius: 0, endRadius: 400)
                )
                
                // 3. Subtle Cyan glow — bottom right
                let gradient3 = Gradient(colors: [
                    Color(red: 0.0, green: 0.4, blue: 0.5).opacity(0.15),
                    Color.clear
                ])
                let center3 = CGPoint(
                    x: size.width * (0.9 + sin(backgroundPhase * .pi * -1) * 0.1),
                    y: size.height * (0.9 + cos(backgroundPhase * .pi * 2) * 0.05)
                )
                context.fill(
                    Circle().path(in: CGRect(
                        x: center3.x - 350, y: center3.y - 350,
                        width: 700, height: 700
                    )),
                    with: .radialGradient(gradient3,
                        center: center3,
                        startRadius: 0, endRadius: 350)
                )
            }
            .blur(radius: 40) // Smooth out the canvas layers
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Text("Голосовой перевод")
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.95))
            .shadow(color: .black.opacity(0.3), radius: 2)
            .tracking(0.5)
    }

    // MARK: - Language Header

    private var languageHeader: some View {
        HStack(spacing: 0) {
            LanguagePickerView(
                selectedLanguage: $viewModel.sourceLanguage,
                label: "ИЗ"
            )

            // Swap button — glowing emerald circle
            Button(action: viewModel.swapLanguages) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0, green: 0.88, blue: 0.56).opacity(0.2),
                                    Color(red: 0, green: 0.76, blue: 0.66).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 0, green: 0.88, blue: 0.56).opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: Color(red: 0, green: 0.88, blue: 0.56).opacity(0.2), radius: 8)

                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0, green: 0.88, blue: 0.56))
                }
            }

            LanguagePickerView(
                selectedLanguage: $viewModel.targetLanguage,
                label: "НА"
            )
        }
        .padding(.horizontal, Constants.UI.horizontalMargin)
        .padding(.vertical, 8)
    }

    // MARK: - API Key Banner

    private var apiKeyBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(red: 0, green: 0.88, blue: 0.56))
                .font(.system(size: 13))

            Text("Добавьте GEMINI_API_KEY в Config/Debug.xcconfig")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)

            Spacer()
        }
        .padding(14)
        .background(glassBackground(tint: Color(red: 0, green: 0.88, blue: 0.56), opacity: 0.12))
    }

    // MARK: - Translation Area

    private var translationArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty && !viewModel.state.isActive {
                        emptyState
                    } else {
                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, Constants.UI.horizontalMargin)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.messages.count) { _, _ in
                if let first = viewModel.messages.first {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        proxy.scrollTo(first.id, anchor: .top)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            // 3D Orb Moved ABOVE the text as requested
            recordSection
                .scaleEffect(1.2) // Make it look like a prominent Orb
                .padding(.bottom, 10)

            VStack(spacing: 8) {
                Text("Нажмите на сферу и говорите")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Live Translation Card

    private var liveTranslationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if viewModel.state == .recording {
                    Circle()
                        .fill(Color(red: 0, green: 0.88, blue: 0.56))
                        .frame(width: 6, height: 6)
                        .shadow(color: Color(red: 0, green: 0.88, blue: 0.56).opacity(0.8), radius: 6)
                }

                Text(viewModel.state.statusText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                if viewModel.state == .recording {
                    Text("● LIVE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0, green: 0.88, blue: 0.56))
                }
            }

            if !viewModel.currentTranslation.isEmpty {
                Text(viewModel.currentTranslation)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(4)
            }

            if viewModel.state == .recording {
                WaveformView(level: viewModel.audioLevel, isActive: true)
                    .frame(height: 36)
                    .padding(.top, 4)
            }
        }
        .padding(18)
        .background(
            glassBackground(
                tint: viewModel.state == .recording
                    ? Color(red: 0, green: 0.88, blue: 0.56)
                    : .white,
                opacity: 0.1
            )
        )
        .shadow(color: .black.opacity(0.2), radius: 10)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red.opacity(0.9))
                .font(.system(size: 16))

            Text(message)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(2)

            Spacer()

            Button { viewModel.state = .idle } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(14)
        .background(glassBackground(tint: .red, opacity: 0.12))
    }

    // MARK: - Record Section

    private var recordSection: some View {
        VStack(spacing: 12) {
            RecordButton(
                isRecording: viewModel.state == .recording || viewModel.state == .translating || viewModel.state == .connecting,
                audioLevel: viewModel.audioLevel,
                onTap: { viewModel.toggleRecording() }
            )
        }
    }

    // MARK: - Glass Helper

    private var glassMaterial: some View {
        Color.clear
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
    }

    private func glassBackground(tint: Color, opacity: Double) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(tint.opacity(opacity))
            
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.15),
                                    .white.opacity(0.05),
                                    tint.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    MainTranslatorView()
}
