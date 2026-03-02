import Foundation

/// Утилиты для конвертации аудио-данных.
enum AudioConversionUtils {

    // MARK: - Int16 → Data

    /// Преобразует массив `Int16` (PCM-сэмплы) в сырые байты `Data` (little-endian).
    static func int16ArrayToData(_ samples: [Int16]) -> Data {
        var copy = samples
        return Data(bytes: &copy, count: samples.count * MemoryLayout<Int16>.size)
    }

    // MARK: - Int16 → Base64

    /// Конвертирует PCM-сэмплы `[Int16]` в Base64-строку,
    /// готовую для отправки через WebSocket в Gemini Live API.
    static func int16ArrayToBase64(_ samples: [Int16]) -> String {
        let data = int16ArrayToData(samples)
        return data.base64EncodedString()
    }

    // MARK: - Base64 → Int16

    /// Декодирует Base64-строку обратно в массив `Int16`.
    /// Возвращает `nil`, если строка невалидна.
    static func base64ToInt16Array(_ base64String: String) -> [Int16]? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        let count = data.count / MemoryLayout<Int16>.size
        guard data.count % MemoryLayout<Int16>.size == 0 else { return nil }

        var result = [Int16](repeating: 0, count: count)
        _ = result.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        return result
    }
}
