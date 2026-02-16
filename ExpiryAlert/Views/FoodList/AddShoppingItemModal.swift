import SwiftUI

struct AddShoppingItemModal: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.dismiss) var dismiss

    /// When set, modal is in edit mode; otherwise create.
    var editingItem: ShoppingItem?

    @State private var name = ""
    @State private var whereToBuy = ""
    @State private var selectedCategoryId: String?
    @State private var showCategoryPicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var onSaved: (() -> Void)?

    private var theme: AppTheme { themeManager.currentTheme }

    private var selectedCategoryName: String {
        guard let id = selectedCategoryId,
              let cat = dataStore.displayCategories.first(where: { $0.id == id }) else {
            return localizationManager.t("common.tapToChoose")
        }
        return localizationManager.getCategoryName(cat)
    }

    /// Unique "where to buy" values from existing shopping items, sorted, for suggestions.
    private var suggestedWhereToBuy: [String] {
        let used = Set(dataStore.shoppingItems.compactMap { item -> String? in
            let w = item.whereToBuy?.trimmingCharacters(in: .whitespaces)
            return (w != nil && !w!.isEmpty) ? w : nil
        })
        return used.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// Filter suggestions by current input (prefix match); if field empty, show all.
    private var filteredSuggestions: [String] {
        let term = whereToBuy.trimmingCharacters(in: .whitespaces).lowercased()
        if term.isEmpty { return suggestedWhereToBuy }
        return suggestedWhereToBuy.filter { $0.lowercased().hasPrefix(term) || $0.lowercased().contains(term) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
                VStack(spacing: 20) {
                    FormField(label: localizationManager.t("addItem.itemName"), theme: theme, labelColor: theme.titleOnBackground) {
                        ThemedTextField(placeholder: localizationManager.t("addItem.itemNamePlaceholder"), text: $name, theme: theme)
                    }
                    FormField(label: localizationManager.t("list.whereToBuy"), theme: theme, labelColor: theme.titleOnBackground) {
                        VStack(alignment: .leading, spacing: 8) {
                            ThemedTextField(placeholder: localizationManager.t("list.whereToBuyPlaceholder"), text: $whereToBuy, theme: theme)
                            if !filteredSuggestions.isEmpty {
                                Text(localizationManager.t("list.whereToBuySuggestions"))
                                    .font(.caption)
                                    .foregroundColor(Color(hex: theme.subtitleOnBackground))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(filteredSuggestions, id: \.self) { suggestion in
                                            Button(action: { whereToBuy = suggestion }) {
                                                Text(suggestion)
                                                    .font(.caption)
                                                    .foregroundColor(Color(hex: theme.primaryColor))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color(hex: theme.primaryColor).opacity(0.12))
                                                    .cornerRadius(8)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    FormField(label: localizationManager.t("addItem.category"), theme: theme, labelColor: theme.titleOnBackground) {
                        Button(action: { showCategoryPicker = true }, label: {
                            HStack {
                                Text(selectedCategoryName)
                                    .foregroundColor(selectedCategoryId == nil ? Color(hex: theme.placeholderColor) : Color(hex: theme.titleOnBackground))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: theme.subtitleOnBackground))
                            }
                            .padding(12)
                            .background(Color(hex: theme.cardBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                            )
                        })
                        .buttonStyle(PlainButtonStyle())
                    }
                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(Color(hex: theme.dangerColor))
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: theme.backgroundColor), for: .navigationBar)
            .onAppear {
                if let item = editingItem {
                    name = item.name
                    whereToBuy = item.whereToBuy ?? ""
                    selectedCategoryId = item.categoryId
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(editingItem == nil ? localizationManager.t("shoppingList.addItem") : localizationManager.t("common.edit"))
                        .font(.headline)
                        .foregroundColor(Color(hex: theme.titleOnBackground))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.t("common.cancel"), action: { dismiss() })
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.t("common.save"), action: save)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: theme.primaryColor))
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedCategoryId == nil || isSaving)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                SimpleCategoryPickerSheet(selectedCategoryId: $selectedCategoryId, onDismiss: { showCategoryPicker = false })
                    .environmentObject(dataStore)
                    .environmentObject(themeManager)
                    .environmentObject(localizationManager)
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, let categoryId = selectedCategoryId else {
            errorMessage = "Name and category are required."
            return
        }
        errorMessage = nil
        isSaving = true
        Task {
            do {
                if let item = editingItem {
                    var updates: [String: Any] = [
                        "name": trimmedName,
                        "category_id": categoryId
                    ]
                    let wtb = whereToBuy.trimmingCharacters(in: .whitespaces)
                    updates["where_to_buy"] = wtb.isEmpty ? NSNull() : wtb
                    try await dataStore.updateShoppingItem(id: item.id, updates: updates)
                    toastManager.show(localizationManager.t("toast.shoppingItemUpdated"), isError: false)
                } else {
                    guard let groupId = dataStore.activeGroupId else {
                        errorMessage = "No group selected."
                        toastManager.show(errorMessage ?? "No group selected.", isError: true)
                        isSaving = false
                        return
                    }
                    var data: [String: Any] = [
                        "group_id": groupId,
                        "name": trimmedName,
                        "quantity": 1,
                        "category_id": categoryId
                    ]
                    if !whereToBuy.trimmingCharacters(in: .whitespaces).isEmpty {
                        data["where_to_buy"] = whereToBuy.trimmingCharacters(in: .whitespaces)
                    }
                    try await dataStore.createShoppingItem(data)
                    toastManager.show(localizationManager.t("toast.shoppingItemAdded"), isError: false)
                }
                onSaved?()
                dismiss()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                toastManager.show(errorMessage ?? error.localizedDescription, isError: true)
            }
            isSaving = false
        }
    }
}

struct SimpleCategoryPickerSheet: View {
    @Binding var selectedCategoryId: String?
    let onDismiss: () -> Void
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss

    private var theme: AppTheme { themeManager.currentTheme }

    private var categories: [Category] {
        localizationManager.deduplicatedCategories(dataStore.visibleDisplayCategories)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
                List {
                    ForEach(categories) { category in
                        Button(action: {
                            selectedCategoryId = category.id
                            onDismiss()
                            dismiss()
                        }, label: {
                            HStack(spacing: 12) {
                                Text(category.icon ?? "🍽️")
                                    .font(.title3)
                                Text(localizationManager.getCategoryName(category))
                                    .foregroundColor(Color(hex: theme.titleOnBackground))
                                Spacer()
                                if selectedCategoryId == category.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: theme.primaryColor))
                                }
                            }
                            .padding(.vertical, 4)
                        })
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color(hex: theme.cardBackground))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: theme.backgroundColor), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(localizationManager.t("addItem.category"))
                        .font(.headline)
                        .foregroundColor(Color(hex: theme.titleOnBackground))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.t("common.close"), action: {
                        onDismiss()
                        dismiss()
                    })
                    .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
        }
    }
}
