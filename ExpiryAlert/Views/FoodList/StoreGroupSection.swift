import SwiftUI

/// Collapsible section grouped by store (where to buy). Store name is the section header;
/// "Undecided" is used when whereToBuy is nil/empty. Keeps shopping list scannable by location.
struct StoreGroupSection<RowContent: View>: View {
    @EnvironmentObject var themeManager: ThemeManager

    let storeName: String
    let items: [ShoppingItem]
    @Binding var isExpanded: Bool
    @ViewBuilder let rowContent: (ShoppingItem) -> RowContent

    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(items) { item in
                rowContent(item)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "storefront")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: theme.subtitleOnCard))
                Text(storeName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .accentColor(Color(hex: theme.primaryColor))
        .listRowBackground(Color(hex: theme.cardBackground))
    }
}
