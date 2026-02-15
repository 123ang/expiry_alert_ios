import SwiftUI

/// Sticky header for Lists screen: title "Lists", segmented Shopping | Wishlist, and Add button.
/// Add opens a sheet (handled by parent). selectedTab: 0 = Shopping, 1 = Wishlist.
struct ListTabsHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager

    let selectedTab: Int
    let onTabChange: (Int) -> Void
    let onAddTap: () -> Void

    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(localizationManager.t("list.title"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
                Button(action: onAddTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.semibold))
                        Text(localizationManager.t("list.add"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: theme.primaryColor))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            HStack(spacing: 4) {
                ForEach(0..<2, id: \.self) { index in
                    let isShopping = index == 0
                    let isSelected = selectedTab == index
                    Button(action: { onTabChange(index) }) {
                        Text(isShopping ? localizationManager.t("shoppingList.shopping") : localizationManager.t("shoppingList.wishlist"))
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .medium)
                            .foregroundColor(isSelected ? .white : Color(hex: theme.subtitleOnCard))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color(hex: theme.primaryColor) : Color(hex: theme.cardBackground))
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(Color(hex: theme.backgroundColor))
    }
}
