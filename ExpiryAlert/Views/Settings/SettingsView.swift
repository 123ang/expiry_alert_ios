import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataStore: DataStore
    
    @State private var showLanguagePicker = false
    @State private var showThemePicker = false
    @State private var showSignOutAlert = false
    @State private var showCreateGroup = false
    @State private var newGroupName = ""
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    Text(localizationManager.t("settings.title"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: theme.textColor))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    
                    // Account Section
                    SettingsSection(title: "Account", theme: theme) {
                        if let user = authViewModel.user {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: theme.primaryColor).opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    Text(String(user.email.prefix(1)).uppercased())
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(hex: theme.primaryColor))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.fullName ?? "User")
                                        .font(.headline)
                                        .foregroundColor(Color(hex: theme.textColor))
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundColor(Color(hex: theme.textSecondary))
                                }
                                Spacer()
                            }
                        }
                    }
                    
                    // Group Management
                    SettingsSection(title: "Groups", theme: theme) {
                        ForEach(dataStore.groups) { group in
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(Color(hex: theme.primaryColor))
                                Text(group.name)
                                    .foregroundColor(Color(hex: theme.textColor))
                                Spacer()
                                if group.id == dataStore.activeGroupId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: theme.primaryColor))
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Task { await dataStore.switchGroup(to: group.id) }
                            }
                        }
                        
                        Button(action: { showCreateGroup = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Color(hex: theme.primaryColor))
                                Text(localizationManager.t("form.createGroup"))
                                    .foregroundColor(Color(hex: theme.primaryColor))
                            }
                        }
                    }
                    
                    // Preferences
                    SettingsSection(title: "Preferences", theme: theme) {
                        settingsRow(icon: "globe", title: localizationManager.t("settings.language"),
                                    subtitle: localizationManager.currentLanguage.displayName) {
                            showLanguagePicker = true
                        }
                        settingsRow(icon: "paintpalette.fill", title: localizationManager.t("settings.theme"),
                                    subtitle: themeManager.currentThemeType.displayName) {
                            showThemePicker = true
                        }
                        
                        NavigationLink(destination: NotificationsView()) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(Color(hex: theme.primaryColor))
                                    .frame(width: 28)
                                Text(localizationManager.t("settings.notifications"))
                                    .foregroundColor(Color(hex: theme.textColor))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: theme.textSecondary))
                            }
                        }
                    }
                    
                    // Management
                    SettingsSection(title: "Management", theme: theme) {
                        NavigationLink(destination: CategoriesManagementView()) {
                            settingsRowContent(icon: "square.grid.2x2.fill",
                                               title: localizationManager.t("settings.manageCategories"))
                        }
                        NavigationLink(destination: LocationsManagementView()) {
                            settingsRowContent(icon: "mappin.circle.fill",
                                               title: localizationManager.t("settings.manageLocations"))
                        }
                    }
                    
                    // Sign Out
                    Button(action: { showSignOutAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Sign Out")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: theme.dangerColor).opacity(0.1))
                        .foregroundColor(Color(hex: theme.dangerColor))
                        .cornerRadius(12)
                    }
                    
                    // About
                    VStack(spacing: 4) {
                        Text(localizationManager.t("about.appName"))
                            .font(.caption)
                            .foregroundColor(Color(hex: theme.textSecondary))
                        Text("v1.0.0 • iOS")
                            .font(.caption2)
                            .foregroundColor(Color(hex: theme.textSecondary))
                    }
                    .padding(.top, 8)
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showLanguagePicker) { languagePicker }
        .sheet(isPresented: $showThemePicker) { themePicker }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task { await authViewModel.signOut() }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Create Group", isPresented: $showCreateGroup) {
            TextField("Group Name", text: $newGroupName)
            Button("Cancel", role: .cancel) { newGroupName = "" }
            Button("Create") {
                Task {
                    try? await dataStore.createGroup(name: newGroupName, description: nil)
                    newGroupName = ""
                }
            }
        }
    }
    
    // MARK: - Settings Row
    private func settingsRow(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: theme.primaryColor))
                    .frame(width: 28)
                Text(title)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color(hex: theme.textSecondary))
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(hex: theme.textSecondary))
            }
        }
    }
    
    private func settingsRowContent(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(hex: theme.primaryColor))
                .frame(width: 28)
            Text(title)
                .foregroundColor(Color(hex: theme.textColor))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(hex: theme.textSecondary))
        }
    }
    
    // MARK: - Language Picker
    private var languagePicker: some View {
        NavigationStack {
            List(AppLanguage.allCases) { language in
                Button(action: {
                    localizationManager.currentLanguage = language
                    showLanguagePicker = false
                }) {
                    HStack {
                        Text(language.displayName)
                            .foregroundColor(Color(hex: theme.textColor))
                        Spacer()
                        if localizationManager.currentLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(hex: theme.primaryColor))
                        }
                    }
                }
            }
            .navigationTitle(localizationManager.t("settings.language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.t("common.close")) { showLanguagePicker = false }
                }
            }
        }
    }
    
    // MARK: - Theme Picker
    private var themePicker: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(ThemeType.allCases) { type in
                        Button(action: {
                            themeManager.setTheme(type)
                            showThemePicker = false
                        }) {
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: type.theme.backgroundColor))
                                    .frame(height: 80)
                                    .overlay(
                                        VStack {
                                            Circle()
                                                .fill(Color(hex: type.theme.primaryColor))
                                                .frame(width: 24, height: 24)
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color(hex: type.theme.cardBackground))
                                                .frame(height: 20)
                                                .padding(.horizontal, 12)
                                        }
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                themeManager.currentThemeType == type
                                                ? Color(hex: type.theme.primaryColor)
                                                : Color(hex: theme.borderColor),
                                                lineWidth: themeManager.currentThemeType == type ? 3 : 1
                                            )
                                    )
                                
                                Text(type.displayName)
                                    .font(.caption)
                                    .foregroundColor(Color(hex: theme.textColor))
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle(localizationManager.t("settings.theme"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.t("common.close")) { showThemePicker = false }
                }
            }
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let theme: AppTheme
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: theme.textSecondary))
                .textCase(.uppercase)
            
            VStack(spacing: 12) {
                content
            }
            .padding(16)
            .background(Color(hex: theme.cardBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: theme.borderColor), lineWidth: 1)
            )
        }
    }
}
