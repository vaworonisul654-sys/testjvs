import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LearnerProfile {
  int totalSessions = 0;
  double overallLevel = 1.0;
  Map<String, double> interestTopics = {};
  double vocabularyScore = 0.2;
  double pronunciationScore = 0.2;
  double grammarScore = 0.2;
  double fluencyScore = 0.2;
  int streakCount = 0;
  DateTime? lastPracticeDate;
  List<Mistake> recentMistakes = [];
  String longTermMemory = "";
  bool isInitialAssessmentComplete = false;
  String? teachingProgram;
  int currentLessonIndex = 1;

  LearnerProfile();

  Map<String, dynamic> toJson() => {
    'totalSessions': totalSessions,
    'overallLevel': overallLevel,
    'interestTopics': interestTopics,
    'vocabularyScore': vocabularyScore,
    'pronunciationScore': pronunciationScore,
    'grammarScore': grammarScore,
    'fluencyScore': fluencyScore,
    'streakCount': streakCount,
    'lastPracticeDate': lastPracticeDate?.toIso8601String(),
    'recentMistakes': recentMistakes.map((m) => m.toJson()).toList(),
    'longTermMemory': longTermMemory,
    'isInitialAssessmentComplete': isInitialAssessmentComplete,
    'teachingProgram': teachingProgram,
    'currentLessonIndex': currentLessonIndex,
  };

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    final profile = LearnerProfile();
    profile.totalSessions = json['totalSessions'] ?? 0;
    profile.overallLevel = json['overallLevel'] ?? 1.0;
    profile.vocabularyScore = json['vocabularyScore'] ?? 0.2;
    profile.pronunciationScore = json['pronunciationScore'] ?? 0.2;
    profile.grammarScore = json['grammarScore'] ?? 0.2;
    profile.fluencyScore = json['fluencyScore'] ?? 0.2;
    profile.streakCount = json['streakCount'] ?? 0;
    profile.longTermMemory = json['longTermMemory'] ?? "";
    profile.isInitialAssessmentComplete = json['isInitialAssessmentComplete'] ?? false;
    profile.teachingProgram = json['teachingProgram'];
    profile.currentLessonIndex = json['currentLessonIndex'] ?? 1;
    
    if (json['lastPracticeDate'] != null) {
      profile.lastPracticeDate = DateTime.parse(json['lastPracticeDate']);
    }
    
    if (json['recentMistakes'] != null) {
      profile.recentMistakes = (json['recentMistakes'] as List)
        .map((m) => Mistake.fromJson(m))
        .toList();
    }
    
    return profile;
  }
}

class Mistake {
  final String original;
  final String correction;
  final String explanation;
  final DateTime date;

  Mistake({required this.original, required this.correction, required this.explanation, required this.date});

  Map<String, dynamic> toJson() => {
    'original': original,
    'correction': correction,
    'explanation': explanation,
    'date': date.toIso8601String(),
  };

  factory Mistake.fromJson(Map<String, dynamic> json) => Mistake(
    original: json['original'],
    correction: json['correction'],
    explanation: json['explanation'],
    date: DateTime.parse(json['date']),
  );
}

class ProfileManager {
  static final ProfileManager _instance = ProfileManager._internal();
  factory ProfileManager() => _instance;
  ProfileManager._internal();

  late SharedPreferences _prefs;
  LearnerProfile currentProfile = LearnerProfile();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final data = _prefs.getString('jarvis_profile');
    if (data != null) {
      currentProfile = LearnerProfile.fromJson(jsonDecode(data));
    }
  }

  Future<void> save() async {
    await _prefs.setString('jarvis_profile', jsonEncode(currentProfile.toJson()));
  }

  void addMistake(String original, String correction, String explanation) {
    currentProfile.recentMistakes.insert(0, Mistake(
      original: original,
      correction: correction,
      explanation: explanation,
      date: DateTime.now(),
    ));
    if (currentProfile.recentMistakes.length > 10) {
      currentProfile.recentMistakes.removeLast();
    }
    save();
  }
}
