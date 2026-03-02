import SwiftUI

/// Settings view — Voice preference and personalization
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = AppSettings.shared
    
    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    private let bgColor = Color(red: 0.02, green: 0.027, blue: 0.059)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                bgColor.ignoresSafeArea()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Voice Section
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "person.wave.2")
                                    .foregroundStyle(emerald)
                                Text("ПЕРСОНАЛИЗАЦИЯ ГОЛОСА")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .tracking(1)
                            }
                            .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                ForEach(AppSettings.VoiceGender.allCases) { gender in
                                    genderRow(gender: gender)
                                    
                                    if gender != AppSettings.VoiceGender.allCases.last {
                                        Divider()
                                            .background(.white.opacity(0.05))
                                            .padding(.leading, 50)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.03))
                                    .background(.ultraThinMaterial.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.05), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Language Section
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundStyle(emerald)
                                Text("ЯЗЫКИ")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .tracking(1)
                            }
                            .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                // Native Language
                                HStack {
                                    ZStack {
                                        Circle().fill(emerald.opacity(0.1)).frame(width: 34, height: 34)
                                        Image(systemName: "person.text.rectangle").font(.system(size: 14)).foregroundStyle(emerald)
                                    }
                                    Text("Родной язык")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.9))
                                    Spacer()
                                    Picker("", selection: $settings.nativeLanguage) {
                                        ForEach(Language.allCases) { lang in
                                            Text("\(lang.flag) \(lang.nameInRussian)").tag(lang)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(emerald)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                
                                Divider().background(.white.opacity(0.05)).padding(.leading, 50)
                                
                                // Learning Language
                                HStack {
                                    ZStack {
                                        Circle().fill(emerald.opacity(0.1)).frame(width: 34, height: 34)
                                        Image(systemName: "book.fill").font(.system(size: 14)).foregroundStyle(emerald)
                                    }
                                    Text("Изучаемый язык")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.9))
                                    Spacer()
                                    Picker("", selection: $settings.learnerTargetLanguage) {
                                        ForEach(Language.allCases) { lang in
                                            Text("\(lang.flag) \(lang.nameInRussian)").tag(lang)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(emerald)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.03))
                                    .background(.ultraThinMaterial.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.05), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Info Section
                        VStack(spacing: 12) {
                            Text("Джарвис будет использовать ваш родной язык только для объяснений и помощи в обучении.")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.3))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Text("Готово")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(emerald)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func genderRow(gender: AppSettings.VoiceGender) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                settings.voiceGender = gender
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(settings.voiceGender == gender ? emerald.opacity(0.2) : .white.opacity(0.05))
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: gender == .male ? "person.fill" : "person.fill.viewfinder")
                        .font(.system(size: 16))
                        .foregroundStyle(settings.voiceGender == gender ? emerald : .white.opacity(0.4))
                }
                
                Text(gender.localizedName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                
                Spacer()
                
                if settings.voiceGender == gender {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(emerald)
                        .font(.system(size: 20))
                } else {
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    SettingsView()
}
