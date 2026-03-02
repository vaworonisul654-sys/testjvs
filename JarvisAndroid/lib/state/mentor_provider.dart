import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:jarvis_voice_system/models/learner_profile.dart';
import 'package:jarvis_voice_system/services/gemini_service.dart';
import 'package:jarvis_voice_system/services/audio_service.dart';
import 'package:jarvis_voice_system/services/tts_service.dart';

class MentorProvider with ChangeNotifier {
  final GeminiService gemini = GeminiService();
  final AudioService audio = AudioService();
  final TTSService tts = TTSService();
  
  LearnerProfile profile = LearnerProfile();
  bool isRecording = false;
  String currentStatus = "Ready to speak";
  String transcript = "";

  Future<void> init(String apiKey) async {
    await audio.init();
    await tts.init();
    // Default connection (Voice mode)
    await connect(apiKey, isMentorMode: false);
  }

  Future<void> connect(String apiKey, {required bool isMentorMode}) async {
    final instruction = getSystemInstruction(isMentorMode: isMentorMode);
    await gemini.connect(apiKey, customSystemInstruction: instruction);
    
    gemini.messages.listen((msg) {
      _handleGeminiMessage(msg);
    });
  }

  String getSystemInstruction({required bool isMentorMode}) {
    if (!isMentorMode) {
      return "You are a real-time voice translator. Translate between Russian and English accurately.";
    }

    final lastLesson = profile.lastLessonSummary != null 
        ? "\nКОНТЕКСТ ПРОШЛОГО УРОКА: ${profile.lastLessonSummary}" : "";
    
    return """
Ты — Джарвис, ИИ-наставник. Помогай пользователю учить английский.
ИСПОЛЬЗУЙ ПРЕЕМСТВЕННОСТЬ: Если есть контекст прошлого урока, начни с него.
$lastLesson
Инструкции: адаптируй сложность, исправляй мягко.
ОСОБАЯ ФУНКЦИЯ: Показать написание. Используй [SHOW: текст].
""";
  }

  void _handleGeminiMessage(Map<String, dynamic> msg) {
    if (msg.containsKey('serverContent')) {
      final content = msg['serverContent'];
      if (content.containsKey('modelTurn')) {
        final parts = content['modelTurn']['parts'];
        for (var part in parts) {
          if (part.containsKey('text')) {
             String text = part['text'];
             // Handle [SHOW: text] tags
             if (text.contains('[SHOW:')) {
               // Logic to show text on screen could go here
             }
            transcript = text;
            notifyListeners();
          }
          if (part.containsKey('inlineData')) {
            final audioData = base64Decode(part['inlineData']['data']);
            tts.playChunk(audioData);
          }
        }
      }
    }
  }

  Future<void> toggleRecording() async {
    if (isRecording) {
      await audio.stopCapture();
      currentStatus = "Thinking...";
      // Finalize session if in mentor mode and we have a transcript
      if (transcript.isNotEmpty) {
        finalizeSession(transcript);
      }
    } else {
      try {
        final stream = await audio.startCapture();
        currentStatus = "Listening...";
        stream.listen((chunk) {
          gemini.sendAudioChunk(chunk);
        });
      } catch (e) {
        currentStatus = "Error: $e";
      }
    }
    isRecording = !isRecording;
    notifyListeners();
  }

  void finalizeSession(String summary) {
    final session = SessionSummary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      topic: "Language Practice",
      summary: summary,
      successRate: 0.8,
    );
    
    profile.sessionHistory.insert(0, session);
    profile.lastLessonSummary = summary;
    notifyListeners();
    // In a real app, save to SharedPreferences here
  }

  @override
  void dispose() {
    audio.dispose();
    tts.dispose();
    gemini.dispose();
    super.dispose();
  }
}
