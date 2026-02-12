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
    
    func getCategoryName(_ category: Category) -> String {
        if let tKey = category.translationKey, !tKey.isEmpty {
            let translated = t(tKey)
            if translated != tKey { return translated }
        }
        return category.name
    }
    
    func getLocationName(_ location: Location) -> String {
        if let tKey = location.translationKey, !tKey.isEmpty {
            let translated = t(tKey)
            if translated != tKey { return translated }
        }
        return location.name
    }
    
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
