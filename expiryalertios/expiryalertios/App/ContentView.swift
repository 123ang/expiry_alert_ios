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

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedTab: Tab = .home
    
    enum Tab: Int, CaseIterable {
        case home = 0, list, calendar, settings
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .list: return "list.bullet"
            case .calendar: return "calendar"
            case .settings: return "gearshape.fill"
            }
        }
        
        func title(using lm: LocalizationManager) -> String {
            switch self {
            case .home: return lm.t("nav.home")
            case .list: return lm.t("nav.list")
            case .calendar: return lm.t("nav.calendar")
            case .settings: return lm.t("nav.settings")
            }
        }
    }
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tag(Tab.home)
            .tabItem {
                Image(systemName: Tab.home.icon)
                Text(Tab.home.title(using: localizationManager))
            }
            
            NavigationStack {
                FoodListView()
            }
            .tag(Tab.list)
            .tabItem {
                Image(systemName: Tab.list.icon)
                Text(Tab.list.title(using: localizationManager))
            }
            
            NavigationStack {
                CalendarScreenView()
            }
            .tag(Tab.calendar)
            .tabItem {
                Image(systemName: Tab.calendar.icon)
                Text(Tab.calendar.title(using: localizationManager))
            }
            
            NavigationStack {
                SettingsView()
            }
            .tag(Tab.settings)
            .tabItem {
                Image(systemName: Tab.settings.icon)
                Text(Tab.settings.title(using: localizationManager))
            }
        }
        .tint(Color(hex: theme.primaryColor))
    }
}
