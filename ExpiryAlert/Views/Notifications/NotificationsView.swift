import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Alert Settings
                    SettingsSection(title: localizationManager.t("notification.alertSettings"), theme: theme) {
                        Toggle(isOn: Binding(
                            get: { notificationService.isEnabled },
                            set: { _ in
                                Task {
                                    if !notificationService.isEnabled {
                                        _ = await notificationService.requestPermission()
                                    } else {
                                        notificationService.isEnabled = false
                                        notificationService.save("notifications_enabled", value: false)
                                    }
                                }
                            }
                        )) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(Color(hex: theme.primaryColor))
                                VStack(alignment: .leading) {
                                    Text(localizationManager.t("notification.enableNotifications"))
                                        .foregroundColor(Color(hex: theme.textColor))
                                    Text(localizationManager.t("notification.enableNotificationsDesc"))
                                        .font(.caption)
                                        .foregroundColor(Color(hex: theme.textSecondary))
                                }
                            }
                        }
                        .tint(Color(hex: theme.primaryColor))
                        
                        Toggle(isOn: $notificationService.expiryAlerts) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(Color(hex: theme.warningColor))
                                Text(localizationManager.t("notification.expiringSoonAlerts"))
                                    .foregroundColor(Color(hex: theme.textColor))
                            }
                        }
                        .tint(Color(hex: theme.warningColor))
                        .disabled(!notificationService.isEnabled)
                        .opacity(notificationService.isEnabled ? 1 : 0.5)
                        
                        Toggle(isOn: $notificationService.todayAlerts) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color(hex: theme.dangerColor))
                                Text(localizationManager.t("notification.expiringTodayAlerts"))
                                    .foregroundColor(Color(hex: theme.textColor))
                            }
                        }
                        .tint(Color(hex: theme.dangerColor))
                        .disabled(!notificationService.isEnabled)
                        .opacity(notificationService.isEnabled ? 1 : 0.5)
                        
                        Toggle(isOn: $notificationService.expiredAlerts) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color(hex: theme.dangerColor))
                                Text(localizationManager.t("notification.expiredAlerts"))
                                    .foregroundColor(Color(hex: theme.textColor))
                            }
                        }
                        .tint(Color(hex: theme.dangerColor))
                        .disabled(!notificationService.isEnabled)
                        .opacity(notificationService.isEnabled ? 1 : 0.5)
                    }
                    
                    // Reminder Timing
                    SettingsSection(title: localizationManager.t("notification.reminderTiming"), theme: theme) {
                        Text(localizationManager.t("notification.alertMeBefore"))
                            .foregroundColor(Color(hex: theme.textColor))
                        
                        HStack(spacing: 12) {
                            ForEach([1, 2, 3, 7], id: \.self) { days in
                                Button(action: { notificationService.setReminderDays(days) }) {
                                    Text("\(days) \(days > 1 ? localizationManager.t("notification.days") : localizationManager.t("notification.day"))")
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            notificationService.reminderDays == days
                                            ? Color(hex: theme.primaryColor)
                                            : Color(hex: theme.backgroundColor)
                                        )
                                        .foregroundColor(
                                            notificationService.reminderDays == days
                                            ? .white
                                            : Color(hex: theme.textColor)
                                        )
                                        .cornerRadius(20)
                                }
                                .disabled(!notificationService.isEnabled)
                            }
                        }
                    }
                    
                    // Test Notification
                    SettingsSection(title: localizationManager.t("notification.testNotification"), theme: theme) {
                        Button(action: { notificationService.sendTestNotification() }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text(localizationManager.t("notification.testButton"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: theme.primaryColor))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(!notificationService.isEnabled)
                        .opacity(notificationService.isEnabled ? 1 : 0.5)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(localizationManager.t("header.notifications"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Settings Section (reusable titled card for settings screens)
struct SettingsSection<Content: View>: View {
    let title: String
    let theme: AppTheme
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: theme.textSecondary))
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: theme.cardBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: theme.borderColor), lineWidth: 1)
            )
        }
    }
}
