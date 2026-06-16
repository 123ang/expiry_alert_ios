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

    private let notificationHour = 9
    private let notificationMinute = 0
    
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
            guard let days = item.daysUntilExpiry,
                  let expiryDate = expiryDate(for: item) else { continue }
            
            // Expiring soon notification
            if expiryAlerts && days > 0,
               let scheduledDate = notificationDate(for: expiryDate, dayOffset: -reminderDays) {
                let labelDays = min(days, reminderDays)
                scheduleNotification(
                    id: "expiring_\(item.id)",
                    title: "Food Expiring Soon",
                    body: "\(item.name) will expire in \(labelDays) day\(labelDays == 1 ? "" : "s")",
                    scheduledDate: scheduledDate
                )
            }
            
            // Expires today notification
            if todayAlerts && days == 0,
               let scheduledDate = notificationDate(for: expiryDate, dayOffset: 0) {
                scheduleNotification(
                    id: "today_\(item.id)",
                    title: "Food Expiring Today!",
                    body: "\(item.name) expires today. Use it now!",
                    scheduledDate: scheduledDate
                )
            }
            
            // Expired notification
            if expiredAlerts && days < 0 {
                scheduleNotification(
                    id: "expired_\(item.id)",
                    title: "Food Has Expired",
                    body: "\(item.name) expired \(abs(days)) day\(abs(days) == 1 ? "" : "s") ago",
                    scheduledDate: nextAvailableNotificationDate()
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

    private func scheduleNotification(id: String, title: String, body: String, scheduledDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components: DateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: scheduledDate
        )
        components.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func expiryDate(for item: FoodItem) -> Date? {
        let rawDate = item.expiryDateFormatted
        guard rawDate != "N/A" else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.current.timeZone
        return formatter.date(from: rawDate)
    }

    private func notificationDate(for expiryDate: Date, dayOffset: Int) -> Date? {
        let calendar = Calendar.current
        guard let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: expiryDate)),
              let scheduledDate = calendar.date(
                bySettingHour: notificationHour,
                minute: notificationMinute,
                second: 0,
                of: targetDay
              ) else { return nil }

        return scheduledDate > Date() ? scheduledDate : nextAvailableNotificationDate()
    }

    private func nextAvailableNotificationDate() -> Date {
        Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date().addingTimeInterval(60)
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
