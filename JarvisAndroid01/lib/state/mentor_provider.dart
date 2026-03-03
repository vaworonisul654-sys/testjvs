import 'dart:async';
import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../models/learner_profile.dart';
import '../config/app_config.dart';

enum MentorState { idle, connecting, active, speaking, error }

class MentorProvider extends ChangeNotifier {
  MentorState _state = MentorState.idle;
  String _currentResponse = "";
  double _audioLevel = 0.0;
  List<Map<String, dynamic>> _history = [];
  
  final GeminiService _gemini = GeminiService();
  StreamSubscription<String>? _textSubscription;
  final LearnerProfile _profile = LearnerProfile();
  
  MentorState get state => _state;
  String get currentResponse => _currentResponse;
  String get transcript => _currentResponse; // For UI parity
  double get audioLevel => _audioLevel;
  bool get isActive => _state == MentorState.active || _state == MentorState.speaking || _state == MentorState.connecting;
  bool get isRecording => _state == MentorState.active; // Simplified for UI
  
  LearnerProfile get profile => _profile;
  String get currentStatus => _state.name;

  MentorProvider() {
    _setupGeminiListeners();
  }

  void toggleRecording() {
    if (isRecording) {
      _state = MentorState.active; // Or however Gemini handles "not recording"
      // _gemini.stopRecording();
    } else {
      startSession();
    }
    notifyListeners();
  }

  void _setupGeminiListeners() {
    _textSubscription = _gemini.textStream.listen((text) {
      _currentResponse += text;
      _state = MentorState.speaking;
      notifyListeners();
    });
  }

  void startSession({bool autoStart = false}) {
    if (_state != MentorState.idle && _state != MentorState.error) return;
    
    _state = MentorState.connecting;
    _currentResponse = "";
    notifyListeners();
    
    final apiKey = AppConfig.geminiKey;
    if (apiKey.isEmpty) {
      _state = MentorState.error;
      _currentResponse = "Критическая ошибка: API ключ не настроен. Проверьте Config.";
      notifyListeners();
      return;
    }

    try {
      _gemini.startSession(
        apiKey: apiKey,
        systemInstruction: "You are JARVIS, a proactive AI mentor. Help the user learn languages through natural conversation.",
      );
      
      _state = MentorState.active;
      if (autoStart) {
        // Initial greet logic would be triggered by Gemini onSetupComplete equivalent
      }
      notifyListeners();
    } catch (e) {
      _state = MentorState.error;
      _currentResponse = "Ошибка подключения: $e";
      notifyListeners();
    }
  }

  void endSession() {
    _gemini.endSession();
    _state = MentorState.idle;
    _currentResponse = "";
    notifyListeners();
  }

  @override
  void dispose() {
    _textSubscription?.cancel();
    super.dispose();
  }
}
