import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case en = "en"
    case ja = "ja"
    case ms = "ms"
    case th = "th"
    case zh = "zh"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .en: return "English"
        case .ja: return "日本語"
        case .ms: return "Bahasa Melayu"
        case .th: return "ไทย"
        case .zh: return "中文"
        }
    }
}

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
        }
    }
    
    init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        self.currentLanguage = AppLanguage(rawValue: saved) ?? .en
    }
    
    func t(_ key: String) -> String {
        let translations = getTranslations()
        return translations[key] ?? key
    }
    
    /// Returns the display name; if it contains " / ", only the part before " / " is returned (e.g. "Meat / Seafood" → "Meat").
    private static func takeFirstPartOnly(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        if let idx = trimmed.firstIndex(of: "/") {
            return trimmed[..<idx].trimmingCharacters(in: .whitespaces)
        }
        return trimmed
    }
    
    /// Maps known English default category names to translation keys when category has no translationKey.
    private static let categoryNameToKey: [String: String] = [
        "fresh food": "defaultCategory.freshFood", "cooked food": "defaultCategory.cookedFood",
        "cooked food / leftovers": "defaultCategory.cookedFood",
        "canned goods": "defaultCategory.cannedPackaged", "canned / packaged food": "defaultCategory.cannedPackaged",
        "frozen food": "defaultCategory.frozenFood", "frozen foods": "defaultCategory.frozenFood",
        "snacks": "defaultCategory.snacks", "drinks": "defaultCategory.drinks", "beverages": "defaultCategory.drinks",
        "dairy": "defaultCategory.dairy",
        "meat / seafood": "defaultCategory.meatSeafood", "meat": "defaultCategory.meatSeafood",
        "fruits": "defaultCategory.fruits", "vegetables": "defaultCategory.vegetables",
        "bread / bakery": "defaultCategory.breadBakery", "bread": "defaultCategory.breadBakery",
        "condiments & sauces": "defaultCategory.condimentsSauces", "spices & seasoning": "defaultCategory.spicesSeasoning",
        "baby food": "defaultCategory.babyFood", "medicine": "defaultCategory.medicine",
        "supplements / vitamins": "defaultCategory.supplements", "first aid": "defaultCategory.firstAid",
        "medical devices (e.g., test strips)": "defaultCategory.medicalDevices",
        "skincare": "defaultCategory.skincare", "makeup": "defaultCategory.makeup",
        "hair care": "defaultCategory.hairCare", "body care": "defaultCategory.bodyCare",
        "perfume": "defaultCategory.perfume", "hygiene products": "defaultCategory.hygieneProducts",
        "cleaning supplies": "defaultCategory.cleaningSupplies", "laundry": "defaultCategory.laundry",
        "kitchen supplies (wrap, foil)": "defaultCategory.kitchenSupplies", "batteries": "defaultCategory.batteries",
        "light bulbs": "defaultCategory.lightBulbs", "filters (water/air)": "defaultCategory.filters",
        "passport": "defaultCategory.passport", "visa / residence card": "defaultCategory.visa",
        "driver license": "defaultCategory.driverLicense", "insurance": "defaultCategory.insurance",
        "contracts": "defaultCategory.contracts", "bills / receipts": "defaultCategory.billsReceipts",
        "warranty": "defaultCategory.warranty", "certificates": "defaultCategory.certificates",
        "membership / subscriptions": "defaultCategory.membership", "pet food": "defaultCategory.petFood",
        "pet medicine": "defaultCategory.petMedicine", "pet supplies": "defaultCategory.petSupplies",
        "electronics / gadgets": "defaultCategory.electronics", "stationery": "defaultCategory.stationery",
        "miscellaneous": "defaultCategory.miscellaneous",
    ]
    
    func getCategoryName(_ category: Category) -> String {
        let raw: String
        if let tKey = category.translationKey, !tKey.isEmpty {
            let translated = t(tKey)
            raw = (translated != tKey) ? translated : category.name
        } else {
            let nameLower = category.name.trimmingCharacters(in: .whitespaces).lowercased()
            let nameFirstPart = Self.takeFirstPartOnly(category.name).trimmingCharacters(in: .whitespaces).lowercased()
            let key = Self.categoryNameToKey[nameLower] ?? Self.categoryNameToKey[nameFirstPart]
            if let k = key {
                let translated = t(k)
                raw = (translated != k) ? translated : category.name
            } else {
                raw = category.name
            }
        }
        return Self.takeFirstPartOnly(raw)
    }
    
    /// Maps known English default location names to translation keys when location has no translationKey.
    private static let locationNameToKey: [String: String] = [
        "fridge (top)": "defaultLocation.fridgeTop", "fridge (middle)": "defaultLocation.fridgeMiddle",
        "fridge (bottom)": "defaultLocation.fridgeBottom", "fridge door": "defaultLocation.fridgeDoor",
        "freezer": "defaultLocation.freezer", "pantry": "defaultLocation.pantry",
        "cabinet": "defaultLocation.cabinet", "drawer": "defaultLocation.drawer",
        "counter / shelf": "defaultLocation.counterShelf", "counter": "defaultLocation.counter",
        "fridge": "defaultLocation.fridge",
        "storage box": "defaultLocation.storageBox", "cardboard box": "defaultLocation.cardboardBox",
        "closet": "defaultLocation.closet", "closet / wardrobe": "defaultLocation.closet",
        "under bed": "defaultLocation.underBed", "storage room": "defaultLocation.storageRoom",
        "garage": "defaultLocation.garage", "balcony storage": "defaultLocation.balconyStorage",
        "bathroom cabinet": "defaultLocation.bathroomCabinet", "sink drawer": "defaultLocation.sinkDrawer",
        "shower shelf": "defaultLocation.showerShelf",
        "desk drawer": "defaultLocation.deskDrawer", "bookshelf": "defaultLocation.bookshelf",
        "file organizer": "defaultLocation.fileOrganizer",
        "backpack": "defaultLocation.backpack", "suitcase": "defaultLocation.suitcase",
    ]
    
    func getLocationName(_ location: Location) -> String {
        let raw: String
        if let tKey = location.translationKey, !tKey.isEmpty {
            let translated = t(tKey)
            raw = (translated != tKey) ? translated : location.name
        } else {
            let nameLower = location.name.trimmingCharacters(in: .whitespaces).lowercased()
            let nameFirstPart = Self.takeFirstPartOnly(location.name).trimmingCharacters(in: .whitespaces).lowercased()
            let key = Self.locationNameToKey[nameLower] ?? Self.locationNameToKey[nameFirstPart]
            if let k = key {
                let translated = t(k)
                raw = (translated != k) ? translated : location.name
            } else {
                raw = location.name
            }
        }
        return Self.takeFirstPartOnly(raw)
    }
    
    /// Returns categories with duplicate display names removed; first occurrence of each name is kept.
    func deduplicatedCategories(_ categories: [Category]) -> [Category] {
        var seen = Set<String>()
        return categories.filter { cat in
            let name = getCategoryName(cat)
            if seen.contains(name) { return false }
            seen.insert(name)
            return true
        }
    }
    
    /// Merged display name: Fridge (Top/Middle/Bottom) and single Fridge all show as localized "Fridge".
    func getLocationDisplayName(_ location: Location) -> String {
        if let key = location.translationKey, Self.fridgeVariantKeys.contains(key) {
            return t("defaultLocation.fridge")
        }
        let name = location.name.trimmingCharacters(in: .whitespaces).lowercased()
        if name == "fridge (top)" || name == "fridge (middle)" || name == "fridge (bottom)" {
            return t("defaultLocation.fridge")
        }
        return getLocationName(location)
    }
    
    private static let fridgeVariantKeys: Set<String> = [
        "defaultLocation.fridge", "defaultLocation.fridgeTop", "defaultLocation.fridgeMiddle", "defaultLocation.fridgeBottom"
    ]
    
    private func getTranslations() -> [String: String] {
        switch currentLanguage {
        case .en: return Translations.en
        case .ja: return Translations.ja
        case .ms: return Translations.ms
        case .th: return Translations.th
        case .zh: return Translations.zh
        }
    }
}
