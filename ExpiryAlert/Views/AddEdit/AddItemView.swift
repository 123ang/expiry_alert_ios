import SwiftUI
import PhotosUI

struct AddItemView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    var prefilledDate: Date?
    var editingItem: FoodItem?
    
    @State private var itemName = ""
    @State private var quantity = "1"
    @State private var selectedCategoryId: String?
    @State private var selectedLocationId: String?
    @State private var expiryDate = Date()
    @State private var notes = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    private var theme: AppTheme { themeManager.currentTheme }
    private var isEditing: Bool { editingItem != nil }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Item Name
                        FormField(label: localizationManager.t("addItem.itemName"), theme: theme) {
                            TextField(localizationManager.t("addItem.itemNamePlaceholder"), text: $itemName)
                                .textFieldStyle(ThemedTextFieldStyle(theme: theme))
                        }
                        
                        // Quantity
                        FormField(label: localizationManager.t("addItem.quantity"), theme: theme) {
                            TextField(localizationManager.t("addItem.quantityPlaceholder"), text: $quantity)
                                .textFieldStyle(ThemedTextFieldStyle(theme: theme))
                                .keyboardType(.numberPad)
                        }
                        
                        // Photo
                        FormField(label: localizationManager.t("form.photo"), theme: theme) {
                            VStack {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    HStack {
                                        Image(systemName: "camera.fill")
                                        Text(selectedImage == nil
                                             ? localizationManager.t("image.addPhoto")
                                             : localizationManager.t("image.changePhoto"))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(hex: theme.primaryColor))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Category
                        FormField(label: localizationManager.t("addItem.category"), theme: theme) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                ForEach(dataStore.categories) { category in
                                    Button(action: { selectedCategoryId = category.id }) {
                                        VStack(spacing: 4) {
                                            Text(category.icon ?? "🍽️")
                                                .font(.title2)
                                            Text(localizationManager.getCategoryName(category))
                                                .font(.caption)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(8)
                                        .background(
                                            selectedCategoryId == category.id
                                            ? Color(hex: theme.primaryColor).opacity(0.15)
                                            : Color(hex: theme.cardBackground)
                                        )
                                        .foregroundColor(Color(hex: theme.textColor))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    selectedCategoryId == category.id
                                                    ? Color(hex: theme.primaryColor)
                                                    : Color(hex: theme.borderColor),
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Location
                        FormField(label: localizationManager.t("addItem.storageLocation"), theme: theme) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                ForEach(dataStore.locations) { location in
                                    Button(action: { selectedLocationId = location.id }) {
                                        VStack(spacing: 4) {
                                            Text(location.icon ?? "📍")
                                                .font(.title2)
                                            Text(localizationManager.getLocationName(location))
                                                .font(.caption)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(8)
                                        .background(
                                            selectedLocationId == location.id
                                            ? Color(hex: theme.primaryColor).opacity(0.15)
                                            : Color(hex: theme.cardBackground)
                                        )
                                        .foregroundColor(Color(hex: theme.textColor))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    selectedLocationId == location.id
                                                    ? Color(hex: theme.primaryColor)
                                                    : Color(hex: theme.borderColor),
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Expiry Date
                        FormField(label: localizationManager.t("addItem.expiryDate"), theme: theme) {
                            DatePicker("", selection: $expiryDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(Color(hex: theme.primaryColor))
                                .padding()
                                .background(Color(hex: theme.cardBackground))
                                .cornerRadius(12)
                        }
                        
                        // Notes
                        FormField(label: localizationManager.t("addItem.notes"), theme: theme) {
                            TextEditor(text: $notes)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color(hex: theme.cardBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                                )
                                .foregroundColor(Color(hex: theme.textColor))
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(isEditing ? localizationManager.t("addItem.editTitle") : localizationManager.t("addItem.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.t("common.cancel")) { dismiss() }
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleSave) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(localizationManager.t("form.save"))
                                .fontWeight(.bold)
                        }
                    }
                    .disabled(isSaving)
                    .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
            .onAppear { setupInitialValues() }
            .onChange(of: selectedPhotoItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func setupInitialValues() {
        if let date = prefilledDate {
            expiryDate = date
        }
        if let item = editingItem {
            itemName = item.name
            quantity = "\(item.quantity)"
            selectedCategoryId = item.categoryId
            selectedLocationId = item.locationId
            notes = item.notes ?? ""
            if let dateStr = item.expiryDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                expiryDate = formatter.date(from: String(dateStr.prefix(10))) ?? Date()
            }
        }
    }
    
    private func handleSave() {
        guard !itemName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = localizationManager.t("error.enterItemName")
            showError = true
            return
        }
        guard selectedLocationId != nil else {
            errorMessage = localizationManager.t("error.selectStorageLocation")
            showError = true
            return
        }
        guard let groupId = dataStore.activeGroupId else {
            errorMessage = "No active group selected"
            showError = true
            return
        }
        
        isSaving = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        Task {
            do {
                var itemData: [String: Any] = [
                    "name": itemName.trimmingCharacters(in: .whitespaces),
                    "quantity": Int(quantity) ?? 1,
                    "group_id": groupId,
                    "expiry_date": formatter.string(from: expiryDate)
                ]
                if let catId = selectedCategoryId { itemData["category_id"] = catId }
                if let locId = selectedLocationId { itemData["location_id"] = locId }
                if !notes.isEmpty { itemData["notes"] = notes }
                
                // Upload image if selected
                if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                    let imageUrl = try await APIService.shared.uploadImage(
                        imageData: imageData,
                        filename: "\(UUID().uuidString).jpg"
                    )
                    itemData["image_url"] = imageUrl
                }
                
                if let editItem = editingItem {
                    try await dataStore.updateFoodItem(id: editItem.id, updates: itemData)
                } else {
                    _ = try await dataStore.createFoodItem(itemData)
                }
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isSaving = false
        }
    }
}

// MARK: - Form Field
struct FormField<Content: View>: View {
    let label: String
    let theme: AppTheme
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: theme.textColor))
            content
        }
    }
}
