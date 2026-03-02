import Foundation

struct LearnerProfile: Codable {
    var totalSessions: Int = 5
    var overallLevel: Double = 3.5
    var interestTopics: [String: Double] = ["Technology": 0.8, "Travel": 0.5]
    var streakCount: Int = 12
    var isInitialAssessmentComplete: Bool = true
}

let profile = LearnerProfile()
if let data = try? JSONEncoder().encode(profile) {
    UserDefaults.standard.set(data, forKey: "jarvis_learner_profile")
    print("Profile bypassed successfully")
}
