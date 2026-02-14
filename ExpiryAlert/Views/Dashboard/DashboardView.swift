import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showAddItem = false
    @State private var showGroupPicker = false
    @State private var homeFilterMode: HomeFilterMode = .all
    @State private var selectedCategoryId: String?
    @State private var selectedLocationId: String?
    @State private var statusSheet: StatusSheetType?
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    enum StatusSheetType: Identifiable {
        case inDate
        case expiringSoon
        case expired
        var id: Self { self }
    }
    private var counts: (total: Int, fresh: Int, expiring: Int, expired: Int) { dataStore.dashboardCounts }
    
    enum HomeFilterMode: String, CaseIterable {
        case all
        case byCategory
        case byLocation
    }
    
    private var filteredFoodItems: [FoodItem] {
        let items = dataStore.foodItems
        switch homeFilterMode {
        case .all:
            return items
        case .byCategory:
            guard let id = selectedCategoryId else { return items }
            return items.filter { $0.categoryId == id }
        case .byLocation:
            guard let id = selectedLocationId else { return items }
            if dataStore.fridgeVariantIds.contains(id) {
                return items.filter { $0.locationId.map { dataStore.fridgeVariantIds.contains($0) } ?? false }
            }
            return items.filter { $0.locationId == id }
        }
    }
    
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
                    
                    // My Items with filter (by category or location)
                    myItemsSection
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
        .sheet(item: $statusSheet) { type in
            statusItemsSheet(type: type)
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
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
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
            Text(localizationManager.t("home.welcome"))
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
                            Text(localizationManager.t("home.groupSubtitle"))
                                .font(.caption)
                                .foregroundColor(Color(hex: theme.textSecondary))
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(Color(hex: theme.textSecondary))
                    }
                    .padding(12)
                    .background(Color(hex: theme.cardBackground))
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
        return localizationManager.t("home.personalGroup")
    }
    
    private var groupPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
                List(dataStore.groups) { group in
                    Button(action: {
                        Task { await dataStore.switchGroup(to: group.id) }
                        showGroupPicker = false
                    }) {
                        HStack {
                            Text(group.name)
                                .font(.body)
                                .foregroundColor(Color(hex: theme.textColor))
                            if group.id == dataStore.activeGroupId {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: theme.primaryColor))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color(hex: theme.cardBackground))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(localizationManager.t("groups.selectGroup"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: theme.cardBackground), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.t("common.done")) { showGroupPicker = false }
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
        }
    }
    
    // MARK: - Three stat cards in a row (tappable → pop-up with items)
    private var threeStatCardsSection: some View {
        HStack(spacing: 12) {
            Button(action: { statusSheet = .inDate }) {
                StatCard(title: localizationManager.t("home.indate"), count: counts.fresh,
                         icon: "checkmark.circle.fill", color: theme.successColor, theme: theme)
            }
            .buttonStyle(PlainButtonStyle())
            Button(action: { statusSheet = .expiringSoon }) {
                StatCard(title: localizationManager.t("status.expiringSoon"), count: counts.expiring,
                         icon: "clock.fill", color: theme.warningColor, theme: theme)
            }
            .buttonStyle(PlainButtonStyle())
            Button(action: { statusSheet = .expired }) {
                StatCard(title: localizationManager.t("home.expired"), count: counts.expired,
                         icon: "exclamationmark.triangle.fill", color: theme.dangerColor, theme: theme)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func statusItemsSheet(type: StatusSheetType) -> some View {
        let (title, items) = statusSheetContent(for: type)
        return NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
                List {
                    if items.isEmpty {
                        Section {
                            Text(emptyStatusMessage(for: type))
                                .font(.subheadline)
                                .foregroundColor(Color(hex: theme.textSecondary))
                                .frame(maxWidth: .infinity)
                                .listRowBackground(Color(hex: theme.backgroundColor))
                        }
                    } else {
                        ForEach(items) { item in
                            NavigationLink(destination: ItemDetailView(itemId: item.id)) {
                                FoodItemRow(item: item, theme: theme, localizationManager: localizationManager)
                                    .padding(.vertical, 4)
                            }
                            .listRowBackground(Color(hex: theme.cardBackground))
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: theme.backgroundColor), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.t("common.close")) {
                        statusSheet = nil
                    }
                    .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
        }
    }
    
    private func statusSheetContent(for type: StatusSheetType) -> (title: String, items: [FoodItem]) {
        switch type {
        case .inDate:
            return (localizationManager.t("home.indate"), dataStore.freshItems)
        case .expiringSoon:
            return (localizationManager.t("status.expiringSoon"), dataStore.expiringItems)
        case .expired:
            return (localizationManager.t("home.expired"), dataStore.expiredItems)
        }
    }
    
    private func emptyStatusMessage(for type: StatusSheetType) -> String {
        switch type {
        case .inDate: return "No in-date items."
        case .expiringSoon: return "No items expiring soon."
        case .expired: return "No expired items."
        }
    }
    
    // MARK: - My Items (with filter by category or location)
    private var myItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localizationManager.t("home.myItems"))
                    .font(.headline)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
                Text("\(filteredFoodItems.count) \(localizationManager.t("home.items"))")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: theme.textSecondary))
            }
            
            // Filter: All | By Category | By Location
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: theme.primaryColor))
                    Text(localizationManager.t("home.filter"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: theme.textSecondary))
                }
                Picker("", selection: $homeFilterMode) {
                    Text(localizationManager.t("home.filterAll")).tag(HomeFilterMode.all)
                    Text(localizationManager.t("home.filterByCategory")).tag(HomeFilterMode.byCategory)
                    Text(localizationManager.t("home.filterByLocation")).tag(HomeFilterMode.byLocation)
                }
                .pickerStyle(.segmented)
                
                if homeFilterMode == .byCategory {
                    categoryFilterPicker
                }
                if homeFilterMode == .byLocation {
                    locationFilterPicker
                }
            }
            .padding(12)
            .background(Color(hex: theme.backgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: theme.borderColor), lineWidth: 1)
            )
            
            if filteredFoodItems.isEmpty {
                Text(listEmptyMessage)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: theme.textSecondary))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredFoodItems) { item in
                        NavigationLink(destination: ItemDetailView(itemId: item.id)) {
                            FoodItemRow(item: item, theme: theme, localizationManager: localizationManager)
                                .padding(.vertical, 10)
                        }
                        if item.id != filteredFoodItems.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .padding(12)
                .background(Color(hex: theme.cardBackground))
                .cornerRadius(theme.borderRadius)
            }
        }
    }
    
    private var categoryFilterPicker: some View {
        Menu {
            Button(localizationManager.t("home.allCategories")) {
                selectedCategoryId = nil
            }
            ForEach(localizationManager.deduplicatedCategories(dataStore.visibleDisplayCategories)) { category in
                Button(localizationManager.getCategoryName(category)) {
                    selectedCategoryId = category.id
                }
            }
        } label: {
            HStack {
                Text(selectedCategoryName)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(Color(hex: theme.textSecondary))
            }
            .padding(10)
            .background(Color(hex: theme.cardBackground))
            .cornerRadius(8)
        }
    }
    
    private var locationFilterPicker: some View {
        Menu {
            Button(localizationManager.t("home.allLocations")) {
                selectedLocationId = nil
            }
            ForEach(dataStore.visibleDisplayLocations) { location in
                Button(localizationManager.getLocationDisplayName(location)) {
                    selectedLocationId = location.id
                }
            }
        } label: {
            HStack {
                Text(selectedLocationName)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(Color(hex: theme.textSecondary))
            }
            .padding(10)
            .background(Color(hex: theme.cardBackground))
            .cornerRadius(8)
        }
    }
    
    private var selectedCategoryName: String {
        guard let id = selectedCategoryId,
              let cat = dataStore.displayCategories.first(where: { $0.id == id }) else {
            return localizationManager.t("home.allCategories")
        }
        return localizationManager.getCategoryName(cat)
    }
    
    private var selectedLocationName: String {
        guard let id = selectedLocationId,
              let loc = dataStore.locations.first(where: { $0.id == id }) else {
            return localizationManager.t("home.allLocations")
        }
        return localizationManager.getLocationDisplayName(loc)
    }
    
    private var listEmptyMessage: String {
        switch homeFilterMode {
        case .all:
            return localizationManager.t("list.noItemsYet")
        case .byCategory:
            return localizationManager.t("list.noItemsInCategory")
        case .byLocation:
            return localizationManager.t("list.noItemsInLocation")
        }
    }
    
    }

