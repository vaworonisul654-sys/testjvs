import SwiftUI

struct MentorView: View {
    @State private var viewModel = MentorViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var autoStart: Bool = false
    
    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    private let bgColor = Color(red: 0.02, green: 0.027, blue: 0.059)
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            // Decorative background elements
            glowEffect
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { viewModel.endSession(); dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    
                    Spacer()
                    
                    // Central Results Button
                    Button(action: { viewModel.isDashboardPresented = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 14))
                            Text("ИТОГИ")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(DesignSystem.Colors.emerald)
                        .padding(.vertical, 8)
                        .padding(.horizontal, Constants.UI.horizontalMargin)
                        .glassCard(cornerRadius: 12)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal)
                
                Text("JARVIS CORE")
                    .font(.system(size: 10, weight: .black))
                    .kerning(2)
                    .foregroundStyle(DesignSystem.Colors.emerald.opacity(0.5))
                    .padding(.top, -16)
                
                Spacer()
                
                // Central Core Visualizer
                jarvisCoreVisualizer
                
                // Real-time Text Feedback
                VStack(spacing: 12) {
                    if !viewModel.currentResponse.isEmpty {
                        Text(viewModel.currentResponse)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .padding()
                            .background(.white.opacity(0.05))
                            .cornerRadius(16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if case .connecting = viewModel.state {
                        Text("Подключение к ядру...")
                            .foregroundStyle(emerald.opacity(0.6))
                    } else if case .idle = viewModel.state {
                        Text("Нажмите на ядро, чтобы начать урок")
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal)
                .frame(height: 120)
                
                Spacer()
                
                // Action Area
                if case .active = viewModel.state {
                    Text("Я слушаю вас...")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.emerald)
                        .padding(.bottom, 40)
                } else if case .speaking = viewModel.state {
                    Text("Джарвис говорит")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 40)
                }
            }
            .padding(.top)
        }
        .onAppear {
            if autoStart {
                viewModel.startSession(autoStart: true)
            }
        }
        .onDisappear {
            viewModel.endSession()
        }
        .sheet(isPresented: $viewModel.isDashboardPresented) {
            MentorDashboardView()
        }
    }
    
    private var jarvisCoreVisualizer: some View {
        ZStack {
            // Pulse Rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(emerald.opacity(0.2), lineWidth: 1)
                    .frame(width: 140 + CGFloat(i * 60), height: 140 + CGFloat(i * 60))
                    .scaleEffect(viewModel.state.isActive ? 1.0 : 0.8)
                    .opacity(viewModel.state.isActive ? 1.0 : 0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(Double(i) * 0.5), value: viewModel.state.isActive)
            }
            
            // Main Core
            Button(action: {
                if viewModel.state.isActive {
                    viewModel.endSession()
                } else {
                    viewModel.startSession(autoStart: true)
                }
            }) {
                ZStack {
                    // Outer Glow
                    Circle()
                        .fill(emerald.opacity(0.15))
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                    
                    // Core Body
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [emerald.opacity(0.8), emerald.opacity(0.3)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(emerald.opacity(0.5), lineWidth: 2)
                        )
                    
                    // Internal Details (CPU/Brain icon)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .white, radius: 10)
                        .scaleEffect(viewModel.state.isActive ? 1.1 + CGFloat(viewModel.audioLevel * 0.5) : 1.0)
                }
            }
            .buttonStyle(.plain)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.state.isActive)
    }
    
    private var glowEffect: some View {
        ZStack {
            Circle()
                .fill(emerald.opacity(0.05))
                .frame(width: 500, height: 500)
                .offset(y: 100)
                .blur(radius: 100)
        }
    }
}

extension MentorViewModel.MentorState {
    var isActive: Bool {
        switch self {
        case .active, .speaking, .connecting: return true
        default: return false
        }
    }
}

#Preview {
    MentorView()
}
