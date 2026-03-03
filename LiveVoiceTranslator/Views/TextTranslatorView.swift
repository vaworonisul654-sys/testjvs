import SwiftUI

/// Text translation screen — emerald glassmorphism design
struct TextTranslatorView: View {
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // Background
            DesignSystem.Gradients.mainBackground.ignoresSafeArea()

            // Subtle emerald glow
            Circle()
                .fill(emerald.opacity(0.03))
                .frame(width: 400, height: 400)
                .offset(y: -100)
                .blur(radius: 80)

            VStack(spacing: 0) {
                // Header
                Text("Текстовый перевод")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 16)
                    .padding(.bottom, 10)

                // Language selector
                languageSelector
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // API key warning
                if !viewModel.isAPIKeyConfigured {
                    apiKeyBanner
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                // Error
                if let error = viewModel.errorMessage {
                    errorBanner(error)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                // Translation panels
                VStack(spacing: 10) {
                    // Input panel
                    inputPanel
                    // Output panel
                    outputPanel
                }
                .padding(.horizontal, 20)

                Spacer()

                // Bottom spacer for tab bar
                Spacer().frame(height: 80)
            }
        }
        .onTapGesture {
            isInputFocused = false
        }
    }

    // MARK: - Language Selector

    private var languageSelector: some View {
        HStack(spacing: 0) {
            LanguagePickerView(
                selectedLanguage: $viewModel.sourceLanguage,
                label: "ИЗ"
            )

            Button(action: viewModel.swapLanguages) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.emerald.opacity(0.12))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(DesignSystem.Colors.emerald.opacity(0.25), lineWidth: 1)
                        )

                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.emerald)
                }
            }

            LanguagePickerView(
                selectedLanguage: $viewModel.targetLanguage,
                label: "НА"
            )
        }
    }

    // MARK: - Input Panel

    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(viewModel.sourceLanguage.flag)
                    .font(.system(size: 13))
                Text(viewModel.sourceLanguage.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()

                if !viewModel.sourceText.isEmpty {
                    Button(action: viewModel.clearAll) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.2))
                    }
                }
            }

            TextField("Введите текст для перевода...", text: $viewModel.sourceText, axis: .vertical)
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(3...8)
                .focused($isInputFocused)
                .tint(emerald)
        }
        .padding(14)
        .frame(minHeight: 180, maxHeight: .infinity, alignment: .top)
        .glassCard(cornerRadius: 14, borderColor: isInputFocused ? DesignSystem.Colors.emerald : DesignSystem.Colors.glassBorder)
        .onTapGesture {
            isInputFocused = true
        }
    }

    // MARK: - Output Panel

    private var outputPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(viewModel.targetLanguage.flag)
                    .font(.system(size: 13))
                Text(viewModel.targetLanguage.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()

                if viewModel.isTranslating {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(emerald)
                }

                if !viewModel.translatedText.isEmpty {
                    Button(action: viewModel.copyTranslation) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundStyle(emerald.opacity(0.6))
                    }
                }
            }

            ScrollView {
                if viewModel.translatedText.isEmpty && !viewModel.isTranslating {
                    Text("Перевод появится здесь")
                        .font(.system(size: 17))
                        .foregroundStyle(.white.opacity(0.15))
                } else {
                    Text(viewModel.translatedText)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.translatedText)
                }
            }
            .scrollIndicators(.visible)
        }
        .padding(14)
        .frame(minHeight: 180, maxHeight: .infinity, alignment: .top)
        .glassCard(cornerRadius: 14)
    }

    // MARK: - Banners

    private var apiKeyBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DesignSystem.Colors.emerald)
                .font(.system(size: 12))

            Text("Добавьте OPENAI_API_KEY в Debug.xcconfig")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DesignSystem.Colors.emerald.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DesignSystem.Colors.emerald.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red.opacity(0.7))
                .font(.system(size: 12))

            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            Button { viewModel.errorMessage = nil } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.red.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.red.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

#Preview {
    TextTranslatorView()
}
