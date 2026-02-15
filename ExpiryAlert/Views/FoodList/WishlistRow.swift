import SwiftUI

/// Wishlist row: name, price, desire level 1–5; single Remove action. Swipe for Delete / Edit.
struct WishlistRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager

    let item: WishItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onRemove: () -> Void

    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: theme.textColor))
                if let price = item.price {
                    Text("\(item.currencySymbol)\(String(format: "%.2f", price))")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: theme.subtitleOnCard))
                }
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { level in
                        Image(systemName: level <= item.desireLevel ? "heart.fill" : "heart")
                            .font(.system(size: 12))
                            .foregroundColor(level <= item.desireLevel ? Color(red: 0.91, green: 0.22, blue: 0.39) : Color(hex: theme.subtitleOnCard).opacity(0.35))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onRemove) {
                Label(localizationManager.t("wishList.remove"), systemImage: "trash")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: theme.dangerColor))
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        .listRowBackground(Color(hex: theme.cardBackground))
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}
