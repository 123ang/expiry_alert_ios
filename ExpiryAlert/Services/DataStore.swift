import SwiftUI
import Combine

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
    
    var freshItems: [FoodItem] {
        foodItems.filter { $0.status == .fresh }
    }
    
    var expiringItems: [FoodItem] {
        foodItems.filter { $0.status == .expiringSoon }
    }
    
    var expiredItems: [FoodItem] {
        foodItems.filter { $0.status == .expired }
    }
    
    var dashboardCounts: (total: Int, fresh: Int, expiring: Int, expired: Int) {
        (foodItems.count, freshItems.count, expiringItems.count, expiredItems.count)
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
            
            // Auto-select first group if none selected
            if activeGroupId == nil, let first = groups.first {
                activeGroupId = first.id
            }
            
            // Load group-specific data; merge default categories/locations (from DB, is_default=true) with group's custom ones.
            // Backend: GET /categories and GET /locations with no group_id should return default rows; with group_id return group's. If your API only supports group_id, have the backend return defaults + group's in one response and we can simplify to a single call.
            if let groupId = activeGroupId {
                async let defaultCats = APIService.shared.getCategories(groupId: nil)
                async let groupCats = APIService.shared.getCategories(groupId: groupId)
                async let defaultLocs = APIService.shared.getLocations(groupId: nil)
                async let groupLocs = APIService.shared.getLocations(groupId: groupId)
                async let items = APIService.shared.getFoodItems(groupId: groupId)
                async let shopping = APIService.shared.getShoppingItems(groupId: groupId)
                async let wishes = APIService.shared.getWishItems(groupId: groupId)
                
                let dCats = (try? await defaultCats) ?? []
                let gCats = (try? await groupCats) ?? []
                let dLocs = (try? await defaultLocs) ?? []
                let gLocs = (try? await groupLocs) ?? []
                categories = DataStore.mergeDefaultsWithGroup(defaults: dCats, groupItems: gCats)
                locations = DataStore.mergeDefaultsWithGroup(defaults: dLocs, groupItems: gLocs)
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
        guard let groupId = activeGroupId else { return }
        do {
            let dCats = (try? await APIService.shared.getCategories(groupId: nil)) ?? []
            let gCats = try await APIService.shared.getCategories(groupId: groupId)
            categories = DataStore.mergeDefaultsWithGroup(defaults: dCats, groupItems: gCats)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func refreshLocations() async {
        guard let groupId = activeGroupId else { return }
        do {
            let dLocs = (try? await APIService.shared.getLocations(groupId: nil)) ?? []
            let gLocs = try await APIService.shared.getLocations(groupId: groupId)
            locations = DataStore.mergeDefaultsWithGroup(defaults: dLocs, groupItems: gLocs)
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
        UserDefaults.standard.set(groupId, forKey: "active_group_id")
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
        try await APIService.shared.deleteCategory(id: id)
        categories.removeAll { $0.id == id }
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
        try await APIService.shared.deleteLocation(id: id)
        locations.removeAll { $0.id == id }
    }
    
    // MARK: - Shopping Item CRUD
    func createShoppingItem(_ data: [String: Any]) async throws {
        let item = try await APIService.shared.createShoppingItem(item: data)
        shoppingItems.append(item)
    }
    
    func toggleShoppingItem(id: String) async throws {
        let updated = try await APIService.shared.toggleShoppingItem(id: id)
        if let index = shoppingItems.firstIndex(where: { $0.id == id }) {
            shoppingItems[index] = updated
        }
    }
    
    func deleteShoppingItem(id: String) async throws {
        try await APIService.shared.deleteShoppingItem(id: id)
        shoppingItems.removeAll { $0.id == id }
    }
    
    // MARK: - Wish Item CRUD
    func createWishItem(_ data: [String: Any]) async throws {
        let item = try await APIService.shared.createWishItem(item: data)
        wishItems.append(item)
    }
    
    func deleteWishItem(id: String) async throws {
        try await APIService.shared.deleteWishItem(id: id)
        wishItems.removeAll { $0.id == id }
    }
}
