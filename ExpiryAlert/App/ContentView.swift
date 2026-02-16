import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        viewContent
            .animation(Animation.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
            .animation(Animation.easeInOut(duration: 0.3), value: authViewModel.isLoading)
    }

    @ViewBuilder
    private var viewContent: some View {
        if authViewModel.isLoading {
            SplashScreenView()
        } else if authViewModel.isAuthenticated {
            MainTabView()
        } else {
            LoginView()
        }
    }
}

// MARK: - Splash Screen
struct SplashScreenView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        ZStack {
            Color(hex: "#006b29")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                
                Text(localizationManager.t("app.name"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text(localizationManager.t("status.loading"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Main Tab View with Custom Tab Bar
struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var toastManager: ToastManager
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedTab: TabItem = .home
    @State private var showAddItem = false
    @State private var showExpiredReminder = false
    @State private var expiredCount = 0
    
    private var theme: AppTheme { themeManager.currentTheme }
    private static let expiredReminderLastShownKey = "expired_reminder_last_shown_date"
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area
            VStack(spacing: 0) {
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Spacer for tab bar height (content stays above bar)
                Color.clear
                    .frame(height: tabBarHeight)
            }
            
            CustomTabBar(
                selectedTab: $selectedTab,
                showAddItem: $showAddItem,
                theme: theme,
                localizationManager: localizationManager
            )
        }
        .overlay {
            if let msg = toastManager.message {
                VStack {
                    Spacer()
                    ToastBanner(message: msg, isError: toastManager.isError, theme: theme)
                    Spacer()
                }
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .overlay {
            if showExpiredReminder {
                ExpiredReminderPopUp(
                    count: expiredCount,
                    theme: theme,
                    localizationManager: localizationManager,
                    onDismiss: { showExpiredReminder = false }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(101)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: toastManager.message)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showExpiredReminder)
        .ignoresSafeArea(edges: .bottom)
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAddItem) {
            AddItemView()
        }
        .onAppear {
            checkExpiredReminderIfNeeded()
        }
    }
    
    private func checkExpiredReminderIfNeeded() {
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await MainActor.run {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let today = formatter.string(from: Date())
                let lastShown = UserDefaults.standard.string(forKey: Self.expiredReminderLastShownKey)
                guard lastShown != today else { return }
                let count = dataStore.dashboardCounts.expired
                guard count > 0 else { return }
                expiredCount = count
                showExpiredReminder = true
                UserDefaults.standard.set(today, forKey: Self.expiredReminderLastShownKey)
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .home:
            NavigationStack {
                DashboardView()
            }
        case .list:
            NavigationStack {
                FoodListView()
            }
        case .add:
            // Never shown, handled by sheet
            Color.clear
        case .calendar:
            NavigationStack {
                CalendarScreenView()
            }
        case .settings:
            NavigationStack {
                SettingsView()
            }
        }
    }
    
    private var tabBarHeight: CGFloat {
        // Tab bar height: 8 (top) + 20 (icon) + 4 (spacing) + 12 (text) + bottom inset (lesser footer space)
        #if os(iOS)
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        let bottomInset = window?.safeAreaInsets.bottom ?? 0
        return 8 + 20 + 4 + 12 + (bottomInset > 0 ? bottomInset : 12)
        #else
        return 56
        #endif
    }
}

// MARK: - Toast banner (centered pop-up message)
struct ToastBanner: View {
    let message: String
    let isError: Bool
    let theme: AppTheme
    
    private var accentColor: String { isError ? theme.dangerColor : theme.successColor }
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: accentColor).opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: accentColor))
            }
            Text(message)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: theme.textColor))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: theme.cardBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
                .shadow(color: Color(hex: accentColor).opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: accentColor).opacity(0.4), lineWidth: 1.5)
        )
        .padding(.horizontal, 32)
    }
}

// MARK: - Expired items today reminder (centered pop-up, once per day)
struct ExpiredReminderPopUp: View {
    let count: Int
    let theme: AppTheme
    let localizationManager: LocalizationManager
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(hex: theme.warningColor).opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: theme.warningColor))
                }
                Text(localizationManager.t("reminder.expiredTodayTitle"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: theme.textColor))
                Text(String(format: localizationManager.t("reminder.expiredTodayMessage"), count))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: theme.textSecondary))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: onDismiss) {
                    Text(localizationManager.t("common.ok"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: theme.primaryColor))
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: theme.cardBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: theme.warningColor).opacity(0.4), lineWidth: 1.5)
            )
        }
    }
}
