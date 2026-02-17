import Foundation
import UIKit

// MARK: - User
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    var fullName: String?
    var avatarUrl: String?
    var languagePreference: String
    var timezone: String
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, timezone
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case languagePreference = "language_preference"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Auth
struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
}

struct DeviceInfo: Codable {
    let deviceUuid: String
    let deviceName: String?
    let deviceType: String?
    let platform: String
    
    enum CodingKeys: String, CodingKey {
        case deviceUuid = "device_uuid"
        case deviceName = "device_name"
        case deviceType = "device_type"
        case platform
    }
    
    static var current: DeviceInfo {
        DeviceInfo(
            deviceUuid: UIDeviceIdentifier.current,
            deviceName: UIDeviceIdentifier.deviceName,
            deviceType: "phone",
            platform: "ios"
        )
    }
}

struct AuthResponse: Codable {
    let message: String
    let user: User
    let tokens: AuthTokens
    let device: DeviceData?
    
    struct DeviceData: Codable {
        let id: String
        let deviceUuid: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case deviceUuid = "device_uuid"
        }
    }
}

struct RefreshResponse: Codable {
    let message: String
    let tokens: AuthTokens
}

// MARK: - Group
struct Group: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var description: String?
    let createdBy: String?
    var inviteCode: String?
    var maxMembers: Int?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case createdBy = "created_by"
        case inviteCode = "invite_code"
        case maxMembers = "max_members"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Group, rhs: Group) -> Bool {
        lhs.id == rhs.id
    }
}

struct GroupMembership: Codable, Identifiable {
    let id: String
    let groupId: String?
    let userId: String
    let role: String
    let joinedAt: String?
    var email: String?
    var fullName: String?
    var avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, role, email
        case groupId = "group_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Group with role/member count (from GET /groups response)
struct GroupWithRole: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var description: String?
    let createdBy: String?
    var inviteCode: String?
    var maxMembers: Int?
    var role: String?
    var memberCount: Int?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, role
        case createdBy = "created_by"
        case inviteCode = "invite_code"
        case maxMembers = "max_members"
        case memberCount = "member_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: GroupWithRole, rhs: GroupWithRole) -> Bool { lhs.id == rhs.id }
}

// MARK: - Category
struct Category: Codable, Identifiable, Hashable {
    let id: String
    var groupId: String?
    var name: String
    var icon: String?
    var color: String?
    var translationKey: String?
    var isDefault: Bool?
    /// Display group (e.g. "Food & Drinks", "Health") for default categories
    var section: String?
    var sortOrder: Int?
    /// True when the category was added by the user (Add Category); only these show edit/remove.
    var isCustomization: Bool?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, color
        case groupId = "group_id"
        case translationKey = "translation_key"
        case isDefault = "is_default"
        case section
        case sortOrder = "sort_order"
        case isCustomization = "is_customization"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Category, rhs: Category) -> Bool { lhs.id == rhs.id }
}

// MARK: - Location
struct Location: Codable, Identifiable, Hashable {
    let id: String
    var groupId: String?
    var name: String
    var icon: String?
    var translationKey: String?
    var isDefault: Bool?
    /// Display group (e.g. "Kitchen", "Home Storage") for default locations
    var section: String?
    var sortOrder: Int?
    /// True when the location was added by the user (Add Location); only these show edit/remove.
    var isCustomization: Bool?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon
        case groupId = "group_id"
        case translationKey = "translation_key"
        case isDefault = "is_default"
        case section
        case sortOrder = "sort_order"
        case isCustomization = "is_customization"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Location, rhs: Location) -> Bool { lhs.id == rhs.id }
}

// MARK: - Food Item
struct FoodItem: Codable, Identifiable {
    let id: String
    var groupId: String
    var createdBy: String?
    var name: String
    var brand: String?
    var quantity: Int
    var unit: String?
    var categoryId: String?
    var locationId: String?
    var purchaseDate: String?
    var expiryDate: String?
    var notes: String?
    var imageUrl: String?
    var barcode: String?
    var purchasePrice: Double?
    var estimatedValue: Double?
    var originalQuantity: Int?
    var remainingQuantity: Int?
    var isConsumed: Bool?
    var consumedAt: String?
    var consumedBy: String?
    let createdAt: String?
    let updatedAt: String?
    var version: Int?
    var syncStatus: String?
    
