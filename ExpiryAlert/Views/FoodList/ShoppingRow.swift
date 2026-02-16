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
            if !item.isPurchased {
                Image(systemName: "line.3.horizontal")
                    .font(.body)
                    .foregroundColor(Color(hex: theme.subtitleOnCard))
            }
            // Large checkbox for easy thumb tap
            Button(action: onToggle) {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.isPurchased ? Color(hex: theme.primaryColor) : Color(hex: theme.subtitleOnCard))
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .strikethrough(item.isPurchased)
                    .foregroundColor(item.isPurchased ? Color(hex: theme.subtitleOnCard).opacity(0.9) : Color(hex: theme.textColor))
                Text("\(categoryDisplay) • \(whereToBuyDisplay)")
                    .font(.caption)
                    .foregroundColor(item.isPurchased ? Color(hex: theme.subtitleOnCard).opacity(0.8) : Color(hex: theme.subtitleOnCard))
                    .strikethrough(item.isPurchased)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !item.isPurchased {
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        Text(localizationManager.t("common.edit"))
                            .font(.caption)
                    }
                    .foregroundColor(Color(hex: theme.primaryColor))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: theme.primaryColor).opacity(0.12))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            } else if item.movedToInventory != true {
                Button(action: onAddToInventory) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.caption)
                        Text(localizationManager.t("list.addToInventory"))
                            .font(.caption)
                    }
                    .foregroundColor(Color(hex: theme.primaryColor))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: theme.primaryColor).opacity(0.12))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        .listRowBackground(Color(hex: theme.cardBackground))
        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
    }
}
