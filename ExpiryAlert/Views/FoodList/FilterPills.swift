import SwiftUI

/// Filter pills for shopping list: All | Active | Bought.
/// Uses consistent pill style and min tap target; selection state uses primary color.
enum ShoppingFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case bought = "Bought"
}

struct FilterPills: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager

    @Binding var selected: ShoppingFilter
    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ShoppingFilter.allCases, id: \.self) { filter in
                Button(action: { selected = filter }) {
                    Text(label(for: filter))
                        .font(.caption)
                        .fontWeight(selected == filter ? .semibold : .regular)
                        .foregroundColor(selected == filter ? .white : Color(hex: theme.textColor))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selected == filter ? Color(hex: theme.primaryColor) : Color(hex: theme.cardBackground))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func label(for filter: ShoppingFilter) -> String {
        switch filter {
        case .all: return localizationManager.t("list.filterAll")
        case .active: return localizationManager.t("list.filterActive")
        case .bought: return localizationManager.t("list.filterBought")
        }
    }
}