    // Joined fields (from API response)
    var categoryName: String?
    var categoryIcon: String?
    var categoryTranslationKey: String?
    var locationName: String?
    var locationIcon: String?
    var locationTranslationKey: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, brand, quantity, unit, notes, barcode, version
        case groupId = "group_id"
        case createdBy = "created_by"
        case categoryId = "category_id"
        case locationId = "location_id"
        case purchaseDate = "purchase_date"
        case expiryDate = "expiry_date"
        case imageUrl = "image_url"
        case purchasePrice = "purchase_price"
        case estimatedValue = "estimated_value"
        case originalQuantity = "original_quantity"
        case remainingQuantity = "remaining_quantity"
        case isConsumed = "is_consumed"
        case consumedAt = "consumed_at"
        case consumedBy = "consumed_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case syncStatus = "sync_status"
        case categoryName = "category_name"
        case categoryIcon = "category_icon"
        case categoryTranslationKey = "category_translation_key"
        case locationName = "location_name"
        case locationIcon = "location_icon"
        case locationTranslationKey = "location_translation_key"
    }
    
    /// Expiry date as calendar day in the user's timezone (yyyy-MM-dd). Handles API returning ISO8601 so we don't show the previous day.
    private var expiryDateAsLocalDay: String? {
        guard let raw = expiryDate, !raw.isEmpty else { return nil }
        let calendar = Calendar.current
        let date: Date?
        if raw.contains("T") {
            let isoWithFrac = ISO8601DateFormatter()
            isoWithFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let isoPlain = ISO8601DateFormatter()
            isoPlain.formatOptions = [.withInternetDateTime]
            date = isoWithFrac.date(from: raw) ?? isoPlain.date(from: raw)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = calendar.timeZone
            date = formatter.date(from: String(raw.prefix(10)))
        }
        guard let d = date else { return String(raw.prefix(10)) }
        let comps = calendar.dateComponents([.year, .month, .day], from: d)
        guard let y = comps.year, let m = comps.month, let day = comps.day else { return String(raw.prefix(10)) }
        return String(format: "%04d-%02d-%02d", y, m, day)
    }
    
    var daysUntilExpiry: Int? {
        guard let localDay = expiryDateAsLocalDay else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.current.timeZone
        guard let date = formatter.date(from: localDay) else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiry = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: expiry).day
    }
    
    var status: FoodItemStatus {
        guard let days = daysUntilExpiry else { return .fresh }
        if days < 0 { return .expired }
        if days == 0 { return .expired }
        if days <= 5 { return .expiringSoon }
        return .fresh
    }
    
    var expiryDateFormatted: String {
        guard let localDay = expiryDateAsLocalDay else { return "N/A" }
        return localDay
    }
}

enum FoodItemStatus: String, CaseIterable {
    case fresh, expiringSoon, expired
    
    var color: String {
        switch self {
        case .fresh: return "#4CAF50"
        case .expiringSoon: return "#FF9800"
        case .expired: return "#F44336"
        }
    }
    
