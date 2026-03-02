import Foundation
import UserNotifications

/// Manages local notifications for daily language practice reminders
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    /// Requests permission from the user to send notifications
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if let error = error {
                print("LVT NotificationManager: Error requesting authorization: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                completion(granted)
                
                if granted {
                    self?.scheduleDailyReminder()
                }
            }
        }
    }
    
    /// Checks the current authorization status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    /// Schedules a daily reminder at 10:00 AM
    func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing reminders to avoid duplicates
        center.removePendingNotificationRequests(withIdentifiers: ["daily_practice_reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Время для урока! 📘"
        content.body = "Джарвис ждёт вас. Практика — ключ к совершенству."
        content.sound = .default
        
        // Configure schedule for 10:00 AM (Moscow Time)
        var dateComponents = DateComponents()
        if let moscowTimezone = TimeZone(identifier: "Europe/Moscow") {
            dateComponents.timeZone = moscowTimezone
        }
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_practice_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("LVT NotificationManager: Error scheduling reminder: \(error.localizedDescription)")
            } else {
                print("LVT NotificationManager: Daily reminder scheduled for 10:00 AM")
            }
        }
    }
}
