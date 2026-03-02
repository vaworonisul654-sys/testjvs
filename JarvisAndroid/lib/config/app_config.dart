import 'secrets.dart';

class AppConfig {
  static const String geminiModel = "models/gemini-2.5-flash-native-audio-preview-12-2025";
  
  // Audio Settings - Synced with iOS for matching performance
  static const int audioSampleRate = 16000;
  static const int audioChunkDurationMs = 60; // Optimized for 1.0s latency
  static const int ttsSampleRate = 24000;
  
  // Design System (Jarvis Emerald & Navy)
  static const int primaryColor = 0xFF00C853;
  static const int backgroundColor = 0xFF0A192F;
  static const int cardColor = 0xFF112240;
  static const int secondaryColor = 0xFF64FFDA; // Teal/Cyan accent
  
  // API Keys (Stored in secrets.dart which is gitignored)
  static const String geminiKey = Secrets.geminiKey;
  static const String openAIKey = Secrets.openAIKey;
}
