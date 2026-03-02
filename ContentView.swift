
//
//  ContentView.swift
//  Live Voice Translator
//
//  Created on 2026-02-24.
//

import SwiftUI

// MARK: - Color Theme

extension Color {
    /// Vibrant Emerald accent (#00E08E)
    static let emerald        = Color(red: 0.0, green: 0.88, blue: 0.56)
    /// Teal-Darker emerald for gradients
    static let emeraldDark    = Color(red: 0.0, green: 0.45, blue: 0.30)
    /// Surface card color (glassy dark)
    static let surfaceDark    = Color(red: 0.08, green: 0.10, blue: 0.15).opacity(0.8)
    /// Background obsidian
    static let backgroundDark = Color(red: 0.01, green: 0.02, blue: 0.04)
}

// MARK: - Data Model

/// Represents a single translation message pair.
struct TranslationMessage: Identifiable {
    let id = UUID()
    let originalText: String
    let originalLanguage: String
    let translatedText: String
    let translatedLanguage: String
    let timestamp: Date
}

// MARK: - Mock Data

extension TranslationMessage {
    static let mockMessages: [TranslationMessage] = [
        TranslationMessage(
            originalText: "Привет! Как у тебя дела?",
            originalLanguage: "RU",
            translatedText: "Hi! How are you doing?",
            translatedLanguage: "EN",
            timestamp: Date().addingTimeInterval(-300)
        ),
        TranslationMessage(
            originalText: "I'm doing great, thanks for asking!",
            originalLanguage: "EN",
            translatedText: "У меня всё отлично, спасибо, что спросил!",
            translatedLanguage: "RU",
            timestamp: Date().addingTimeInterval(-240)
        ),
        TranslationMessage(
            originalText: "Давай встретимся завтра в кафе.",
            originalLanguage: "RU",
            translatedText: "Let's meet tomorrow at a café.",
            translatedLanguage: "EN",
            timestamp: Date().addingTimeInterval(-180)
        ),
        TranslationMessage(
            originalText: "Sounds good! What time works for you?",
            originalLanguage: "EN",
            translatedText: "Звучит отлично! Во сколько тебе удобно?",
            translatedLanguage: "RU",
            timestamp: Date().addingTimeInterval(-120)
        ),
        TranslationMessage(
            originalText: "Давай в два часа дня.",
            originalLanguage: "RU",
            translatedText: "Let's say 2 PM.",
            translatedLanguage: "EN",
            timestamp: Date().addingTimeInterval(-60)
        ),
    ]
}

// MARK: - ContentView

struct ContentView: View {
    @State private var isRecording = false
    @State private var messages: [TranslationMessage] = TranslationMessage.mockMessages

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.backgroundDark, Color(red: 0.04, green: 0.08, blue: 0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────
                headerView

                // ── Chat List ───────────────────────────────
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // ── Microphone Button ───────────────────────
                microphoneButton
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.emerald)

                Text("Live Voice Translator")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                // Language pair badge
                languagePairBadge(from: "RU", to: "EN")
            }

            // Subtle separator
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .emerald.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func languagePairBadge(from: String, to: String) -> some View {
        HStack(spacing: 6) {
            Text(from)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.emerald)

            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.5))

            Text(to)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.emerald.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Microphone Button

    private var microphoneButton: some View {
        ZStack {
            // Pulsing rings (visible only while recording)
            if isRecording {
                ForEach(0..<3, id: \.self) { i in
                    PulseRing(delay: Double(i) * 0.4)
                }
            }

            // Main button
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isRecording.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isRecording
                                    ? [Color.red.opacity(0.9), Color.red.opacity(0.6)]
                                    : [.emerald, .emeraldDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(
                            color: isRecording ? .red.opacity(0.5) : .emerald.opacity(0.5),
                            radius: 16, x: 0, y: 4
                        )

                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(isRecording ? 0.85 : 1.0)
                }
            }
            .buttonStyle(.plain)

            // Status label
            if isRecording {
                Text("Listening…")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.emerald)
                    .offset(y: 52)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(height: 100)
        .animation(.easeInOut(duration: 0.3), value: isRecording)
    }
}

// MARK: - Pulse Ring Animation

struct PulseRing: View {
    let delay: Double
    @State private var animate = false

    var body: some View {
        Circle()
            .stroke(Color.emerald.opacity(0.4), lineWidth: 2)
            .frame(width: 72, height: 72)
            .scaleEffect(animate ? 2.2 : 1.0)
            .opacity(animate ? 0 : 0.6)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    animate = true
                }
            }
    }
}

// MARK: - Message Bubble

struct MessageBubbleView: View {
    let message: TranslationMessage

    var body: some View {
        VStack(spacing: 8) {
            // ── Original (left-aligned) ─────────────────
            HStack {
                bubbleContent(
                    text: message.originalText,
                    lang: message.originalLanguage,
                    style: .original
                )
                Spacer(minLength: 60)
            }

            // ── Translation (right-aligned) ─────────────
            HStack {
                Spacer(minLength: 60)
                bubbleContent(
                    text: message.translatedText,
                    lang: message.translatedLanguage,
                    style: .translated
                )
            }
        }
    }

    private enum BubbleStyle {
        case original, translated
    }

    private func bubbleContent(text: String, lang: String, style: BubbleStyle) -> some View {
        VStack(alignment: style == .original ? .leading : .trailing, spacing: 4) {
            // Language tag
            HStack(spacing: 4) {
                if style == .translated {
                    Spacer()
                }
                Circle()
                    .fill(style == .original ? Color.white.opacity(0.4) : Color.emerald)
                    .frame(width: 6, height: 6)

                Text(lang)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(
                        style == .original
                            ? .white.opacity(0.5)
                            : .emerald
                    )
                if style == .original {
                    Spacer()
                }
            }

            // Text bubble
            Text(text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(
                    style == .original ? .white.opacity(0.85) : .white
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            style == .original
                                ? Color.surfaceDark
                                : LinearGradient(
                                    colors: [.emerald.opacity(0.25), .emeraldDark.opacity(0.18)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(
                                    style == .original
                                        ? Color.white.opacity(0.06)
                                        : Color.emerald.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 15 Pro")
    }
}
