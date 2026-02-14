import SwiftUI

struct FoodListView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager

    @State private var listMode: ListMode = .shopping
    @State private var showAddShoppingModal = false
    @State private var showAddWishlistModal = false
    @State private var shoppingFilter: ShoppingFilter = .all
    @State private var selectedStoreKey: String? = nil
    @State private var selectedCategoryFilterId: String?
    @State private var collapsedStoreKeys: Set<String> = []
    @State private var shoppingItemForInventory: ShoppingItem?
    @State private var showAddToInventorySheet = false
    @State private var shoppingItemToEdit: ShoppingItem?
    @State private var wishlistItemToEdit: WishItem?
    @State private var showClearCompletedDialog = false
    @State private var showClearCompletedWarningAlert = false
    /// nil = All, 1...5 = filter by that desire level (flames).
    @State private var wishlistRatingFilter: Int? = nil
    /// When false, filter chips are always shown; when true, collapsed to a single row (user choice, persisted).
    @State private var wishlistFiltersCollapsed: Bool = UserDefaults.standard.object(forKey: Self.wishlistFiltersCollapsedKey) as? Bool ?? false

    private var theme: AppTheme { themeManager.currentTheme }

    private static let lastWishlistCurrencyKey = "lastWishlistCurrencyCode"
    private static let wishlistFiltersCollapsedKey = "wishlistFiltersCollapsed"

    private var purchasedShoppingItems: [ShoppingItem] {
        visibleShoppingItems.filter { $0.isPurchased }
    }

    enum ListMode: String, CaseIterable {
        case shopping
        case wish
    }

    // MARK: - Filtered & grouped data

    /// Exclude items already added to inventory (they are removed from the shopping list).
    private var visibleShoppingItems: [ShoppingItem] {
        dataStore.shoppingItems.filter { $0.movedToInventory != true }
    }

    /// Filter by All/Active/Bought and optional category; then optionally by store.
    private var filteredShoppingItems: [ShoppingItem] {
        var list = visibleShoppingItems
        switch shoppingFilter {
        case .all: break
        case .active: list = list.filter { !$0.isPurchased }
        case .bought: list = list.filter { $0.isPurchased }
        }
        if let catId = selectedCategoryFilterId {
            list = list.filter { $0.categoryId == catId }
        }
        if let store = selectedStoreKey {
            list = list.filter { storeDisplayKey(for: $0) == store }
        }
        return list
    }

    /// Group by store (where to buy); active items first within each group for scannable list.
    private var shoppingStoreGroups: [(key: String, items: [ShoppingItem])] {
        let keyed = Dictionary(grouping: filteredShoppingItems) { storeDisplayKey(for: $0) }
        return keyed.map { (key: $0.key, items: $0.value.sorted { !$0.isPurchased && $1.isPurchased }) }
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
    }

    /// Items filtered by All/Active/Bought and category only (no store filter), for building store dropdown.
    private var filteredShoppingItemsWithoutStoreFilter: [ShoppingItem] {
        var list = visibleShoppingItems
        switch shoppingFilter {
        case .all: break
        case .active: list = list.filter { !$0.isPurchased }
        case .bought: list = list.filter { $0.isPurchased }
        }
        if let catId = selectedCategoryFilterId {
            list = list.filter { $0.categoryId == catId }
        }
        return list
    }

    /// Unique store names for "All stores" dropdown (from filter + category, not store).
    private var storeFilterOptionKeys: [String] {
        Array(Set(filteredShoppingItemsWithoutStoreFilter.map { storeDisplayKey(for: $0) }))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func storeDisplayKey(for item: ShoppingItem) -> String {
        if let w = item.whereToBuy?.trimmingCharacters(in: .whitespaces), !w.isEmpty { return w }
        return localizationManager.t("list.whereToBuyUndecided")
    }

    /// Wishlist sorted by desire level descending for quick prioritization.
    private var sortedWishItems: [WishItem] {
        dataStore.wishItems.sorted { $0.desireLevel > $1.desireLevel }
    }

    /// Wishlist items filtered by rating (1–5 flames); nil = show all.
    private var filteredWishItems: [WishItem] {
        guard let level = wishlistRatingFilter else { return sortedWishItems }
        return sortedWishItems.filter { $0.desireLevel == level }
    }

    /// Sum of prices for filtered wishlist items (no currency conversion; for display only).
    private var wishlistTotalAmount: Double {
        filteredWishItems.compactMap(\.price).reduce(0, +)
    }

    /// Currency symbol for total display (user's last-used wishlist currency).
    private var wishlistTotalCurrencySymbol: String {
        let code = UserDefaults.standard.string(forKey: Self.lastWishlistCurrencyKey) ?? "USD"
        return CurrencyOption.symbol(for: code)
    }

    private func categoryDisplayName(categoryId: String?) -> String {
        guard let id = categoryId,
              let cat = dataStore.displayCategories.first(where: { $0.id == id }) else { return "—" }
        return localizationManager.getCategoryName(cat)
    }

    private func whereToBuyDisplay(item: ShoppingItem) -> String {
        if let w = item.whereToBuy?.trimmingCharacters(in: .whitespaces), !w.isEmpty { return w }
        return localizationManager.t("list.whereToBuyUndecided")
    }

    /// Sections are expanded by default; user can collapse. Binding: true = expanded.
    private func bindingExpanded(for storeKey: String) -> Binding<Bool> {
        Binding(
            get: { !collapsedStoreKeys.contains(storeKey) },
            set: { if $0 { collapsedStoreKeys.remove(storeKey) } else { collapsedStoreKeys.insert(storeKey) } }
        )
    }

    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()

            VStack(spacing: 0) {
                ListTabsHeader(
                    selectedTab: listMode == .shopping ? 0 : 1,
                    onTabChange: { listMode = $0 == 0 ? .shopping : .wish },
                    onAddTap: {
                        if listMode == .shopping {
                            shoppingItemToEdit = nil
                            showAddShoppingModal = true
                        } else {
                            wishlistItemToEdit = nil
                            showAddWishlistModal = true
                        }
                    }
                )
                .environmentObject(themeManager)
                .environmentObject(localizationManager)

                if listMode == .shopping {
                    shoppingFiltersAndStoreBar
                    shoppingListContent
                } else {
                    wishListContent
                }
            }
        }
        .navigationBarHidden(true)
        .refreshable { await dataStore.loadAll() }
        .sheet(isPresented: $showAddShoppingModal) {
            AddShoppingItemModal(editingItem: shoppingItemToEdit, onSaved: { shoppingItemToEdit = nil })
                .environmentObject(dataStore)
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
        }
        .sheet(isPresented: $showAddWishlistModal) {
            AddWishlistItemModal(editingItem: wishlistItemToEdit, onSaved: { wishlistItemToEdit = nil })
                .environmentObject(dataStore)
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
        }
        .sheet(isPresented: $showAddToInventorySheet) {
            if let item = shoppingItemForInventory {
                AddItemView(
                    prefilledName: item.name,
                    prefilledCategoryId: item.categoryId,
                    onSavedInventoryItemId: { newId in
                        Task {
                            try? await dataStore.markShoppingItemMovedToInventory(id: item.id, inventoryItemId: newId)
                        }
                    }
                )
                .environmentObject(dataStore)
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
            }
        }
        .onChange(of: showAddWishlistModal) { _, showing in if !showing { wishlistItemToEdit = nil } }
        .onChange(of: showAddShoppingModal) { _, showing in if !showing { shoppingItemToEdit = nil } }
        .onChange(of: showAddToInventorySheet) { _, showing in if !showing { shoppingItemForInventory = nil } }
    }

    // MARK: - Shopping filters + store dropdown

    /// Filter pills (All / Active / Bought) and store/category dropdowns in one card.
    private var shoppingFiltersAndStoreBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterPills(selected: $shoppingFilter)
                .environmentObject(themeManager)
                .environmentObject(localizationManager)

            HStack(spacing: 10) {
                Menu {
                    Button(localizationManager.t("list.allStores")) { selectedStoreKey = nil }
                    ForEach(storeFilterOptionKeys, id: \.self) { store in
                        Button(store) { selectedStoreKey = store }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "storefront")
                            .font(.caption)
                            .foregroundColor(Color(hex: theme.primaryColor))
                        Text(selectedStoreKey ?? localizationManager.t("list.allStores"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: theme.textColor))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color(hex: theme.textSecondary))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: theme.cardBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: theme.borderColor).opacity(0.6), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Menu {
                    Button(localizationManager.t("list.allCategories")) { selectedCategoryFilterId = nil }
                    ForEach(localizationManager.deduplicatedCategories(dataStore.visibleDisplayCategories)) { cat in
                        Button(localizationManager.getCategoryName(cat)) { selectedCategoryFilterId = cat.id }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tag")
                            .font(.caption)
                            .foregroundColor(Color(hex: theme.primaryColor))
                        Text(selectedCategoryFilterId == nil ? localizationManager.t("list.allCategories") : categoryDisplayName(categoryId: selectedCategoryFilterId))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: theme.textColor))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color(hex: theme.textSecondary))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: theme.cardBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: theme.borderColor).opacity(0.6), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(Color(hex: theme.backgroundColor))
    }

    @ViewBuilder
    private var shoppingListContent: some View {
        if filteredShoppingItems.isEmpty {
            emptyStateView(
                message: localizationManager.t("shoppingList.noItems") + "\n" + localizationManager.t("list.tapAddToAddItem"),
                buttonTitle: localizationManager.t("shoppingList.addItem"),
                onAddTap: { showAddShoppingModal = true }
            )
        } else {
            VStack(spacing: 0) {
                List {
                    ForEach(shoppingStoreGroups, id: \.key) { group in
                        StoreGroupSection(
                            storeName: group.key,
                            items: group.items,
                            isExpanded: bindingExpanded(for: group.key)
                        ) { item in
                            ShoppingRow(
                                item: item,
                                categoryDisplay: categoryDisplayName(categoryId: item.categoryId),
                                whereToBuyDisplay: whereToBuyDisplay(item: item),
                                onToggle: { Task { try? await dataStore.toggleShoppingItem(id: item.id) } },
                                onDelete: { Task { try? await dataStore.deleteShoppingItem(id: item.id) } },
                                onEdit: { shoppingItemToEdit = item; showAddShoppingModal = true },
                                onAddToInventory: { shoppingItemForInventory = item; showAddToInventorySheet = true }
                            )
                            .environmentObject(themeManager)
                            .environmentObject(localizationManager)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { try? await dataStore.deleteShoppingItem(id: item.id) }
                                } label: { Label(localizationManager.t("action.delete"), systemImage: "trash") }
                            }
                            .swipeActions(edge: .leading) {
                                if item.isPurchased && item.movedToInventory != true {
                                    Button {
                                        shoppingItemForInventory = item
                                        showAddToInventorySheet = true
                                    } label: { Label(localizationManager.t("list.addToInventory"), systemImage: "square.and.arrow.down") }
                                } else {
                                    Button {
                                        shoppingItemToEdit = item
                                        showAddShoppingModal = true
                                    } label: { Label(localizationManager.t("common.edit"), systemImage: "pencil") }
                                }
                            }
                        }
                        .environmentObject(themeManager)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                if purchasedShoppingItems.isEmpty == false {
                    Button(action: { showClearCompletedDialog = true }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text(localizationManager.t("list.clearCompleted"))
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: theme.primaryColor))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: theme.primaryColor).opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .confirmationDialog(localizationManager.t("list.clearCompletedDialogTitle"), isPresented: $showClearCompletedDialog, titleVisibility: .visible) {
                        Button(localizationManager.t("list.clearCompletedThrowAway"), role: .destructive) {
                            tryClearCompletedShoppingItems()
                        }
                        Button(localizationManager.t("common.cancel"), role: .cancel) {}
                    }
                    .alert(localizationManager.t("list.clearCompletedNotYetInInventoryTitle"), isPresented: $showClearCompletedWarningAlert) {
                        Button(localizationManager.t("common.cancel"), role: .cancel) {}
                        Button(localizationManager.t("list.removeAnyway"), role: .destructive) {
                            clearCompletedShoppingItems()
                        }
                    } message: {
                        Text(localizationManager.t("list.clearCompletedNotYetInInventoryMessage"))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var wishListContent: some View {
        if dataStore.wishItems.isEmpty {
            emptyStateView(
                message: localizationManager.t("wishList.noItems") + "\n" + localizationManager.t("list.tapAddToAddItem"),
                buttonTitle: localizationManager.t("wishList.addItem"),
                onAddTap: { showAddWishlistModal = true }
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                // ——— 1) Filter by desire level (collapsible) ———
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            wishlistFiltersCollapsed.toggle()
                            UserDefaults.standard.set(wishlistFiltersCollapsed, forKey: Self.wishlistFiltersCollapsedKey)
                        }
                    } label: {
                        HStack {
                            Text(localizationManager.t("wishList.filterByDesireLevel"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: theme.textColor))
                            Spacer()
                            Text(wishlistFiltersCollapsed ? localizationManager.t("wishList.filterShow") : localizationManager.t("wishList.filterHide"))
                                .font(.caption)
                                .foregroundColor(Color(hex: theme.primaryColor))
                            Image(systemName: wishlistFiltersCollapsed ? "chevron.down" : "chevron.up")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color(hex: theme.textSecondary))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    if !wishlistFiltersCollapsed {
                        LazyVGrid(columns: [
                            GridItem(.flexible(minimum: 56), spacing: 8),
                            GridItem(.flexible(minimum: 56), spacing: 8),
                            GridItem(.flexible(minimum: 56), spacing: 8)
                        ], spacing: 8) {
                            filterChip(title: localizationManager.t("wishList.filterAllRatings"), selected: wishlistRatingFilter == nil) {
                                wishlistRatingFilter = nil
                            }
                            .frame(maxWidth: .infinity)
                            ForEach([5, 4, 3, 2, 1], id: \.self) { level in
                                filterChip(title: "\(level) 🔥", selected: wishlistRatingFilter == level) {
                                    wishlistRatingFilter = level
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                }
                .background(Color(hex: theme.cardBackground))
                .cornerRadius(10)

                // ——— 2) Amount still needed (prominent card) ———
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "banknote")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: theme.primaryColor))
                        Text(localizationManager.t("wishList.amountNeeded"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: theme.textSecondary))
                    }
                    Text("\(wishlistTotalCurrencySymbol)\(wishlistTotalAmount, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: theme.textColor))
                    Text(localizationManager.t("wishList.amountNeededSubtitle"))
                        .font(.caption)
                        .foregroundColor(Color(hex: theme.textSecondary))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(hex: theme.cardBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: theme.primaryColor).opacity(0.4), lineWidth: 1.5)
                )
                .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            List {
                ForEach(filteredWishItems) { item in
                    WishlistRow(
                        item: item,
                        onEdit: { wishlistItemToEdit = item; showAddWishlistModal = true },
                        onDelete: { Task { try? await dataStore.deleteWishItem(id: item.id) } },
                        onRemove: { Task { try? await dataStore.deleteWishItem(id: item.id) } }
                    )
                    .environmentObject(themeManager)
                    .environmentObject(localizationManager)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { try? await dataStore.deleteWishItem(id: item.id) }
                        } label: { Label(localizationManager.t("action.delete"), systemImage: "trash") }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            wishlistItemToEdit = item
                            showAddWishlistModal = true
                        } label: { Label(localizationManager.t("common.edit"), systemImage: "pencil") }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private func filterChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(selected ? .semibold : .medium)
                .foregroundColor(selected ? .white : Color(hex: theme.textSecondary))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? Color(hex: theme.primaryColor) : Color(hex: theme.cardBackground))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func emptyStateView(message: String, buttonTitle: String, onAddTap: @escaping () -> Void) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color(hex: theme.textSecondary))
                .multilineTextAlignment(.center)
            Button(action: onAddTap) {
                Text(buttonTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hex: theme.primaryColor))
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
        }
        .padding()
    }

    private func tryClearCompletedShoppingItems() {
        let notYetInInventory = purchasedShoppingItems.contains { $0.movedToInventory != true }
        if notYetInInventory {
            showClearCompletedWarningAlert = true
        } else {
            clearCompletedShoppingItems()
        }
    }

    private func clearCompletedShoppingItems() {
        guard let groupId = dataStore.activeGroupId else { return }
        Task { try? await dataStore.clearPurchasedShoppingItems(groupId: groupId) }
    }
}
