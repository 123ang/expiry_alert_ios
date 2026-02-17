import SwiftUI

struct CategoriesManagementView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showAddSheet = false
    @State private var showNoSelectionAlert = false
    @State private var editingCategory: Category?
    @State private var newName = ""
    @State private var newIcon = "🍽️"
    @State private var showDeleteAlert = false
    @State private var categoryToDelete: Category?
    @State private var showDeleteError = false
    @State private var deleteErrorMessage: String?
    @State private var searchText = ""
    /// Section keys that are expanded. Empty set = all expanded (we fill on appear).
    @State private var expandedSections: Set<String> = []
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    /// Whether this category is beverages/drinks (split out from Food).
    private func isBeverageCategory(_ category: Category) -> Bool {
        let key = (category.translationKey ?? "").lowercased()
        let name = category.name.lowercased()
        return key.contains("drink") || name.contains("beverage") || name.contains("drink")
    }
    
    /// Normalizes section: empty/Other/Food & Drinks split into "Food" vs "Beverages"; rest unchanged.
    private func normalizedSection(for category: Category) -> String {
        let sec = category.section ?? ""
        let t = sec.trimmingCharacters(in: .whitespaces).lowercased()
        let isCustomizationGroup = t.isEmpty || t == "other" || t == "food & drinks" || t == "food and drinks"
        if isCustomizationGroup {
            return isBeverageCategory(category) ? "Beverages" : "Food"
        }
        return sec.isEmpty ? "Other" : sec
    }
    
    /// True when edit/remove should be shown: backend sends is_customization == true, or (for backward compatibility) when field is missing and category is non-default.
    private func isCustomizationCategory(_ category: Category) -> Bool {
        if let custom = category.isCustomization { return custom }
        return category.isDefault != true
    }
    
    /// Section keys for the split Food/Beverages, shown first.
    private let customizationSectionKeys = ["Food", "Beverages"]
    /// Section for user-added categories; always first, count 0 if empty.
    private let customizeSectionKey = "Customize"
    
    /// Display categories with duplicate names removed (first occurrence kept).
    private var displayCategoriesDeduplicated: [Category] {
        localizationManager.deduplicatedCategories(dataStore.displayCategories)
    }
    
    /// User-added (customization) categories only (excluding debug).
    private var customizeCategories: [Category] {
        displayCategoriesDeduplicated.filter { isCustomizationCategory($0) }
    }
    
    /// Groups categories by section; Customize first, then Food/Beverages, then rest.
    private var categoriesBySection: [(section: String, items: [Category])] {
        var map: [String: [Category]] = [:]
        for c in displayCategoriesDeduplicated where !isCustomizationCategory(c) {
            let key = normalizedSection(for: c)
            map[key, default: []].append(c)
        }
        var order: [String] = []
        for c in displayCategoriesDeduplicated where !isCustomizationCategory(c) {
            let key = normalizedSection(for: c)
            if !order.contains(key) { order.append(key) }
        }
        let head = customizationSectionKeys.filter { order.contains($0) }
        let tail = order.filter { !customizationSectionKeys.contains($0) }
        let reordered = head + tail
        let otherSections = reordered.map { (section: $0, items: map[$0] ?? []) }
        return [(section: customizeSectionKey, items: customizeCategories)] + otherSections
    }
    
    /// Sections with items filtered by search; Customize always shown (count 0 if no matches).
    private var filteredSections: [(section: String, items: [Category])] {
        let term = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let base = categoriesBySection
        if term.isEmpty { return base }
        return base.map { pair in
            let filtered = pair.items.filter {
                localizationManager.getCategoryName($0).lowercased().contains(term)
            }
            return (pair.section, filtered)
        }
    }
    
    /// Total number of categories currently selected (for display). Empty selection = all count.
    private var selectedCategoryCount: Int {
        displayCategoriesDeduplicated.filter { dataStore.isCategorySelected(id: $0.id) }.count
    }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            VStack(spacing: 0) {
                searchBar
                selectAllBar
                List {
                    errorSection
                    if !searchText.isEmpty && filteredSections.isEmpty {
                        Section {
                            Text("No categories match \"\(searchText)\"")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: theme.textSecondary))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                        .listRowBackground(Color(hex: theme.cardBackground))
                    }
                    ForEach(Array(filteredSections.enumerated()), id: \.offset) { _, pair in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedSections.contains(pair.section) },
                                set: { expanded in
                                    if expanded {
                                        expandedSections.insert(pair.section)
                                    } else {
                                        expandedSections.remove(pair.section)
                                    }
                                }
                            ),
                            content: {
                                ForEach(pair.items) { category in
                                    categoryRow(category)
                                        .listRowBackground(Color(hex: theme.cardBackground))
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                }
                            },
                            label: {
                                sectionHeaderLabel(pair.section, count: pair.items.count, selectedInSection: pair.items.filter { dataStore.isCategorySelected(id: $0.id) }.count)
                            }
                        )
                        .listRowBackground(Color(hex: theme.backgroundColor))
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(localizationManager.t("categories.title"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if dataStore.visibleDisplayCategories.isEmpty {
                        showNoSelectionAlert = true
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    editingCategory = nil
                    newName = ""
                    newIcon = "🍽️"
                    showAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            addEditSheet
        }
        .onAppear {
            expandedSections = []
            Task { await dataStore.refreshCategories() }
        }
        .alert(localizationManager.t("alert.error"), isPresented: $showNoSelectionAlert) {
            Button(localizationManager.t("common.ok"), role: .cancel) {}
            Button(localizationManager.t("manage.leaveAnyway")) { dismiss() }
        } message: {
            Text(localizationManager.t("manage.noCategorySelectedMessage"))
        }
        .alert(localizationManager.t("action.delete"), isPresented: $showDeleteAlert) {
            Button(localizationManager.t("common.cancel"), role: .cancel) {
                categoryToDelete = nil
            }
            Button(localizationManager.t("action.delete"), role: .destructive) {
                guard let cat = categoryToDelete else { return }
                Task {
                    do {
                        try await dataStore.deleteCategory(id: cat.id)
                        categoryToDelete = nil
                    } catch {
                        deleteErrorMessage = error.localizedDescription
                        showDeleteError = true
                    }
                }
            }
        } message: {
            Text(localizationManager.t("action.deleteCategoryConfirm"))
        }
        .alert("Delete failed", isPresented: $showDeleteError) {
            Button(localizationManager.t("common.ok"), role: .cancel) {
                deleteErrorMessage = nil
            }
        } message: {
            if let msg = deleteErrorMessage { Text(msg) }
        }
        .refreshable {
            await dataStore.refreshCategories()
        }
    }
    
    // MARK: - Search
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundColor(Color(hex: theme.textSecondary))
            TextField(localizationManager.t("categories.searchPlaceholder"), text: $searchText)
                .font(.body)
                .foregroundColor(Color(hex: theme.textColor))
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(hex: theme.textSecondary))
                }
            }
        }
        .padding(10)
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var errorSection: some View {
        if displayCategoriesDeduplicated.isEmpty, let err = dataStore.error {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(Color(hex: theme.warningColor))
                    Text(localizationManager.t("categories.loadError"))
                        .font(.headline)
                        .foregroundColor(Color(hex: theme.textColor))
                    Text(err)
                        .font(.caption)
                        .foregroundColor(Color(hex: theme.textSecondary))
                        .multilineTextAlignment(.center)
                    Button(localizationManager.t("categories.retry")) {
                        dataStore.error = nil
                        Task { await dataStore.refreshCategories() }
                    }
                    .foregroundColor(Color(hex: theme.primaryColor))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .listRowBackground(Color(hex: theme.cardBackground))
        }
    }
    
    private func localizedSectionTitle(_ section: String) -> String {
        if section == customizeSectionKey { return localizationManager.t("common.sectionCustomize") }
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
    
    private var selectAllBar: some View {
        HStack(spacing: 12) {
            Button(action: { dataStore.selectAllCategories() }) {
                Text(localizationManager.t("manage.selectAll"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: theme.primaryColor))
            }
            .buttonStyle(PlainButtonStyle())
            Button(action: { dataStore.deselectAllCategories() }) {
                Text(localizationManager.t("manage.deselectAll"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: theme.textSecondary))
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
            Text(localizationManager.t("manage.selectedCount").replacingOccurrences(of: "%@", with: "\(selectedCategoryCount)"))
                .font(.caption)
                .foregroundColor(Color(hex: theme.subtitleOnBackground))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: theme.backgroundColor))
    }
    
    private func sectionHeaderLabel(_ section: String, count: Int, selectedInSection: Int) -> some View {
        let displayName = localizedSectionTitle(section)
        return HStack(spacing: 8) {
            Text(displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: theme.textSecondary))
                .textCase(.uppercase)
                .tracking(0.4)
            if count > 0 {
                Text("\(selectedInSection)/\(count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: theme.primaryColor))
                    .cornerRadius(10)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func categoryRow(_ category: Category) -> some View {
        HStack(spacing: 10) {
            Button(action: { dataStore.toggleCategorySelection(id: category.id) }) {
                Image(systemName: dataStore.isCategorySelected(id: category.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(dataStore.isCategorySelected(id: category.id) ? Color(hex: theme.primaryColor) : Color(hex: theme.textSecondary).opacity(0.5))
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(category.icon ?? "🍽️")
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color(hex: theme.primaryColor).opacity(0.12))
                .clipShape(Circle())
            
            HStack(spacing: 6) {
                Text(localizationManager.getCategoryName(category))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: theme.textColor))
                    .lineLimit(1)
            }
            
            Spacer(minLength: 8)
            
            if isCustomizationCategory(category) {
                Button(action: {
                    editingCategory = category
                    newName = category.name
                    newIcon = category.icon ?? "🍽️"
                    showAddSheet = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
                .buttonStyle(PlainButtonStyle())
                Button(action: {
                    categoryToDelete = category
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: theme.dangerColor))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 2)
    }
    
    private var addEditSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Category name – padded down so it's easy to tap
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.t("categoryName"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: theme.textSecondary))
                        TextField(localizationManager.t("categoryName"), text: $newName)
                            .textFieldStyle(ThemedTextFieldStyle(theme: theme))
                            .padding(.vertical, 4)
                    }
                    .padding(.top, 8)
                    
                    // Icon grid – scrolls with the sheet
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizationManager.t("common.icon"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: theme.textSecondary))
                        
                        let emojis = categoryIconEmojis
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                            ForEach(emojis, id: \.self) { emoji in
                                Button(action: { newIcon = emoji }) {
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            newIcon == emoji
                                            ? Color(hex: theme.primaryColor).opacity(0.2)
                                            : Color(hex: theme.backgroundColor)
                                        )
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    newIcon == emoji ? Color(hex: theme.primaryColor) : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(hex: theme.backgroundColor))
            .navigationTitle(editingCategory != nil ? localizationManager.t("editCategory") : localizationManager.t("addCategory"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.t("common.cancel")) { showAddSheet = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.t("common.save")) {
                        Task {
                            if let cat = editingCategory {
                                try? await dataStore.updateCategory(id: cat.id, name: newName, icon: newIcon)
                            } else {
                                try? await dataStore.createCategory(name: newName, icon: newIcon)
                            }
                            showAddSheet = false
                        }
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    /// Full list of category icons (expiry-alert relevant). Kept in one place for Add/Edit sheet.
    private var categoryIconEmojis: [String] {
        [
            "🥬", "🥕", "🍎", "🍅", "🥒", "🫑", "🥦", "🍇", "🍓", "🍑", "🍒", "🥭", "🍍", "🫐", "🥝", "🍋", "🍊", "🍉", "🫒", "🥑", "🧅", "🥔", "🍄", "🌽", "🌶️", "🫛", "🥜",
            "🥛", "🧀", "🥩", "🍗", "🥓", "🐟", "🦐", "🥚", "🧈", "🍣", "🦑", "🥖",
            "🍦", "🍰", "🧁", "🍩", "🍪", "🍫", "🍬", "🍿", "🍞", "🥐", "🍕", "🍔", "🌮", "🥗", "🍜", "🍱", "🍲", "🥣", "🧆", "🫕", "🥙", "🍳", "🥪", "🌯", "🫔", "🥟", "🍙", "🍘", "🥠", "🍢", "🥮", "🎂", "🧇", "🥞", "🫓",
            "🫙", "🧂", "🥫", "🍼", "🍯", "☕", "🍵", "🥤", "🧊", "🍶", "🍷", "🍺", "🧃", "🧉", "🍹", "🫖",
            "💊", "💉", "🩹", "🩺", "🩸", "🧬", "🩻", "🦷", "👁️",
            "🧴", "💄", "💇", "🧼", "🌸", "🪥", "🪒", "🧽", "🪮", "💅",
            "🧹", "🧺", "📦", "🔋", "💡", "💨", "🗑️", "🧻", "🪣", "🪤", "🧲", "🔌",
            "🛂", "📇", "🪪", "📋", "📄", "🧾", "📑", "📜", "🎫", "📁", "✏️", "📌", "📎", "🗂️", "📂", "💼",
            "🐕", "🐈", "🦴", "🐠", "🐦", "🐹", "🐰", "🦜", "🐢", "🐁",
            "📱", "🖥️", "⌨️", "⚠️", "🔔", "⏰", "🗓️", "📅", "🏷️", "🔖",
        ]
    }
}
