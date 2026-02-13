import SwiftUI

struct FoodListView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var listMode: ListMode = .shopping
    @State private var newItemText = ""
    @State private var newItemQuantity = 1
    @State private var newItemPrice = ""
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
                
                // Add item form
                VStack(spacing: 12) {
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
                    
                    HStack(spacing: 12) {
                        // Quantity stepper
                        HStack(spacing: 8) {
                            Button(action: { if newItemQuantity > 1 { newItemQuantity -= 1 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(Color(hex: theme.textSecondary))
                            }
                            Text("\(newItemQuantity)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: theme.textColor))
                                .frame(minWidth: 30)
                            Button(action: { newItemQuantity += 1 }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Color(hex: theme.primaryColor))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: theme.cardBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                        )
                        
                        // Price field for wish list
                        if listMode == .wish {
                            HStack {
                                Text("$")
                                    .foregroundColor(Color(hex: theme.textSecondary))
                                TextField("Price", text: $newItemPrice)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(Color(hex: theme.textColor))
                            }
                            .padding(12)
                            .background(Color(hex: theme.cardBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                            )
                        }
                        
                        Spacer()
                    }
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
        VStack(spacing: 0) {
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
                                    .font(.title3)
                                    .foregroundColor(item.isPurchased ? Color(hex: theme.primaryColor) : Color(hex: theme.textSecondary))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .strikethrough(item.isPurchased)
                                    .foregroundColor(Color(hex: theme.textColor))
                                if item.quantity > 1 {
                                    Text("Quantity: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: theme.textSecondary))
                                }
                            }
                            
                            Spacer()
                            
                            // Edit and Delete buttons
                            Button(action: {}) {
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: theme.primaryColor))
                            }
                            Button(action: {
                                Task { try? await dataStore.deleteShoppingItem(id: item.id) }
                            }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: theme.dangerColor))
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color(hex: theme.cardBackground))
                    }
                }
                .listStyle(.plain)
                
                // Clear completed button
                if dataStore.shoppingItems.contains(where: { $0.isPurchased }) {
                    Button(action: clearCompletedShoppingItems) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Clear Completed")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: theme.primaryColor))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: theme.primaryColor).opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
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
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .foregroundColor(Color(hex: theme.textColor))
                                if let price = item.price {
                                    Text("$\(String(format: "%.2f", price))")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: theme.primaryColor))
                                }
                                if let rating = item.rating, rating > 0 {
                                    HStack(spacing: 2) {
                                        ForEach(0..<rating, id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                                .font(.caption2)
                                                .foregroundColor(Color(hex: theme.warningColor))
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Edit and Delete buttons
                            Button(action: {}) {
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: theme.primaryColor))
                            }
                            Button(action: {
                                Task { try? await dataStore.deleteWishItem(id: item.id) }
                            }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: theme.dangerColor))
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color(hex: theme.cardBackground))
                    }
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
                    try await dataStore.createShoppingItem([
                        "group_id": groupId,
                        "name": name,
                        "quantity": newItemQuantity
                    ])
                } else {
                    var params: [String: Any] = ["group_id": groupId, "name": name]
                    if let price = Double(newItemPrice) {
                        params["price"] = price
                    }
                    try await dataStore.createWishItem(params)
                }
                // Reset form
                newItemQuantity = 1
                newItemPrice = ""
            } catch {
                // Could show error
            }
            isAdding = false
        }
    }
    
    private func clearCompletedShoppingItems() {
        guard let groupId = dataStore.activeGroupId else { return }
        Task {
            try? await dataStore.clearPurchasedShoppingItems(groupId: groupId)
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