    var icon: String {
        switch self {
        case .fresh: return "checkmark.circle.fill"
        case .expiringSoon: return "clock.fill"
        case .expired: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Food Item Event
struct FoodItemEvent: Codable, Identifiable {
    let id: String
    let foodItemId: String
    let groupId: String
    let userId: String
    let eventType: String
    let quantityAffected: Int
    var disposalReason: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case foodItemId = "food_item_id"
        case groupId = "group_id"
        case userId = "user_id"
        case eventType = "event_type"
        case quantityAffected = "quantity_affected"
        case disposalReason = "disposal_reason"
        case createdAt = "created_at"
    }
}

// MARK: - Shopping Item
struct ShoppingItem: Codable, Identifiable {
    let id: String
    var groupId: String
    var createdBy: String?
    var name: String
    var quantity: Int
    var unit: String?
    var categoryId: String?
    /// Where to buy (e.g. store name). Optional.
    var whereToBuy: String?
    var isPurchased: Bool
    var purchasedAt: String?
    var purchasedBy: String?
    /// True after user has added this item to inventory via "Add to Inventory".
    var movedToInventory: Bool?
    /// ID of the inventory (food) item created when "Add to Inventory" was used.
    var inventoryItemId: String?
    var notes: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, quantity, unit, notes
        case groupId = "group_id"
        case createdBy = "created_by"
        case categoryId = "category_id"
        case whereToBuy = "where_to_buy"
        case isPurchased = "is_purchased"
        case purchasedAt = "purchased_at"
        case purchasedBy = "purchased_by"
        case movedToInventory = "moved_to_inventory"
        case inventoryItemId = "inventory_item_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Bought = checkbox checked; applies line-through and "Add to Inventory" when true.
    var isBought: Bool { isPurchased }
}

// MARK: - Currency (for wishlist price)
struct CurrencyOption: Identifiable {
    let code: String
    let symbol: String
    let name: String
    var id: String { code }
    
    static let all: [CurrencyOption] = [
        CurrencyOption(code: "USD", symbol: "$", name: "US Dollar"),
        CurrencyOption(code: "EUR", symbol: "€", name: "Euro"),
        CurrencyOption(code: "GBP", symbol: "£", name: "British Pound"),
        CurrencyOption(code: "JPY", symbol: "¥", name: "Japanese Yen"),
        CurrencyOption(code: "CNY", symbol: "¥", name: "Chinese Yuan"),
        CurrencyOption(code: "AUD", symbol: "A$", name: "Australian Dollar"),
        CurrencyOption(code: "CAD", symbol: "C$", name: "Canadian Dollar"),
        CurrencyOption(code: "CHF", symbol: "Fr", name: "Swiss Franc"),
        CurrencyOption(code: "INR", symbol: "₹", name: "Indian Rupee"),
        CurrencyOption(code: "KRW", symbol: "₩", name: "South Korean Won"),
        CurrencyOption(code: "SGD", symbol: "S$", name: "Singapore Dollar"),
        CurrencyOption(code: "HKD", symbol: "HK$", name: "Hong Kong Dollar"),
        CurrencyOption(code: "MXN", symbol: "$", name: "Mexican Peso"),
        CurrencyOption(code: "BRL", symbol: "R$", name: "Brazilian Real"),
        CurrencyOption(code: "RUB", symbol: "₽", name: "Russian Ruble"),
        CurrencyOption(code: "ZAR", symbol: "R", name: "South African Rand"),
        CurrencyOption(code: "AED", symbol: "د.إ", name: "UAE Dirham"),
        CurrencyOption(code: "MYR", symbol: "RM", name: "Malaysian Ringgit"),
        CurrencyOption(code: "THB", symbol: "฿", name: "Thai Baht"),
        CurrencyOption(code: "IDR", symbol: "Rp", name: "Indonesian Rupiah"),
        CurrencyOption(code: "PHP", symbol: "₱", name: "Philippine Peso"),
        CurrencyOption(code: "PLN", symbol: "zł", name: "Polish Zloty"),
        CurrencyOption(code: "SEK", symbol: "kr", name: "Swedish Krona"),
        CurrencyOption(code: "NOK", symbol: "kr", name: "Norwegian Krone"),
        CurrencyOption(code: "DKK", symbol: "kr", name: "Danish Krone"),
        CurrencyOption(code: "NZD", symbol: "NZ$", name: "New Zealand Dollar"),
        CurrencyOption(code: "TWD", symbol: "NT$", name: "Taiwan Dollar"),
        CurrencyOption(code: "TRY", symbol: "₺", name: "Turkish Lira"),
        CurrencyOption(code: "SAR", symbol: "﷼", name: "Saudi Riyal"),
        CurrencyOption(code: "ILS", symbol: "₪", name: "Israeli Shekel"),
        CurrencyOption(code: "EGP", symbol: "E£", name: "Egyptian Pound"),
        CurrencyOption(code: "PKR", symbol: "₨", name: "Pakistani Rupee"),
        CurrencyOption(code: "BDT", symbol: "৳", name: "Bangladeshi Taka"),
        CurrencyOption(code: "VND", symbol: "₫", name: "Vietnamese Dong"),
    ]
    
    static func symbol(for code: String?) -> String {
        let c = (code ?? "USD").uppercased()
        return all.first(where: { $0.code == c })?.symbol ?? "$"
    }
    
    /// Currencies that use no minor units (show whole numbers only, e.g. JPY 10000 not 10000.00).
    private static let noDecimalCodes: Set<String> = ["JPY", "KRW", "VND", "TWD", "IDR", "HUF", "CLP"]
    
    /// Formatted price for display: no decimals for JPY/KRW/VND/etc., two decimals otherwise.
    static func formattedPrice(_ price: Double, currencyCode: String?) -> String {
        let code = (currencyCode ?? "USD").uppercased()
        if noDecimalCodes.contains(code) {
            return String(format: "%.0f", price)
        }
        return String(format: "%.2f", price)
    }
}

// MARK: - Wish Item
struct WishItem: Codable, Identifiable {
    let id: String
    var groupId: String
    var createdBy: String?
    var name: String
    var notes: String?
    var price: Double?
    /// ISO currency code (e.g. USD, EUR). Optional; default display uses USD.
    var currencyCode: String?
    /// Desire level 1–5. Stored in API as `rating` for compatibility.
    var rating: Int?
    var imageUrl: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, notes, price, rating
        case groupId = "group_id"
        case createdBy = "created_by"
        case currencyCode = "currency_code"
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Desire level 1–5 (how much user wants it). Clamped; default 3.
    var desireLevel: Int {
        get { (rating ?? 3).clamped(to: 1...5) }
        set { rating = newValue.clamped(to: 1...5) }
    }
    
    /// Currency symbol for display (e.g. $, €).
    var currencySymbol: String { CurrencyOption.symbol(for: currencyCode) }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Invitation
struct Invitation: Codable, Identifiable {
    let id: String
    let groupId: String
    let invitedBy: String
    let invitedEmail: String
    let inviteCode: String?
    let status: String
    let expiresAt: String?
    let createdAt: String?
    var groupName: String?
    var groupDescription: String?
    var inviterName: String?
    var invitedByName: String?
    var invitedByEmail: String?
    
    enum CodingKeys: String, CodingKey {
        case id, status
        case groupId = "group_id"
        case invitedBy = "invited_by"
        case invitedEmail = "invited_email"
        case inviteCode = "invite_code"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case groupName = "group_name"
        case groupDescription = "group_description"
        case inviterName = "inviter_name"
        case invitedByName = "invited_by_name"
        case invitedByEmail = "invited_by_email"
    }
}

struct InviteVerification: Codable {
    let valid: Bool
    let group: InviteVerificationGroup?
    let error: String?
}

struct InviteVerificationGroup: Codable {
    let id: String
    let name: String
    let description: String?
    let memberCount: Int?
    let maxMembers: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case memberCount = "member_count"
        case maxMembers = "max_members"
    }
}

// MARK: - User Settings
struct UserSettings: Codable {
    var priceTrackingEnabled: Bool?
    var notificationTime: String?
    var expiringSoonDays: Int?
    var expiringTodayAlerts: Bool?
    var expiredAlerts: Bool?
    var theme: String?
    
    enum CodingKeys: String, CodingKey {
        case theme
        case priceTrackingEnabled = "price_tracking_enabled"
        case notificationTime = "notification_time"
        case expiringSoonDays = "expiring_soon_days"
        case expiringTodayAlerts = "expiring_today_alerts"
        case expiredAlerts = "expired_alerts"
    }
}

// MARK: - Analytics
struct AnalyticsSummary: Codable {
    let totalItemsAdded: Int?
    let totalItemsUsed: Int?
    let totalItemsThrownAway: Int?
    let totalItemsExpired: Int?
    let wastePercentage: Double?
    let avgDaysBeforeExpiry: Double?
    let estimatedWasteValue: Double?
    
    enum CodingKeys: String, CodingKey {
        case totalItemsAdded = "total_items_added"
        case totalItemsUsed = "total_items_used"
        case totalItemsThrownAway = "total_items_thrown_away"
        case totalItemsExpired = "total_items_expired"
        case wastePercentage = "waste_percentage"
        case avgDaysBeforeExpiry = "avg_days_before_expiry"
        case estimatedWasteValue = "estimated_waste_value"
    }
}

struct CategoryBreakdown: Codable {
    let categoryId: String?
    let categoryName: String?
    let totalItems: Int?
    let wastedItems: Int?
    let wastePercentage: Double?
    let estimatedWasteValue: Double?
    
    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case categoryName = "category_name"
        case totalItems = "total_items"
        case wastedItems = "wasted_items"
        case wastePercentage = "waste_percentage"
        case estimatedWasteValue = "estimated_waste_value"
    }
}

struct LocationBreakdown: Codable {
    let locationId: String?
    let locationName: String?
    let totalItems: Int?
    let wastedItems: Int?
    let wastePercentage: Double?
    let estimatedWasteValue: Double?
    
