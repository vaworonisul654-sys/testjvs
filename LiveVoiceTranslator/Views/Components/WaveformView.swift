import SwiftUI

/// Emerald-teal waveform visualization
struct WaveformView: View {
    let level: Float
    let isActive: Bool

    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    private let teal = Color(red: 0, green: 0.76, blue: 0.66)

    @State private var barHeights: [CGFloat] = Array(repeating: 0.05, count: Constants.Audio.maxWaveformBars)

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<Constants.Audio.maxWaveformBars, id: \.self) { index in
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barGradient(for: index))
                        .shadow(color: emerald.opacity(Double(level) * 0.4), radius: isActive ? 4 : 0)
                        .frame(width: 3, height: calculateBarHeight(for: index))
                    Spacer()
                }
            }
        }
        .frame(height: 60)
        .onChange(of: level) { _, newLevel in
            updateBars(with: newLevel)
        }
        .onChange(of: isActive) { _, active in
            if !active {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    barHeights = Array(repeating: 0.05, count: Constants.Audio.maxWaveformBars)
                }
            }
        }
    }

    private func calculateBarHeight(for index: Int) -> CGFloat {
        let baseHeight = barHeights[index] * 50
        let mid = CGFloat(Constants.Audio.maxWaveformBars) / 2
        let distance = abs(CGFloat(index) - mid)
        let taper = max(0.2, 1.0 - (distance / mid))
        return max(3, baseHeight * taper)
    }

    private func barGradient(for index: Int) -> LinearGradient {
        let progress = CGFloat(index) / CGFloat(Constants.Audio.maxWaveformBars)
        return LinearGradient(
            colors: [
                emerald.opacity(0.6 + progress * 0.4),
                teal.opacity(0.8)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private func updateBars(with level: Float) {
        let normalizedLevel = CGFloat(sqrt(max(0, level)))
        withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.6)) {
            for i in 0..<(barHeights.count - 1) {
                barHeights[i] = barHeights[i + 1]
            }
            let jitter = CGFloat.random(in: 0.85...1.15)
            barHeights[barHeights.count - 1] = normalizedLevel * jitter
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.02, green: 0.027, blue: 0.059).ignoresSafeArea()
        WaveformView(level: 0.6, isActive: true)
            .frame(height: 36)
            .padding()
    }
}
