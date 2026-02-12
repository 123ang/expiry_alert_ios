import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showAddItem = false
    @State private var showGroupPicker = false
    
    private var theme: AppTheme { themeManager.currentTheme }
    private var counts: (total: Int, fresh: Int, expiring: Int, expired: Int) { dataStore.dashboardCounts }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerSection
                    
                    // Group Selector
                    if dataStore.groups.count > 1 {
                        groupSelector
                    }
                    
                    // Stats Cards
                    statsSection
                    
                    // Quick Actions
                    quickActions
                    
                    // Expiring Soon Section
                    if !dataStore.expiringItems.isEmpty {
                        expiringSoonSection
                    }
                    
                    // Recently Added
                    if !dataStore.foodItems.isEmpty {
                        recentItemsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .refreshable {
                await dataStore.loadAll()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddItem) {
            AddItemView()
        }
        .task {
            if dataStore.foodItems.isEmpty {
                await dataStore.loadAll()
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.t("home.welcome"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: theme.textColor))
                    
                    if let user = authViewModel.user {
                        Text(user.fullName ?? user.email)
                            .font(.subheadline)
                            .foregroundColor(Color(hex: theme.textSecondary))
                    }
                }
                Spacer()
                
                // Notification Bell
                NavigationLink(destination: NotificationsView()) {
                    Image(systemName: "bell.fill")
                        .font(.title3)
                        .foregroundColor(Color(hex: theme.primaryColor))
                        .padding(10)
                        .background(Color(hex: theme.cardBackground))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Group Selector
    private var groupSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(dataStore.groups) { group in
                    Button(action: {
                        Task { await dataStore.switchGroup(to: group.id) }
                    }) {
                        Text(group.name)
                            .font(.subheadline)
                            .fontWeight(group.id == dataStore.activeGroupId ? .bold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                group.id == dataStore.activeGroupId
                                ? Color(hex: theme.primaryColor)
                                : Color(hex: theme.cardBackground)
                            )
                            .foregroundColor(
                                group.id == dataStore.activeGroupId
                                ? .white
                                : Color(hex: theme.textColor)
                            )
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Stats
    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()), GridItem(.flexible())
        ], spacing: 12) {
            StatCard(title: localizationManager.t("status.items"), count: counts.total,
                     icon: "tray.full.fill", color: theme.primaryColor, theme: theme)
            StatCard(title: localizationManager.t("home.indate"), count: counts.fresh,
                     icon: "checkmark.circle.fill", color: theme.successColor, theme: theme)
            StatCard(title: localizationManager.t("status.expiringSoon"), count: counts.expiring,
                     icon: "clock.fill", color: theme.warningColor, theme: theme)
            StatCard(title: localizationManager.t("home.expired"), count: counts.expired,
                     icon: "exclamationmark.triangle.fill", color: theme.dangerColor, theme: theme)
        }
    }
    
    // MARK: - Quick Actions
    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickActionButton(icon: "plus.circle.fill", title: localizationManager.t("nav.add"), color: theme.primaryColor, theme: theme) {
                showAddItem = true
            }
            
            NavigationLink(destination: CategoriesManagementView()) {
                QuickActionContent(icon: "square.grid.2x2.fill", title: localizationManager.t("nav.categories"), color: theme.tertiaryColor, theme: theme)
            }
            
            NavigationLink(destination: LocationsManagementView()) {
                QuickActionContent(icon: "mappin.circle.fill", title: localizationManager.t("nav.locations"), color: theme.secondaryColor, theme: theme)
            }
        }
    }
    
    // MARK: - Expiring Soon
    private var expiringSoonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localizationManager.t("status.expiringSoon"))
                    .font(.headline)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
                Text("\(dataStore.expiringItems.count) \(localizationManager.t("home.items"))")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: theme.textSecondary))
            }
            
            ForEach(dataStore.expiringItems.prefix(5)) { item in
                NavigationLink(destination: ItemDetailView(itemId: item.id)) {
                    FoodItemRow(item: item, theme: theme, localizationManager: localizationManager)
                }
            }
        }
        .padding(16)
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(theme.borderRadius)
    }
    
    // MARK: - Recent Items
    private var recentItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Items")
                .font(.headline)
                .foregroundColor(Color(hex: theme.textColor))
            
            ForEach(dataStore.foodItems.prefix(5)) { item in
                NavigationLink(destination: ItemDetailView(itemId: item.id)) {
                    FoodItemRow(item: item, theme: theme, localizationManager: localizationManager)
                }
            }
        }
        .padding(16)
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(theme.borderRadius)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: String
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: color))
                Spacer()
                Text("\(count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: theme.textColor))
            }
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color(hex: theme.textSecondary))
                Spacer()
            }
        }
        .padding(16)
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(theme.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.borderRadius)
                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
        )
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: String
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            QuickActionContent(icon: icon, title: title, color: color, theme: theme)
        }
    }
}

struct QuickActionContent: View {
    let icon: String
    let title: String
    let color: String
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: color))
            Text(title)
                .font(.caption)
                .foregroundColor(Color(hex: theme.textColor))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(theme.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.borderRadius)
                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
        )
    }
}

// MARK: - Food Item Row
struct FoodItemRow: View {
    let item: FoodItem
    let theme: AppTheme
    let localizationManager: LocalizationManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon/emoji
            ZStack {
                Circle()
                    .fill(Color(hex: theme.primaryColor).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                if let icon = item.categoryIcon, !icon.isEmpty {
                    Text(icon)
                        .font(.title3)
                } else {
                    Image(systemName: "fork.knife")
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: theme.textColor))
                
                HStack(spacing: 8) {
                    if let days = item.daysUntilExpiry {
                        Label(
                            days < 0
                                ? "\(abs(days)) \(localizationManager.t("foodStatus.expiredDays"))"
                                : days == 0
                                    ? localizationManager.t("foodStatus.expirestoday")
                                    : "\(days) \(localizationManager.t("foodStatus.daysLeft"))",
                            systemImage: item.status.icon
                        )
                        .font(.caption)
                        .foregroundColor(Color(hex: item.status.color))
                    }
                    
                    if let locName = item.locationName {
                        Text(locName)
                            .font(.caption)
                            .foregroundColor(Color(hex: theme.textSecondary))
                    }
                }
            }
            
            Spacer()
            
            Text("x\(item.quantity)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: theme.textSecondary))
        }
        .padding(.vertical, 4)
    }
}
