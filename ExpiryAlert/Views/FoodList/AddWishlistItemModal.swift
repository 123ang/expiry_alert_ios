import SwiftUI

private let lastWishlistCurrencyKey = "lastWishlistCurrencyCode"

struct AddWishlistItemModal: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    var editingItem: WishItem?
    
    @State private var name = ""
    @State private var priceText = ""
    @State private var selectedCurrencyCode: String = UserDefaults.standard.string(forKey: lastWishlistCurrencyKey) ?? "USD"
    @State private var desireLevel: Int = 3
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private var selectedCurrency: CurrencyOption {
        CurrencyOption.all.first(where: { $0.code == selectedCurrencyCode }) ?? CurrencyOption.all[0]
    }
    
    var onSaved: (() -> Void)?
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
                VStack(spacing: 20) {
                    FormField(label: localizationManager.t("addItem.itemName"), theme: theme, labelColor: theme.titleOnBackground) {
                        ThemedTextField(placeholder: localizationManager.t("addItem.itemNamePlaceholder"), text: $name, theme: theme)
                    }
                    FormField(label: localizationManager.t("wishList.price"), theme: theme, labelColor: theme.titleOnBackground) {
                        HStack(spacing: 12) {
                            Menu {
                                ForEach(CurrencyOption.all) { currency in
                                    Button(action: {
                                        selectedCurrencyCode = currency.code
                                        UserDefaults.standard.set(currency.code, forKey: lastWishlistCurrencyKey)
                                    }, label: {
                                        HStack {
                                            Text(currency.symbol)
                                            Text(currency.name)
                                            Text("(\(currency.code))")
                                                .foregroundColor(Color(hex: theme.subtitleOnCard))
                                            if selectedCurrencyCode == currency.code {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(Color(hex: theme.primaryColor))
                                            }
                                        }
                                    })
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(selectedCurrency.symbol)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(hex: theme.titleOnBackground))
                                        .frame(minWidth: 32, alignment: .leading)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                        .foregroundColor(Color(hex: theme.subtitleOnBackground))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(hex: theme.cardBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                                )
                            }
                            ThemedTextField(placeholder: "0.00", text: $priceText, theme: theme, keyboardType: .decimalPad)
                        }
                    }
                    FormField(label: localizationManager.t("wishList.desireLevel"), theme: theme, labelColor: theme.titleOnBackground) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { level in
                                    Button(action: { desireLevel = level }, label: {
                                        Text(level == 1 ? "1" : level == 5 ? "5" : "\(level)")
                                            .font(.subheadline)
                                            .fontWeight(desireLevel == level ? .bold : .regular)
                                            .foregroundColor(desireLevel == level ? .white : Color(hex: theme.calendarTextColor))
                                            .frame(width: 44, height: 44)
                                            .background(desireLevel == level ? Color(hex: theme.primaryColor) : Color(hex: theme.cardBackground))
                                            .clipShape(Circle())
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 22)
                                                    .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                                            )
                                    })
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            HStack(spacing: 4) {
                                Text(localizationManager.t("wishList.desireLevelHint").replacingOccurrences(of: "%@", with: "\(desireLevel)"))
                                    .font(.caption)
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(red: 0.91, green: 0.22, blue: 0.39))
                            }
                            .foregroundColor(Color(hex: theme.subtitleOnBackground))
                        }
                        .padding(12)
                        .background(Color(hex: theme.cardBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                        )
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(editingItem == nil ? localizationManager.t("wishList.addItem") : localizationManager.t("wishList.editItem"))
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
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .onAppear {
                if let item = editingItem {
                    name = item.name
                    priceText = item.price.map { String(format: "%.2f", $0) } ?? ""
                    selectedCurrencyCode = item.currencyCode ?? UserDefaults.standard.string(forKey: lastWishlistCurrencyKey) ?? "USD"
                    desireLevel = item.desireLevel
                } else {
                    selectedCurrencyCode = UserDefaults.standard.string(forKey: lastWishlistCurrencyKey) ?? "USD"
                }
            }
        }
    }
    
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, let groupId = dataStore.activeGroupId else {
            errorMessage = "Name is required."
            return
        }
        errorMessage = nil
        isSaving = true
        Task {
            do {
                if let existing = editingItem {
                    var updates: [String: Any] = ["name": trimmedName, "rating": desireLevel, "currency_code": selectedCurrencyCode]
                    let priceTrimmed = priceText.trimmingCharacters(in: .whitespaces)
                    if !priceTrimmed.isEmpty, let p = Double(priceTrimmed) {
                        updates["price"] = p
                    }
                    try await dataStore.updateWishItem(id: existing.id, updates: updates)
                } else {
                    var data: [String: Any] = [
                        "group_id": groupId,
                        "name": trimmedName,
                        "rating": desireLevel,
                        "currency_code": selectedCurrencyCode
                    ]
                    let priceTrimmed = priceText.trimmingCharacters(in: .whitespaces)
                    if !priceTrimmed.isEmpty, let p = Double(priceTrimmed) {
                        data["price"] = p
                    }
                    try await dataStore.createWishItem(data)
                }
                UserDefaults.standard.set(selectedCurrencyCode, forKey: lastWishlistCurrencyKey)
                onSaved?()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
