import SwiftUI
import Combine

private let selectedCategoryIdsKey = "selectedCategoryIds"
private let selectedLocationIdsKey = "selectedLocationIds"
private let activeGroupIdKey = "active_group_id"
private let hasAppliedInitialCategorySelectionKey = "hasAppliedInitialCategorySelection"
private let hasAppliedInitialLocationSelectionKey = "hasAppliedInitialLocationSelection"
private let localGroupId = "local"

struct LocalDataExport: Codable {
    let schemaVersion: Int
    let exportedAt: String
    var groups: [Group]
    var categories: [Category]
    var locations: [Location]
    var foodItems: [FoodItem]
    var shoppingItems: [ShoppingItem]
    var wishItems: [WishItem]
}

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
    private weak var notificationService: NotificationService?
    var isLocalMode: Bool { authViewModel?.isLocalMode == true }
    private var localStorageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("expiry-alert-ios-local-data.json")
    }
    
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
    
    /// On first install, select all categories so Add Item and pickers show them. User can manage later in Settings. Idempotent after first run.
    func applyInitialCategorySelectionIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: hasAppliedInitialCategorySelectionKey) else { return }
        selectedCategoryIds = Set(displayCategories.map(\.id))
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
    func configure(authViewModel: AuthViewModel, notificationService: NotificationService? = nil) {
        self.authViewModel = authViewModel
        self.notificationService = notificationService
        if authViewModel.isAuthenticated || authViewModel.isLocalMode {
            Task { await loadAll() }
        }
    }

    private func refreshExpiryNotifications() {
        notificationService?.scheduleExpiryNotifications(for: activeFoodItems)
    }

    private static func nowISO() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private func defaultLocalGroup() -> Group {
        Group(
            id: localGroupId,
            name: "Personal",
            description: "Private Local Mode",
            createdBy: nil,
            inviteCode: nil,
            maxMembers: 1,
            createdAt: Self.nowISO(),
            updatedAt: Self.nowISO()
        )
    }

    private func localGroups(from importedGroups: [Group]) -> [Group] {
        var nextGroups = importedGroups.isEmpty ? [defaultLocalGroup()] : importedGroups
        if !nextGroups.contains(where: { $0.id == localGroupId }) {
            nextGroups.insert(defaultLocalGroup(), at: 0)
        }
        return nextGroups
    }

    private func defaultLocalCategories() -> [Category] {
        [
            ("local-category-vegetables", "Vegetables", "🥬", "category.vegetables", 1),
            ("local-category-fruits", "Fruits", "🍎", "category.fruits", 2),
            ("local-category-dairy", "Dairy", "🥛", "category.dairy", 3),
            ("local-category-meat", "Meat", "🥩", "category.meat", 4),
            ("local-category-bread", "Bread", "🍞", "category.bread", 5),
            ("local-category-snacks", "Snacks", "🍪", "category.snacks", 6),
            ("local-category-beverages", "Beverages", "🥤", "category.beverages", 7),
            ("local-category-canned", "Canned Food", "🥫", "category.canned", 8),
        ].map { id, name, icon, key, order in
            Category(
                id: id,
                groupId: nil,
                name: name,
                icon: icon,
                color: nil,
                translationKey: key,
                isDefault: true,
                section: nil,
                sortOrder: order,
                isCustomization: false,
                createdAt: Self.nowISO(),
                updatedAt: Self.nowISO()
            )
        }
    }

    private func defaultLocalLocations() -> [Location] {
        [
            ("local-location-fridge", "Fridge", "❄️", "defaultLocation.fridge", 1),
            ("local-location-freezer", "Freezer", "🧊", "defaultLocation.freezer", 2),
            ("local-location-pantry", "Pantry", "🏠", "defaultLocation.pantry", 3),
            ("local-location-cabinet", "Cabinet", "🗄️", "defaultLocation.cabinet", 4),
        ].map { id, name, icon, key, order in
            Location(
                id: id,
                groupId: nil,
                name: name,
                icon: icon,
                translationKey: key,
                isDefault: true,
                section: nil,
                sortOrder: order,
                isCustomization: false,
                createdAt: Self.nowISO(),
                updatedAt: Self.nowISO()
            )
        }
    }

    func loadLocalData() async {
        if let data = try? Data(contentsOf: localStorageURL),
           let localExport = try? JSONDecoder().decode(LocalDataExport.self, from: data) {
            groups = localGroups(from: localExport.groups)
            categories = localExport.categories.isEmpty ? defaultLocalCategories() : localExport.categories
            locations = localExport.locations.isEmpty ? defaultLocalLocations() : localExport.locations
            foodItems = localExport.foodItems
            shoppingItems = localExport.shoppingItems
            wishItems = localExport.wishItems
        } else {
            groups = [defaultLocalGroup()]
            categories = defaultLocalCategories()
            locations = defaultLocalLocations()
            foodItems = []
            shoppingItems = []
            wishItems = []
            try? saveLocalData()
        }

        activeGroupId = localGroupId
        UserDefaults.standard.set(localGroupId, forKey: activeGroupIdKey)
        applyInitialCategorySelectionIfNeeded()
        applyInitialLocationSelectionIfNeeded()
    }

    @discardableResult
    func saveLocalData() throws -> URL {
        let localExport = LocalDataExport(
            schemaVersion: 1,
            exportedAt: Self.nowISO(),
            groups: groups,
            categories: categories,
            locations: locations,
            foodItems: foodItems,
            shoppingItems: shoppingItems,
            wishItems: wishItems
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(localExport)
        try data.write(to: localStorageURL, options: [.atomic])
        refreshExpiryNotifications()
        return localStorageURL
    }

    func exportLocalData() throws -> URL {
        try saveLocalData()
    }

    func importLocalData(from json: String) throws {
        guard let data = json.data(using: .utf8) else {
            throw NSError(domain: "ExpiryAlertLocalImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON text."])
        }

        let localExport = try JSONDecoder().decode(LocalDataExport.self, from: data)
        groups = localGroups(from: localExport.groups)
        categories = localExport.categories.isEmpty ? defaultLocalCategories() : localExport.categories
        locations = localExport.locations.isEmpty ? defaultLocalLocations() : localExport.locations
        foodItems = localExport.foodItems
        shoppingItems = localExport.shoppingItems
        wishItems = localExport.wishItems
        activeGroupId = localGroupId
        UserDefaults.standard.set(localGroupId, forKey: activeGroupIdKey)
        try saveLocalData()
        refreshExpiryNotifications()
    }
    
    // MARK: - Load All Data
    func loadAll() async {
        guard authViewModel?.isLocalMode != true else {
            isLoading = true
            await loadLocalData()
            isLoading = false
            return
        }

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
                applyInitialLocationSelectionIfNeeded()
                foodItems = try await items
                shoppingItems = try await shopping
                wishItems = try await wishes
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        refreshExpiryNotifications()
        isLoading = false
    }
    
    // MARK: - Refresh Methods
    func refreshFoodItems() async {
        if authViewModel?.isLocalMode == true {
            await loadLocalData()
            return
        }

        guard let groupId = activeGroupId else { return }
        do {
            foodItems = try await APIService.shared.getFoodItems(groupId: groupId)
            refreshExpiryNotifications()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func refreshCategories() async {
        if authViewModel?.isLocalMode == true {
            await loadLocalData()
            return
        }

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
        if authViewModel?.isLocalMode == true {
            await loadLocalData()
            return
        }

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
        if authViewModel?.isLocalMode == true {
            await loadLocalData()
            return
        }

        guard let groupId = activeGroupId else { return }
        do {
            shoppingItems = try await APIService.shared.getShoppingItems(groupId: groupId)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func refreshWishItems() async {
        if authViewModel?.isLocalMode == true {
            await loadLocalData()
            return
        }

        guard let groupId = activeGroupId else { return }
        do {
            wishItems = try await APIService.shared.getWishItems(groupId: groupId)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Switch Group
    func switchGroup(to groupId: String) async {
        if authViewModel?.isLocalMode == true {
            activeGroupId = localGroupId
            UserDefaults.standard.set(localGroupId, forKey: activeGroupIdKey)
            return
        }

        activeGroupId = groupId
        UserDefaults.standard.set(groupId, forKey: activeGroupIdKey)
        await loadAll()
    }
    
    // MARK: - Create Group
    func createGroup(name: String, description: String?) async throws -> Group {
        if authViewModel?.isLocalMode == true {
            throw NSError(domain: "ExpiryAlertLocalMode", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cloud sharing needs Cloud Mode."])
        }

        let group = try await APIService.shared.createGroup(name: name, description: description)
        groups.append(group)
        if activeGroupId == nil {
            activeGroupId = group.id
        }
        return group
    }
    
    // MARK: - Group CRUD
    func updateGroup(id: String, name: String?, description: String?) async throws -> Group {
        if authViewModel?.isLocalMode == true {
            throw NSError(domain: "ExpiryAlertLocalMode", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cloud sharing needs Cloud Mode."])
        }

        let group = try await APIService.shared.updateGroup(id: id, name: name, description: description)
        if let index = groups.firstIndex(where: { $0.id == id }) {
            groups[index] = group
        }
        return group
    }
    
    func deleteGroup(id: String) async throws {
        if authViewModel?.isLocalMode == true {
            throw NSError(domain: "ExpiryAlertLocalMode", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cloud sharing needs Cloud Mode."])
        }

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
        if authViewModel?.isLocalMode == true {
            return []
        }

        return try await APIService.shared.getGroupMembers(groupId: groupId)
    }
    
    func removeGroupMember(groupId: String, memberId: String) async throws {
        if authViewModel?.isLocalMode == true { return }
        try await APIService.shared.removeGroupMember(groupId: groupId, memberId: memberId)
    }
    
    func updateGroupMemberRole(groupId: String, memberId: String, role: String) async throws {
        if authViewModel?.isLocalMode == true { return }
        try await APIService.shared.updateGroupMemberRole(groupId: groupId, memberId: memberId, role: role)
    }
    
    // MARK: - Invitations
    func sendInvitation(groupId: String, email: String) async throws -> Invitation {
        if authViewModel?.isLocalMode == true {
            throw NSError(domain: "ExpiryAlertLocalMode", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cloud sharing needs Cloud Mode."])
        }

        return try await APIService.shared.sendInvitation(groupId: groupId, email: email)
    }
    
    func getPendingInvitations() async throws -> [Invitation] {
        if authViewModel?.isLocalMode == true {
            return []
        }

        return try await APIService.shared.getPendingInvitations()
    }
    
    func acceptInvitation(id: String) async throws {
        if authViewModel?.isLocalMode == true { return }
        try await APIService.shared.acceptInvitation(id: id)
        // Reload groups since we joined a new one
        await loadAll()
    }
    
    func declineInvitation(id: String) async throws {
        if authViewModel?.isLocalMode == true { return }
        try await APIService.shared.declineInvitation(id: id)
    }
    
    func joinGroupByCode(code: String) async throws {
        if authViewModel?.isLocalMode == true {
            throw NSError(domain: "ExpiryAlertLocalMode", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cloud sharing needs Cloud Mode."])
        }

        try await APIService.shared.joinGroupByCode(code: code)
        // Reload groups since we joined a new one
        await loadAll()
    }
    
    // MARK: - Food Item CRUD
    func createFoodItem(_ data: [String: Any]) async throws -> FoodItem {
        if authViewModel?.isLocalMode == true {
            let now = Self.nowISO()
            let categoryId = data["category_id"] as? String
            let locationId = data["location_id"] as? String
            let category = categories.first { $0.id == categoryId }
            let location = locations.first { $0.id == locationId }
            let item = FoodItem(
                id: UUID().uuidString,
                groupId: localGroupId,
                createdBy: nil,
                name: data["name"] as? String ?? "",
                brand: data["brand"] as? String,
                quantity: data["quantity"] as? Int ?? 1,
                unit: data["unit"] as? String,
                categoryId: categoryId,
                locationId: locationId,
                purchaseDate: data["purchase_date"] as? String,
                expiryDate: data["expiry_date"] as? String,
                notes: data["notes"] as? String,
                imageUrl: data["image_url"] as? String,
                barcode: data["barcode"] as? String,
                purchasePrice: data["purchase_price"] as? Double,
                estimatedValue: data["estimated_value"] as? Double,
                originalQuantity: data["original_quantity"] as? Int,
                remainingQuantity: data["remaining_quantity"] as? Int,
                isConsumed: false,
                consumedAt: nil,
                consumedBy: nil,
                createdAt: now,
                updatedAt: now,
                version: 1,
                syncStatus: "local",
                categoryName: category?.name,
                categoryIcon: category?.icon,
                categoryTranslationKey: category?.translationKey,
                locationName: location?.name,
                locationIcon: location?.icon,
                locationTranslationKey: location?.translationKey
            )
            foodItems.append(item)
            try saveLocalData()
            return item
        }

        let item = try await APIService.shared.createFoodItem(item: data)
        foodItems.append(item)
        refreshExpiryNotifications()
        return item
    }
    
    func updateFoodItem(id: String, updates: [String: Any]) async throws {
        if authViewModel?.isLocalMode == true {
            guard let index = foodItems.firstIndex(where: { $0.id == id }) else { return }
            if let name = updates["name"] as? String { foodItems[index].name = name }
            if let quantity = updates["quantity"] as? Int { foodItems[index].quantity = quantity }
            if let categoryId = updates["category_id"] as? String { foodItems[index].categoryId = categoryId }
            if let locationId = updates["location_id"] as? String { foodItems[index].locationId = locationId }
            if let expiryDate = updates["expiry_date"] as? String { foodItems[index].expiryDate = expiryDate }
            if let notes = updates["notes"] as? String { foodItems[index].notes = notes }
            if let category = categories.first(where: { $0.id == foodItems[index].categoryId }) {
                foodItems[index].categoryName = category.name
                foodItems[index].categoryIcon = category.icon
                foodItems[index].categoryTranslationKey = category.translationKey
            }
            if let location = locations.first(where: { $0.id == foodItems[index].locationId }) {
                foodItems[index].locationName = location.name
                foodItems[index].locationIcon = location.icon
                foodItems[index].locationTranslationKey = location.translationKey
            }
            try saveLocalData()
            return
        }

        let updated = try await APIService.shared.updateFoodItem(id: id, updates: updates)
        if let index = foodItems.firstIndex(where: { $0.id == id }) {
            foodItems[index] = updated
        }
        refreshExpiryNotifications()
    }
    
    func deleteFoodItem(id: String) async throws {
        if authViewModel?.isLocalMode == true {
            foodItems.removeAll { $0.id == id }
            try saveLocalData()
            return
        }

        try await APIService.shared.deleteFoodItem(id: id)
        foodItems.removeAll { $0.id == id }
        refreshExpiryNotifications()
    }
    
    /// Merges a full item (e.g. from single-item fetch) into the list so the list shows updated fields like image_url.
    func mergeFoodItemInList(_ item: FoodItem) {
        if let index = foodItems.firstIndex(where: { $0.id == item.id }) {
            foodItems[index] = item
            refreshExpiryNotifications()
        }
    }
    
    func logFoodItemEvent(itemId: String, eventType: String, quantity: Int, reason: String? = nil) async throws {
        if authViewModel?.isLocalMode == true {
            if let index = foodItems.firstIndex(where: { $0.id == itemId }) {
                foodItems[index].quantity = max(0, foodItems[index].quantity - quantity)
                try saveLocalData()
            }
            return
        }

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
        if authViewModel?.isLocalMode == true {
            let now = Self.nowISO()
            let cat = Category(id: UUID().uuidString, groupId: localGroupId, name: name, icon: icon, color: nil, translationKey: nil, isDefault: false, section: nil, sortOrder: nil, isCustomization: true, createdAt: now, updatedAt: now)
            categories.append(cat)
            selectedCategoryIds = selectedCategoryIds.union([cat.id])
            try saveLocalData()
            return
        }

        let cat = try await APIService.shared.createCategory(name: name, icon: icon, groupId: activeGroupId)
        categories.append(cat)
        selectedCategoryIds = selectedCategoryIds.union([cat.id])
    }
    
    func updateCategory(id: String, name: String?, icon: String?) async throws {
        if authViewModel?.isLocalMode == true {
            if let index = categories.firstIndex(where: { $0.id == id }) {
                if let name { categories[index].name = name }
                if let icon { categories[index].icon = icon }
                try saveLocalData()
            }
            return
        }

        let updated = try await APIService.shared.updateCategory(id: id, name: name, icon: icon)
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index] = updated
        }
    }
    
    func deleteCategory(id: String) async throws {
        if authViewModel?.isLocalMode == true {
            selectedCategoryIds.remove(id)
            categories.removeAll { $0.id == id }
            try saveLocalData()
            return
        }

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
        if authViewModel?.isLocalMode == true {
            let now = Self.nowISO()
            let loc = Location(id: UUID().uuidString, groupId: localGroupId, name: name, icon: icon, translationKey: nil, isDefault: false, section: nil, sortOrder: nil, isCustomization: true, createdAt: now, updatedAt: now)
            locations.append(loc)
            selectedLocationIds = selectedLocationIds.union([loc.id])
            try saveLocalData()
            return
        }

        let loc = try await APIService.shared.createLocation(name: name, icon: icon, groupId: activeGroupId)
        locations.append(loc)
        selectedLocationIds = selectedLocationIds.union([loc.id])
    }
    
    func updateLocation(id: String, name: String?, icon: String?) async throws {
        if authViewModel?.isLocalMode == true {
            if let index = locations.firstIndex(where: { $0.id == id }) {
                if let name { locations[index].name = name }
                if let icon { locations[index].icon = icon }
                try saveLocalData()
            }
            return
        }

        let updated = try await APIService.shared.updateLocation(id: id, name: name, icon: icon)
        if let index = locations.firstIndex(where: { $0.id == id }) {
            locations[index] = updated
        }
    }
    
    func deleteLocation(id: String) async throws {
        if authViewModel?.isLocalMode == true {
            selectedLocationIds.remove(id)
            locations.removeAll { $0.id == id }
            try saveLocalData()
            return
        }

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
        if authViewModel?.isLocalMode == true {
            let now = Self.nowISO()
            let item = ShoppingItem(
                id: UUID().uuidString,
                groupId: localGroupId,
                createdBy: nil,
                name: data["name"] as? String ?? "",
                quantity: data["quantity"] as? Int ?? 1,
                unit: data["unit"] as? String,
                categoryId: data["category_id"] as? String,
                whereToBuy: data["where_to_buy"] as? String,
                isPurchased: false,
                purchasedAt: nil,
                purchasedBy: nil,
                movedToInventory: false,
                inventoryItemId: nil,
                notes: data["notes"] as? String,
                createdAt: now,
                updatedAt: now
            )
            shoppingItems.append(item)
            try saveLocalData()
            return
        }

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
        if authViewModel?.isLocalMode == true {
            try saveLocalData()
            return
        }
        do {
            let updated = try await APIService.shared.toggleShoppingItem(id: id)
            shoppingItems[index] = updated
        } catch {
            shoppingItems[index] = previous
            throw error
        }
    }
    
    func updateShoppingItem(id: String, updates: [String: Any]) async throws {
        if authViewModel?.isLocalMode == true {
            guard let index = shoppingItems.firstIndex(where: { $0.id == id }) else { return }
            if let name = updates["name"] as? String { shoppingItems[index].name = name }
            if let quantity = updates["quantity"] as? Int { shoppingItems[index].quantity = quantity }
            if let unit = updates["unit"] as? String { shoppingItems[index].unit = unit }
            if let categoryId = updates["category_id"] as? String { shoppingItems[index].categoryId = categoryId }
            if let whereToBuy = updates["where_to_buy"] as? String { shoppingItems[index].whereToBuy = whereToBuy }
            if let moved = updates["moved_to_inventory"] as? Bool { shoppingItems[index].movedToInventory = moved }
            if let inventoryItemId = updates["inventory_item_id"] as? String { shoppingItems[index].inventoryItemId = inventoryItemId }
            try saveLocalData()
            return
        }

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
        if authViewModel?.isLocalMode == true {
            shoppingItems.removeAll { $0.id == id }
            try saveLocalData()
            return
        }

        try await APIService.shared.deleteShoppingItem(id: id)
        shoppingItems.removeAll { $0.id == id }
    }
    
    func clearPurchasedShoppingItems(groupId: String) async throws {
        if authViewModel?.isLocalMode == true {
            shoppingItems.removeAll { $0.isPurchased }
            try saveLocalData()
            return
        }

        _ = try await APIService.shared.clearPurchasedShoppingItems(groupId: groupId)
        shoppingItems.removeAll { $0.isPurchased }
    }
    
    // MARK: - Wish Item CRUD
    func createWishItem(_ data: [String: Any]) async throws {
        if authViewModel?.isLocalMode == true {
            let now = Self.nowISO()
            let item = WishItem(
                id: UUID().uuidString,
                groupId: localGroupId,
                createdBy: nil,
                name: data["name"] as? String ?? "",
                notes: data["notes"] as? String,
                price: data["price"] as? Double,
                currencyCode: data["currency_code"] as? String,
                rating: data["rating"] as? Int,
                imageUrl: data["image_url"] as? String,
                createdAt: now,
                updatedAt: now
            )
            wishItems.append(item)
            try saveLocalData()
            return
        }

        let item = try await APIService.shared.createWishItem(item: data)
        wishItems.append(item)
    }
    
    func updateWishItem(id: String, updates: [String: Any]) async throws {
        if authViewModel?.isLocalMode == true {
            guard let index = wishItems.firstIndex(where: { $0.id == id }) else { return }
            if let name = updates["name"] as? String { wishItems[index].name = name }
            if let notes = updates["notes"] as? String { wishItems[index].notes = notes }
            if let price = updates["price"] as? Double { wishItems[index].price = price }
            if let currencyCode = updates["currency_code"] as? String { wishItems[index].currencyCode = currencyCode }
            if let rating = updates["rating"] as? Int { wishItems[index].rating = rating }
            try saveLocalData()
            return
        }

        let updated = try await APIService.shared.updateWishItem(id: id, updates: updates)
        if let index = wishItems.firstIndex(where: { $0.id == id }) {
            wishItems[index] = updated
        }
    }
    
    func deleteWishItem(id: String) async throws {
        if authViewModel?.isLocalMode == true {
            wishItems.removeAll { $0.id == id }
            try saveLocalData()
            return
        }

        wishItems.removeAll { $0.id == id }
        do {
            try await APIService.shared.deleteWishItem(id: id)
        } catch {
            await refreshWishItems()
            throw error
        }
    }
}
