# J.A.R.V.I.S. (Just A Rather Very Intelligent System) 🌐🛰️

J.A.R.V.I.S. is a proactive linguistic partner designed for seamless voice, text, and visual translation, combined with an AI-powered educational mentor.

## 🚀 Key Features

- **Voice Translator**: Real-time bidirectional translation with zero latency using Gemini 2.5 Flash.
- **AI Mentor (Jarvis Core)**: Personalized language tutor with educational continuity (remembers previous lessons).
- **Photo Translator**: Analyze and translate text from images using OpenAI Vision.
- **Text Translator**: Clean, glassmorphic interface for traditional text translation.
- **Learner Memory**: Track your progress, vocabulary, and success rates over time.

## 📱 Platforms

### iOS (SwiftUI)
- **Architecture**: Minimalist Clean Architecture, Callback-based (Stage 2 Stable).
- **Requirements**: iOS 17.0+, Xcode 15.0+.
- **Primary Tech**: SwiftUI, AVFoundation, Gemini Live API.

### Android (Flutter)
- **Architecture**: Modular BLoC/Provider architecture.
- **Requirements**: Flutter 3.10+, Android API 21+.
- **Primary Tech**: Flutter, Dart, Camera API, WebSockets.

## 🛠️ Setup & Installation

### 1. API Keys
Create a `Debug.xcconfig` (iOS) and update `app_config.dart` (Android) with your keys:
- `GEMINI_API_KEY`: [Google AI Studio](https://aistudio.google.com/)
- `OPENAI_API_KEY`: [OpenAI Dashboard](https://platform.openai.com/)

### 2. iOS Build
```bash
open LiveVoiceTranslator.xcodeproj
# Select your device and hit Run
```

### 3. Android Build
```bash
cd JarvisAndroid
flutter pub get
flutter run --release
```

## ⚖️ License
MIT License. See [LICENSE](LICENSE) for details.

---
*Built with ❤️ by the Jarvis Team.* 🚀🤖