    enum CodingKeys: String, CodingKey {
        case locationId = "location_id"
        case locationName = "location_name"
        case totalItems = "total_items"
        case wastedItems = "wasted_items"
        case wastePercentage = "waste_percentage"
        case estimatedWasteValue = "estimated_waste_value"
    }
}

struct MonthlyTrend: Codable {
    let month: String?
    let totalItemsAdded: Int?
    let totalItemsUsed: Int?
    let totalItemsWasted: Int?
    let wastePercentage: Double?
    let estimatedWasteValue: Double?
    
    enum CodingKeys: String, CodingKey {
        case month
        case totalItemsAdded = "total_items_added"
        case totalItemsUsed = "total_items_used"
        case totalItemsWasted = "total_items_wasted"
        case wastePercentage = "waste_percentage"
        case estimatedWasteValue = "estimated_waste_value"
    }
}

struct WastedItem: Codable {
    let itemName: String?
    let categoryName: String?
    let timesWasted: Int?
    let totalQuantity: Int?
    let estimatedValue: Double?
    
    enum CodingKeys: String, CodingKey {
        case itemName = "item_name"
        case categoryName = "category_name"
        case timesWasted = "times_wasted"
        case totalQuantity = "total_quantity"
        case estimatedValue = "estimated_value"
    }
}

struct DisposalReasonBreakdown: Codable {
    let disposalReason: String?
    let count: Int?
    let percentage: Double?
    
