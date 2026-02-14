import SwiftUI

/// Single shopping list row: large checkbox, name (bold), subtext "Category • Where to buy".
/// When checked: strikethrough and dim. No inline trash; use swipe for Delete / Edit or Add to Inventory.
/// Min height 56pt for thumb-friendly tap target.
struct ShoppingRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager

    let item: ShoppingItem
    let categoryDisplay: String
    let whereToBuyDisplay: String
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onAddToInventory: () -> Void

    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        HStack(spacing: 12) {
            // Large checkbox for easy thumb tap
            Button(action: onToggle) {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.isPurchased ? Color(hex: theme.primaryColor) : Color(hex: theme.textSecondary))
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .strikethrough(item.isPurchased)
                    .foregroundColor(item.isPurchased ? Color(hex: theme.textSecondary).opacity(0.8) : Color(hex: theme.textColor))
                Text("\(categoryDisplay) • \(whereToBuyDisplay)")
                    .font(.caption)
                    .foregroundColor(item.isPurchased ? Color(hex: theme.textSecondary).opacity(0.7) : Color(hex: theme.textSecondary))
                    .strikethrough(item.isPurchased)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        .listRowBackground(Color(hex: theme.cardBackground))
        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
    }
}
