import SwiftUI
import Combine

// MARK: - App Theme
struct AppTheme: Equatable {
    let name: String
    let backgroundColor: String
    let primaryColor: String
    let secondaryColor: String
    let textColor: String
    let tertiaryColor: String
    let cardBackground: String
    let borderColor: String
    let shadowColor: String
    let textSecondary: String
    /// Hint/placeholder color: dark on light themes, light on dark themes. Use for placeholders and “Tap to choose”.
    let placeholderColor: String
    let successColor: String
    let warningColor: String
    let dangerColor: String
    let headerBackground: String
    let borderRadius: CGFloat
    
    /// Secondary text color that contrasts with cardBackground. Use for subtitles and captions on cards so they stay readable in all themes.
    var subtitleOnCard: String {
        Self.contrastingSubtitleHex(forBackgroundHex: cardBackground)
    }
    
    /// Secondary text that contrasts with backgroundColor. Use for labels on the main screen background.
    var subtitleOnBackground: String {
        Self.contrastingSubtitleHex(forBackgroundHex: backgroundColor)
    }
    
    /// Title and label text on the main screen background. White for Black/Dark Brown/Dark Gold; otherwise dark on light background, white on dark.
    var titleOnBackground: String {
        if useWhiteCalendarText { return "#FFFFFF" }
        return Self.luminance(ofHex: backgroundColor) > 0.5 ? "#212529" : "#FFFFFF"
    }
    
    /// Text color for calendar UI (month, weekdays, dates). White for Black/Dark Brown/Dark Gold; otherwise dark on light card, white on dark card.
    var calendarTextColor: String {
        if useWhiteCalendarText { return "#FFFFFF" }
        return Self.calendarTextHex(forBackgroundHex: cardBackground)
    }
    
    /// True when the card (or calendar) background is dark so the system date picker should use light content (white text). Explicitly true for Black, Dark Brown, Dark Gold.
    var isDarkCardTheme: Bool {
        useWhiteCalendarText || Self.luminance(ofHex: cardBackground) <= 0.5
    }
    
    /// Black, Dark Brown, and Dark Gold always use white calendar text.
    private var useWhiteCalendarText: Bool {
        switch name {
        case "Black", "Dark Brown", "Dark Gold": return true
        default: return false
        }
    }
    
    /// Returns dark (#212529) for bright backgrounds, white (#FFFFFF) for dark backgrounds (by luminance of card).
    private static func calendarTextHex(forBackgroundHex hex: String) -> String {
        let lum = luminance(ofHex: hex)
        return lum > 0.5 ? "#212529" : "#FFFFFF"
    }
    
    private static func luminance(ofHex hex: String) -> Double {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard h.count == 6 || h.count == 8 else { return 0.5 }
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        return 0.299 * r + 0.587 * g + 0.114 * b
    }
    
    /// Returns a hex color for secondary text that contrasts with the given background (dark grey on light BG, light grey on dark BG).
    private static func contrastingSubtitleHex(forBackgroundHex hex: String) -> String {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard h.count == 6 || h.count == 8 else { return "#6B7280" }
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5 ? "#4B5563" : "#D1D5DB"
    }
}

