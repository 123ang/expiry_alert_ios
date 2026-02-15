import SwiftUI

@main
struct ExpiryAlertApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var localizationManager = LocalizationManager()
    @StateObject private var dataStore = DataStore()
    @StateObject private var notificationService = NotificationService()
    
    init() {
        // Larger cache for item thumbnails so list and detail can reuse loaded images
        let memoryCapacity = 50 * 1024 * 1024  // 50 MB
        let diskCapacity = 100 * 1024 * 1024   // 100 MB
        URLCache.shared = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)
    }
    
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
