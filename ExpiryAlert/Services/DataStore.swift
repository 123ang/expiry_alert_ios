import SwiftUI
import Combine

private let selectedCategoryIdsKey = "selectedCategoryIds"
private let selectedLocationIdsKey = "selectedLocationIds"
private let activeGroupIdKey = "active_group_id"
private let hasAppliedInitialCategorySelectionKey = "hasAppliedInitialCategorySelection"
private let hasAppliedInitialLocationSelectionKey = "hasAppliedInitialLocationSelection"

/// Translation keys for categories selected by default on first install (Dairy, Vegetables, Meat, Snacks).
private let defaultSelectedCategoryTranslationKeys: Set<String> = [
    "defaultCategory.dairy",
    "defaultCategory.vegetables",
    "defaultCategory.meatSeafood",
    "defaultCategory.snacks"
]

@MainActor
class DataStore: ObservableObject {
    // MARK: - Published State
    @Published var groups: [Group] = []
    @Published var activeGroupId: String?
    @Published var categories: [Category] = []
    @Published var locations: [Location] = []
    @Published var foodItems: [FoodItem] = []
    @Published var shoppingItems: [ShoppingItem] = []
    @Published var wishItems: [WishItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var authViewModel: AuthViewModel?
    
    // MARK: - Computed
    var activeGroup: Group? {
        groups.first { $0.id == activeGroupId }
    }
    
    /// Items with quantity > 0 (used/thrown items excluded from lists and counts).
    var activeFoodItems: [FoodItem] {
        foodItems.filter { $0.quantity > 0 }
    }
    
    var freshItems: [FoodItem] {
        activeFoodItems.filter { $0.status == .fresh }
    }
    
    var expiringItems: [FoodItem] {
        activeFoodItems.filter { $0.status == .expiringSoon }
    }
    
    var expiredItems: [FoodItem] {
        activeFoodItems.filter { $0.status == .expired }
    }
    
    var dashboardCounts: (total: Int, fresh: Int, expiring: Int, expired: Int) {
        (activeFoodItems.count, freshItems.count, expiringItems.count, expiredItems.count)
    }
    
    /// Category IDs the user has selected to show. Empty = show all.
    @Published var selectedCategoryIds: Set<String> = {
        let raw = UserDefaults.standard.string(forKey: selectedCategoryIdsKey) ?? ""
        return raw.isEmpty ? [] : Set(raw.split(separator: ",").map { String($0) })
    }() {
        didSet {
            let raw = selectedCategoryIds.sorted().joined(separator: ",")
            UserDefaults.standard.set(raw, forKey: selectedCategoryIdsKey)
        }
    }
    
    /// Categories to show in pickers/dashboard when user has made a selection. Empty selection = all.
    var visibleCategories: [Category] {
        if selectedCategoryIds.isEmpty { return categories }
        return categories.filter { selectedCategoryIds.contains($0.id) }
    }
    
    /// Hide debug/test categories from UI (e.g. "DebugTestCategory").
    private static func isDebugCategory(_ category: Category) -> Bool {
        let name = category.name.trimmingCharacters(in: .whitespaces).lowercased()
        return name == "debugtestcategory"
    }
    
    /// Hide "Other" category from UI (user requested removal).
    private static func isOtherCategory(_ category: Category) -> Bool {
        let name = category.name.trimmingCharacters(in: .whitespaces).lowercased()
        return name == "other"
    }
    
    /// User-added (customization) category: always show in pickers so new custom categories can be chosen when adding items.
    private static func isCustomizationCategory(_ category: Category) -> Bool {
        if let custom = category.isCustomization { return custom }
        return category.isDefault != true
    }
    
    /// Categories for display: excludes debug/test and "Other" entries.
    var displayCategories: [Category] {
        categories.filter { !Self.isDebugCategory($0) && !Self.isOtherCategory($0) }
    }
    
    /// Visible categories for pickers (Add Item, etc.). Respects Manage Categories: only selected IDs plus user-added (customization) categories. When user has deselected all, empty selection = show only customization categories (not all).
    var visibleDisplayCategories: [Category] {
        let display = displayCategories
        if selectedCategoryIds.isEmpty {
            return display.filter { Self.isCustomizationCategory($0) }
        }
        return display.filter { selectedCategoryIds.contains($0.id) || Self.isCustomizationCategory($0) }
    }
    
    /// Toggle whether a category is selected (shown in pickers). Empty = none selected; first tap selects.
    func toggleCategorySelection(id: String) {
        if selectedCategoryIds.isEmpty {
            selectedCategoryIds = [id]
        } else {
            if selectedCategoryIds.contains(id) {
                selectedCategoryIds = selectedCategoryIds.subtracting([id])
            } else {
                selectedCategoryIds = selectedCategoryIds.union([id])
            }
        }
    }
    
    /// Whether a category is selected (shown). When no selection stored, none are selected (so Deselect All works).
    func isCategorySelected(id: String) -> Bool {
        selectedCategoryIds.contains(id)
    }
    
    /// Select all display categories (for use in Manage Categories).
    func selectAllCategories() {
        selectedCategoryIds = Set(displayCategories.map(\.id))
    }
    
    /// Deselect all display categories except user-added (customization) ones.
    func deselectAllCategories() {
        selectedCategoryIds = Set(displayCategories.filter { Self.isCustomizationCategory($0) }.map(\.id))
    }
    
    /// On first install, set selected categories to Dairy, Vegetables, Meat, Snacks only. Idempotent after first run.
    func applyInitialCategorySelectionIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: hasAppliedInitialCategorySelectionKey) else { return }
        let display = categories.filter { !Self.isDebugCategory($0) }
        let defaultIds = Set(display.filter { cat in
            guard let key = cat.translationKey, !key.isEmpty else { return false }
            return defaultSelectedCategoryTranslationKeys.contains(key)
        }.map(\.id))
        if defaultIds.isEmpty {
            selectedCategoryIds = Set(display.map(\.id))
        } else {
            selectedCategoryIds = defaultIds
        }
        UserDefaults.standard.set(true, forKey: hasAppliedInitialCategorySelectionKey)
    }
    
    /// Location IDs the user has selected to show. Empty = show all.
    @Published var selectedLocationIds: Set<String> = {
        let raw = UserDefaults.standard.string(forKey: selectedLocationIdsKey) ?? ""
        return raw.isEmpty ? [] : Set(raw.split(separator: ",").map { String($0) })
    }() {
        didSet {
            let raw = selectedLocationIds.sorted().joined(separator: ",")
            UserDefaults.standard.set(raw, forKey: selectedLocationIdsKey)
        }
    }
    
    /// Locations to show in pickers. Empty selection = none (user deselected all); otherwise only selected.
    var visibleLocations: [Location] {
        if selectedLocationIds.isEmpty { return [] }
        return locations.filter { selectedLocationIds.contains($0.id) }
    }
    
    // MARK: - Display locations (hide 4 defaults, merge Fridge Top/Middle/Bottom into one)
    private static let hiddenDefaultLocationKeys: Set<String> = ["defaultLocation.counter"]
    private static let hiddenDefaultLocationNames: Set<String> = ["basement", "counter", "office", "other"]
    private static let fridgeVariantKeys: Set<String> = [
        "defaultLocation.fridge", "defaultLocation.fridgeTop", "defaultLocation.fridgeMiddle", "defaultLocation.fridgeBottom"
    ]
    
    static func isHiddenDefaultLocation(_ location: Location) -> Bool {
        if let key = location.translationKey, Self.hiddenDefaultLocationKeys.contains(key) { return true }
        let name = location.name.trimmingCharacters(in: .whitespaces).lowercased()
        return Self.hiddenDefaultLocationNames.contains(name)
    }
    
    static func isFridgeVariant(_ location: Location) -> Bool {
        if let key = location.translationKey, Self.fridgeVariantKeys.contains(key) { return true }
        let name = location.name.trimmingCharacters(in: .whitespaces).lowercased()
        return name == "fridge (top)" || name == "fridge (middle)" || name == "fridge (bottom)"
    }
    
    /// Filter out hidden defaults (Basement, Counter, Office); merge Fridge Top/Middle/Bottom into one row.
    static func filterAndMergeLocations(_ list: [Location]) -> [Location] {
        let filtered = list.filter { !Self.isHiddenDefaultLocation($0) }
        let fridgeVariants = filtered.filter { Self.isFridgeVariant($0) }
        let rest = filtered.filter { !Self.isFridgeVariant($0) }
        let mergedFridge: Location? = fridgeVariants.sorted { a, b in
            let aOrder = a.sortOrder ?? Int.max
            let bOrder = b.sortOrder ?? Int.max
            if aOrder != bOrder { return aOrder < bOrder }
            return a.id.compare(b.id) == .orderedAscending
        }.first
        var result = rest
        if let one = mergedFridge { result.append(one) }
        result.sort { a, b in
            let aDef = a.isDefault == true
            let bDef = b.isDefault == true
            if aDef != bDef { return aDef }
            let aOrder = a.sortOrder ?? Int.max
            let bOrder = b.sortOrder ?? Int.max
            if aOrder != bOrder { return aOrder < bOrder }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
        return result
    }
    
    /// Locations for UI: hidden defaults removed, Fridge Top/Middle/Bottom shown as one.
    var displayLocations: [Location] {
        Self.filterAndMergeLocations(locations)
    }
    
    /// Visible locations with same filter/merge for pickers.
    var visibleDisplayLocations: [Location] {
        Self.filterAndMergeLocations(visibleLocations)
    }
    
    /// IDs of locations that are Fridge (Top/Middle/Bottom) for merged row selection.
    var fridgeVariantIds: Set<String> {
        Set(locations.filter { Self.isFridgeVariant($0) }.map(\.id))
    }
    
    func toggleLocationSelection(id: String) {
        let fridgeIds = fridgeVariantIds
        let idsToToggle: Set<String> = fridgeIds.contains(id) ? fridgeIds : [id]
        let allIds = Set(locations.map(\.id))
        if selectedLocationIds.isEmpty {
            selectedLocationIds = idsToToggle
        } else {
            let anySelected = idsToToggle.contains(where: { selectedLocationIds.contains($0) })
            if anySelected {
                selectedLocationIds = selectedLocationIds.subtracting(idsToToggle)
            } else {
                selectedLocationIds = selectedLocationIds.union(idsToToggle)
            }
        }
    }
    
    func isLocationSelected(id: String) -> Bool {
        if selectedLocationIds.isEmpty { return false }
        let fridgeIds = fridgeVariantIds
        if fridgeIds.contains(id) {
            return fridgeIds.contains(where: { selectedLocationIds.contains($0) })
        }
        return selectedLocationIds.contains(id)
    }
    
    /// Select all display locations (for use in Manage Locations).
    func selectAllLocations() {
        selectedLocationIds = Set(locations.map(\.id))
    }
    
    /// Deselect all display locations except user-added (customization) ones.
    func deselectAllLocations() {
        let customIds = Set(displayLocations.filter { ($0.isCustomization ?? false) }.map(\.id))
        selectedLocationIds = customIds
    }
    
    /// On first load of locations, set selected to all so pickers show locations. Idempotent after first run.
    func applyInitialLocationSelectionIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: hasAppliedInitialLocationSelectionKey) else { return }
        selectedLocationIds = Set(locations.map(\.id))
        UserDefaults.standard.set(true, forKey: hasAppliedInitialLocationSelectionKey)
    }
    
    // MARK: - Configuration
    func configure(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        if authViewModel.isAuthenticated {
            Task { await loadAll() }
        }
    }
    
    // MARK: - Load All Data
    func loadAll() async {
        guard authViewModel?.isAuthenticated == true else { return }
        isLoading = true
        error = nil
        
        do {
            // Load groups first
            groups = try await APIService.shared.getGroups()
            
            // Restore last selected group from UserDefaults, or auto-select first if none saved or saved group no longer exists
            let savedGroupId = UserDefaults.standard.string(forKey: activeGroupIdKey)
            if let saved = savedGroupId, groups.contains(where: { $0.id == saved }) {
                activeGroupId = saved
            } else if activeGroupId == nil || (activeGroupId != nil && !groups.contains(where: { $0.id == activeGroupId! })) {
                if let first = groups.first {
                    activeGroupId = first.id
                    UserDefaults.standard.set(first.id, forKey: activeGroupIdKey)
                }
            }
            
            // Load group-specific data; merge default categories/locations (from DB, is_default=true) with group's custom ones.
            // Backend: GET /categories and GET /locations with no group_id should return default rows; with group_id return group's. If your API only supports group_id, have the backend return defaults + group's in one response and we can simplify to a single call.
            if let groupId = activeGroupId {
                async let defaultCats = APIService.shared.getCategories(groupId: nil)
                async let groupCats = APIService.shared.getCategories(groupId: groupId)
                async let defaultLocs = APIService.shared.getLocations(groupId: nil)
                async let groupLocs = APIService.shared.getLocations(groupId: groupId)
                async let items = APIService.shared.getFoodItems(groupId: groupId)
                async let shopping = APIService.shared.getShoppingItems(groupId: groupId, includePurchased: true)
                async let wishes = APIService.shared.getWishItems(groupId: groupId)
                
                let dCats = (try? await defaultCats) ?? []
                let gCats = (try? await groupCats) ?? []
                let dLocs = (try? await defaultLocs) ?? []
                let gLocs = (try? await groupLocs) ?? []
                categories = DataStore.mergeDefaultsWithGroup(defaults: dCats, groupItems: gCats)
                locations = DataStore.mergeDefaultsWithGroup(defaults: dLocs, groupItems: gLocs)
                applyInitialCategorySelectionIfNeeded()
                foodItems = try await items
                shoppingItems = try await shopping
                wishItems = try await wishes
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Refresh Methods
    func refreshFoodItems() async {
        guard let groupId = activeGroupId else { return }
        do {
            foodItems = try await APIService.shared.getFoodItems(groupId: groupId)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func refreshCategories() async {
        error = nil
        let sortCategories: ([Category]) -> [Category] = { list in
            list.sorted { a, b in
                let aOrder = a.sortOrder ?? Int.max
                let bOrder = b.sortOrder ?? Int.max
                if aOrder != bOrder { return aOrder < bOrder }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        }
        let dCats = (try? await APIService.shared.getCategories(groupId: nil)) ?? []
        if let groupId = activeGroupId {
            do {
                let gCats = try await APIService.shared.getCategories(groupId: groupId)
                categories = DataStore.mergeDefaultsWithGroup(defaults: dCats, groupItems: gCats)
            } catch {
                self.error = error.localizedDescription
                categories = sortCategories(dCats)
            }
        } else {
            categories = sortCategories(dCats)
        }
        applyInitialCategorySelectionIfNeeded()
    }
    
    func refreshLocations() async {
        guard let groupId = activeGroupId else { return }
        do {
            let dLocs = (try? await APIService.shared.getLocations(groupId: nil)) ?? []
            let gLocs = try await APIService.shared.getLocations(groupId: groupId)
            locations = DataStore.mergeDefaultsWithGroup(defaults: dLocs, groupItems: gLocs)
            applyInitialLocationSelectionIfNeeded()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Merges default categories with group's; no duplicate ids. Sorted: defaults first, then by sort_order, then by name.
    private static func mergeDefaultsWithGroup(defaults: [Category], groupItems: [Category]) -> [Category] {
        var seen = Set<String>()
        var result: [Category] = []
        for d in defaults {
            seen.insert(d.id)
            result.append(d)
        }
        for g in groupItems {
            if seen.contains(g.id) { continue }
            seen.insert(g.id)
            result.append(g)
        }
        result.sort { a, b in
            let aDef = a.isDefault == true
            let bDef = b.isDefault == true
            if aDef != bDef { return aDef }
            let aOrder = a.sortOrder ?? Int.max
            let bOrder = b.sortOrder ?? Int.max
            if aOrder != bOrder { return aOrder < bOrder }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
        return result
    }
    
    /// Merges default locations with group's; no duplicate ids. Sorted: defaults first, then by sort_order, then by name.
    private static func mergeDefaultsWithGroup(defaults: [Location], groupItems: [Location]) -> [Location] {
        var seen = Set<String>()
        var result: [Location] = []
        for d in defaults {
            seen.insert(d.id)
            result.append(d)
        }
        for g in groupItems {
            if seen.contains(g.id) { continue }
            seen.insert(g.id)
            result.append(g)
        }
        result.sort { a, b in
            let aDef = a.isDefault == true
            let bDef = b.isDefault == true
            if aDef != bDef { return aDef }
            let aOrder = a.sortOrder ?? Int.max
            let bOrder = b.sortOrder ?? Int.max
            if aOrder != bOrder { return aOrder < bOrder }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
        return result
    }
    
    func refreshShoppingItems() async {
        guard let groupId = activeGroupId else { return }
        do {
            shoppingItems = try await APIService.shared.getShoppingItems(groupId: groupId)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func refreshWishItems() async {
        guard let groupId = activeGroupId else { return }
        do {
            wishItems = try await APIService.shared.getWishItems(groupId: groupId)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Switch Group
    func switchGroup(to groupId: String) async {
        activeGroupId = groupId
        UserDefaults.standard.set(groupId, forKey: activeGroupIdKey)
        await loadAll()
    }
    
    // MARK: - Create Group
    func createGroup(name: String, description: String?) async throws -> Group {
        let group = try await APIService.shared.createGroup(name: name, description: description)
        groups.append(group)
        if activeGroupId == nil {
            activeGroupId = group.id
        }
        return group
    }
    
    // MARK: - Group CRUD
    func updateGroup(id: String, name: String?, description: String?) async throws -> Group {
        let group = try await APIService.shared.updateGroup(id: id, name: name, description: description)
        if let index = groups.firstIndex(where: { $0.id == id }) {
            groups[index] = group
        }
        return group
    }
    
    func deleteGroup(id: String) async throws {
        try await APIService.shared.deleteGroup(id: id)
        groups.removeAll { $0.id == id }
        if activeGroupId == id {
            activeGroupId = groups.first?.id
            if let newId = activeGroupId {
                UserDefaults.standard.set(newId, forKey: activeGroupIdKey)
                await loadAll()
            }
        }
    }
    
    func getGroupMembers(groupId: String) async throws -> [GroupMembership] {
        return try await APIService.shared.getGroupMembers(groupId: groupId)
    }
    
    func removeGroupMember(groupId: String, memberId: String) async throws {
        try await APIService.shared.removeGroupMember(groupId: groupId, memberId: memberId)
    }
    
    func updateGroupMemberRole(groupId: String, memberId: String, role: String) async throws {
        try await APIService.shared.updateGroupMemberRole(groupId: groupId, memberId: memberId, role: role)
    }
    
    // MARK: - Invitations
    func sendInvitation(groupId: String, email: String) async throws -> Invitation {
        return try await APIService.shared.sendInvitation(groupId: groupId, email: email)
    }
    
    func getPendingInvitations() async throws -> [Invitation] {
        return try await APIService.shared.getPendingInvitations()
    }
    
    func acceptInvitation(id: String) async throws {
        try await APIService.shared.acceptInvitation(id: id)
        // Reload groups since we joined a new one
        await loadAll()
    }
    
    func declineInvitation(id: String) async throws {
        try await APIService.shared.declineInvitation(id: id)
    }
    
    func joinGroupByCode(code: String) async throws {
        try await APIService.shared.joinGroupByCode(code: code)
        // Reload groups since we joined a new one
        await loadAll()
    }
    
    // MARK: - Food Item CRUD
    func createFoodItem(_ data: [String: Any]) async throws -> FoodItem {
        let item = try await APIService.shared.createFoodItem(item: data)
        foodItems.append(item)
        return item
    }
    
    func updateFoodItem(id: String, updates: [String: Any]) async throws {
        let updated = try await APIService.shared.updateFoodItem(id: id, updates: updates)
        if let index = foodItems.firstIndex(where: { $0.id == id }) {
            foodItems[index] = updated
        }
    }
    
    func deleteFoodItem(id: String) async throws {
        try await APIService.shared.deleteFoodItem(id: id)
        foodItems.removeAll { $0.id == id }
    }
    
    /// Merges a full item (e.g. from single-item fetch) into the list so the list shows updated fields like image_url.
    func mergeFoodItemInList(_ item: FoodItem) {
        if let index = foodItems.firstIndex(where: { $0.id == item.id }) {
            foodItems[index] = item
        }
    }
    
    func logFoodItemEvent(itemId: String, eventType: String, quantity: Int, reason: String? = nil) async throws {
        _ = try await APIService.shared.logFoodItemEvent(
            itemId: itemId,
            eventType: eventType,
            quantityAffected: quantity,
            disposalReason: reason
        )
        await refreshFoodItems()
    }
    
    // MARK: - Category CRUD
    func createCategory(name: String, icon: String?) async throws {
        let cat = try await APIService.shared.createCategory(name: name, icon: icon, groupId: activeGroupId)
        categories.append(cat)
    }
    
    func updateCategory(id: String, name: String?, icon: String?) async throws {
        let updated = try await APIService.shared.updateCategory(id: id, name: name, icon: icon)
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index] = updated
        }
    }
    
    func deleteCategory(id: String) async throws {
        let previous = categories
        var newSelected = selectedCategoryIds
        newSelected.remove(id)
        selectedCategoryIds = newSelected
        categories.removeAll { $0.id == id }
        do {
            try await APIService.shared.deleteCategory(id: id)
        } catch {
            categories = previous
            selectedCategoryIds = selectedCategoryIds.union([id])
            throw error
        }
    }
    
    // MARK: - Location CRUD
    func createLocation(name: String, icon: String?) async throws {
        let loc = try await APIService.shared.createLocation(name: name, icon: icon, groupId: activeGroupId)
        locations.append(loc)
    }
    
    func updateLocation(id: String, name: String?, icon: String?) async throws {
        let updated = try await APIService.shared.updateLocation(id: id, name: name, icon: icon)
        if let index = locations.firstIndex(where: { $0.id == id }) {
            locations[index] = updated
        }
    }
    
    func deleteLocation(id: String) async throws {
        let previous = locations
        var newSelected = selectedLocationIds
        newSelected.remove(id)
        selectedLocationIds = newSelected
        locations.removeAll { $0.id == id }
        do {
            try await APIService.shared.deleteLocation(id: id)
        } catch {
            locations = previous
            selectedLocationIds = selectedLocationIds.union([id])
            throw error
        }
    }
    
    // MARK: - Shopping Item CRUD
    func createShoppingItem(_ data: [String: Any]) async throws {
        var item = try await APIService.shared.createShoppingItem(item: data)
        // If the API doesn't return where_to_buy in the response, keep the value we sent so the list shows it
        if item.whereToBuy == nil, let sent = data["where_to_buy"] as? String, !sent.trimmingCharacters(in: .whitespaces).isEmpty {
            item.whereToBuy = sent.trimmingCharacters(in: .whitespaces)
        }
        shoppingItems.append(item)
    }
    
    func toggleShoppingItem(id: String) async throws {
        guard let index = shoppingItems.firstIndex(where: { $0.id == id }) else { return }
        let previous = shoppingItems[index]
        var optimistic = previous
        optimistic.isPurchased.toggle()
        shoppingItems[index] = optimistic
        do {
            let updated = try await APIService.shared.toggleShoppingItem(id: id)
            shoppingItems[index] = updated
        } catch {
            shoppingItems[index] = previous
            throw error
        }
    }
    
    func updateShoppingItem(id: String, updates: [String: Any]) async throws {
        let updated = try await APIService.shared.updateShoppingItem(id: id, updates: updates)
        if let index = shoppingItems.firstIndex(where: { $0.id == id }) {
            shoppingItems[index] = updated
        }
    }
    
    /// Mark shopping item as moved to inventory (after user adds it via Add Item flow).
    func markShoppingItemMovedToInventory(id: String, inventoryItemId: String) async throws {
        try await updateShoppingItem(id: id, updates: [
            "moved_to_inventory": true,
            "inventory_item_id": inventoryItemId
        ])
        // Ensure local state reflects moved state (API may not return new fields yet)
        if let index = shoppingItems.firstIndex(where: { $0.id == id }) {
            var updated = shoppingItems[index]
            updated.movedToInventory = true
            updated.inventoryItemId = inventoryItemId
            shoppingItems[index] = updated
        }
    }
    
    func deleteShoppingItem(id: String) async throws {
        try await APIService.shared.deleteShoppingItem(id: id)
        shoppingItems.removeAll { $0.id == id }
    }
    
    func clearPurchasedShoppingItems(groupId: String) async throws {
        _ = try await APIService.shared.clearPurchasedShoppingItems(groupId: groupId)
        shoppingItems.removeAll { $0.isPurchased }
    }
    
    // MARK: - Wish Item CRUD
    func createWishItem(_ data: [String: Any]) async throws {
        let item = try await APIService.shared.createWishItem(item: data)
        wishItems.append(item)
    }
    
    func updateWishItem(id: String, updates: [String: Any]) async throws {
        let updated = try await APIService.shared.updateWishItem(id: id, updates: updates)
        if let index = wishItems.firstIndex(where: { $0.id == id }) {
            wishItems[index] = updated
        }
    }
    
    func deleteWishItem(id: String) async throws {
        wishItems.removeAll { $0.id == id }
        do {
            try await APIService.shared.deleteWishItem(id: id)
        } catch {
            await refreshWishItems()
            throw error
        }
    }
}
