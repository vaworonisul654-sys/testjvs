import Foundation
import SwiftUI

/// Constants used throughout the app
enum Constants {
    enum UI {
        static let cornerRadius: CGFloat = 16
        static let premiumRadius: CGFloat = 24
        static let smallCornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let horizontalMargin: CGFloat = 12
        static let smallPadding: CGFloat = 8
        static let recordButtonSize: CGFloat = 80
        static let animationDuration: Double = 0.3
    }

    enum Audio {
        static let maxWaveformBars: Int = 30
        static let silenceThreshold: Float = 0.01
    }
}

/// J.A.R.V.I.S. Design System 💎
/// Centralized tokens for colors, glassmorphism, and layouts.
struct DesignSystem {
    enum Colors {
        static let emerald = Color(red: 0, green: 0.88, blue: 0.56)
        static let deepSea = Color(red: 0.02, green: 0.027, blue: 0.059)
        static let glassWhite = Color.white.opacity(0.05)
        static let glassBorder = Color.white.opacity(0.1)
    }
    
    enum Gradients {
        static let mainBackground = LinearGradient(
            colors: [Colors.deepSea, Color(red: 0.04, green: 0.05, blue: 0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let emeraldGlow = RadialGradient(
            colors: [Colors.emerald.opacity(0.15), Color.clear],
            center: .center,
            startRadius: 0,
            endRadius: 300
        )
    }
}

// MARK: - Glassmorphism Modifier

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var borderColor: Color = DesignSystem.Colors.emerald.opacity(0.15)
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DesignSystem.Colors.glassWhite)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial.opacity(0.3))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .white.opacity(0.05),
                                borderColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor.opacity(0.5), lineWidth: 0.5)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, borderColor: Color = DesignSystem.Colors.emerald.opacity(0.15)) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, borderColor: borderColor))
    }
}
