import SwiftUI

struct JoinGroupView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var inviteCode = ""
    @State private var isVerifying = false
    @State private var isJoining = false
    @State private var verifiedGroupName: String?
    @State private var verifiedGroupDesc: String?
    @State private var verifiedMemberCount: Int?
    @State private var verificationError: String?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false
    @FocusState private var codeFocused: Bool
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: theme.primaryColor).opacity(0.1))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "person.3.sequence.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(hex: theme.primaryColor))
                            }
                            
                            Text("Join a Group")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: theme.textColor))
                            
                            Text("Enter the invite code to join an existing group")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: theme.textSecondary))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 8)
                        
                        // Code Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Invite Code")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: theme.textColor))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "ticket.fill")
                                    .foregroundColor(Color(hex: theme.textSecondary))
                                    .frame(width: 20)
                                
                                TextField("Enter invite code", text: $inviteCode)
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .autocapitalization(.allCharacters)
                                    .disableAutocorrection(true)
                                    .foregroundColor(Color(hex: theme.textColor))
                                    .focused($codeFocused)
                                    .onChange(of: inviteCode) { _ in
                                        // Reset verification when code changes
                                        verifiedGroupName = nil
                                        verificationError = nil
                                    }
                                
                                if !inviteCode.isEmpty {
                                    Button(action: { inviteCode = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color(hex: theme.textSecondary))
                                    }
                                }
                            }
                            .padding(14)
                            .background(Color(hex: theme.cardBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        codeFocused
                                        ? Color(hex: theme.primaryColor)
                                        : Color(hex: theme.borderColor),
                                        lineWidth: codeFocused ? 2 : 1
                                    )
                            )
                        }
                        
                        // Verify Button
                        if verifiedGroupName == nil && inviteCode.count >= 8 {
                            Button(action: { Task { await verifyCode() } }) {
                                HStack(spacing: 8) {
                                    if isVerifying {
                                        ProgressView()
                                            .tint(Color(hex: theme.primaryColor))
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                    }
                                    Text(isVerifying ? "Verifying..." : "Verify Code")
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
                            .disabled(isVerifying)
                        }
                        
                        // Verification Error
                        if let error = verificationError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color(hex: theme.dangerColor))
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: theme.dangerColor))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: theme.dangerColor).opacity(0.08))
                            .cornerRadius(8)
                        }
                        
                        // Verified Group Preview
                        if let groupName = verifiedGroupName {
                            VStack(spacing: 16) {
                                // Group Preview Card
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: theme.primaryColor).opacity(0.15))
                                            .frame(width: 56, height: 56)
                                        Image(systemName: "person.3.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(Color(hex: theme.primaryColor))
                                    }
                                    
                                    Text(groupName)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(hex: theme.textColor))
                                    
                                    if let desc = verifiedGroupDesc, !desc.isEmpty {
                                        Text(desc)
                                            .font(.subheadline)
                                            .foregroundColor(Color(hex: theme.textSecondary))
                                    }
                                    
                                    if let count = verifiedMemberCount {
                                        HStack(spacing: 4) {
                                            Image(systemName: "person.2.fill")
                                                .font(.caption)
                                            Text("\(count) member\(count == 1 ? "" : "s")")
                                                .font(.caption)
                                        }
                                        .foregroundColor(Color(hex: theme.textSecondary))
                                    }
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: theme.primaryColor).opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: theme.primaryColor).opacity(0.3), lineWidth: 1)
                                )
                                
                                // Join Button
                                Button(action: { Task { await joinGroup() } }) {
                                    HStack(spacing: 8) {
                                        if isJoining {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "arrow.right.circle.fill")
                                        }
                                        Text(isJoining ? "Joining..." : "Join Group")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(hex: theme.primaryColor))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(isJoining)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Join Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "Something went wrong")
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("You have successfully joined \(verifiedGroupName ?? "the group")!")
            }
        }
    }
    
    // MARK: - Actions
    private func verifyCode() async {
        isVerifying = true
        verificationError = nil
        
        do {
            let verification = try await APIService.shared.verifyInviteCode(code: inviteCode)
            if verification.valid, let group = verification.group {
                verifiedGroupName = group.name
                verifiedGroupDesc = group.description
                verifiedMemberCount = group.memberCount
            } else {
                verificationError = verification.error ?? "Invalid or expired invite code"
            }
        } catch {
            verificationError = "Could not verify code. Please check and try again."
        }
        
        isVerifying = false
    }
    
    private func joinGroup() async {
        isJoining = true
        
        do {
            try await dataStore.joinGroupByCode(code: inviteCode)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isJoining = false
    }
}
