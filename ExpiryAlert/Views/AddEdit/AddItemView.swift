import SwiftUI
import PhotosUI

struct AddItemView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    var prefilledDate: Date?
    var editingItem: FoodItem?
    /// Prefill name when opening from "Add to Inventory" (shopping list).
    var prefilledName: String?
    /// Prefill category when opening from "Add to Inventory".
    var prefilledCategoryId: String?
    /// Called with the new inventory item id when saved from "Add to Inventory" flow.
    var onSavedInventoryItemId: ((String) -> Void)?
    
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
    @State private var categorySearchText = ""
    @State private var locationSearchText = ""
    @State private var showCategoryPicker = false
    @State private var showLocationPicker = false
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    private var appLocale: Locale {
        switch localizationManager.currentLanguage {
        case .en: return Locale(identifier: "en_US")
        case .ja: return Locale(identifier: "ja_JP")
        case .ms: return Locale(identifier: "ms_MY")
        case .th: return Locale(identifier: "th_TH")
        case .zh: return Locale(identifier: "zh_Hans")
        }
    }
    
    private var selectedCategoryName: String {
        guard let id = selectedCategoryId,
              let cat = dataStore.displayCategories.first(where: { $0.id == id }) else { return localizationManager.t("common.none") }
        return localizationManager.getCategoryName(cat)
    }
    
    private var selectedLocationName: String {
        guard let id = selectedLocationId,
              let loc = dataStore.locations.first(where: { $0.id == id }) else { return "" }
        return localizationManager.getLocationDisplayName(loc)
    }
    private var isEditing: Bool { editingItem != nil }
    
    var body: some View {
        NavigationStack {
            addItemFormContent
                .navigationTitle(isEditing ? localizationManager.t("addItem.editTitle") : localizationManager.t("addItem.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }, label: {
                        Text(localizationManager.t("common.cancel"))
                    })
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { handleSave() }, label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(localizationManager.t("form.save"))
                                .fontWeight(.bold)
                        }
                    })
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
            .alert(localizationManager.t("alert.error"), isPresented: $showError) {
                Button(localizationManager.t("common.ok"), role: .cancel, action: {})
            } message: {
                Text(errorMessage)
            }
            .environment(\.locale, appLocale)
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerSheet(
                    selectedCategoryId: $selectedCategoryId,
                    searchText: $categorySearchText,
                    onDismiss: { showCategoryPicker = false }
                )
                .environmentObject(dataStore)
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerSheet(
                    selectedLocationId: $selectedLocationId,
                    searchText: $locationSearchText,
                    onDismiss: { showLocationPicker = false }
                )
                .environmentObject(dataStore)
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
            }
        }
    }
    
    private var addItemFormContent: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    FormField(label: localizationManager.t("addItem.itemName"), theme: theme) {
                        ThemedTextField(placeholder: localizationManager.t("addItem.itemNamePlaceholder"), text: $itemName, theme: theme)
                    }
                    FormField(label: localizationManager.t("addItem.quantity"), theme: theme) {
                        ThemedTextField(placeholder: localizationManager.t("addItem.quantityPlaceholder"), text: $quantity, theme: theme, keyboardType: .numberPad)
                            .keyboardType(.numberPad)
                    }
                    FormField(label: localizationManager.t("form.photo"), theme: theme) {
                        addItemPhotoSection
                    }
                    FormField(label: localizationManager.t("addItem.category"), theme: theme) {
                        categoryFieldButton
                    }
                    FormField(label: localizationManager.t("addItem.storageLocation"), theme: theme) {
                        locationFieldButton
                    }
                    FormField(label: localizationManager.t("addItem.expiryDate"), theme: theme) {
                        DatePicker("", selection: $expiryDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(Color(hex: theme.primaryColor))
                            .foregroundColor(Color(hex: theme.textColor))
                            .padding()
                            .background(Color(hex: theme.cardBackground))
                            .cornerRadius(12)
                    }
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
    }
    
    private var addItemPhotoSection: some View {
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
    
    private var categoryFieldButtonLabel: some View {
        HStack(spacing: 12) {
            ZStack {
                if selectedCategoryId == nil {
                    Image(systemName: "tag.fill")
                        .font(.title3)
                } else {
                    Text(dataStore.displayCategories.first(where: { $0.id == selectedCategoryId })?.icon ?? "🍽️")
                        .font(.title3)
                }
            }
            .frame(width: 32, height: 32)
            .background(Color(hex: theme.primaryColor).opacity(0.12))
            .clipShape(Circle())
            Text(selectedCategoryId == nil ? localizationManager.t("common.tapToChoose") : selectedCategoryName)
                .font(.subheadline)
                .foregroundColor(selectedCategoryId == nil ? Color(hex: theme.placeholderColor) : Color(hex: theme.textColor))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(hex: theme.placeholderColor))
        }
        .padding(12)
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
        )
    }
    
    private var categoryFieldButton: some View {
        Button(action: { showCategoryPicker = true }, label: { categoryFieldButtonLabel })
            .buttonStyle(PlainButtonStyle())
    }
    
    private var locationFieldButtonLabel: some View {
        HStack(spacing: 12) {
            Text(selectedLocationId == nil ? "📍" : (dataStore.locations.first(where: { $0.id == selectedLocationId })?.icon ?? "📍"))
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color(hex: theme.primaryColor).opacity(0.12))
                .clipShape(Circle())
            Text(selectedLocationName.isEmpty ? localizationManager.t("common.tapToChoose") : selectedLocationName)
                .font(.subheadline)
                .foregroundColor(selectedLocationName.isEmpty ? Color(hex: theme.placeholderColor) : Color(hex: theme.textColor))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(hex: theme.placeholderColor))
        }
        .padding(12)
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
        )
    }
    
    private var locationFieldButton: some View {
        Button(action: { showLocationPicker = true }, label: { locationFieldButtonLabel })
            .buttonStyle(PlainButtonStyle())
    }
    
    private func setupInitialValues() {
        if let date = prefilledDate {
            expiryDate = date
        }
        if let name = prefilledName, !name.isEmpty {
            itemName = name
        }
        if let catId = prefilledCategoryId {
            selectedCategoryId = catId
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
                    let created = try await dataStore.createFoodItem(itemData)
                    onSavedInventoryItemId?(created.id)
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

// MARK: - Category Picker Sheet (pop-up)
struct CategoryPickerSheet: View {
    @Binding var selectedCategoryId: String?
    @Binding var searchText: String
    let onDismiss: () -> Void
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var expandedSections: Set<String> = []
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    private func isBeverageCategory(_ category: Category) -> Bool {
        let key = (category.translationKey ?? "").lowercased()
        let name = category.name.lowercased()
        return key.contains("drink") || name.contains("beverage") || name.contains("drink")
    }
    
    private func normalizedCategorySection(for category: Category) -> String {
        let sec = category.section ?? ""
        let t = sec.trimmingCharacters(in: .whitespaces).lowercased()
        let isCustomizationGroup = t.isEmpty || t == "other" || t == "food & drinks" || t == "food and drinks"
        if isCustomizationGroup {
            return isBeverageCategory(category) ? "Beverages" : "Food"
        }
        return sec.isEmpty ? "Other" : sec
    }
    
    private let customizationSectionKeys = ["Food", "Beverages"]
    private let customizeSectionKey = "Customize"
    
    private func localizedSectionTitle(_ section: String) -> String {
        let key: String
        switch section.trimmingCharacters(in: .whitespaces).lowercased() {
        case "food": key = "section.food"
        case "beverages": key = "section.beverages"
        case "other": key = "section.other"
        case "health": key = "section.health"
        case "personal care": key = "section.personalCare"
        case "home": key = "section.home"
        case "documents": key = "section.documents"
        case "pets": key = "section.pets"
        case "others": key = "section.others"
        default: return section
        }
        let translated = localizationManager.t(key)
        return translated != key ? translated : section
    }
    
    private func isCustomizationCategory(_ category: Category) -> Bool {
        if let custom = category.isCustomization { return custom }
        return category.isDefault != true
    }
    
    private var categoriesBySection: [(section: String, items: [Category])] {
        let term = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        var list = localizationManager.deduplicatedCategories(dataStore.visibleDisplayCategories)
        if !term.isEmpty {
            list = list.filter { localizationManager.getCategoryName($0).lowercased().contains(term) }
        }
        let customItems = list.filter { isCustomizationCategory($0) }
        let rest = list.filter { !isCustomizationCategory($0) }
        var map: [String: [Category]] = [:]
        for c in rest {
            let key = normalizedCategorySection(for: c)
            map[key, default: []].append(c)
        }
        var order: [String] = []
        for c in rest {
            let key = normalizedCategorySection(for: c)
            if !order.contains(key) { order.append(key) }
        }
        let head = customizationSectionKeys.filter { order.contains($0) }
        let tail = order.filter { !customizationSectionKeys.contains($0) }
        let reordered = head + tail
        let otherSections = reordered.map { (section: $0, items: map[$0] ?? []) }
        return [(section: customizeSectionKey, items: customItems)] + otherSections
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 12) {
                    ThemedTextField(placeholder: localizationManager.t("categories.searchPlaceholder"), text: $searchText, theme: theme)
                        .padding(.horizontal)
                    
                    if localizationManager.deduplicatedCategories(dataStore.visibleDisplayCategories).isEmpty {
                        Text(localizationManager.t("categories.noCategoriesHint"))
                            .font(.subheadline)
                            .foregroundColor(Color(hex: theme.textSecondary))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(32)
                    } else {
                    List {
                        ForEach(Array(categoriesBySection.enumerated()), id: \.offset) { _, pair in
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedSections.contains(pair.section) },
                                    set: { expanded in
                                        if expanded { expandedSections.insert(pair.section) }
                                        else { expandedSections.remove(pair.section) }
                                    }
                                ),
                                content: {
                                    ForEach(pair.items) { category in
                                        Button(action: {
                                            selectedCategoryId = category.id
                                            onDismiss()
                                            dismiss()
                                        }, label: {
                                            rowContent(
                                                icon: category.icon ?? "🍽️",
                                                name: localizationManager.getCategoryName(category),
                                                isSelected: selectedCategoryId == category.id
                                            )
                                        })
                                        .buttonStyle(PlainButtonStyle())
                                        .listRowBackground(Color(hex: theme.cardBackground))
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    }
                                },
                                label: {
                                    let sectionTitle = pair.section == customizeSectionKey
                                        ? localizationManager.t("common.sectionCustomize")
                                        : (pair.section.isEmpty ? " " : localizedSectionTitle(pair.section))
                                    HStack(spacing: 8) {
                                        Text(sectionTitle)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Color(hex: theme.textSecondary))
                                            .textCase(.uppercase)
                                        Text("\(pair.items.count)")
                                            .font(.caption)
                                            .foregroundColor(Color(hex: theme.textSecondary).opacity(0.8))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(hex: theme.borderColor).opacity(0.5))
                                            .cornerRadius(6)
                                    }
                                    .padding(.vertical, 4)
                                }
                            )
                            .listRowBackground(Color(hex: theme.cardBackground))
                        }
                        Section {
                            NavigationLink(destination: CategoriesManagementView()) {
                                HStack(spacing: 10) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.body)
                                        .foregroundColor(Color(hex: theme.textSecondary))
                                    Text(localizationManager.t("settings.manageCategories"))
                                        .font(.subheadline)
                                        .foregroundColor(Color(hex: theme.textSecondary))
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color(hex: theme.cardBackground))
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    }
                }
                .padding(.top, 8)
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                    expandedSections = []
                } else {
                    expandedSections = Set(categoriesBySection.map(\.section))
                }
            }
            .navigationTitle(localizationManager.t("categories.chooseTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onDismiss()
                        dismiss()
                    }, label: {
                        Text(localizationManager.t("common.close"))
                    })
                    .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
        }
    }
    
    private func rowContent(icon: String, name: String, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color(hex: theme.primaryColor).opacity(0.12))
                .clipShape(Circle())
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: theme.textColor))
                .lineLimit(1)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: theme.primaryColor))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Location Picker Sheet (pop-up)
