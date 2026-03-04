import AVFoundation
import Foundation

/// Streaming PCM playback using AVAudioEngine — plays each chunk instantly
@Observable
final class TTSService: NSObject, AVSpeechSynthesizerDelegate {

    // MARK: - Public State

    /// True while audio is actively playing — used to mute mic during playback
    private(set) var isSpeaking = false

    // MARK: - Private

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let outputFormat: AVAudioFormat
    private var isEngineRunning = false
    private var pendingBuffers = 0

    // Gemini outputs PCM at 24kHz 16-bit mono
    private static let geminiSampleRate: Double = 24000
    private static let geminiChannels: AVAudioChannelCount = 1

    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - Init

    override init() {
        outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: Self.geminiSampleRate,
            channels: Self.geminiChannels,
            interleaved: true
        )!

        super.init()

        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: outputFormat)

        // Maximized hardware output levels
        playerNode.volume = 1.0
        
        // Setup synthesizer
        synthesizer.usesApplicationAudioSession = true
        synthesizer.delegate = self
    }

    // MARK: - Public API
    
    /// Offline TTS using system voices
    func speak(_ text: String, language: Language) {
        stop() // Stop any current playback
        ensureAudioSession()
        
        let utterance = AVSpeechUtterance(string: text)
        // Select best matching voice based on gender preference
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let preferredGender: AVSpeechSynthesisVoiceGender = DispatchQueue.main.sync {
            AppSettings.shared.voiceGender == .male ? .male : .female
        }
        
        // 1. Try to find exact locale + gender
        if let voice = voices.first(where: { $0.language == language.voiceLocale && $0.gender == preferredGender }) {
            utterance.voice = voice
        } 
        // 2. Fallback to language code + gender
        else if let voice = voices.first(where: { $0.language.hasPrefix(String(language.voiceLocale.prefix(2))) && $0.gender == preferredGender }) {
            utterance.voice = voice
        }
        // 3. Fallback to just locale (default)
        else {
            utterance.voice = AVSpeechSynthesisVoice(language: language.voiceLocale)
        }
        
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0 // Max system utterance volume
        utterance.pitchMultiplier = 1.0
        
        print("DEBUG: TTSService – Speaking offline: '\(text)' in \(language.voiceLocale)")
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Plays a PCM audio chunk — schedules immediately for streaming
    func playGeminiAudio(_ data: Data) {
        guard !data.isEmpty else { return }

        if !isEngineRunning {
            startEngine()
        }

        // Apply high-gain 10.0x boost (User requested 10x louder)
        // Combined with professional limiter to preserve signal quality.
        let amplifiedData = amplifyPCM(data, gain: 10.0)

        let frameCount = UInt32(amplifiedData.count) / 2
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCount) else {
            return
        }

        buffer.frameLength = frameCount

        amplifiedData.withUnsafeBytes { rawPtr in
            if let src = rawPtr.baseAddress {
                memcpy(buffer.int16ChannelData![0], src, amplifiedData.count)
            }
        }

        pendingBuffers += 1
        isSpeaking = true

        // Schedule buffer — completion fires when THIS buffer finishes playing
        playerNode.scheduleBuffer(buffer) { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.pendingBuffers -= 1
                // Only mark as done when ALL buffers finished
                if self.pendingBuffers <= 0 {
                    self.pendingBuffers = 0
                    if !self.synthesizer.isSpeaking {
                        self.isSpeaking = false
                    }
                }
            }
        }

        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    /// Stops all playback immediately
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        playerNode.stop()
        pendingBuffers = 0
        isSpeaking = false
        if isEngineRunning {
            audioEngine.stop()
            isEngineRunning = false
        }
    }

    // MARK: - Delegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            if self.pendingBuffers <= 0 {
                self.isSpeaking = false
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            if self.pendingBuffers <= 0 {
                self.isSpeaking = false
            }
        }
    }

    // MARK: - Private

    private func ensureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Synchronized with AudioCaptureService for clean playback and hardware button sync
            // Reverting to .videoChat as it's louder and clearer for hardware speakers.
            try session.setCategory(.playAndRecord, mode: .videoChat, options: [
                .defaultToSpeaker,
                .allowBluetoothHFP,
                .duckOthers
            ])
            try session.setActive(true)
        } catch {
            print("ERROR: TTSService – Session config failed: \(error.localizedDescription)")
        }
    }

    private func startEngine() {
        // Session config should be handled by the caller or once per session start
        do {
            try audioEngine.start()
            isEngineRunning = true
        } catch {
            print("ERROR: TTSService – Engine start failed: \(error.localizedDescription)")
        }
    }

    /// Amplify raw PCM16 data by a gain factor with professional hybrid limiting
    private func amplifyPCM(_ data: Data, gain: Float) -> Data {
        var amplified = Data(count: data.count)
        let sampleCount = data.count / 2

        data.withUnsafeBytes { srcRaw in
            amplified.withUnsafeMutableBytes { dstRaw in
                let src = srcRaw.bindMemory(to: Int16.self)
                let dst = dstRaw.bindMemory(to: Int16.self)
                
                for i in 0..<sampleCount {
                    // 10x Gain Boost
                    var sample = Float(src[i]) * gain
                    
                    // Professional Soft-Knee Limiter (Quality Preservation)
                    // High-gain signals require a safer transition to prevent "unclean" square waves.
                    let threshold: Float = 28000.0
                    let hardLimit: Float = 32760.0
                    
                    if abs(sample) > threshold {
                        let sign: Float = sample > 0 ? 1 : -1
                        let excess = abs(sample) - threshold
                        // Soft compression ratio (0.05) to squeeze peak without harsh clipping
                        let compressed = threshold + (excess * 0.05)
                        sample = min(compressed, hardLimit) * sign
                    }
                    
                    dst[i] = Int16(clamping: Int32(sample))
                }
            }
        }
        return amplified
    }
}
