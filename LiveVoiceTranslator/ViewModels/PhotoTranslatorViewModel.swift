import SwiftUI
import UIKit
import Foundation

/// ViewModel for photo translation with crop selection
@Observable
final class PhotoTranslatorViewModel {

    // MARK: - State

    var capturedImage: UIImage?
    var originalCapturedImage: UIImage? // Permanent full photo
    var translation: OpenAIVisionService.PhotoTranslation?
    var isTranslating = false
    var errorMessage: String?
    var sourceLanguage: Language? = nil // nil = auto-detect
    var targetLanguage: Language = .russian
    var showCamera = false

    // Crop selection state
    var isCropping = false
    var cropRect: CGRect = .zero  // In image coordinates
    var rotationAngle: Double = 0 // Effective total rotation in degrees
    var currentRotation: Double = 0 // Interaction session rotation

    // Internal state to handle the "Crop then Translate" flow
    private var savedSelectionAngle: Double = 0
    private var savedSelectionRect: CGRect = .zero
    
    var isShowingProcessedImage: Bool {
        capturedImage != originalCapturedImage && capturedImage != nil
    }

    // MARK: - Computed Properties
    
    var totalRotation: Double {
        if isShowingProcessedImage { return 0 }
        return (rotationAngle + currentRotation).truncatingRemainder(dividingBy: 360)
    }
    
    var rotatedImageSize: CGSize {
        guard let image = capturedImage else { return .zero }
        let radians = totalRotation * .pi / 180
        let w = Double(image.size.width)
        let h = Double(image.size.height)
        return CGSize(
            width: abs(w * cos(radians)) + abs(h * sin(radians)),
            height: abs(w * sin(radians)) + abs(h * cos(radians))
        )
    }

    private let service = OpenAIVisionService()

    // MARK: - Public

    var isAPIKeyConfigured: Bool { OpenAIVisionService.isConfigured }
    var hasResult: Bool { translation != nil && translation?.error == nil }

    func openCamera() {
        errorMessage = nil
        showCamera = true
    }

    func handleCapturedImage(_ image: UIImage) {
        capturedImage = image
        originalCapturedImage = image
        showCamera = false
        // Show crop mode first
        isCropping = true
        translation = nil
        errorMessage = nil
        rotationAngle = 0
        // Initialize crop to center 80% of image
        let w = image.size.width * 0.8
        let h = image.size.height * 0.8
        cropRect = CGRect(
            x: (image.size.width - w) / 2,
            y: (image.size.height - h) / 2,
            width: w,
            height: h
        )
    }

    func rotate() {
        rotationAngle = (rotationAngle + 90).truncatingRemainder(dividingBy: 360)
        resetCropToDefault()
    }

    func updateRotation(_ degrees: Double) {
        currentRotation = degrees
    }

    func finalizeRotation() {
        rotationAngle = (rotationAngle + currentRotation).truncatingRemainder(dividingBy: 360)
        currentRotation = 0
        resetCropToDefault()
    }

    private func resetCropToDefault() {
        guard let image = capturedImage else { return }
        let currentAngle = rotationAngle + currentRotation
        let radians = currentAngle * .pi / 180
        let w = Double(image.size.width)
        let h = Double(image.size.height)
        let rotatedW = abs(w * cos(radians)) + abs(h * sin(radians))
        let rotatedH = abs(w * sin(radians)) + abs(h * cos(radians))
        
        let cropW = rotatedW * 0.8
        let cropH = rotatedH * 0.8
        cropRect = CGRect(
            x: (rotatedW - cropW) / 2,
            y: (rotatedH - cropH) / 2,
            width: cropW,
            height: cropH
        )
    }

    func reshoot() {
        clearResult()
        openCamera()
    }

    func translateCroppedArea() {
        guard let original = originalCapturedImage else {
            print("⚠️ PhotoTranslatorViewModel: translateCroppedArea called but originalCapturedImage is nil")
            return
        }
        
        print("📸 PhotoTranslatorViewModel: Starting translation for cropped area. Rotation: \(totalRotation), Rect: \(cropRect)")
        
        // 1. Save current selection state so we can restore it later
        savedSelectionAngle = totalRotation
        savedSelectionRect = cropRect
        
        // 2. Physically crop/rotate the image
        let processed = service.processImage(original, rotationAngle: totalRotation, cropRect: cropRect)
        
        // 3. Update state: Show only the cropped piece
        capturedImage = processed
        isCropping = false
        
        // 4. Translate the RESULTING cropped image
        performTranslation(imageToTranslate: processed)
    }

    func reselectArea() {
        print("📸 PhotoTranslatorViewModel: Reselecting area")
        // 1. Restore original photo and selection state
        if let original = originalCapturedImage {
            capturedImage = original
            rotationAngle = savedSelectionAngle
            currentRotation = 0
            cropRect = savedSelectionRect
        }
        
        translation = nil
        errorMessage = nil
        isCropping = true
    }

    func clearResult() {
        capturedImage = nil
        translation = nil
        errorMessage = nil
        isCropping = false
    }

    func copyTranslation() {
        let text = translation?.translatedText ?? translation?.blocks?.map { $0.text }.joined(separator: "\n\n") ?? ""
        if !text.isEmpty {
            UIPasteboard.general.string = text
        }
    }

    // MARK: - Private

    private func performTranslation(imageToTranslate: UIImage) {
        print("📸 PhotoTranslatorViewModel: Initiating performTranslation. Image size: \(imageToTranslate.size)")
        isTranslating = true
        errorMessage = nil
        translation = nil

        Task { @MainActor in
            do {
                print("📸 PhotoTranslatorViewModel: Task started for translation")
                let result = try await service.translatePhoto(
                    image: imageToTranslate,
                    sourceLanguage: self.sourceLanguage,
                    targetLanguage: self.targetLanguage
                )
                print("📸 PhotoTranslatorViewModel: Translation successful: \(result.translatedText?.prefix(50) ?? "nil")...")
                self.translation = result
                if let error = result.error { 
                    print("📸 PhotoTranslatorViewModel: AI returned error: \(error)")
                    self.errorMessage = error 
                }
                self.isTranslating = false
            } catch {
                print("❌ PhotoTranslatorViewModel: Translation task failed with error: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.isTranslating = false
            }
        }
    }
}
