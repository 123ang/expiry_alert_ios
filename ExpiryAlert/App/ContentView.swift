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
    var body: some View {
        ZStack {
            Color(hex: "#006b29")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "leaf.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                
                Text("Expiry Alert")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("Loading...")
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
    @State private var selectedTab: TabItem = .home
    @State private var showAddItem = false
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area
            VStack(spacing: 0) {
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Spacer for tab bar height
                Color.clear
                    .frame(height: tabBarHeight)
            }
            
            // Custom tab bar overlay
            CustomTabBar(
                selectedTab: $selectedTab,
                showAddItem: $showAddItem,
                theme: theme,
                localizationManager: localizationManager
            )
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAddItem) {
            AddItemView()
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
        // Tab bar height: 12 (top padding) + 20 (icon) + 4 (spacing) + 12 (text) + bottom safe area
        #if os(iOS)
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        let bottomInset = window?.safeAreaInsets.bottom ?? 0
        return 12 + 20 + 4 + 12 + 12 + bottomInset
        #else
        return 60
        #endif
    }
}
