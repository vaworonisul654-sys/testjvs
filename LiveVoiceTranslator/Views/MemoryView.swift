import SwiftUI

/// Memory (Память) View — Premium List of saved translation templates
struct MemoryView: View {
    @State private var viewModel = MemoryViewModel()
    @FocusState private var isInputFocused: Bool
    
    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    private let bgColor = Color(red: 0.02, green: 0.027, blue: 0.059)
    
    var body: some View {
        ZStack {
            // Background
            bgColor.ignoresSafeArea()
            
            // Subtle glow
            Circle()
                .fill(emerald.opacity(0.04))
                .frame(width: 400, height: 400)
                .offset(y: -150)
                .blur(radius: 100)
            
            VStack(spacing: 0) {
                // Header
                header
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                
                if viewModel.items.isEmpty {
                    emptyState
                } else {
                    itemList
                }
                
                Spacer()
                
                // Bottom spacer for tab bar
                Spacer().frame(height: 100)
            }
            
            // Floating "+" Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    plusButton
                        .padding(.trailing, 24)
                        .padding(.bottom, 110)
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingCreation) {
            creationSheet
        }
    }
    
    // MARK: - Components
    
    private var header: some View {
        VStack(spacing: 4) {
            Text("Память")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            
            Text("\(viewModel.items.count) из 10 шаблонов")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(emerald.opacity(0.6))
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(emerald.opacity(0.05))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "cpu")
                    .font(.system(size: 48))
                    .foregroundStyle(emerald.opacity(0.3))
            }
            
            VStack(spacing: 8) {
                Text("Ваша память пуста")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                
                Text("Нажмите +, чтобы сохранить важную фразу\nдля быстрого доступа")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Spacer()
        }
    }
    
    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.items) { item in
                    templateCard(item)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
    }
    
    private func templateCard(_ item: MemoryItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.sourceLanguage.flag)
                Text("→")
                    .foregroundStyle(.white.opacity(0.2))
                Text(item.targetLanguage.flag)
                
                Spacer()
                
                Button(action: { viewModel.playItem(item) }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(emerald)
                        .padding(8)
                        .background(Circle().fill(emerald.opacity(0.1)))
                }
                
                Button(action: { viewModel.deleteItem(item) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(.red.opacity(0.5))
                        .padding(8)
                        .background(Circle().fill(.red.opacity(0.05)))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.originalText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                
                Text(item.translatedText)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(emerald)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white.opacity(0.03))
                .background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(emerald.opacity(0.1), lineWidth: 1))
        )
    }
    
    private var plusButton: some View {
        Button(action: { viewModel.isShowingCreation = true }) {
            ZStack {
                Circle()
                    .fill(emerald)
                    .frame(width: 64, height: 64)
                    .shadow(color: emerald.opacity(0.4), radius: 15, x: 0, y: 8)
                
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(bgColor)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Creation Sheet
    
    private var creationSheet: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button("Отмена") {
                        viewModel.isShowingCreation = false
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("Новый шаблон")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button("Сохранить") {
                        viewModel.saveItem()
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(emerald)
                    .disabled(viewModel.translatedText.isEmpty)
                    .opacity(viewModel.translatedText.isEmpty ? 0.3 : 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                
                // Language Selector
                HStack(spacing: 0) {
                    LanguagePickerView(selectedLanguage: $viewModel.sourceLanguage, label: "ИЗ")
                    
                    Button(action: viewModel.swapLanguages) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(emerald)
                            .padding(10)
                            .background(Circle().fill(.white.opacity(0.05)))
                    }
                    
                    LanguagePickerView(selectedLanguage: $viewModel.targetLanguage, label: "НА")
                }
                .padding(.horizontal, 20)
                
                // Input Area
                VStack(alignment: .leading, spacing: 12) {
                    Text("ОРИГИНАЛ")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.horizontal, 4)
                    
                    TextField("Введите текст...", text: $viewModel.sourceText, axis: .vertical)
                        .focused($isInputFocused)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.04)).overlay(RoundedRectangle(cornerRadius: 16).stroke(emerald.opacity(0.15), lineWidth: 1)))
                        .onChange(of: viewModel.sourceText) { _, newVal in
                            if !newVal.isEmpty {
                                Task { await viewModel.translate() }
                            } else {
                                viewModel.translatedText = ""
                            }
                        }
                }
                .padding(.horizontal, 20)
                
                // Output Area
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("ПЕРЕВОД")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(emerald.opacity(0.7))
                        Spacer()
                        
                        if viewModel.isTranslating {
                            ProgressView().tint(emerald).scaleEffect(0.7)
                        } else if !viewModel.translatedText.isEmpty {
                            Button(action: viewModel.playCurrentPreview) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(emerald)
                                    .padding(6)
                                    .background(Circle().fill(emerald.opacity(0.1)))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    Text(viewModel.isTranslating ? "Перевожу..." : (viewModel.translatedText.isEmpty ? "Результат появится здесь" : viewModel.translatedText))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(viewModel.translatedText.isEmpty ? .white.opacity(0.1) : .white)
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                        .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.03)).background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial.opacity(0.2))).overlay(RoundedRectangle(cornerRadius: 20).stroke(emerald.opacity(0.2), lineWidth: 1)))
                }
                .padding(.horizontal, 20)
                
                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(.red.opacity(0.7))
                        .padding(.horizontal, 24)
                }
                
                Spacer()
            }
        }
    }
}
