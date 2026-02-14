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
                // Header – blends with page (same background as content)
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Text(localizationManager.t("settings.title"))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color(hex: theme.textColor))
                    Spacer(minLength: 0)
                }
                .padding(.top, 10)
                .padding(.bottom, 8)
                .padding(.horizontal, 16)
                .background(Color(hex: theme.backgroundColor))
                .overlay(
                    Rectangle()
                        .fill(Color(hex: theme.borderColor).opacity(0.35))
                        .frame(height: 0.5),
                    alignment: .bottom
                )
                .padding(.top, 44)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Group 1: Account & Groups
                        SettingsSectionTitle(title: localizationManager.t("settings.sectionAccountGroups"))
                        SettingsGroup {
                            if let user = authViewModel.user {
                                NavigationLink(destination: AccountSettingsView()) {
                                    SettingsRowContent(
                                        icon: "person.fill",
                                        title: localizationManager.t("settings.account"),
                                        subtitle: user.email,
                                        showChevron: true
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            Button(action: { showGroupsModal = true }) {
                                SettingsRowContent(
                                    icon: "person.3.fill",
                                    title: localizationManager.t("settings.groups"),
                                    subtitle: localizationManager.t("settings.groupsDescription")
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        sectionDivider
                        
                        // Group 2: Preferences
                        SettingsSectionTitle(title: localizationManager.t("settings.sectionPreferences"))
                        SettingsGroup {
                            Button(action: { showLanguagePicker = true }) {
                                SettingsRowContent(
                                    icon: "globe",
                                    title: localizationManager.t("settings.language"),
                                    subtitle: localizationManager.t("settings.languageDescription")
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            Button(action: { showThemePicker = true }) {
                                SettingsRowContent(
                                    icon: "paintbrush.fill",
                                    title: localizationManager.t("settings.theme"),
                                    subtitle: "\(localizationManager.t("settings.themeDescription")): \(localizationManager.t("theme.\(themeManager.currentThemeType.rawValue)"))"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        sectionDivider
                        
                        // Group 3: Management
                        SettingsSectionTitle(title: localizationManager.t("settings.sectionManagement"))
                        SettingsGroup {
                            NavigationLink(destination: CategoriesManagementView()) {
                                SettingsRowContent(
                                    icon: "tag.fill",
                                    title: localizationManager.t("settings.manageCategories"),
                                    subtitle: localizationManager.t("settings.manageCategoriesDescription")
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            NavigationLink(destination: LocationsManagementView()) {
                                SettingsRowContent(
                                    icon: "mappin.circle.fill",
                                    title: localizationManager.t("settings.manageLocations"),
                                    subtitle: localizationManager.t("settings.manageLocationsDescription")
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            NavigationLink(destination: NotificationsView()) {
                                SettingsRowContent(
                                    icon: "bell.fill",
                                    title: localizationManager.t("settings.notifications"),
                                    subtitle: localizationManager.t("settings.notificationsDescription")
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        sectionDivider
                        
                        // Group 4: Data & Inventory
                        SettingsSectionTitle(title: localizationManager.t("settings.sectionData"))
                        SettingsGroup {
                            Button(action: { showClearExpiredAlert = true }) {
                                SettingsRowContent(
                                    icon: "trash.fill",
                                    title: localizationManager.t("settings.clearExpiredItems"),
                                    subtitle: localizationManager.t("settings.clearExpiredItemsDescription")
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            Button(action: { showClearUsedAlert = true }) {
                                SettingsRowContent(
                                    icon: "checkmark.circle.fill",
                                    title: localizationManager.t("settings.clearUsedItems"),
                                    subtitle: localizationManager.t("settings.clearUsedItemsDescription")
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
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
        .alert(localizationManager.t("settings.signOutAlertTitle"), isPresented: $showSignOutAlert) {
            Button(localizationManager.t("common.cancel"), role: .cancel) {}
            Button(localizationManager.t("settings.signOutButton"), role: .destructive) {
                Task { await authViewModel.signOut() }
            }
        } message: {
            Text(localizationManager.t("settings.signOutAlertMessage"))
        }
        .alert(localizationManager.t("settings.clearExpiredAlertTitle"), isPresented: $showClearExpiredAlert) {
            Button(localizationManager.t("common.cancel"), role: .cancel) {}
            Button(localizationManager.t("settings.clearButton"), role: .destructive) {
                Task {
                    // TODO: Implement clear expired items functionality
                }
            }
        } message: {
            Text(localizationManager.t("settings.clearExpiredAlertMessage"))
        }
        .alert(localizationManager.t("settings.clearUsedAlertTitle"), isPresented: $showClearUsedAlert) {
            Button(localizationManager.t("common.cancel"), role: .cancel) {}
            Button(localizationManager.t("settings.clearButton"), role: .destructive) {
                Task {
                    // TODO: Implement clear used items functionality
                }
            }
        } message: {
            Text(localizationManager.t("settings.clearUsedAlertMessage"))
        }
        .task {
            await loadPendingInvitationCount()
        }
    }
    
    /// Line between sections only (not between rows within a group).
    private var sectionDivider: some View {
        Rectangle()
            .fill(Color(hex: theme.borderColor).opacity(0.6))
            .frame(height: 0.5)
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
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
    
    // MARK: - Language Picker
    private var languagePicker: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
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
                    .listRowBackground(Color(hex: theme.cardBackground))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(localizationManager.t("settings.language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: theme.backgroundColor), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.t("common.close")) { showLanguagePicker = false }
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
        }
    }
    
    // MARK: - Theme Picker
    private var themePicker: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
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
                                    
                                    Text(localizationManager.t("theme.\(type.rawValue)"))
                                        .font(.caption)
                                        .foregroundColor(Color(hex: theme.textColor))
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(localizationManager.t("settings.theme"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: theme.backgroundColor), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.t("common.close")) { showThemePicker = false }
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
        }
    }
}

// MARK: - Reusable Settings UI Components

/// Section label above a group. Small, uppercase, light gray (iOS grouped style).
struct SettingsSectionTitle: View {
    let title: String
    @EnvironmentObject var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: theme.textSecondary))
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.bottom, 8)
    }
}

/// Single row content: icon in tinted square, title, optional subtitle, optional chevron. Min 44pt height.
struct SettingsRowContent: View {
    let icon: String
    let title: String
    let subtitle: String?
    let showChevron: Bool
    @EnvironmentObject var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.currentTheme }
    
    init(icon: String, title: String, subtitle: String? = nil, showChevron: Bool = true) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
    }
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: theme.primaryColor).opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(Color(hex: theme.primaryColor))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: theme.textColor))
                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: theme.textSecondary))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: theme.textSecondary).opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minHeight: 48)
        .contentShape(Rectangle())
    }
}

/// Thin divider between rows in a group. Leading inset to align with title.
struct SettingsRowDivider: View {
    @EnvironmentObject var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        Rectangle()
            .fill(Color(hex: theme.borderColor))
            .frame(height: 0.5)
            .padding(.leading, 60)
    }
}

/// One box per section: rounded card, refined width and shadow.
struct SettingsGroup<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @EnvironmentObject var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: theme.cardBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: theme.borderColor).opacity(0.6), lineWidth: 1)
            )
            .shadow(
                color: Color(hex: theme.shadowColor).opacity(0.35),
                radius: 6,
                x: 0,
                y: 2
            )
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
    @State private var showLanguagePicker = false
    @State private var showThemePicker = false
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
                            Text("👥 \(localizationManager.t("groups.manageGroups"))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: theme.textColor))
                            Text(localizationManager.t("groups.createAndManage"))
                                .font(.subheadline)
                                .foregroundColor(Color(hex: theme.textSecondary))
                        }
                        .padding(.top, 8)
                        
                        // Groups List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(localizationManager.t("groups.yourGroups")) (\(dataStore.groups.count))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: theme.textSecondary))
                                .padding(.horizontal, 4)
                            
                            if dataStore.groups.isEmpty {
                                VStack(spacing: 12) {
                                    Text(localizationManager.t("groups.noGroupsYet"))
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
                                    Text(localizationManager.t("groups.pendingInvitations"))
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
                                Text(localizationManager.t("groups.createNewGroup"))
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
                                    Text(localizationManager.t("groups.joinWithInviteCode"))
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
            .navigationTitle(localizationManager.t("groups.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.t("common.close")) { dismiss() }
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupModal(isPresented: $showCreateGroup)
                    .environmentObject(localizationManager)
            }
            .sheet(isPresented: $showJoinGroup) {
                JoinGroupView()
            }
            .alert(localizationManager.t("alert.error"), isPresented: $showError) {
                Button(localizationManager.t("common.ok")) {}
            } message: {
                Text(errorMessage ?? localizationManager.t("common.somethingWentWrong"))
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
                Text(group.description ?? localizationManager.t("groups.noDescription"))
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: theme.textSecondary))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Active Badge or Role
            if group.id == dataStore.activeGroupId {
                Text(localizationManager.t("groups.active"))
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
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
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
                    .listRowBackground(Color(hex: theme.cardBackground))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(localizationManager.t("settings.language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: theme.backgroundColor), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.t("common.close")) { showLanguagePicker = false }
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
        }
    }
    
    // MARK: - Theme Picker
    private var themePicker: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
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
                                    
                                    Text(localizationManager.t("theme.\(type.rawValue)"))
                                        .font(.caption)
                                        .foregroundColor(Color(hex: theme.textColor))
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(localizationManager.t("settings.theme"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: theme.backgroundColor), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.t("common.close")) { showThemePicker = false }
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
        }
    }
}

// MARK: - Create Group Modal
struct CreateGroupModal: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
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
                            Text(localizationManager.t("groups.createNewGroup"))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: theme.textColor))
                        }
                        .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizationManager.t("groups.groupName"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: theme.textColor))
                            TextField(localizationManager.t("groups.groupNamePlaceholder"), text: $name)
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
                            Text(localizationManager.t("groups.descriptionOptional"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: theme.textColor))
                            TextField(localizationManager.t("groups.groupDescriptionPlaceholder"), text: $description, axis: .vertical)
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
                            Button(localizationManager.t("common.cancel")) {
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
                                    Text(isCreating ? localizationManager.t("groups.creating") : localizationManager.t("groups.create"))
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
            .alert(localizationManager.t("alert.error"), isPresented: $showError) {
                Button(localizationManager.t("common.ok")) {}
            } message: {
                Text(errorMessage ?? localizationManager.t("common.somethingWentWrong"))
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
