import XCTest
@testable import LiveVoiceTranslator

/// Тесты утилит конвертации аудио-форматов.
///
/// Покрывает:
/// - Кодирование `[Int16]` → `Base64`
/// - Декодирование `Base64` → `[Int16]`
/// - Граничные случаи (пустой массив, невалидная строка и т.д.)
final class AudioFormatTests: XCTestCase {

    // MARK: - int16ArrayToBase64

    /// Пустой массив должен давать пустую (но валидную) Base64-строку.
    func testEmptyArrayReturnsEmptyBase64() {
        let result = AudioConversionUtils.int16ArrayToBase64([])
        XCTAssertEqual(result, "", "Base64 пустого массива должен быть пустой строкой")
    }

    /// Один сэмпл (0) → 2 байта нулей → Base64 "AAA=".
    func testSingleZeroSample() {
        let samples: [Int16] = [0]
        let base64 = AudioConversionUtils.int16ArrayToBase64(samples)
        XCTAssertEqual(base64, "AAA=")
    }

    /// Проверяем round-trip: encode → decode возвращает исходный массив.
    func testRoundTripSmallArray() {
        let original: [Int16] = [1, -1, 32767, -32768, 0, 12345]
        let base64 = AudioConversionUtils.int16ArrayToBase64(original)
        let decoded = AudioConversionUtils.base64ToInt16Array(base64)
        XCTAssertEqual(decoded, original, "Round-trip должен вернуть исходный массив")
    }

    /// Большой массив (16 000 сэмплов ≈ 1 секунда 16 kHz) — проверяем целостность.
    func testRoundTripLargeArray() {
        let count = 16_000
        let original = (0..<count).map { Int16(truncatingIfNeeded: $0) }
        let base64 = AudioConversionUtils.int16ArrayToBase64(original)
        let decoded = AudioConversionUtils.base64ToInt16Array(base64)
        XCTAssertEqual(decoded, original)
    }

    // MARK: - int16ArrayToData

    /// Длина Data должна быть ровно count * 2 байта.
    func testDataLength() {
        let samples: [Int16] = [100, 200, 300]
        let data = AudioConversionUtils.int16ArrayToData(samples)
        XCTAssertEqual(data.count, samples.count * MemoryLayout<Int16>.size)
    }

    // MARK: - base64ToInt16Array (негативные кейсы)

    /// Невалидная Base64-строка → nil.
    func testInvalidBase64ReturnsNil() {
        let result = AudioConversionUtils.base64ToInt16Array("%%%NOT_BASE64%%%")
        XCTAssertNil(result, "Невалидный Base64 должен возвращать nil")
    }

    /// Нечётное количество байтов (1 байт) — не выровнено под Int16 → nil.
    func testOddByteCountReturnsNil() {
        // "QQ==" → 1 байт, не делится на 2
        let result = AudioConversionUtils.base64ToInt16Array("QQ==")
        XCTAssertNil(result, "Нечётное число байтов должно возвращать nil")
    }

    /// Пустая Base64-строка → пустой массив.
    func testEmptyBase64ReturnsEmptyArray() {
        let result = AudioConversionUtils.base64ToInt16Array("")
        XCTAssertEqual(result, [], "Пустой Base64 должен вернуть пустой массив")
    }

    // MARK: - Производительность

    /// Замеряем скорость кодирования 1 секунды аудио (16 kHz, mono, Int16).
    func testEncodingPerformance() {
        let samples = [Int16](repeating: 1234, count: 16_000)
        measure {
            _ = AudioConversionUtils.int16ArrayToBase64(samples)
        }
    }
}
