import Foundation

/// A chunk of raw audio data ready to be sent to the API
struct AudioChunk: Sendable {
    let data: Data
    let timestamp: Date
    let sampleRate: Double
    let channelCount: Int

    /// Base64 encoded string for the Gemini API
    var base64Encoded: String {
        data.base64EncodedString()
    }

    /// MIME type string for the API
    var mimeType: String {
        "audio/pcm;rate=\(Int(sampleRate))"
    }

    init(
        data: Data,
        timestamp: Date = Date(),
        sampleRate: Double = AppConfiguration.audioSampleRate,
        channelCount: Int = AppConfiguration.audioChannels
    ) {
        self.data = data
        self.timestamp = timestamp
        self.sampleRate = sampleRate
        self.channelCount = channelCount
    }
}
