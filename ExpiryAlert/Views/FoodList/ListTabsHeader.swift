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
        VStack(spacing: 0) {
            HStack {
                Text(localizationManager.t("list.title"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
                Button(action: onAddTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text(localizationManager.t("list.add"))
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: theme.primaryColor))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            HStack(spacing: 0) {
                ForEach(0..<2, id: \.self) { index in
                    let isShopping = index == 0
                    Button(action: { onTabChange(index) }) {
                        Text(isShopping ? localizationManager.t("shoppingList.shopping") : localizationManager.t("shoppingList.wishlist"))
                            .font(.subheadline)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .foregroundColor(selectedTab == index ? Color(hex: theme.primaryColor) : Color(hex: theme.textSecondary))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) {
                        if selectedTab == index {
                            Rectangle()
                                .fill(Color(hex: theme.primaryColor))
                                .frame(height: 3)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Color(hex: theme.backgroundColor))
    }
}
