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
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            List {
                ForEach(dataStore.categories) { category in
                    HStack(spacing: 12) {
                        Text(category.icon ?? "🍽️")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: theme.primaryColor).opacity(0.1))
                            .clipShape(Circle())
                        
                        Text(localizationManager.getCategoryName(category))
                            .foregroundColor(Color(hex: theme.textColor))
                        
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
                    .listRowBackground(Color(hex: theme.cardBackground))
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(localizationManager.t("categories.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        .alert(localizationManager.t("action.delete"), isPresented: $showDeleteAlert) {
            Button(localizationManager.t("common.cancel"), role: .cancel) {}
            Button(localizationManager.t("action.delete"), role: .destructive) {
                if let cat = categoryToDelete {
                    Task { try? await dataStore.deleteCategory(id: cat.id) }
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
                    
                    let emojis = ["🍎", "🥦", "🥩", "🧀", "🍞", "🐟", "🍰", "🍿", "🥗", "🍜", "🥚", "🌽", "🍕", "🍔", "🌮", "🍱"]
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
