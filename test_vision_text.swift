import UIKit
import Foundation

// 🧪 Swift Port of the Vision Test Script
// To run: Paste into a Playground or run within the project context

@MainActor
func testVisionTranslation() async {
    print("🚀 Starting Vision Test (Swift)...")
    
    // 1. Setup Service
    let visionService = OpenAIVisionService()
    
    // 2. Load Image from URL (same as Python script)
    let imageUrlString = "https://st4.depositphotos.com/2627021/20422/i/450/depositphotos_204221764-stock-photo-simple-text-isolated-white-background.jpg"
    
    guard let url = URL(string: imageUrlString) else {
        print("❌ Invalid URL")
        return
    }
    
    print("📷 Downloading test image...")
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            print("❌ Failed to create UIImage from data")
            return
        }
        
        print("✅ Image downloaded. Sending to OpenAI Vision...")
        
        // 3. Call Service
        let translatedText = try await visionService.translatePhoto(image)
        
        print("\n--- RESULT ---")
        print(translatedText)
        print("--------------\n")
        
    } catch {
        print("❌ Test failed: \(error.localizedDescription)")
    }
}

// Trigger test
Task {
    await testVisionTranslation()
}
