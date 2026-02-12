import SwiftUI

@main
struct ExpiryAlertApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var localizationManager = LocalizationManager()
    @StateObject private var dataStore = DataStore()
    @StateObject private var notificationService = NotificationService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
                .environmentObject(dataStore)
                .environmentObject(notificationService)
                .onAppear {
                    dataStore.configure(authViewModel: authViewModel)
                }
                .onChange(of: authViewModel.isAuthenticated) { _, isAuth in
                    if isAuth {
                        Task { await dataStore.loadAll() }
                    }
                }
        }
    }
}
