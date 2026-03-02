import SwiftUI

/// 3D AI Orb — iridescent emerald-teal with breathing animation
struct RecordButton: View {
    let isRecording: Bool
    let audioLevel: Float
    let onTap: () -> Void

    @State private var breatheScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var rotationAngle: Double = 0
    
    // Dynamic sizing based on screen
    private var orbSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return min(160, screenWidth * 0.45)
    }
    
    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    private let teal = Color(red: 0, green: 0.76, blue: 0.66)
    private let darkEmerald = Color(red: 0, green: 0.45, blue: 0.30)

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer volumetric glow — much larger and more vibrant
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                emerald.opacity(isRecording ? 0.4 : 0.15),
                                teal.opacity(isRecording ? 0.1 : 0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: orbSize * 0.2,
                            endRadius: orbSize * 1.2
                        )
                    )
                    .frame(width: orbSize * 2.2, height: orbSize * 2.2)
                    .scaleEffect(breatheScale)
                    .blur(radius: isRecording ? 20 : 10)

                // Mid glow ring — rotating with pulse
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [emerald.opacity(0.5), teal.opacity(0.1), emerald.opacity(0.3), teal.opacity(0.05), emerald.opacity(0.5)],
                            center: .center,
                            startAngle: .degrees(rotationAngle),
                            endAngle: .degrees(rotationAngle + 360)
                        ),
                        lineWidth: 2.0
                    )
                    .frame(width: orbSize + 30, height: orbSize + 30)
                    .opacity(isRecording ? 0.9 : 0.4)
                    .blur(radius: 1)

                // Main orb body — liquid metal with internal texture
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    emerald.opacity(0.95),
                                    teal.opacity(0.8),
                                    darkEmerald.opacity(0.7),
                                    Color(red: 0.01, green: 0.1, blue: 0.08)
                                ],
                                center: UnitPoint(x: 0.3, y: 0.25),
                                startRadius: 2,
                                endRadius: orbSize * 0.6
                            )
                        )
                    
                    // Internal Grain/Noise Texture for organic feel
                    Circle()
                        .fill(.white.opacity(0.03))
                        .overlay(
                            Image(systemName: "plus") // Using repeated symbols or pattern for grain
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .opacity(0.02)
                                .blendMode(.overlay)
                        )
                }
                .frame(width: orbSize, height: orbSize)
                .overlay(
                    // Sharp Specular highlight — top-left
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    .white.opacity(0.1),
                                    Color.clear
                                ],
                                center: UnitPoint(x: 0.25, y: 0.2),
                                startRadius: 0,
                                endRadius: orbSize * 0.3
                            )
                        )
                )
                .overlay(
                    // Glass rim highlight
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    emerald.opacity(0.1),
                                    .clear,
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: emerald.opacity(isRecording ? 0.6 : 0.2), radius: isRecording ? 40 : 20)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 10)

                // Audio level reactive reactive "Aura"
                if isRecording {
                    Circle()
                        .stroke(emerald.opacity(0.3), lineWidth: 3)
                        .frame(
                            width: orbSize + CGFloat(audioLevel) * 60 + 10,
                            height: orbSize + CGFloat(audioLevel) * 60 + 10
                        )
                        .blur(radius: 2)
                        .animation(.easeOut(duration: 0.08), value: audioLevel)
                }

                // Icon — more defined
                Group {
                    if isRecording {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                            .frame(width: 26, height: 26)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .shadow(color: .white.opacity(0.3), radius: 10)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .heavy), trigger: isRecording)
        .onAppear {
            // Breathing animation
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breatheScale = 1.08
                glowOpacity = 0.6
            }
            // Rotating ring
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
        .onChange(of: isRecording) { _, recording in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                breatheScale = recording ? 1.15 : 1.08
            }
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.02, green: 0.027, blue: 0.059).ignoresSafeArea()
        VStack(spacing: 40) {
            RecordButton(isRecording: false, audioLevel: 0, onTap: {})
            RecordButton(isRecording: true, audioLevel: 0.5, onTap: {})
        }
    }
}
