import Foundation

// MARK: - All Translations (composed from per-language files)
// Each language lives in its own file for easier review and editing:
//   TranslationsEN.swift  – English
//   TranslationsJA.swift  – Japanese
//   TranslationsMS.swift  – Malay
//   TranslationsTH.swift  – Thai
//   TranslationsZH.swift  – Chinese
enum Translations {
    static var en: [String: String] { TranslationsEN.strings }
    static var ja: [String: String] { TranslationsJA.strings }
    static var ms: [String: String] { TranslationsMS.strings }
    static var th: [String: String] { TranslationsTH.strings }
    static var zh: [String: String] { TranslationsZH.strings }
}
