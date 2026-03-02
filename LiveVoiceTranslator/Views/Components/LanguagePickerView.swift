import SwiftUI

/// Glassmorphism language picker with emerald accents
struct LanguagePickerView: View {
    @Binding var selectedLanguage: Language
    let label: String

    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(emerald.opacity(0.5))
                .tracking(2)

            Menu {
                ForEach(Language.allCases) { language in
                    Button {
                        selectedLanguage = language
                    } label: {
                        HStack {
                            Text(language.flag)
                            Text("\(language.displayName) (\(language.nameInRussian))")
                            if language == selectedLanguage {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedLanguage.flag)
                        .font(.system(size: 18))

                    Text(selectedLanguage.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(emerald.opacity(0.5))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(emerald.opacity(0.12), lineWidth: 1)
                        )
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        Color(red: 0.02, green: 0.027, blue: 0.059).ignoresSafeArea()
        LanguagePickerView(selectedLanguage: .constant(.english), label: "FROM")
    }
}
