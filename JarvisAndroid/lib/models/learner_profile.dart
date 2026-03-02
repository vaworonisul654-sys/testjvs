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
    successRate: json['successRate'],
  );
}

class Mistake {
  final String original;
  final String correction;

  Mistake({required this.original, required this.correction});

  Map<String, dynamic> toJson() => {'original': original, 'correction': correction};
}

class LearnerProfile {
  double overallLevel;
  List<String> userContext;
  List<String> learnedVocabulary;
  String? lastLessonSummary;
  List<SessionSummary> sessionHistory;
  List<Mistake> recentMistakes;
  bool isInitialAssessmentComplete;

  LearnerProfile({
    this.overallLevel = 1.0,
    this.userContext = const [],
    this.learnedVocabulary = const [],
    this.lastLessonSummary,
    this.sessionHistory = const [],
    this.recentMistakes = const [],
    this.isInitialAssessmentComplete = false,
  });

  Map<String, dynamic> toJson() => {
    'overallLevel': overallLevel,
    'userContext': userContext,
    'learnedVocabulary': learnedVocabulary,
    'lastLessonSummary': lastLessonSummary,
    'sessionHistory': sessionHistory.map((e) => e.toJson()).toList(),
    'recentMistakes': recentMistakes.map((e) => e.toJson()).toList(),
    'isInitialAssessmentComplete': isInitialAssessmentComplete,
  };
}
