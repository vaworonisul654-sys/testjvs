import Foundation

/// Represents the current state of the translator
enum TranslatorState: Equatable {
    case idle
    case connecting
    case recording
    case translating
    case error(String)

    var isActive: Bool {
        switch self {
        case .recording, .translating, .connecting:
            return true
        default:
            return false
        }
    }

    var statusText: String {
        switch self {
        case .idle:             return "Готов к переводу"
        case .connecting:       return "Подключение..."
        case .recording:        return "Слушаю..."
        case .translating:      return "Перевожу..."
        case .error(let msg):   return "Ошибка: \(msg)"
        }
    }
}