// MARK: - Storage Locations Section with Grid
struct StorageLocationsSection: View {
    let locations: [Location]
    let foodItems: [FoodItem]
    let theme: AppTheme
    let localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localizationManager.t("settings.manageLocations"))
                    .font(.headline)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
                NavigationLink(destination: LocationsManagementView()) {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(locations.prefix(6)) { location in
                    LocationCardView(
                        location: location,
                        itemCount: itemCount(for: location.id),
                        theme: theme,
                        localizationManager: localizationManager
                    )
                }
            }
        }
    }
    
    private func itemCount(for locationId: String) -> Int {
        foodItems.filter { $0.locationId == locationId }.count
    }
}

// MARK: - Location Card View
struct LocationCardView: View {
    let location: Location
    let itemCount: Int
    let theme: AppTheme
    let localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Text(location.icon ?? "📦")
                .font(.system(size: 32))
            
            // Name
            Text(resolvedName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: theme.textColor))
                .lineLimit(1)
            
            // Item count
            Text("\(itemCount) \(itemCount == 1 ? "item" : "items")")
                .font(.caption)
                .foregroundColor(Color(hex: theme.textSecondary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(theme.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.borderRadius)
                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
        )
        .shadow(
            color: Color(hex: theme.shadowColor),
            radius: 4,
            x: 0,
            y: 2
        )
    }
    
    private var resolvedName: String {
        localizationManager.getLocationDisplayName(location)
    }
}

// MARK: - Categories Section with Grid
struct CategoriesSection: View {
    let categories: [Category]
    let foodItems: [FoodItem]
    let theme: AppTheme
    let localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localizationManager.t("settings.manageCategories"))
                    .font(.headline)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
                NavigationLink(destination: CategoriesManagementView()) {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(categories.prefix(6)) { category in
                    CategoryCardView(
                        category: category,
                        itemCount: itemCount(for: category.id),
                        theme: theme,
                        localizationManager: localizationManager
                    )
                }
            }
        }
    }
    
    private func itemCount(for categoryId: String) -> Int {
        foodItems.filter { $0.categoryId == categoryId }.count
    }
}

// MARK: - Category Card View
struct CategoryCardView: View {
    let category: Category
    let itemCount: Int
    let theme: AppTheme
    let localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Text(category.icon ?? "🍽️")
                .font(.system(size: 32))
            
            // Name
            Text(resolvedName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: theme.textColor))
                .lineLimit(1)
            
            // Item count
            Text("\(itemCount) \(itemCount == 1 ? "item" : "items")")
                .font(.caption)
                .foregroundColor(Color(hex: theme.textSecondary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(theme.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.borderRadius)
                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
        )
        .shadow(
            color: Color(hex: theme.shadowColor),
            radius: 4,
            x: 0,
            y: 2
        )
    }
    
    private var resolvedName: String {
        localizationManager.getCategoryName(category)
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