    enum CodingKeys: String, CodingKey {
        case disposalReason = "disposal_reason"
        case count
        case percentage
    }
}

struct ExpiryPatterns: Codable {
    let avgDaysBeforeExpiry: Double?
    let mostCommonExpiryDay: Int?
    let expiryDistribution: [ExpiryDistribution]?
    
    enum CodingKeys: String, CodingKey {
        case avgDaysBeforeExpiry = "avg_days_before_expiry"
        case mostCommonExpiryDay = "most_common_expiry_day"
        case expiryDistribution = "expiry_distribution"
    }
}

struct ExpiryDistribution: Codable {
    let daysRange: String?
    let count: Int?
    let percentage: Double?
    
    enum CodingKeys: String, CodingKey {
        case daysRange = "days_range"
        case count
        case percentage
    }
}

struct ComprehensiveAnalytics: Codable {
    let summary: AnalyticsSummary?
    let categoryBreakdown: [CategoryBreakdown]?
    let locationBreakdown: [LocationBreakdown]?
    let monthlyTrends: [MonthlyTrend]?
    let mostWasted: [WastedItem]?
    let disposalReasons: [DisposalReasonBreakdown]?
    let expiryPatterns: ExpiryPatterns?
    
    enum CodingKeys: String, CodingKey {
        case summary
        case categoryBreakdown = "category_breakdown"
        case locationBreakdown = "location_breakdown"
        case monthlyTrends = "monthly_trends"
        case mostWasted = "most_wasted"
        case disposalReasons = "disposal_reasons"
        case expiryPatterns = "expiry_patterns"
    }
}

// MARK: - API Response Wrappers
struct ItemsResponse<T: Codable>: Codable {
    let items: [T]
}

/// API returns { "categories": [...] } for GET /categories
struct CategoriesResponse: Codable {
    let categories: [Category]
}

/// API returns { "locations": [...] } for GET /locations
struct LocationsResponse: Codable {
    let locations: [Location]
}

/// API returns { "message", "category" } for POST/PATCH category
struct CategorySingleResponse: Codable {
    let message: String?
    let category: Category
}

/// API returns { "message", "location" } for POST/PATCH location
struct LocationSingleResponse: Codable {
    let message: String?
    let location: Location
}

struct SingleItemResponse<T: Codable>: Codable {
    let message: String?
    let item: T
}

struct MessageResponse: Codable {
    let message: String
}

struct ErrorResponse: Codable {
    let error: String
}

struct HealthStatus: Codable {
    let status: String
    let timestamp: String?
    let environment: String?
}

// MARK: - Device Identifier Helper
struct UIDeviceIdentifier {
    static var current: String {
        if let uuid = UserDefaults.standard.string(forKey: "device_uuid") {
            return uuid
        }
        let uuid = UUID().uuidString
        UserDefaults.standard.set(uuid, forKey: "device_uuid")
        return uuid
    }
    
    static var deviceName: String {
        UIDevice.current.name
    }
}
