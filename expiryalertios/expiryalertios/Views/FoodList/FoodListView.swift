import SwiftUI

struct FoodListView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var searchText = ""
    @State private var selectedFilter: ListFilter = .all
    @State private var showAddItem = false
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    enum ListFilter: String, CaseIterable {
        case all, indate, expiring, expired
        
        func title(using lm: LocalizationManager) -> String {
            switch self {
            case .all: return lm.t("list.all")
            case .indate: return lm.t("list.indate")
            case .expiring: return lm.t("list.expiring")
            case .expired: return lm.t("list.expired")
            }
        }
    }
    
    private var filteredItems: [FoodItem] {
        var items = dataStore.foodItems
        
        // Filter by status
        switch selectedFilter {
        case .all: break
        case .indate: items = items.filter { $0.status == .fresh }
        case .expiring: items = items.filter { $0.status == .expiringSoon }
        case .expired: items = items.filter { $0.status == .expired }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return items
    }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text(localizationManager.t("nav.list"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: theme.textColor))
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(hex: theme.textSecondary))
                        TextField(localizationManager.t("list.search"), text: $searchText)
                            .foregroundColor(Color(hex: theme.textColor))
                    }
                    .padding(12)
                    .background(Color(hex: theme.cardBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                    )
                    
                    // Filter Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ListFilter.allCases, id: \.self) { filter in
                                Button(action: { selectedFilter = filter }) {
                                    Text(filter.title(using: localizationManager))
                                        .font(.subheadline)
                                        .fontWeight(selectedFilter == filter ? .bold : .regular)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedFilter == filter
                                            ? Color(hex: theme.primaryColor)
                                            : Color(hex: theme.cardBackground)
                                        )
                                        .foregroundColor(
                                            selectedFilter == filter ? .white : Color(hex: theme.textColor)
                                        )
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color(hex: theme.borderColor), lineWidth: selectedFilter == filter ? 0 : 1)
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(hex: theme.cardBackground))
                
                // Items List
                if filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: theme.textSecondary))
                        Text(searchText.isEmpty
                             ? localizationManager.t("list.noItems")
                             : localizationManager.t("list.noSearch"))
                            .foregroundColor(Color(hex: theme.textSecondary))
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            NavigationLink(destination: ItemDetailView(itemId: item.id)) {
                                FoodItemRow(item: item, theme: theme, localizationManager: localizationManager)
                            }
                            .listRowBackground(Color(hex: theme.cardBackground))
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showAddItem = true }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color(hex: theme.primaryColor))
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(20)
        }
        .sheet(isPresented: $showAddItem) {
            AddItemView()
        }
        .refreshable {
            await dataStore.refreshFoodItems()
        }
    }
}
