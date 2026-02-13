import SwiftUI

struct FoodListView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var listMode: ListMode = .shopping
    @State private var newItemText = ""
    @State private var isAdding = false
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    enum ListMode: String, CaseIterable {
        case shopping = "Shopping List"
        case wish = "Wish List"
    }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header: Lists title
                HStack {
                    Text("Lists")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: theme.textColor))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Segment: Shopping List | Wish List
                HStack(spacing: 0) {
                    ForEach(ListMode.allCases, id: \.self) { mode in
                        Button(action: { listMode = mode }) {
                            Text(mode.rawValue)
                                .font(.subheadline)
                                .fontWeight(listMode == mode ? .semibold : .regular)
                                .foregroundColor(listMode == mode ? Color(hex: theme.primaryColor) : Color(hex: theme.textSecondary))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(alignment: .bottom) {
                            if listMode == mode {
                                Rectangle()
                                    .fill(Color(hex: theme.primaryColor))
                                    .frame(height: 3)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Add item row: text field + camera + plus
                HStack(spacing: 12) {
                    TextField("Add item", text: $newItemText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(hex: theme.cardBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                        )
                        .foregroundColor(Color(hex: theme.textColor))
                    
                    Button(action: {}) {
                        Image(systemName: "camera")
                            .font(.title3)
                            .foregroundColor(Color(hex: theme.primaryColor))
                            .frame(width: 44, height: 44)
                    }
                    
                    Button(action: addCurrentItem) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: theme.primaryColor))
                            .clipShape(Circle())
                    }
                    .disabled(newItemText.trimmingCharacters(in: .whitespaces).isEmpty || isAdding)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                // List content
                if listMode == .shopping {
                    shoppingListContent
                } else {
                    wishListContent
                }
            }
        }
        .navigationBarHidden(true)
        .refreshable {
            await dataStore.loadAll()
        }
    }
    
    private var shoppingListContent: some View {
        ZStack {
            if dataStore.shoppingItems.isEmpty {
                emptyStateView(message: "No shopping items yet.\nTap + to add.")
            } else {
                List {
                    ForEach(dataStore.shoppingItems) { item in
                        HStack(spacing: 12) {
                            Button(action: {
                                Task {
                                    try? await dataStore.toggleShoppingItem(id: item.id)
                                }
                            }) {
                                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isPurchased ? Color(hex: theme.primaryColor) : Color(hex: theme.textSecondary))
                            }
                            Text(item.name)
                                .strikethrough(item.isPurchased)
                                .foregroundColor(Color(hex: theme.textColor))
                            if item.quantity > 1 {
                                Text("×\(item.quantity)")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: theme.textSecondary))
                            }
                            Spacer()
                        }
                        .listRowBackground(Color(hex: theme.cardBackground))
                    }
                    .onDelete(perform: deleteShoppingItems)
                }
                .listStyle(.plain)
            }
        }
    }
    
    private var wishListContent: some View {
        ZStack {
            if dataStore.wishItems.isEmpty {
                emptyStateView(message: "No wish items yet.\nTap + to add.")
            } else {
                List {
                    ForEach(dataStore.wishItems) { item in
                        HStack {
                            Text(item.name)
                                .foregroundColor(Color(hex: theme.textColor))
                            Spacer()
                        }
                        .listRowBackground(Color(hex: theme.cardBackground))
                    }
                    .onDelete(perform: deleteWishItems)
                }
                .listStyle(.plain)
            }
        }
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color(hex: theme.textSecondary))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
    
    private func addCurrentItem() {
        let name = newItemText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let groupId = dataStore.activeGroupId else { return }
        newItemText = ""
        isAdding = true
        Task {
            do {
                if listMode == .shopping {
                    try await dataStore.createShoppingItem(["group_id": groupId, "name": name])
                } else {
                    try await dataStore.createWishItem(["group_id": groupId, "name": name])
                }
            } catch {
                // Could show error
            }
            isAdding = false
        }
    }
    
    private func deleteShoppingItems(at offsets: IndexSet) {
        for index in offsets {
            let id = dataStore.shoppingItems[index].id
            Task { try? await dataStore.deleteShoppingItem(id: id) }
        }
    }
    
    private func deleteWishItems(at offsets: IndexSet) {
        for index in offsets {
            let id = dataStore.wishItems[index].id
            Task { try? await dataStore.deleteWishItem(id: id) }
        }
    }
}
