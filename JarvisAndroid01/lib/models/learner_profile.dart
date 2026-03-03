import 'dart:convert';

class LearnerProfile {
  int totalSessions = 0;
  double overallLevel = 1.0;
  Map<String, double> interestTopics = {};
  List<Mistake> recentMistakes = [];
  List<SessionSummary> sessionHistory = [];
  List<String> learnedVocabulary = [];
  String longTermMemory = "";
  bool isInitialAssessmentComplete = false;

  LearnerProfile();

  Map<String, dynamic> toJson() => {
    'totalSessions': totalSessions,
    'overallLevel': overallLevel,
    'interestTopics': interestTopics,
    'recentMistakes': recentMistakes.map((e) => e.toJson()).toList(),
    'sessionHistory': sessionHistory.map((e) => e.toJson()).toList(),
    'longTermMemory': longTermMemory,
    'isInitialAssessmentComplete': isInitialAssessmentComplete,
  };

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    var profile = LearnerProfile();
    profile.totalSessions = json['totalSessions'] ?? 0;
    profile.overallLevel = json['overallLevel'] ?? 1.0;
    profile.interestTopics = Map<String, double>.from(json['interestTopics'] ?? {});
    profile.longTermMemory = json['longTermMemory'] ?? "";
    profile.isInitialAssessmentComplete = json['isInitialAssessmentComplete'] ?? false;
    
    if (json['recentMistakes'] != null) {
      profile.recentMistakes = (json['recentMistakes'] as List)
          .map((e) => Mistake.fromJson(e))
          .toList();
    }
    
    if (json['sessionHistory'] != null) {
      profile.sessionHistory = (json['sessionHistory'] as List)
          .map((e) => SessionSummary.fromJson(e))
          .toList();
    }
    
    return profile;
  }
}

class Mistake {
  final String id;
  final String original;
  final String correction;
  final String explanation;
  final DateTime date;

  Mistake({
    required this.id,
    required this.original,
    required this.correction,
    required this.explanation,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'original': original,
    'correction': correction,
    'explanation': explanation,
    'date': date.toIso8601String(),
  };

  factory Mistake.fromJson(Map<String, dynamic> json) => Mistake(
    id: json['id'],
    original: json['original'],
    correction: json['correction'],
    explanation: json['explanation'],
    date: DateTime.parse(json['date']),
  );
}

class SessionSummary {
  final String id;
  final DateTime date;
  final String topic;
  final String summary;
  final double successRate;

  SessionSummary({
    required this.id,
    required this.date,
    required this.topic,
    required this.summary,
    required this.successRate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'topic': topic,
    'summary': summary,
    'successRate': successRate,
  };

  factory SessionSummary.fromJson(Map<String, dynamic> json) => SessionSummary(
    id: json['id'],
    date: DateTime.parse(json['date']),
    topic: json['topic'],
    summary: json['summary'],
    successRate: json['successRate'] ?? 0.0,
  );
}