// MARK: - All 11 Themes
enum ThemeType: String, CaseIterable, Identifiable {
    case original, recycled, darkBrown, black, blue, green, softPink, brightPink, naturalGreen, mintRed, darkGold
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .original: return "Original"
        case .recycled: return "Recycled"
        case .darkBrown: return "Dark Brown"
        case .black: return "Black"
        case .blue: return "Blue"
        case .green: return "Green"
        case .softPink: return "Soft Pink"
        case .brightPink: return "Bright Pink"
        case .naturalGreen: return "Yellow"
        case .mintRed: return "Mint-Red"
        case .darkGold: return "Dark Gold"
        }
    }
    
    var theme: AppTheme {
        switch self {
        case .original:
            return AppTheme(name: "Original", backgroundColor: "#F8F9FA", primaryColor: "#2E7D32", secondaryColor: "#E9ECEF", textColor: "#212529", tertiaryColor: "#4CAF50", cardBackground: "#FFFFFF", borderColor: "#CED4DA", shadowColor: "#00000026", textSecondary: "#9CA3AF", placeholderColor: "#6B7280", successColor: "#2E7D32", warningColor: "#FF9800", dangerColor: "#F44336", headerBackground: "#FFFFFF", borderRadius: 8)
        case .recycled:
            return AppTheme(name: "Recycled", backgroundColor: "#F3C88B", primaryColor: "#2E7D32", secondaryColor: "#FFF1D6", textColor: "#2E2E2E", tertiaryColor: "#B8860B", cardBackground: "#FDF0C0", borderColor: "#E8DCC6", shadowColor: "#0000001A", textSecondary: "#8A7A6B", placeholderColor: "#6B6348", successColor: "#2E7D32", warningColor: "#F4A460", dangerColor: "#CD5C5C", headerBackground: "#FFF1D6", borderRadius: 16)
        case .darkBrown:
            return AppTheme(name: "Dark Brown", backgroundColor: "#2C2417", primaryColor: "#4CAF50", secondaryColor: "#B8860B", textColor: "#F5EFE7", tertiaryColor: "#8D6E63", cardBackground: "#3D3426", borderColor: "#F5EFE733", shadowColor: "#0000004D", textSecondary: "#C0B494", placeholderColor: "#C0B494", successColor: "#4CAF50", warningColor: "#F4A460", dangerColor: "#CD5C5C", headerBackground: "#3D3426", borderRadius: 16)
        case .black:
            return AppTheme(name: "Black", backgroundColor: "#000000", primaryColor: "#4CAF50", secondaryColor: "#1A1A1A", textColor: "#FFFFFF", tertiaryColor: "#66BB6A", cardBackground: "#1A1A1A", borderColor: "#FFFFFF1A", shadowColor: "#00000080", textSecondary: "#B0B0B0", placeholderColor: "#A0A0A0", successColor: "#4CAF50", warningColor: "#FFA726", dangerColor: "#F44336", headerBackground: "#1A1A1A", borderRadius: 16)
        case .blue:
            return AppTheme(name: "Blue", backgroundColor: "#c1d9e3", primaryColor: "#2d4e68", secondaryColor: "#a1c0d8", textColor: "#2d4e68", tertiaryColor: "#5b88a8", cardBackground: "#edf4f7", borderColor: "#a1c0d8", shadowColor: "#2d4e6833", textSecondary: "#9BB5CC", placeholderColor: "#4a5d6d", successColor: "#4CAF50", warningColor: "#FF9800", dangerColor: "#F44336", headerBackground: "#a1c0d8", borderRadius: 16)
        case .green:
            return AppTheme(name: "Green", backgroundColor: "#dbe1c0", primaryColor: "#2d4e20", secondaryColor: "#d8c58d", textColor: "#3164a3", tertiaryColor: "#3d6a28", cardBackground: "#fafaf0", borderColor: "#d8c58d", shadowColor: "#3d6a2833", textSecondary: "#A8B88E", placeholderColor: "#4a5a70", successColor: "#2d4e20", warningColor: "#FF9800", dangerColor: "#F44336", headerBackground: "#d8c58d", borderRadius: 16)
        case .softPink:
            return AppTheme(name: "Soft Pink", backgroundColor: "#fce7dd", primaryColor: "#8B5A47", secondaryColor: "#e9c9b2", textColor: "#44281c", tertiaryColor: "#a37d6c", cardBackground: "#f5d3d3", borderColor: "#e9c9b2", shadowColor: "#44281c33", textSecondary: "#C4A193", placeholderColor: "#6B4A3A", successColor: "#4CAF50", warningColor: "#FF9800", dangerColor: "#F44336", headerBackground: "#e9c9b2", borderRadius: 16)
        case .brightPink:
            return AppTheme(name: "Bright Pink", backgroundColor: "#fdd0d4", primaryColor: "#8B3A42", secondaryColor: "#f2bcbc", textColor: "#3c1d20", tertiaryColor: "#ad5b62", cardBackground: "#ffe5e5", borderColor: "#f2bcbc", shadowColor: "#3c1d2033", textSecondary: "#D18B94", placeholderColor: "#5a3a38", successColor: "#4CAF50", warningColor: "#FF9800", dangerColor: "#F44336", headerBackground: "#f2bcbc", borderRadius: 16)
        case .naturalGreen:
            return AppTheme(name: "Yellow", backgroundColor: "#fbfcee", primaryColor: "#3971b8", secondaryColor: "#c8d69b", textColor: "#182020", tertiaryColor: "#3971b8", cardBackground: "#f6e6a5", borderColor: "#c8d69b", shadowColor: "#1820201A", textSecondary: "#7A9C6E", placeholderColor: "#4a5a40", successColor: "#4CAF50", warningColor: "#FF9800", dangerColor: "#F44336", headerBackground: "#c8d69b", borderRadius: 16)
        case .mintRed:
            return AppTheme(name: "Mint-Red", backgroundColor: "#d8f2c9", primaryColor: "#d84444", secondaryColor: "#68b9a6", textColor: "#000000", tertiaryColor: "#ef5f5f", cardBackground: "#8cd1b8", borderColor: "#68b9a6", shadowColor: "#0000001A", textSecondary: "#2E5B4F", placeholderColor: "#1E4A3F", successColor: "#4CAF50", warningColor: "#FF9800", dangerColor: "#d84444", headerBackground: "#68b9a6", borderRadius: 16)
        case .darkGold:
            return AppTheme(name: "Dark Gold", backgroundColor: "#2c2c2c", primaryColor: "#d4a332", secondaryColor: "#3e3e42", textColor: "#ffffff", tertiaryColor: "#b6862e", cardBackground: "#494949", borderColor: "#3e3e42", shadowColor: "#0000004D", textSecondary: "#999999", placeholderColor: "#B0B0B0", successColor: "#4CAF50", warningColor: "#FF9800", dangerColor: "#F44336", headerBackground: "#3e3e42", borderRadius: 16)
        }
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var currentThemeType: ThemeType {
        didSet {
            UserDefaults.standard.set(currentThemeType.rawValue, forKey: "selected_theme")
        }
    }
    
    var currentTheme: AppTheme { currentThemeType.theme }
    
    init() {
        let saved = UserDefaults.standard.string(forKey: "selected_theme") ?? "original"
        self.currentThemeType = ThemeType(rawValue: saved) ?? .original
    }
    
    func setTheme(_ type: ThemeType) {
        currentThemeType = type
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme View Modifier
struct ThemedBackground: ViewModifier {
    let theme: AppTheme
    
    func body(content: Content) -> some View {
        content
            .background(Color(hex: theme.backgroundColor))
    }
}

extension View {
    func themedBackground(_ theme: AppTheme) -> some View {
        modifier(ThemedBackground(theme: theme))
    }
}
