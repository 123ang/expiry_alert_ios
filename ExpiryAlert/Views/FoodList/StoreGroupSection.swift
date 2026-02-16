import SwiftUI

/// Collapsible section grouped by store (where to buy). Store name is the section header;
/// Unbought items first (reorderable), then bought items at bottom.
struct StoreGroupSection<RowContent: View>: View {
    @EnvironmentObject var themeManager: ThemeManager

    let storeName: String
    let items: [ShoppingItem]
    @Binding var isExpanded: Bool
    var onMoveUnbought: ((IndexSet, Int) -> Void)?
    @ViewBuilder let rowContent: (ShoppingItem) -> RowContent

    private var theme: AppTheme { themeManager.currentTheme }
    private var unboughtItems: [ShoppingItem] { items.filter { !$0.isPurchased } }
    private var boughtItems: [ShoppingItem] { items.filter { $0.isPurchased } }

    private var unboughtRows: some View {
        ForEach(unboughtItems) { item in rowContent(item) }
            .onMove { source, dest in onMoveUnbought?(source, dest) }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            unboughtRows
            ForEach(boughtItems) { item in
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
