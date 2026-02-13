import SwiftUI

struct GroupDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    let group: Group
    
    @State private var members: [GroupMembership] = []
    @State private var isLoadingMembers = true
    @State private var showEditGroup = false
    @State private var showDeleteAlert = false
    @State private var showInviteMember = false
    @State private var showInviteCodeCopied = false
    @State private var editName = ""
    @State private var editDescription = ""
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var currentUserRole: String = "member"
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Group Info Card
                    groupInfoCard
                    
                    // Invite Code Card
                    if let inviteCode = group.inviteCode, !inviteCode.isEmpty {
                        inviteCodeCard(code: inviteCode)
                    }
                    
                    // Actions
                    actionsSection
                    
                    // Members Section
                    membersSection
                    
                    // Danger Zone
                    if currentUserRole == "owner" {
                        dangerZoneSection
                    }
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if currentUserRole == "owner" || currentUserRole == "admin" {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editName = group.name
                        editDescription = group.description ?? ""
                        showEditGroup = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(Color(hex: theme.primaryColor))
                    }
                }
            }
        }
        .task {
            await loadMembers()
        }
        .sheet(isPresented: $showInviteMember) {
            InviteMemberView(groupId: group.id)
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
                .environmentObject(dataStore)
        }
        .alert("Edit Group", isPresented: $showEditGroup) {
            TextField("Group Name", text: $editName)
            TextField("Description (optional)", text: $editDescription)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                Task { await updateGroup() }
            }
        }
        .alert("Delete Group", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteGroup() }
            }
        } message: {
            Text("Are you sure you want to delete \"\(group.name)\"? This will permanently remove all items, categories, locations, and members. This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Something went wrong")
        }
        .overlay {
            if showInviteCodeCopied {
                VStack {
                    Spacer()
                    Text("Invite code copied!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(hex: theme.primaryColor))
                        .cornerRadius(25)
                        .shadow(radius: 4)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showInviteCodeCopied)
            }
        }
    }
    
    // MARK: - Group Info Card
    private var groupInfoCard: some View {
        VStack(spacing: 16) {
            // Group Icon
            ZStack {
                Circle()
                    .fill(Color(hex: theme.primaryColor).opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: theme.primaryColor))
            }
            
            VStack(spacing: 6) {
                Text(group.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: theme.textColor))
                
                if let desc = group.description, !desc.isEmpty {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: theme.textSecondary))
                        .multilineTextAlignment(.center)
                }
            }
            
            // Stats
            HStack(spacing: 24) {
                statItem(icon: "person.2.fill", value: "\(members.count)", label: "Members")
                statItem(icon: "person.fill.badge.plus", value: "\(group.maxMembers ?? 100)", label: "Max")
                if let role = currentUserRole.capitalized as String? {
                    statItem(icon: "shield.fill", value: role, label: "Your Role")
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
        )
    }
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: theme.primaryColor))
            Text(value)
                .font(.headline)
                .foregroundColor(Color(hex: theme.textColor))
            Text(label)
                .font(.caption2)
                .foregroundColor(Color(hex: theme.textSecondary))
        }
    }
    
    // MARK: - Invite Code Card
    private func inviteCodeCard(code: String) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "ticket.fill")
                    .foregroundColor(Color(hex: theme.primaryColor))
                Text("Invite Code")
                    .font(.headline)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
            }
            
            HStack {
                Text(code)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: theme.primaryColor))
                    .tracking(3)
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = code
                    showInviteCodeCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showInviteCodeCopied = false
                    }
                }) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: theme.primaryColor))
                        .padding(8)
                        .background(Color(hex: theme.primaryColor).opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Text("Share this code with others to let them join your group")
                .font(.caption)
                .foregroundColor(Color(hex: theme.textSecondary))
        }
        .padding(16)
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
        )
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 8) {
            if currentUserRole == "owner" || currentUserRole == "admin" {
                Button(action: { showInviteMember = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16))
                        Text("Invite Member")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: theme.primaryColor))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            Button(action: {
                guard let code = group.inviteCode else { return }
                let text = "Join my group \"\(group.name)\" on Expiry Alert! Use invite code: \(code)"
                let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                    Text("Share Invite Link")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: theme.cardBackground))
                .foregroundColor(Color(hex: theme.primaryColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: theme.primaryColor), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Members Section
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Members")
                    .font(.headline)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
                Text("\(members.count)")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: theme.textSecondary))
            }
            
            if isLoadingMembers {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else {
                ForEach(members) { member in
                    MemberRow(
                        member: member,
                        currentUserRole: currentUserRole,
                        currentUserId: authViewModel.user?.id ?? "",
                        theme: theme,
                        onRoleChange: { newRole in
                            Task { await changeMemberRole(member: member, to: newRole) }
                        },
                        onRemove: {
                            Task { await removeMember(member) }
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
        )
    }
    
    // MARK: - Danger Zone
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger Zone")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: theme.dangerColor))
                .textCase(.uppercase)
            
            Button(action: { showDeleteAlert = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Group")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: theme.dangerColor).opacity(0.1))
                .foregroundColor(Color(hex: theme.dangerColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: theme.dangerColor).opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Actions
    private func loadMembers() async {
        isLoadingMembers = true
        do {
            members = try await dataStore.getGroupMembers(groupId: group.id)
            // Find current user's role
            if let userId = authViewModel.user?.id,
               let myMembership = members.first(where: { $0.userId == userId }) {
                currentUserRole = myMembership.role
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoadingMembers = false
    }
    
    private func updateGroup() async {
        do {
            _ = try await dataStore.updateGroup(
                id: group.id,
                name: editName.isEmpty ? nil : editName,
                description: editDescription.isEmpty ? nil : editDescription
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func deleteGroup() async {
        do {
            try await dataStore.deleteGroup(id: group.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func changeMemberRole(member: GroupMembership, to role: String) async {
        do {
            try await dataStore.updateGroupMemberRole(groupId: group.id, memberId: member.userId, role: role)
            await loadMembers()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func removeMember(_ member: GroupMembership) async {
        do {
            try await dataStore.removeGroupMember(groupId: group.id, memberId: member.userId)
            members.removeAll { $0.id == member.id }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Member Row
struct MemberRow: View {
    let member: GroupMembership
    let currentUserRole: String
    let currentUserId: String
    let theme: AppTheme
    let onRoleChange: (String) -> Void
    let onRemove: () -> Void
    
    @State private var showActions = false
    @State private var showRemoveAlert = false
    
    private var isCurrentUser: Bool { member.userId == currentUserId }
    private var isOwner: Bool { member.role == "owner" }
    private var canManage: Bool { (currentUserRole == "owner" || currentUserRole == "admin") && !isCurrentUser && !isOwner }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(roleColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(avatarInitial)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(roleColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.fullName ?? member.email ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: theme.textColor))
                    
                    if isCurrentUser {
                        Text("You")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: theme.primaryColor))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: theme.primaryColor).opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                if let email = member.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(Color(hex: theme.textSecondary))
                }
            }
            
            Spacer()
            
            // Role Badge
            Text(member.role.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(roleColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(roleColor.opacity(0.1))
                .cornerRadius(6)
            
            // Actions
            if canManage {
                Menu {
                    if member.role == "member" {
                        Button(action: { onRoleChange("admin") }) {
                            Label("Make Admin", systemImage: "shield.fill")
                        }
                    } else if member.role == "admin" {
                        Button(action: { onRoleChange("member") }) {
                            Label("Make Member", systemImage: "person.fill")
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showRemoveAlert = true }) {
                        Label("Remove", systemImage: "person.badge.minus")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: theme.textSecondary))
                        .padding(8)
                }
            }
        }
        .padding(.vertical, 4)
        .alert("Remove Member", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) { onRemove() }
        } message: {
            Text("Are you sure you want to remove \(member.fullName ?? member.email ?? "this member") from the group?")
        }
    }
    
    private var avatarInitial: String {
        let name = member.fullName ?? member.email ?? "?"
        return String(name.prefix(1)).uppercased()
    }
    
    private var roleColor: Color {
        switch member.role {
        case "owner": return Color(hex: "#F59E0B")
        case "admin": return Color(hex: theme.primaryColor)
        default: return Color(hex: theme.textSecondary)
        }
    }
}
