import SwiftUI
import Combine
import UserNotifications

@MainActor
class NotificationService: ObservableObject {
    @Published var isEnabled = false
    @Published var expiryAlerts = true
    @Published var todayAlerts = true
    @Published var expiredAlerts = true
    @Published var reminderDays = 3
    
    init() {
        loadSettings()
        // Defer permission check to next run loop so we don't trigger system callbacks during app launch
        DispatchQueue.main.async { [weak self] in
            self?.checkPermission()
        }
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            let authorized = settings.authorizationStatus == .authorized
            DispatchQueue.main.async {
                self.isEnabled = authorized
            }
        }
    }
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isEnabled = granted
                save("notifications_enabled", value: granted)
            }
            return granted
        } catch {
            return false
        }
    }
    
    func scheduleExpiryNotifications(for items: [FoodItem]) {
        guard isEnabled else { return }
        
        // Remove all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for item in items {
            guard let days = item.daysUntilExpiry else { continue }
            
            // Expiring soon notification
            if expiryAlerts && days > 0 && days <= reminderDays {
                scheduleNotification(
                    id: "expiring_\(item.id)",
                    title: "Food Expiring Soon",
                    body: "\(item.name) will expire in \(days) day\(days == 1 ? "" : "s")",
                    timeInterval: 1 // Immediate for testing; in production, schedule for morning
                )
            }
            
            // Expires today notification
            if todayAlerts && days == 0 {
                scheduleNotification(
                    id: "today_\(item.id)",
                    title: "Food Expiring Today!",
                    body: "\(item.name) expires today. Use it now!",
                    timeInterval: 1
                )
            }
            
            // Expired notification
            if expiredAlerts && days < 0 {
                scheduleNotification(
                    id: "expired_\(item.id)",
                    title: "Food Has Expired",
                    body: "\(item.name) expired \(abs(days)) day\(abs(days) == 1 ? "" : "s") ago",
                    timeInterval: 1
                )
            }
        }
    }
    
    func sendTestNotification() {
        scheduleNotification(
            id: "test_\(UUID().uuidString)",
            title: "Expiry Alert",
            body: "This is a test notification from Expiry Alert!",
            timeInterval: 2
        )
    }
    
    private func scheduleNotification(id: String, title: String, body: String, timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Settings Persistence
    private func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")
        expiryAlerts = UserDefaults.standard.object(forKey: "expiry_alerts") as? Bool ?? true
        todayAlerts = UserDefaults.standard.object(forKey: "today_alerts") as? Bool ?? true
        expiredAlerts = UserDefaults.standard.object(forKey: "expired_alerts") as? Bool ?? true
        reminderDays = UserDefaults.standard.object(forKey: "reminder_days") as? Int ?? 3
    }
    
    func save(_ key: String, value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    func toggleExpiryAlerts() { expiryAlerts.toggle(); save("expiry_alerts", value: expiryAlerts) }
    func toggleTodayAlerts() { todayAlerts.toggle(); save("today_alerts", value: todayAlerts) }
    func toggleExpiredAlerts() { expiredAlerts.toggle(); save("expired_alerts", value: expiredAlerts) }
    func setReminderDays(_ days: Int) { reminderDays = days; save("reminder_days", value: days) }
}
