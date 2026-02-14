import SwiftUI

/// Wishlist row: name (bold), price (secondary), desire level 1–5 as flame icons.
/// Swipe left Delete, swipe right Edit. Min height 52pt.
struct WishlistRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager

    let item: WishItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: theme.textColor))
                if let price = item.price {
                    Text("\(item.currencySymbol)\(String(format: "%.2f", price))")
                        .font(.caption)
                        .foregroundColor(Color(hex: theme.textSecondary))
                }
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { level in
                        Image(systemName: level <= item.desireLevel ? "flame.fill" : "flame")
                            .font(.caption2)
                            .foregroundColor(level <= item.desireLevel ? Color(hex: theme.warningColor) : Color(hex: theme.textSecondary).opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
        .listRowBackground(Color(hex: theme.cardBackground))
        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
    }
}
