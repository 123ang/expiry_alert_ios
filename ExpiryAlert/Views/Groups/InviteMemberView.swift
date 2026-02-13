import SwiftUI

struct InviteMemberView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    let groupId: String
    
    @State private var email = ""
    @State private var isSending = false
    @State private var sentEmails: [String] = []
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false
    @FocusState private var emailFocused: Bool
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    private var isValidEmail: Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: theme.backgroundColor).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Illustration
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: theme.primaryColor).opacity(0.1))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color(hex: theme.primaryColor))
                            }
                            
                            Text("Invite a Member")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: theme.textColor))
                            
                            Text("Send an invitation email to add someone to your group")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: theme.textSecondary))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 8)
                        
                        // Email Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: theme.textColor))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(Color(hex: theme.textSecondary))
                                    .frame(width: 20)
                                
                                TextField("Enter email address", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .foregroundColor(Color(hex: theme.textColor))
                                    .focused($emailFocused)
                                
                                if !email.isEmpty {
                                    Button(action: { email = "" }) {
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
                                        emailFocused
                                        ? Color(hex: theme.primaryColor)
                                        : Color(hex: theme.borderColor),
                                        lineWidth: emailFocused ? 2 : 1
                                    )
                            )
                            
                            if !email.isEmpty && !isValidEmail {
                                Text("Please enter a valid email address")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: theme.dangerColor))
                            }
                        }
                        
                        // Send Button
                        Button(action: { Task { await sendInvitation() } }) {
                            HStack(spacing: 8) {
                                if isSending {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                }
                                Text(isSending ? "Sending..." : "Send Invitation")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                isValidEmail && !isSending
                                ? Color(hex: theme.primaryColor)
                                : Color(hex: theme.primaryColor).opacity(0.4)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isValidEmail || isSending)
                        
                        // Sent Invitations
                        if !sentEmails.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Sent Invitations")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(hex: theme.textColor))
                                
                                ForEach(sentEmails, id: \.self) { sentEmail in
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(hex: theme.successColor))
                                        Text(sentEmail)
                                            .font(.subheadline)
                                            .foregroundColor(Color(hex: theme.textColor))
                                        Spacer()
                                        Text("Sent")
                                            .font(.caption)
                                            .foregroundColor(Color(hex: theme.successColor))
                                    }
                                    .padding(12)
                                    .background(Color(hex: theme.successColor).opacity(0.08))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Invite Member")
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
        }
    }
    
    private func sendInvitation() async {
        guard isValidEmail else { return }
        isSending = true
        
        do {
            _ = try await dataStore.sendInvitation(groupId: groupId, email: email)
            sentEmails.append(email)
            email = ""
            emailFocused = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isSending = false
    }
}
