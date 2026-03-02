import Foundation
import UIKit

/// OpenAI Vision service — sends photo to GPT-4o for text translation
final class OpenAIVisionService {

    // MARK: - Config

    private static let apiKey: String = {
        guard let key = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String,
              !key.isEmpty,
              key != "YOUR_OPENAI_KEY_HERE" else {
            return ""
        }
        return key
    }()

    static var isConfigured: Bool { !apiKey.isEmpty }

    private static let endpoint = "https://api.openai.com/v1/chat/completions"
    private static let model = "gpt-4o"

    // MARK: - Response Model

    struct PhotoTranslation: Decodable {
        let sourceLang: String?
        let translatedText: String? // Fallback for whole text
        let blocks: [TranslationBlock]?
        let error: String?
        
        enum CodingKeys: String, CodingKey {
            case source_lang, sourceLang
            case translated_text, translatedText
            case blocks, error
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            error = try container.decodeIfPresent(String.self, forKey: .error)
            blocks = try container.decodeIfPresent([TranslationBlock].self, forKey: .blocks)
            
            sourceLang = (try? container.decodeIfPresent(String.self, forKey: .source_lang)) ??
                         (try? container.decodeIfPresent(String.self, forKey: .sourceLang))
            
            translatedText = (try? container.decodeIfPresent(String.self, forKey: .translated_text)) ??
                             (try? container.decodeIfPresent(String.self, forKey: .translatedText))
        }
    }

    struct TranslationBlock: Decodable {
        let text: String
        let bbox: [Double] // [ymin, xmin, ymax, xmax] normalized 0-1000
    }

    // MARK: - Translate Photo (full or cropped area)

    func translatePhoto(
        image: UIImage,
        sourceLanguage: Language?,
        targetLanguage: Language
    ) async throws -> PhotoTranslation {
        guard Self.isConfigured else {
            throw PhotoTranslationError.apiKeyMissing
        }

        let processedImage = image // Already cropped by VM if needed
        let imageData = resizeImage(processedImage, maxDimension: 1024).jpegData(compressionQuality: 0.8)
        guard let imageData = imageData else {
            throw PhotoTranslationError.imageEncodingFailed
        }

        let base64Image = imageData.base64EncodedString()
        let fromLangSnippet = sourceLanguage != nil ? "detect the text in \(sourceLanguage!.displayName)" : "automatically detect the source language"

        let systemPrompt = """
        You are an expert linguist and spatial analyst. Analyze the image, extract ALL visible text, \(fromLangSnippet), and translate to \(targetLanguage.displayName) with MAXIMUM ACCURACY.
        
        GOAL: Produce an AR-style translation. You must group related text into logical blocks (sentences, table cells, sign components).
        
        RULES:
        1. CONTEXTUAL TRANSLATION: Align words into grammatically correct sentences first, THEN translate the whole sentence. Never translate words in isolation if they part of a larger context.
        2. GRAMMAR: Use perfect grammar, declensions, and natural flow in \(targetLanguage.displayName).
        3. SPATIAL AWARENESS: For each logical block, provide a normalized bounding box [ymin, xmin, ymax, xmax] relative to the image (0-1000).
        4. STRUCTURE: Preserve the visual relationship (e.g., table structure) through correct grouping and coordinates.
        5. If no text found, return: {"error": "Текст не найден"}
        
        RESPOND IN JSON ONLY:
        {
          "source_lang": "detected language",
          "blocks": [
            {"text": "translated text block", "bbox": [ymin, xmin, ymax, xmax]}
          ],
          "translated_text": "full text summary (optional)"
        }
        """

        let body: [String: Any] = [
            "model": Self.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "auto"
                            ]
                        ]
                    ]
                ]
            ],
            "temperature": 0.1,
            "max_tokens": 2048
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body),
              let url = URL(string: Self.endpoint) else {
            throw PhotoTranslationError.requestFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Self.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 60

        print("🚀 OpenAI Vision: Starting request with model \(Self.model)")
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ OpenAI Vision: Response is not HTTPURLResponse")
            throw PhotoTranslationError.requestFailed
        }

        print("📡 OpenAI Vision: Received response. Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            print("❌ OpenAI Vision: API Error. Code: \(httpResponse.statusCode), Body: \(errorBody)")
            throw PhotoTranslationError.apiError("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            print("❌ OpenAI Vision: Failed to parse initial JSON structure")
            throw PhotoTranslationError.parseFailed
        }

        print("📝 OpenAI Vision: Raw content from AI: \(content)")

        // Robust JSON extraction
        var cleanedContent = content
        if let firstBrace = content.firstIndex(of: "{"),
           let lastBrace = content.lastIndex(of: "}") {
            cleanedContent = String(content[firstBrace...lastBrace])
        } else {
            cleanedContent = content
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        print("🧹 OpenAI Vision: Cleaned content: \(cleanedContent)")

        guard let resultData = cleanedContent.data(using: .utf8) else {
            print("❌ OpenAI Vision: Failed to get UTF8 data from content: \(cleanedContent)")
            throw PhotoTranslationError.parseFailed
        }

        do {
            let decoded = try JSONDecoder().decode(PhotoTranslation.self, from: resultData)
            print("✅ OpenAI Vision: Successfully decoded result")
            return decoded
        } catch {
            print("❌ OpenAI Vision: Decode failed for JSON: \(cleanedContent). Error: \(error)")
            throw PhotoTranslationError.parseFailed
        }
    }

    // MARK: - Image Processing Helpers

    func processImage(_ image: UIImage, rotationAngle: Double, cropRect: CGRect?) -> UIImage {
        let radians = rotationAngle * .pi / 180
        let w = Double(image.size.width)
        let h = Double(image.size.height)
        let rotatedSize = CGSize(
            width: abs(w * cos(radians)) + abs(h * sin(radians)),
            height: abs(w * sin(radians)) + abs(h * cos(radians))
        )
        
        let scale = image.scale
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        
        let renderer = UIGraphicsImageRenderer(size: rotatedSize, format: format)
        let rotatedImage = renderer.image { context in
            context.cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.cgContext.rotate(by: CGFloat(radians))
            image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
        }
        
        var processed = rotatedImage
        
        if let crop = cropRect, let cgImage = processed.cgImage {
            let pixelRect = CGRect(
                x: crop.origin.x * scale,
                y: crop.origin.y * scale,
                width: crop.size.width * scale,
                height: crop.size.height * scale
            )
            
            if let croppedCG = cgImage.cropping(to: pixelRect) {
                processed = UIImage(cgImage: croppedCG, scale: scale, orientation: .up)
            }
        }
        
        return processed
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

// MARK: - Errors

enum PhotoTranslationError: LocalizedError {
    case apiKeyMissing
    case imageEncodingFailed
    case requestFailed
    case apiError(String)
    case parseFailed

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:        return "OpenAI API ключ не настроен."
        case .imageEncodingFailed:  return "Не удалось закодировать изображение."
        case .requestFailed:        return "Ошибка сетевого запроса."
        case .apiError(let msg):    return "OpenAI: \(msg)"
        case .parseFailed:          return "Не удалось разобрать ответ."
        }
    }
}
