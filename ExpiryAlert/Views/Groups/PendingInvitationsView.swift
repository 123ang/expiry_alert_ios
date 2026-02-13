import SwiftUI

struct PendingInvitationsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var invitations: [Invitation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var processingIds: Set<String> = []
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            if isLoading {
                ProgressView()
            } else if invitations.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(invitations) { invitation in
                            InvitationCard(
                                invitation: invitation,
                                theme: theme,
                                isProcessing: processingIds.contains(invitation.id),
                                onAccept: { Task { await acceptInvitation(invitation) } },
                                onDecline: { Task { await declineInvitation(invitation) } }
                            )
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Invitations")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInvitations()
        }
        .refreshable {
            await loadInvitations()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Something went wrong")
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: theme.primaryColor).opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "envelope.open")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: theme.primaryColor))
            }
            
            Text("No Pending Invitations")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: theme.textColor))
            
            Text("When someone invites you to a group, it will appear here")
                .font(.subheadline)
                .foregroundColor(Color(hex: theme.textSecondary))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Actions
    private func loadInvitations() async {
        isLoading = true
        do {
            invitations = try await dataStore.getPendingInvitations()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
    
    private func acceptInvitation(_ invitation: Invitation) async {
        processingIds.insert(invitation.id)
        do {
            try await dataStore.acceptInvitation(id: invitation.id)
            invitations.removeAll { $0.id == invitation.id }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        processingIds.remove(invitation.id)
    }
    
    private func declineInvitation(_ invitation: Invitation) async {
        processingIds.insert(invitation.id)
        do {
            try await dataStore.declineInvitation(id: invitation.id)
            invitations.removeAll { $0.id == invitation.id }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        processingIds.remove(invitation.id)
    }
}

// MARK: - Invitation Card
struct InvitationCard: View {
    let invitation: Invitation
    let theme: AppTheme
    let isProcessing: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: theme.primaryColor).opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(invitation.groupName ?? "Group")
                        .font(.headline)
                        .foregroundColor(Color(hex: theme.textColor))
                    
                    if let desc = invitation.groupDescription, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(Color(hex: theme.textSecondary))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            
            // Invited by
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundColor(Color(hex: theme.textSecondary))
                Text("Invited by")
                    .font(.caption)
                    .foregroundColor(Color(hex: theme.textSecondary))
                Text(invitation.invitedByName ?? invitation.invitedByEmail ?? "Someone")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: theme.textColor))
                Spacer()
                
                if let expiresAt = invitation.expiresAt {
                    Text(expiryText(expiresAt))
                        .font(.caption2)
                        .foregroundColor(Color(hex: theme.warningColor))
                }
            }
            
            Divider()
            
            // Buttons
            HStack(spacing: 10) {
                Button(action: onDecline) {
                    HStack(spacing: 4) {
                        if isProcessing {
                            ProgressView()
                                .tint(Color(hex: theme.textSecondary))
                                .scaleEffect(0.8)
                        }
                        Text("Decline")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: theme.cardBackground))
                    .foregroundColor(Color(hex: theme.textSecondary))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: theme.borderColor), lineWidth: 1)
                    )
                }
                .disabled(isProcessing)
                
                Button(action: onAccept) {
                    HStack(spacing: 4) {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        }
                        Text("Accept")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: theme.primaryColor))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isProcessing)
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
    
    private func expiryText(_ dateStr: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateStr) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateStr) else { return "" }
            return timeUntil(date)
        }
        return timeUntil(date)
    }
    
    private func timeUntil(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days <= 0 { return "Expires soon" }
        if days == 1 { return "Expires in 1 day" }
        return "Expires in \(days) days"
    }
}
