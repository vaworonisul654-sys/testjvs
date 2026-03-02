import SwiftUI

/// Chat bubble with emerald glassmorphism
struct ChatBubbleView: View {
    let message: TranslationMessage

    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Translation (primary)
            HStack(spacing: 8) {
                Text(message.targetLanguage.flag)
                    .font(.system(size: 15))

                Text(message.translatedText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }

            // Divider
            Rectangle()
                .fill(emerald.opacity(0.08))
                .frame(height: 1)

            // Original (secondary)
            HStack(spacing: 8) {
                Text(message.sourceLanguage.flag)
                    .font(.system(size: 13))

                Text(message.originalText)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
            }

            // Timestamp
            HStack {
                Spacer()
                Text(message.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(emerald.opacity(0.25))
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.04))
                
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.15),
                                        .clear,
                                        emerald.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
            }
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .contextMenu {
            Button {
                UIPasteboard.general.string = message.translatedText
            } label: {
                Label("Копировать перевод", systemImage: "doc.on.doc")
            }

            Button {
                UIPasteboard.general.string = message.originalText
            } label: {
                Label("Копировать оригинал", systemImage: "doc.on.clipboard")
            }
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.02, green: 0.027, blue: 0.059).ignoresSafeArea()
        ChatBubbleView(
            message: TranslationMessage(
                originalText: "Hello, how are you?",
                translatedText: "Привет, как дела?",
                sourceLanguage: .english,
                targetLanguage: .russian
            )
        )
        .padding()
    }
}
