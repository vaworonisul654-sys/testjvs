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
  
  MentorState get state => _state;
  String get currentResponse => _currentResponse;
  double get audioLevel => _audioLevel;
  bool get isActive => _state == MentorState.active || _state == MentorState.speaking || _state == MentorState.connecting;

  void startSession({bool autoStart = false}) {
    if (_state != MentorState.idle && _state != MentorState.error) return;
    
    _state = MentorState.connecting;
    notifyListeners();
    
    // Simulate connection and parity logic
    // In real implementation, this would call _gemini.startSession(...)
    
    Future.delayed(const Duration(seconds: 1), () {
      _state = MentorState.active;
      if (autoStart) {
        // Send initial greeting trigger
        _sendGreeting();
      }
      notifyListeners();
    });
  }

  void _sendGreeting() {
    _currentResponse = "Привет! Я твой наставник Джарвис. С чего начнем обучение сегодня?";
    _state = MentorState.speaking;
    notifyListeners();
  }

  void endSession() {
    _state = MentorState.idle;
    _currentResponse = "";
    notifyListeners();
  }

  void toggleRecording() {
    if (_state == MentorState.active) {
      // Start recording logic
    } else {
      // Stop logic
    }
  }
}
