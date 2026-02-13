import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataStore: DataStore
    
    @State private var showLanguagePicker = false
    @State private var showThemePicker = false
    @State private var showSignOutAlert = false
    @State private var showGroupsModal = false
    @State private var showJoinGroup = false
    @State private var showClearExpiredAlert = false
    @State private var showClearUsedAlert = false
    @State private var pendingInvitationCount = 0
    
    private var theme: AppTheme { themeManager.currentTheme }
    private var isAuthenticated: Bool { authViewModel.isAuthenticated }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                Text("Settings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: theme.textColor))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.top, 50)
                    .background(Color(hex: theme.cardBackground))
                    .overlay(
                        Rectangle()
                            .fill(Color(hex: theme.borderColor))
                            .frame(height: 1),
                        alignment: .bottom
                    )
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Settings Card
                        VStack(spacing: 0) {
                            // Language
                            settingsRow(
                                icon: "globe",
                                title: localizationManager.t("settings.language"),
                                description: "Change app language",
                                action: { showLanguagePicker = true }
                            )
                            
                            settingsDivider()
                            
                            // Account
                            if let user = authViewModel.user {
                                settingsRow(
                                    icon: "person.fill",
                                    title: "Account",
                                    description: user.email,
                                    action: nil,
                                    showChevron: false
                                )
                                
                                settingsDivider()
                            }
                            
                            // Groups - Opens modal like in React Native
                            settingsRow(
                                icon: "person.3.fill",
                                title: "Groups",
                                description: "Manage your personal and family groups",
                                action: { showGroupsModal = true }
                            )
                            
                            settingsDivider()
                            
                            // Theme
                            settingsRow(
                                icon: "paintbrush.fill",
                                title: localizationManager.t("settings.theme"),
                                description: "Choose your preferred theme: \(themeManager.currentThemeType.displayName)",
                                action: { showThemePicker = true }
                            )
                            
                            settingsDivider()
                            
                            // Categories
                            NavigationLink(destination: CategoriesManagementView()) {
                                settingsRowContent(
                                    icon: "tag.fill",
                                    title: localizationManager.t("settings.manageCategories"),
                                    description: "Manage food categories"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            settingsDivider()
                            
                            // Storage Locations
                            NavigationLink(destination: LocationsManagementView()) {
                                settingsRowContent(
                                    icon: "mappin.circle.fill",
                                    title: localizationManager.t("settings.manageLocations"),
                                    description: "Manage storage locations"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            settingsDivider()
                            
                            // Notifications
                            NavigationLink(destination: NotificationsView()) {
                                settingsRowContent(
                                    icon: "bell.fill",
                                    title: localizationManager.t("settings.notifications"),
                                    description: "Manage notification settings"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            settingsDivider()
                            
                            // Clear Expired Items
                            settingsRow(
                                icon: "trash.fill",
                                title: "Clear Expired Items",
                                description: "Remove all expired items from your inventory",
                                action: { showClearExpiredAlert = true }
                            )
                            
                            settingsDivider()
                            
                            // Clear Used/Eaten Items
                            settingsRow(
                                icon: "checkmark.circle.fill",
                                title: "Clear Used/Eaten Items",
                                description: "Bulk remove items that have been consumed",
                                action: { showClearUsedAlert = true }
                            )
                        }
                        .background(Color(hex: theme.cardBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showLanguagePicker) { languagePicker }
        .sheet(isPresented: $showThemePicker) { themePicker }
        .sheet(isPresented: $showGroupsModal) {
            GroupsManagementModal(pendingInvitationCount: $pendingInvitationCount)
        }
        .sheet(isPresented: $showJoinGroup) {
            JoinGroupView()
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task { await authViewModel.signOut() }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Clear Expired Items", isPresented: $showClearExpiredAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                Task {
                    // TODO: Implement clear expired items functionality
                }
            }
        } message: {
            Text("This will remove all expired items from your list. This action cannot be undone.")
        }
        .alert("Clear Used Items", isPresented: $showClearUsedAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                Task {
                    // TODO: Implement clear used items functionality
                }
            }
        } message: {
            Text("This will remove all consumed items from your list. This action cannot be undone.")
        }
        .task {
            await loadPendingInvitationCount()
        }
    }
    
    // MARK: - Data Loading
    private func loadPendingInvitationCount() async {
        do {
            let invitations = try await dataStore.getPendingInvitations()
            pendingInvitationCount = invitations.count
        } catch {
            pendingInvitationCount = 0
        }
    }
    
    // MARK: - Settings Row with Action
    @ViewBuilder
    private func settingsRow(
        icon: String,
        title: String,
        description: String,
        action: (() -> Void)?,
        showChevron: Bool = true
    ) -> some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: theme.primaryColor).opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: theme.textColor))
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: theme.textSecondary))
                        .lineLimit(1)
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: theme.textSecondary))
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil && !showChevron)
    }
    
    // MARK: - Settings Row Content (for NavigationLink)
    @ViewBuilder
    private func settingsRowContent(
        icon: String,
        title: String,
        description: String
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: theme.primaryColor).opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: theme.primaryColor))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: theme.textColor))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: theme.textSecondary))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: theme.textSecondary))
        }
        .padding(16)
    }
    
    private func settingsDivider() -> some View {
        Divider()
            .padding(.leading, 60)
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

// MARK: - Groups Management Modal
struct GroupsManagementModal: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @Binding var pendingInvitationCount: Int
    
    @State private var showCreateGroup = false
    @State private var newGroupName = ""
    @State private var newGroupDescription = ""
    @State private var showJoinGroup = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("👥 Manage Groups")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: theme.textColor))
                            Text("Create and manage your groups")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: theme.textSecondary))
                        }
                        .padding(.top, 8)
                        
                        // Groups List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("YOUR GROUPS (\(dataStore.groups.count))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: theme.textSecondary))
                                .padding(.horizontal, 4)
                            
                            if dataStore.groups.isEmpty {
                                VStack(spacing: 12) {
                                    Text("No groups yet. Create your first group!")
                                        .font(.subheadline)
                                        .foregroundColor(Color(hex: theme.textSecondary))
                                        .multilineTextAlignment(.center)
                                        .padding(.vertical, 20)
                                }
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: theme.cardBackground))
                                .cornerRadius(12)
                            } else {
                                ForEach(dataStore.groups) { group in
                                    NavigationLink(destination: GroupDetailView(group: group)) {
                                        groupRow(group: group)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Pending Invitations
                        NavigationLink(destination: PendingInvitationsView()) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: theme.primaryColor).opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: theme.primaryColor))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Pending Invitations")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(hex: theme.textColor))
                                }
                                
                                Spacer()
                                
                                if pendingInvitationCount > 0 {
                                    Text("\(pendingInvitationCount)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color(hex: theme.dangerColor))
                                        .cornerRadius(10)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: theme.textSecondary))
                            }
                            .padding(12)
                            .background(Color(hex: theme.cardBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Action Buttons
                        VStack(spacing: 10) {
                            Button(action: { showCreateGroup = true }) {
                                Text("Create New Group")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(hex: theme.primaryColor))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: { showJoinGroup = true }) {
                                HStack {
                                    Image(systemName: "ticket.fill")
                                    Text("Join with Invite Code")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: theme.primaryColor))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: theme.cardBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: theme.primaryColor), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupModal(isPresented: $showCreateGroup)
            }
            .sheet(isPresented: $showJoinGroup) {
                JoinGroupView()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "Something went wrong")
            }
        }
    }
    
    @ViewBuilder
    private func groupRow(group: Group) -> some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: theme.primaryColor).opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(String(group.name.prefix(1)).uppercased())
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: theme.primaryColor))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: theme.textColor))
                Text(group.description ?? "No description")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: theme.textSecondary))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Active Badge or Role
            if group.id == dataStore.activeGroupId {
                Text("Active")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: theme.primaryColor))
                    .cornerRadius(10)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: theme.textSecondary))
        }
        .padding(12)
        .background(Color(hex: theme.backgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
        )
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

// MARK: - Create Group Modal
struct CreateGroupModal: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var dataStore: DataStore
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("Create New Group")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: theme.textColor))
                        }
                        .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Group Name")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: theme.textColor))
                            TextField("e.g., Family, Roommates, Office", text: $name)
                                .padding(14)
                                .background(Color(hex: theme.cardBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                                )
                                .foregroundColor(Color(hex: theme.textColor))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (optional)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: theme.textColor))
                            TextField("What is this group for?", text: $description, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(14)
                                .background(Color(hex: theme.cardBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                                )
                                .foregroundColor(Color(hex: theme.textColor))
                        }
                        
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                dismiss()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: theme.backgroundColor))
                            .foregroundColor(Color(hex: theme.textColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                            )
                            
                            Button(action: { Task { await createGroup() } }) {
                                HStack {
                                    if isCreating {
                                        ProgressView().tint(.white).scaleEffect(0.8)
                                    }
                                    Text(isCreating ? "Creating..." : "Create")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(name.isEmpty ? Color(hex: theme.textSecondary) : Color(hex: theme.primaryColor))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .disabled(name.isEmpty || isCreating)
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "Something went wrong")
            }
        }
    }
    
    private func createGroup() async {
        isCreating = true
        do {
            _ = try await dataStore.createGroup(
                name: name,
                description: description.isEmpty ? nil : description
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isCreating = false
    }
}
