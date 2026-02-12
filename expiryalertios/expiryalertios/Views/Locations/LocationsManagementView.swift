import SwiftUI

struct LocationsManagementView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var showAddSheet = false
    @State private var editingLocation: Location?
    @State private var newName = ""
    @State private var newIcon = "📍"
    @State private var showDeleteAlert = false
    @State private var locationToDelete: Location?
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            List {
                ForEach(dataStore.locations) { location in
                    HStack(spacing: 12) {
                        Text(location.icon ?? "📍")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: theme.primaryColor).opacity(0.1))
                            .clipShape(Circle())
                        
                        Text(localizationManager.getLocationName(location))
                            .foregroundColor(Color(hex: theme.textColor))
                        
                        Spacer()
                        
                        if location.isDefault != true {
                            Button(action: {
                                editingLocation = location
                                newName = location.name
                                newIcon = location.icon ?? "📍"
                                showAddSheet = true
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(Color(hex: theme.primaryColor))
                            }
                            
                            Button(action: {
                                locationToDelete = location
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
        .navigationTitle(localizationManager.t("locations.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    editingLocation = nil
                    newName = ""
                    newIcon = "📍"
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
                if let loc = locationToDelete {
                    Task { try? await dataStore.deleteLocation(id: loc.id) }
                }
            }
        }
    }
    
    private var addEditSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField(localizationManager.t("locationName"), text: $newName)
                    .textFieldStyle(ThemedTextFieldStyle(theme: theme))
                
                VStack(alignment: .leading) {
                    Text("Icon")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: theme.textSecondary))
                    
                    let emojis = ["🧊", "❄️", "🗄️", "🏠", "🍳", "📦", "🧺", "🚗", "🏢", "🌡️", "🍶", "🛒"]
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button(action: { newIcon = emoji }) {
                                Text(emoji)
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
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
            .navigationTitle(editingLocation != nil ? localizationManager.t("editLocation") : localizationManager.t("addLocation"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.t("common.cancel")) { showAddSheet = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.t("common.save")) {
                        Task {
                            if let loc = editingLocation {
                                try? await dataStore.updateLocation(id: loc.id, name: newName, icon: newIcon)
                            } else {
                                try? await dataStore.createLocation(name: newName, icon: newIcon)
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
