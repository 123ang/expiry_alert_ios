import Foundation

// MARK: - Category Theme Data
struct CategoryThemeData: Identifiable {
    let id: String
    let nameKey: String
    let descKey: String
    let icon: String
    let categories: [CategoryData]
    
    struct CategoryData {
        let translationKey: String
        let icon: String
    }
}

// MARK: - All Predefined Themes
let ALL_CATEGORY_THEMES: [CategoryThemeData] = [
    CategoryThemeData(
        id: "food",
        nameKey: "theme.food",
        descKey: "theme.foodDesc",
        icon: "🍔",
        categories: [
            CategoryThemeData.CategoryData(translationKey: "category.vegetables", icon: "🥕"),
            CategoryThemeData.CategoryData(translationKey: "category.fruits", icon: "🍎"),
            CategoryThemeData.CategoryData(translationKey: "category.dairy", icon: "🧀"),
            CategoryThemeData.CategoryData(translationKey: "category.meat", icon: "🥩"),
            CategoryThemeData.CategoryData(translationKey: "category.snacks", icon: "🥨"),
            CategoryThemeData.CategoryData(translationKey: "category.desserts", icon: "🍰"),
            CategoryThemeData.CategoryData(translationKey: "category.seafood", icon: "🦞"),
            CategoryThemeData.CategoryData(translationKey: "category.bread", icon: "🍞")
        ]
    ),
    CategoryThemeData(
        id: "health",
        nameKey: "theme.health",
        descKey: "theme.healthDesc",
        icon: "❤️",
        categories: [
            CategoryThemeData.CategoryData(translationKey: "category.medications", icon: "💊"),
            CategoryThemeData.CategoryData(translationKey: "category.vitamins", icon: "💪"),
            CategoryThemeData.CategoryData(translationKey: "category.firstAid", icon: "🩹"),
            CategoryThemeData.CategoryData(translationKey: "category.contactLenses", icon: "👁️")
        ]
    ),
    CategoryThemeData(
        id: "beauty",
        nameKey: "theme.beauty",
        descKey: "theme.beautyDesc",
        icon: "💄",
        categories: [
            CategoryThemeData.CategoryData(translationKey: "category.makeup", icon: "💅"),
            CategoryThemeData.CategoryData(translationKey: "category.skincare", icon: "🧴"),
            CategoryThemeData.CategoryData(translationKey: "category.hairCare", icon: "💇"),
            CategoryThemeData.CategoryData(translationKey: "category.perfume", icon: "💨")
        ]
    ),
    CategoryThemeData(
        id: "household",
        nameKey: "theme.household",
        descKey: "theme.householdDesc",
        icon: "🏠",
        categories: [
            CategoryThemeData.CategoryData(translationKey: "category.cleaningSupplies", icon: "🧼"),
            CategoryThemeData.CategoryData(translationKey: "category.laundryProducts", icon: "🧺"),
            CategoryThemeData.CategoryData(translationKey: "category.batteries", icon: "🔋")
        ]
    )
]

// MARK: - Translated Theme
struct TranslatedCategoryTheme: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let categories: [TranslatedCategory]
    
    struct TranslatedCategory: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let translationKey: String
    }
}

func getTranslatedThemes(using lm: LocalizationManager) -> [TranslatedCategoryTheme] {
    return ALL_CATEGORY_THEMES.map { theme in
        TranslatedCategoryTheme(
            id: theme.id,
            name: lm.t(theme.nameKey),
            description: lm.t(theme.descKey),
            icon: theme.icon,
            categories: theme.categories.map { cat in
                TranslatedCategoryTheme.TranslatedCategory(
                    name: lm.t(cat.translationKey),
                    icon: cat.icon,
                    translationKey: cat.translationKey
                )
            }
        )
    }
}
