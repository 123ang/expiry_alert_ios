import SwiftUI

struct CategoriesManagementView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var showAddSheet = false
    @State private var editingCategory: Category?
    @State private var newName = ""
    @State private var newIcon = "🍽️"
    @State private var showDeleteAlert = false
    @State private var categoryToDelete: Category?
    @State private var showThemeSetup = false
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    /// Groups categories by section (from DB) for display; preserves sort order.
    private var categoriesBySection: [(section: String, items: [Category])] {
        var result: [(String, [Category])] = []
        var currentSection = ""
        var currentItems: [Category] = []
        for c in dataStore.categories {
            let sec = c.section ?? ""
            if sec != currentSection {
                if !currentItems.isEmpty { result.append((currentSection, currentItems)) }
                currentSection = sec
                currentItems = [c]
            } else {
                currentItems.append(c)
            }
        }
        if !currentItems.isEmpty { result.append((currentSection, currentItems)) }
        return result
    }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            List {
                if dataStore.categories.isEmpty, let err = dataStore.error {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundColor(Color(hex: theme.warningColor))
                            Text("Couldn't load categories")
                                .font(.headline)
                                .foregroundColor(Color(hex: theme.textColor))
                            Text(err)
                                .font(.caption)
                                .foregroundColor(Color(hex: theme.textSecondary))
                                .multilineTextAlignment(.center)
                            Button("Retry") {
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
                ForEach(Array(categoriesBySection.enumerated()), id: \.offset) { _, pair in
                    Section(header: sectionHeader(pair.section)) {
                        ForEach(pair.items) { category in
                            categoryRow(category)
                                .listRowBackground(Color(hex: theme.cardBackground))
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(localizationManager.t("categories.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showThemeSetup = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                            .font(.subheadline)
                        Text("Quick Setup")
                            .font(.subheadline)
                    }
                    .foregroundColor(Color(hex: theme.primaryColor))
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
        .onAppear { Task { await dataStore.refreshCategories() } }
        .alert(localizationManager.t("action.delete"), isPresented: $showDeleteAlert) {
            Button(localizationManager.t("common.cancel"), role: .cancel) {}
            Button(localizationManager.t("action.delete"), role: .destructive) {
                if let cat = categoryToDelete {
                    Task { try? await dataStore.deleteCategory(id: cat.id) }
                }
            }
        }
        .sheet(isPresented: $showThemeSetup) {
            ThemeSetupModal()
        }
        .onChange(of: showThemeSetup) { _, isShowing in
            if !isShowing { Task { await dataStore.refreshCategories() } }
        }
        .refreshable {
            await dataStore.refreshCategories()
        }
    }
    
    @ViewBuilder
    private func sectionHeader(_ section: String) -> some View {
        if section.isEmpty {
            EmptyView()
        } else {
            Text(section)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: theme.textSecondary))
        }
    }
    
    private func categoryRow(_ category: Category) -> some View {
        HStack(spacing: 12) {
            Text(category.icon ?? "🍽️")
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color(hex: theme.primaryColor).opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(localizationManager.getCategoryName(category))
                    .foregroundColor(Color(hex: theme.textColor))
                if category.isDefault == true {
                    Text("Default")
                        .font(.caption2)
                        .foregroundColor(Color(hex: theme.textSecondary))
                }
            }
            
            Spacer()
            
            if category.isDefault != true {
                Button(action: {
                    editingCategory = category
                    newName = category.name
                    newIcon = category.icon ?? "🍽️"
                    showAddSheet = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
                
                Button(action: {
                    categoryToDelete = category
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(Color(hex: theme.dangerColor))
                }
            }
        }
    }
    
    private var addEditSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField(localizationManager.t("categoryName"), text: $newName)
                    .textFieldStyle(ThemedTextFieldStyle(theme: theme))
                
                VStack(alignment: .leading) {
                    Text("Icon")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: theme.textSecondary))
                    
                    // Icons from DB seed + extras for custom categories
                    let emojis = [
                        // Food & Drinks
                        "🥬", "🍱", "🍪", "🥤", "🧊", "🥛", "🥩", "🍎", "🥕", "🍞", "🫙", "🧂", "🥫", "🍼",
                        // Health
                        "💊", "💉", "🩹", "🩺",
                        // Personal Care
                        "🧴", "💄", "💇", "🧼", "🌸", "🪥",
                        // Home
                        "🧹", "🧺", "📦", "🔋", "💡", "💨",
                        // Documents
                        "🛂", "📇", "🪪", "📋", "📄", "🧾", "📑", "📜", "🎫",
                        // Pets
                        "🐕", "🦴",
                        // Others & extras
                        "📱", "✏️", "🍕", "🍔", "🌮", "🥗", "🍜", "🥚", "🌽", "🍰", "🍿", "🐟",
                    ]
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
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
                        }
                    }
                }
                
                Spacer()
            }
            .padding(20)
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
}
