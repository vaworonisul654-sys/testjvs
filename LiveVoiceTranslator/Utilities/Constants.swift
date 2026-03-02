import Foundation

/// Constants used throughout the app
enum Constants {
    enum UI {
        static let cornerRadius: CGFloat = 16
        static let smallCornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let recordButtonSize: CGFloat = 80
        static let animationDuration: Double = 0.3
    }

    enum Audio {
        static let maxWaveformBars: Int = 30
        static let silenceThreshold: Float = 0.01
    }
}