struct LocationPickerSheet: View {
    @Binding var selectedLocationId: String?
    @Binding var searchText: String
    let onDismiss: () -> Void
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var expandedSections: Set<String> = []
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    /// Match LocationsManagementView: Fridge (merged) → Kitchen; empty/other → Other.
    private func sectionKey(for location: Location) -> String {
        if DataStore.isFridgeVariant(location) { return "Kitchen" }
        let t = (location.section ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        if t.isEmpty || t == "other" { return "Other" }
        return location.section ?? "Other"
    }
    
    private let otherSectionKey = "Other"
    private let customizeSectionKey = "Customize"
    
    /// User-added locations only (same as Manage Locations).
    private func isCustomizationLocation(_ location: Location) -> Bool {
        if let custom = location.isCustomization { return custom }
        return location.isDefault != true
    }
    
    private var customizeLocations: [Location] {
        dataStore.visibleDisplayLocations.filter { isCustomizationLocation($0) }
    }
    
    private func localizedLocationSectionTitle(_ section: String) -> String {
        if section == customizeSectionKey { return localizationManager.t("common.sectionCustomize") }
        if section.isEmpty || section == otherSectionKey { return localizationManager.t("locations.sectionOther") }
        let key: String
        switch section.trimmingCharacters(in: .whitespaces).lowercased() {
        case "kitchen": key = "section.kitchen"
        case "home storage": key = "section.homeStorage"
        case "bathroom": key = "section.bathroom"
        case "office": key = "section.office"
        case "travel": key = "section.travel"
        default: return section
        }
        let translated = localizationManager.t(key)
        return translated != key ? translated : section
    }
    
    /// Same grouping as LocationsManagementView: Customize (user-added only), then sections by sectionKey (Fridge → Kitchen).
    private var locationsBySection: [(section: String, items: [Location])] {
        let term = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        var list = dataStore.visibleDisplayLocations
        if !term.isEmpty {
            list = list.filter { localizationManager.getLocationDisplayName($0).lowercased().contains(term) }
        }
        let custom = list.filter { isCustomizationLocation($0) }
        let defaultList = list.filter { !isCustomizationLocation($0) }
        var map: [String: [Location]] = [:]
        for loc in defaultList {
            let key = sectionKey(for: loc)
            map[key, default: []].append(loc)
        }
        var order: [String] = []
        for loc in defaultList {
            let key = sectionKey(for: loc)
            if !order.contains(key) { order.append(key) }
        }
        if order.contains("Kitchen") {
            order.removeAll { $0 == "Kitchen" }
            order.insert("Kitchen", at: 0)
        }
        if order.contains(otherSectionKey) {
            order.removeAll { $0 == otherSectionKey }
            order.append(otherSectionKey)
        }
        let otherSections = order.map { (section: $0, items: map[$0] ?? []) }
        return [(section: customizeSectionKey, items: custom)] + otherSections
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 12) {
                    ThemedTextField(placeholder: localizationManager.t("locations.searchPlaceholder"), text: $searchText, theme: theme)
                        .padding(.horizontal)
                    
                    if dataStore.visibleDisplayLocations.isEmpty {
                        Text(localizationManager.t("locations.noLocationsHint"))
                            .font(.subheadline)
                            .foregroundColor(Color(hex: theme.textSecondary))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(32)
                    } else {
                    List {
                        ForEach(Array(locationsBySection.enumerated()), id: \.offset) { _, pair in
                            let sectionTitle = localizedLocationSectionTitle(pair.section)
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedSections.contains(pair.section) },
                                    set: { expanded in
                                        if expanded { expandedSections.insert(pair.section) }
                                        else { expandedSections.remove(pair.section) }
                                    }
                                ),
                                content: {
                                    ForEach(pair.items) { location in
                                        Button(action: {
                                            selectedLocationId = location.id
                                            onDismiss()
                                            dismiss()
                                        }, label: {
                                            HStack(spacing: 12) {
                                                Text(location.icon ?? "📍")
                                                    .font(.title3)
                                                    .frame(width: 32, height: 32)
                                                    .background(Color(hex: theme.primaryColor).opacity(0.12))
                                                    .clipShape(Circle())
                                                Text(localizationManager.getLocationDisplayName(location))
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(Color(hex: theme.textColor))
                                                    .lineLimit(1)
                                                Spacer()
                                                if selectedLocationId == location.id {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.subheadline)
                                                        .foregroundColor(Color(hex: theme.primaryColor))
                                                }
                                            }
                                            .padding(.vertical, 4)
                                            .contentShape(Rectangle())
                                        })
                                        .buttonStyle(PlainButtonStyle())
                                        .listRowBackground(Color(hex: theme.cardBackground))
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    }
                                },
                                label: {
                                    HStack(spacing: 8) {
                                        Text(sectionTitle.isEmpty ? " " : sectionTitle)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Color(hex: theme.textSecondary))
                                            .textCase(.uppercase)
                                        Text("\(pair.items.count)")
                                            .font(.caption)
                                            .foregroundColor(Color(hex: theme.textSecondary).opacity(0.8))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(hex: theme.borderColor).opacity(0.5))
                                            .cornerRadius(6)
                                    }
                                    .padding(.vertical, 4)
                                }
                            )
                            .listRowBackground(Color(hex: theme.cardBackground))
                        }
                        Section {
                            NavigationLink(destination: LocationsManagementView()) {
                                HStack(spacing: 10) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.body)
                                        .foregroundColor(Color(hex: theme.textSecondary))
                                    Text(localizationManager.t("settings.manageLocations"))
                                        .font(.subheadline)
                                        .foregroundColor(Color(hex: theme.textSecondary))
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color(hex: theme.cardBackground))
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    }
                }
                .padding(.top, 8)
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                    expandedSections = []
                } else {
                    expandedSections = Set(locationsBySection.map(\.section))
                }
            }
            .navigationTitle(localizationManager.t("locations.chooseTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onDismiss()
                        dismiss()
                    }, label: {
                        Text(localizationManager.t("common.close"))
                    })
                    .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
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
