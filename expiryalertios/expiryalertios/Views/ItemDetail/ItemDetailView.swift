import SwiftUI

struct ItemDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    let itemId: String
    
    @State private var item: FoodItem?
    @State private var isLoading = true
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showQuantitySheet = false
    @State private var quantityAction: String = "use"
    @State private var quantityInput = "1"
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            if isLoading {
                ProgressView()
            } else if let item = item {
                ScrollView {
                    VStack(spacing: 0) {
                        // Image / Icon Header
                        ZStack {
                            Color(hex: theme.cardBackground)
                            
                            VStack(spacing: 12) {
                                if let icon = item.categoryIcon, !icon.isEmpty {
                                    Text(icon)
                                        .font(.system(size: 60))
                                } else if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 48))
                                        .foregroundColor(Color(hex: theme.primaryColor))
                                }
                                
                                Text(item.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: theme.textColor))
                                
                                // Status Badge
                                statusBadge(item: item)
                            }
                            .padding(.vertical, 24)
                        }
                        
                        // Details
                        VStack(spacing: 12) {
                            detailRow(icon: "📅", label: localizationManager.t("item.expiryDate"), value: item.expiryDateFormatted)
                            detailRow(icon: "📦", label: localizationManager.t("item.quantity"), value: "\(item.quantity)")
                            if let catName = item.categoryName {
                                detailRow(icon: item.categoryIcon ?? "🏷️", label: localizationManager.t("item.category"), value: catName)
                            }
                            if let locName = item.locationName {
                                detailRow(icon: item.locationIcon ?? "📍", label: localizationManager.t("item.location"), value: locName)
                            }
                            if let notes = item.notes, !notes.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(localizationManager.t("item.notes"))
                                        .font(.headline)
                                        .foregroundColor(Color(hex: theme.textColor))
                                    Text(notes)
                                        .foregroundColor(Color(hex: theme.textSecondary))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(hex: theme.cardBackground))
                                .cornerRadius(12)
                            }
                        }
                        .padding(16)
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button(action: { quantityAction = "use"; showQuantitySheet = true }) {
                                Label(localizationManager.t("item.useItem"), systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: theme.successColor))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: { quantityAction = "throw"; showQuantitySheet = true }) {
                                Label(localizationManager.t("item.throwAway"), systemImage: "trash.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: theme.dangerColor))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            } else {
                VStack {
                    Text("⚠️").font(.system(size: 48))
                    Text("Item not found")
                        .foregroundColor(Color(hex: theme.textSecondary))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: { showEditSheet = true }) {
                        Image(systemName: "pencil")
                    }
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(Color(hex: theme.dangerColor))
                    }
                }
            }
        }
        .task { await loadItem() }
        .sheet(isPresented: $showEditSheet) {
            if let item = item {
                AddItemView(editingItem: item)
            }
        }
        .alert(localizationManager.t("alert.deleteTitle"), isPresented: $showDeleteAlert) {
            Button(localizationManager.t("common.cancel"), role: .cancel) {}
            Button(localizationManager.t("action.delete"), role: .destructive) { deleteItem() }
        } message: {
            Text("\(localizationManager.t("alert.deleteMessage")) \"\(item?.name ?? "")\"?")
        }
        .sheet(isPresented: $showQuantitySheet) {
            quantitySheet
        }
    }
    
    // MARK: - Status Badge
    private func statusBadge(item: FoodItem) -> some View {
        let days = item.daysUntilExpiry ?? 0
        let text: String
        let color: String
        
        if days < 0 {
            text = "\(abs(days)) \(localizationManager.t("item.expiredDays"))"
            color = theme.dangerColor
        } else if days == 0 {
            text = localizationManager.t("item.expirestoday")
            color = theme.dangerColor
        } else if days <= 5 {
            text = "\(days) \(localizationManager.t("item.daysLeft"))"
            color = theme.warningColor
        } else {
            text = "\(days) \(localizationManager.t("item.daysLeft"))"
            color = theme.successColor
        }
        
        return HStack {
            Image(systemName: item.status.icon)
            Text(text)
                .fontWeight(.semibold)
        }
        .foregroundColor(Color(hex: color))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(hex: color).opacity(0.15))
        .cornerRadius(20)
    }
    
    // MARK: - Detail Row
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Text(icon)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(Color(hex: theme.primaryColor).opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Color(hex: theme.textSecondary))
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: theme.textColor))
            }
            Spacer()
        }
        .padding()
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Quantity Sheet
    private var quantitySheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(quantityAction == "use"
                     ? localizationManager.t("item.useQuantity")
                     : localizationManager.t("item.throwQuantity"))
                    .font(.headline)
                
                TextField("1", text: $quantityInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(ThemedTextFieldStyle(theme: theme))
                    .multilineTextAlignment(.center)
                    .frame(width: 120)
                
                HStack(spacing: 16) {
                    Button(localizationManager.t("common.cancel")) {
                        showQuantitySheet = false
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: theme.cardBackground))
                    .cornerRadius(8)
                    
                    Button(action: handleQuantityAction) {
                        Text(quantityAction == "use"
                             ? localizationManager.t("item.useItem")
                             : localizationManager.t("item.throwAway"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: quantityAction == "use" ? theme.successColor : theme.dangerColor))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .presentationDetents([.height(250)])
    }
    
    // MARK: - Actions
    private func loadItem() async {
        isLoading = true
        // Try from local cache first
        item = dataStore.foodItems.first { $0.id == itemId }
        if item == nil {
            do {
                item = try await APIService.shared.getFoodItem(id: itemId)
            } catch {}
        }
        isLoading = false
    }
    
    private func deleteItem() {
        Task {
            do {
                try await dataStore.deleteFoodItem(id: itemId)
                dismiss()
            } catch {}
        }
    }
    
    private func handleQuantityAction() {
        let qty = Int(quantityInput) ?? 1
        showQuantitySheet = false
        Task {
            do {
                let eventType = quantityAction == "use" ? "used_partially" : "thrown_away"
                try await dataStore.logFoodItemEvent(
                    itemId: itemId,
                    eventType: eventType,
                    quantity: qty,
                    reason: quantityAction == "throw" ? "other" : nil
                )
                await loadItem()
            } catch {}
        }
    }
}
