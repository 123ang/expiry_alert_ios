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
    @State private var showDeleteError = false
    @State private var deleteErrorMessage: String?
    @State private var searchText = ""
    @State private var expandedSections: Set<String> = []
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    /// Section key for grouping: Fridge (merged) goes under Kitchen; empty/other → "Other".
    private func sectionKey(for location: Location) -> String {
        if DataStore.isFridgeVariant(location) { return "Kitchen" }
        let t = (location.section ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        if t.isEmpty || t == "other" { return "Other" }
        return location.section ?? "Other"
    }
    
    private let otherSectionKey = "Other"
    /// Section for user-added locations; always first, count 0 if empty.
    private let customizeSectionKey = "Customize"
    
    /// User-added (customization) locations only.
    private var customizeLocations: [Location] {
        dataStore.displayLocations.filter { isCustomizationLocation($0) }
    }
    
    /// True when edit/remove should be shown: backend sends is_customization == true, or (for backward compatibility) when field is missing and location is non-default.
    private func isCustomizationLocation(_ location: Location) -> Bool {
        if let custom = location.isCustomization { return custom }
        return location.isDefault != true
    }
    
    private var locationsBySection: [(section: String, items: [Location])] {
        let list = dataStore.displayLocations.filter { !isCustomizationLocation($0) }
        var map: [String: [Location]] = [:]
        for loc in list {
            let key = sectionKey(for: loc)
            map[key, default: []].append(loc)
        }
        var order: [String] = []
        for loc in list {
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
        return [(section: customizeSectionKey, items: customizeLocations)] + otherSections
    }
    
    private var filteredSections: [(section: String, items: [Location])] {
        let term = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let base = locationsBySection
        if term.isEmpty { return base }
        return base.map { pair in
            let filtered = pair.items.filter {
                localizationManager.getLocationDisplayName($0).lowercased().contains(term)
            }
            return (pair.section, filtered)
        }
    }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            VStack(spacing: 0) {
                searchBar
                List {
                    errorSection
                    if !searchText.isEmpty && filteredSections.isEmpty {
                        Section {
                            Text("No locations match \"\(searchText)\"")
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
                                ForEach(pair.items) { location in
                                    locationRow(location)
                                        .listRowBackground(Color(hex: theme.cardBackground))
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                }
                            },
                            label: {
                                sectionHeaderLabel(pair.section, count: pair.items.count)
                            }
                        )
                        .listRowBackground(Color(hex: theme.backgroundColor))
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
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
        .onAppear {
            expandedSections = []
            Task { await dataStore.refreshLocations() }
        }
        .sheet(isPresented: $showAddSheet) {
            addEditSheet
        }
        .alert(localizationManager.t("action.delete"), isPresented: $showDeleteAlert) {
            Button(localizationManager.t("common.cancel"), role: .cancel) {
                locationToDelete = nil
            }
            Button(localizationManager.t("action.delete"), role: .destructive) {
                guard let loc = locationToDelete else { return }
                Task {
                    do {
                        try await dataStore.deleteLocation(id: loc.id)
                        locationToDelete = nil
                    } catch {
                        deleteErrorMessage = error.localizedDescription
                        showDeleteError = true
                    }
                }
            }
        } message: {
            Text(localizationManager.t("action.deleteLocationConfirm"))
        }
        .alert("Delete failed", isPresented: $showDeleteError) {
            Button(localizationManager.t("common.ok"), role: .cancel) {
                deleteErrorMessage = nil
            }
        } message: {
            if let msg = deleteErrorMessage { Text(msg) }
        }
        .refreshable {
            await dataStore.refreshLocations()
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundColor(Color(hex: theme.textSecondary))
            TextField(localizationManager.t("locations.searchPlaceholder"), text: $searchText)
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
        if dataStore.locations.isEmpty, let err = dataStore.error {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(Color(hex: theme.warningColor))
                    Text("Couldn't load locations")
                        .font(.headline)
                        .foregroundColor(Color(hex: theme.textColor))
                    Text(err)
                        .font(.caption)
                        .foregroundColor(Color(hex: theme.textSecondary))
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        dataStore.error = nil
                        Task { await dataStore.refreshLocations() }
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
    
    private func sectionHeaderLabel(_ section: String, count: Int) -> some View {
        let displayName = localizedSectionTitle(section)
        return HStack(spacing: 8) {
            Text(displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: theme.textSecondary))
                .textCase(.uppercase)
                .tracking(0.4)
            Text("\(count)")
                .font(.caption)
                .foregroundColor(Color(hex: theme.textSecondary).opacity(0.8))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(hex: theme.borderColor).opacity(0.5))
                .cornerRadius(6)
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func locationRow(_ location: Location) -> some View {
        HStack(spacing: 10) {
            Button(action: { dataStore.toggleLocationSelection(id: location.id) }) {
                Image(systemName: dataStore.isLocationSelected(id: location.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(dataStore.isLocationSelected(id: location.id) ? Color(hex: theme.primaryColor) : Color(hex: theme.textSecondary).opacity(0.5))
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(location.icon ?? "📍")
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color(hex: theme.primaryColor).opacity(0.12))
                .clipShape(Circle())
            
            HStack(spacing: 6) {
                Text(localizationManager.getLocationDisplayName(location))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: theme.textColor))
                    .lineLimit(1)
            }
            
            Spacer(minLength: 8)
            
            if isCustomizationLocation(location) {
                Button(action: {
                    editingLocation = location
                    newName = location.name
                    newIcon = location.icon ?? "📍"
                    showAddSheet = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
                .buttonStyle(PlainButtonStyle())
                Button(action: {
                    locationToDelete = location
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
            VStack(spacing: 20) {
                TextField(localizationManager.t("locationName"), text: $newName)
                    .textFieldStyle(ThemedTextFieldStyle(theme: theme))
                
                VStack(alignment: .leading) {
                    Text("Icon")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: theme.textSecondary))
                    
                    let emojis = [
                        "🧊", "🚪", "❄️", "🗄️", "📦", "🗃️", "🪑",
                        "👔", "🛏️", "🚗", "🏠", "🪞", "🚰", "🚿",
                        "📚", "📁", "🎒", "🧳", "🏢", "🍳", "🧺", "🌡️", "🍶", "🛒",
                    ]
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
