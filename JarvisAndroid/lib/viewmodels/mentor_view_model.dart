import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/learner_profile.dart';
import 'audio/audio_capture_service.dart';
import 'network/gemini_live_service.dart';
import 'tts/tts_service.dart';
import 'mentor/mentor_service.dart';

enum MentorState { idle, connecting, active, speaking, error }

class MentorViewModel extends ChangeNotifier {
  MentorState _state = MentorState.idle;
  String _currentResponse = "";
  double _audioLevel = 0;
  
  // Services
  final GeminiLiveService _geminiService = GeminiLiveService();
  final AudioCaptureService _audioCaptureService = AudioCaptureService();
  final TTSService _ttsService = TTSService();
  final MentorService _mentorService = MentorService();
  final ProfileManager _profileManager = ProfileManager();

  MentorState get state => _state;
  String get currentResponse => _currentResponse;
  double get audioLevel => _audioLevel;

  MentorViewModel() {
    _setupCallbacks();
  }

  Future<void> init() async {
    await _profileManager.init();
    await _audioCaptureService.init();
    await _ttsService.init();
  }

  void _setupCallbacks() {
    _geminiService.onTranslatedText = (text) {
      _currentResponse += text;
      _state = MentorState.speaking;
      notifyListeners();
    };

    _geminiService.onAudioData = (audio) {
      _ttsService.playGeminiAudio(Uint8List.fromList(audio));
      _state = MentorState.speaking;
      notifyListeners();
    };

    _geminiService.onTurnComplete = () {
      if (_currentResponse.isNotEmpty) {
        _parseAndProcessTags(_currentResponse);
        _currentResponse = "";
      }
      _state = MentorState.active;
      notifyListeners();
    };

    _geminiService.onSetupComplete = () {
      _geminiService.sendTextMessage("Начни."); // Trigger first response
    };

    _geminiService.onError = (err) {
      _state = MentorState.error;
      notifyListeners();
    };
  }

  Future<void> startSession(String apiKey) async {
    _state = MentorState.connecting;
    notifyListeners();

    try {
      final instruction = _mentorService.getSystemInstruction(_profileManager.currentProfile);
      
      _geminiService.startSession(
        apiKey: apiKey,
        systemInstruction: instruction,
      );

      // Start audio capture stream
      await _audioCaptureService.startCapture();
      _audioCaptureService.audioStream.listen((chunk) {
        if (_geminiService.isSessionActive && !_ttsService.isSpeaking) {
          _geminiService.sendAudioChunk(chunk);
        }
      });

    } catch (e) {
      _state = MentorState.error;
      notifyListeners();
    }
  }

  void stopSession() {
    _geminiService.endSession();
    _audioCaptureService.stopCapture();
    _ttsService.stop();
    _state = MentorState.idle;
    _currentResponse = "";
    notifyListeners();
  }

  void _parseAndProcessTags(String text) {
    // 1. Parse Mistakes [MISTAKE: original | correction | explanation]
    final mistakeRegex = RegExp(r'\[MISTAKE\s*:\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\]');
    final mistakeMatches = mistakeRegex.allMatches(text);
    for (var match in mistakeMatches) {
      _profileManager.addMistake(match.group(1)!, match.group(2)!, match.group(3)!);
    }
    
    // 2. Parse Program Update [PROGRAM_UPDATE: text]
    final programRegex = RegExp(r'\[PROGRAM_UPDATE\s*:\s*(.*?)\s*\]', dotAll: true);
    final programMatch = programRegex.firstMatch(text);
    if (programMatch != null) {
      _profileManager.currentProfile.teachingProgram = programMatch.group(1);
      _profileManager.currentProfile.isInitialAssessmentComplete = true;
      _profileManager.save();
    }
  }

  @override
  void dispose() {
    _audioCaptureService.dispose();
    _ttsService.dispose();
    _geminiService.endSession();
    super.dispose();
  }
}
