import AVFoundation
import Foundation

/// Captures microphone audio as PCM16 mono 16kHz and streams clean chunks
@Observable
final class AudioCaptureService {

    // MARK: - Public State

    private(set) var isCapturing = false
    private(set) var currentLevel: Float = 0

    // MARK: - Private

    private let engine = AVAudioEngine()
    private var audioChunkContinuation: AsyncStream<AudioChunk>.Continuation?

    // MARK: - Public API

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Starts capturing audio with clean quality
    func startCapture() throws -> AsyncStream<AudioChunk> {
        guard !isCapturing else {
            return AsyncStream { $0.finish() }
        }

        configureAudioSession()

        let inputNode = engine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)

        // Target: PCM16, 16kHz, mono — what Gemini expects
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: AppConfiguration.audioSampleRate,
            channels: 1,
            interleaved: true
        ) else {
            throw AudioCaptureError.formatNotSupported
        }

        guard let converter = AVAudioConverter(from: nativeFormat, to: targetFormat) else {
            throw AudioCaptureError.converterCreationFailed
        }

        let stream = AsyncStream<AudioChunk> { continuation in
            self.audioChunkContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    self.stopCapture()
                }
            }
        }

        // How many 16kHz samples per chunk (e.g. 100ms = 1600 samples)
        let chunkSampleCount = Int(AppConfiguration.audioSampleRate * Double(AppConfiguration.audioChunkDurationMs) / 1000.0)
        let chunkByteSize = chunkSampleCount * 2

        var accumulatedData = Data()
        accumulatedData.reserveCapacity(chunkByteSize * 2)

        // Use native buffer size (4096) for clean conversion from 48kHz → 16kHz
        // Larger buffer = converter has more data = cleaner downsampling
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nativeFormat) { [weak self] buffer, _ in
            guard let self else { return }

            self.updateLevel(from: buffer)

            // Calculate how many output frames we can get from this input
            let ratio = targetFormat.sampleRate / nativeFormat.sampleRate
            let expectedOutputFrames = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
            guard expectedOutputFrames > 0 else { return }

            guard let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: expectedOutputFrames
            ) else { return }

            var error: NSError?
            var inputConsumed = false
            let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                if inputConsumed {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                inputConsumed = true
                outStatus.pointee = .haveData
                return buffer
            }

            guard status == .haveData || status == .endOfStream, error == nil else { return }

            // Extract clean PCM bytes
            if let channelData = convertedBuffer.int16ChannelData {
                let frameLength = Int(convertedBuffer.frameLength)
                guard frameLength > 0 else { return }
                let data = Data(bytes: channelData[0], count: frameLength * 2)
                accumulatedData.append(data)

                // Send when chunk is full
                while accumulatedData.count >= chunkByteSize {
                    let chunkData = accumulatedData.prefix(chunkByteSize)
                    let chunk = AudioChunk(data: Data(chunkData))
                    self.audioChunkContinuation?.yield(chunk)
                    accumulatedData.removeFirst(chunkByteSize)
                }
            }
        }

        try engine.start()
        isCapturing = true
        AppLogger.audio.info("Capture started: \(nativeFormat.sampleRate)Hz → 16kHz, chunk=\(AppConfiguration.audioChunkDurationMs)ms")

        return stream
    }

    func stopCapture() {
        guard isCapturing else { return }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isCapturing = false
        currentLevel = 0
        audioChunkContinuation?.finish()
        audioChunkContinuation = nil
    }

    // MARK: - Private

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // .videoChat mode is significantly louder and clearer for hardware speaker output than .voiceChat
            try session.setCategory(.playAndRecord, mode: .videoChat, options: [
                .defaultToSpeaker,
                .allowBluetoothHFP,
                .duckOthers
            ])
            // Don't force sample rate — let system use optimal native rate (48kHz)
            // We downsample in software which gives cleaner results
            try session.setPreferredIOBufferDuration(0.01) // 10ms is optimal balance
            try session.setActive(true)
            AppLogger.audio.info("Audio session: \(session.sampleRate)Hz, buffer=\(session.ioBufferDuration)s")
        } catch {
            AppLogger.audio.error("Audio session config failed: \(error.localizedDescription)")
        }
    }

    private func updateLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return }
        var sum: Float = 0
        for i in 0..<frames {
            sum += abs(channelData[0][i])
        }
        let level = min(sum / Float(frames) * 5, 1.0)
        DispatchQueue.main.async {
            self.currentLevel = level
        }
    }
}

// MARK: - Errors

enum AudioCaptureError: LocalizedError {
    case formatNotSupported
    case converterCreationFailed
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .formatNotSupported:      return "Формат аудио не поддерживается."
        case .converterCreationFailed: return "Ошибка конвертера аудио."
        case .permissionDenied:        return "Нет доступа к микрофону."
        }
    }
}
