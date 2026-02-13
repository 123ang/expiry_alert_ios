import SwiftUI

// MARK: - Theme Setup Modal
struct ThemeSetupModal: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategories: Set<String> = []
    @State private var expandedThemes: Set<String> = []
    @State private var isApplying = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var theme: AppTheme { themeManager.currentTheme }
    private var translatedThemes: [TranslatedCategoryTheme] {
        getTranslatedThemes(using: localizationManager)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header info
                    VStack(spacing: 8) {
                        Text("Quick Setup with Themes")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: theme.textColor))
                        Text("Select category themes to add to your collection")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: theme.textSecondary))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Themes list
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(translatedThemes) { theme in
                                ThemeCard(
                                    theme: theme,
                                    isExpanded: expandedThemes.contains(theme.id),
                                    selectedCategories: $selectedCategories,
                                    appTheme: self.theme,
                                    onToggleExpand: {
                                        if expandedThemes.contains(theme.id) {
                                            expandedThemes.remove(theme.id)
                                        } else {
                                            expandedThemes.insert(theme.id)
                                        }
                                    },
                                    onToggleAll: {
                                        let allKeys = theme.categories.map { $0.translationKey }
                                        let allSelected = allKeys.allSatisfy { selectedCategories.contains($0) }
                                        if allSelected {
                                            allKeys.forEach { selectedCategories.remove($0) }
                                        } else {
                                            allKeys.forEach { selectedCategories.insert($0) }
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    
                    // Bottom buttons
                    VStack(spacing: 12) {
                        Button(action: applyThemes) {
                            HStack {
                                if isApplying {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark")
                                    Text("Apply Selected (\(selectedCategories.count))")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: self.theme.primaryColor))
                            .cornerRadius(12)
                        }
                        .disabled(selectedCategories.isEmpty || isApplying)
                        .opacity(selectedCategories.isEmpty ? 0.5 : 1)
                        
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(Color(hex: self.theme.primaryColor))
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func applyThemes() {
        guard let groupId = dataStore.activeGroupId else { return }
        isApplying = true
        
        Task {
            do {
                // Get existing categories to avoid duplicates
                let existingKeys = Set(dataStore.categories.compactMap { $0.translationKey })
                let existingNames = Set(dataStore.categories.map { $0.name.lowercased() })
                
                // Find categories to create
                var categoriesToCreate: [(name: String, icon: String, key: String)] = []
                
                for themeData in ALL_CATEGORY_THEMES {
                    for catData in themeData.categories {
                        if selectedCategories.contains(catData.translationKey) {
                            let name = localizationManager.t(catData.translationKey)
                            // Skip if already exists by key or name
                            if !existingKeys.contains(catData.translationKey) &&
                               !existingNames.contains(name.lowercased()) {
                                categoriesToCreate.append((
                                    name: name,
                                    icon: catData.icon,
                                    key: catData.translationKey
                                ))
                            }
                        }
                    }
                }
                
                // Create categories sequentially
                for (name, icon, key) in categoriesToCreate {
                    try await dataStore.createCategory([
                        "group_id": groupId,
                        "name": name,
                        "icon": icon,
                        "translation_key": key
                    ])
                    // Small delay to avoid overwhelming the API
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
                
                // Refresh categories
                await dataStore.refreshCategories()
                
                await MainActor.run {
                    isApplying = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isApplying = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Theme Card
struct ThemeCard: View {
    let theme: TranslatedCategoryTheme
    let isExpanded: Bool
    @Binding var selectedCategories: Set<String>
    let appTheme: AppTheme
    let onToggleExpand: () -> Void
    let onToggleAll: () -> Void
    
    private var allSelected: Bool {
        theme.categories.allSatisfy { selectedCategories.contains($0.translationKey) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Theme header
            Button(action: onToggleExpand) {
                HStack(spacing: 12) {
                    // Theme icon
                    Text(theme.icon)
                        .font(.system(size: 32))
                        .frame(width: 50, height: 50)
                        .background(Color(hex: appTheme.primaryColor).opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.name)
                            .font(.headline)
                            .foregroundColor(Color(hex: appTheme.textColor))
                        Text(theme.description)
                            .font(.caption)
                            .foregroundColor(Color(hex: appTheme.textSecondary))
                        Text("\(theme.categories.count) categories")
                            .font(.caption2)
                            .foregroundColor(Color(hex: appTheme.primaryColor))
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color(hex: appTheme.textSecondary))
                }
                .padding()
            }
            
            // Expanded categories
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                    
                    // Select all button
                    Button(action: onToggleAll) {
                        HStack {
                            Image(systemName: allSelected ? "checkmark.square.fill" : "square")
                                .foregroundColor(Color(hex: appTheme.primaryColor))
                            Text(allSelected ? "Deselect All" : "Select All")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: appTheme.primaryColor))
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    
                    Divider()
                    
                    // Category checkboxes
                    ForEach(theme.categories) { category in
                        CategoryCheckbox(
                            category: category,
                            isSelected: selectedCategories.contains(category.translationKey),
                            appTheme: appTheme,
                            onToggle: {
                                if selectedCategories.contains(category.translationKey) {
                                    selectedCategories.remove(category.translationKey)
                                } else {
                                    selectedCategories.insert(category.translationKey)
                                }
                            }
                        )
                        
                        if category.id != theme.categories.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
        .background(Color(hex: appTheme.cardBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: appTheme.borderColor), lineWidth: 1)
        )
        .shadow(
            color: Color(hex: appTheme.shadowColor),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Category Checkbox
struct CategoryCheckbox: View {
    let category: TranslatedCategoryTheme.TranslatedCategory
    let isSelected: Bool
    let appTheme: AppTheme
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(Color(hex: appTheme.primaryColor))
                
                Text(category.icon)
                    .font(.title3)
                
                Text(category.name)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: appTheme.textColor))
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }
}
