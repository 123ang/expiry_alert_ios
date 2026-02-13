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
                VStack(spacing: 20) {
                    // Logo + Title
                    headerLogoSection
                    
                    // Welcome card with group selector
                    welcomeCardSection
                    
                    // Three stat cards: Fresh, Expiring, Expired
                    threeStatCardsSection
                    
                    // Storage Locations section with edit
                    StorageLocationsSection(theme: theme)
                    
                    // Categories section with edit
                    CategoriesSection(theme: theme)
                    
                    // Expiring Soon (if any)
                    if !dataStore.expiringItems.isEmpty {
                        expiringSoonSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .refreshable {
                await dataStore.loadAll()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddItem) {
            AddItemView()
        }
        .sheet(isPresented: $showGroupPicker) {
            groupPickerSheet
        }
        .task {
            if dataStore.foodItems.isEmpty {
                await dataStore.loadAll()
            }
        }
    }
    
    // MARK: - Logo + Title Header
    private var headerLogoSection: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: theme.primaryColor))
                    .frame(width: 44, height: 44)
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Text(localizationManager.t("app.name"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: theme.textColor))
            Spacer()
        }
        .padding(.top, 12)
    }
    
    // MARK: - Welcome Card (green) with group selector
    private var welcomeCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome Back!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                Button(action: { if dataStore.groups.count > 1 { showGroupPicker = true } }) {
                    HStack(spacing: 10) {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(Color(hex: theme.primaryColor))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activeGroupName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: theme.textColor))
                            Text("Your personal food management group.")
                                .font(.caption)
                                .foregroundColor(Color(hex: theme.textSecondary))
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(Color(hex: theme.textSecondary))
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    Task { await dataStore.loadAll() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color(hex: theme.primaryColor).opacity(0.8))
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: theme.primaryColor))
        .cornerRadius(16)
    }
    
    private var activeGroupName: String {
        if let id = dataStore.activeGroupId,
           let group = dataStore.groups.first(where: { $0.id == id }) {
            return group.name
        }
        return "Personal"
    }
    
    private var groupPickerSheet: some View {
        NavigationStack {
            List(dataStore.groups) { group in
                Button(action: {
                    Task { await dataStore.switchGroup(to: group.id) }
                    showGroupPicker = false
                }) {
                    HStack {
                        Text(group.name)
                            .foregroundColor(Color(hex: theme.textColor))
                        if group.id == dataStore.activeGroupId {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: theme.primaryColor))
                        }
                    }
                }
            }
            .navigationTitle("Select Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showGroupPicker = false }
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
        }
    }
    
    // MARK: - Three stat cards in a row (Fresh, Expiring, Expired)
    private var threeStatCardsSection: some View {
        HStack(spacing: 12) {
            StatCard(title: localizationManager.t("home.indate"), count: counts.fresh,
                     icon: "checkmark.circle.fill", color: theme.successColor, theme: theme)
            StatCard(title: localizationManager.t("status.expiringSoon"), count: counts.expiring,
                     icon: "clock.fill", color: theme.warningColor, theme: theme)
            StatCard(title: localizationManager.t("home.expired"), count: counts.expired,
                     icon: "exclamationmark.triangle.fill", color: theme.dangerColor, theme: theme)
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
}

// MARK: - Storage Locations Section (header + pencil)
struct StorageLocationsSection: View {
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Storage Locations")
                    .font(.headline)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
                NavigationLink(destination: LocationsManagementView()) {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
        }
    }
}

// MARK: - Categories Section (header + pencil)
struct CategoriesSection: View {
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Categories")
                    .font(.headline)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
                NavigationLink(destination: CategoriesManagementView()) {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
        }
    }
}

// MARK: - Stat Card (icon on top, label, then big number)
struct StatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: String
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: color))
            Text(title)
                .font(.caption)
                .foregroundColor(Color(hex: theme.textSecondary))
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: theme.primaryColor))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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
