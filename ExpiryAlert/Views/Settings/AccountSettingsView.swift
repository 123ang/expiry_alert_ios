import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isChangingPassword = false
    @State private var showLogoutAlert = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Messages
                    if let err = errorMessage {
                        messageBanner(icon: "exclamationmark.triangle.fill", text: err, color: theme.dangerColor)
                    }
                    if let ok = successMessage {
                        messageBanner(icon: "checkmark.circle.fill", text: ok, color: theme.successColor)
                    }
                    
                    // Account info card – email (read-only)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: theme.primaryColor).opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(hex: theme.primaryColor))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizationManager.t("account.email"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: theme.placeholderColor))
                                    .textCase(.uppercase)
                                Text(authViewModel.user?.email ?? "—")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: theme.textColor))
                            }
                            Spacer()
                        }
                        .padding(16)
                    }
                    .background(cardBackground)
                    
                    // Change password card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: theme.primaryColor))
                            Text(localizationManager.t("account.changePasswordSection"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(hex: theme.textColor))
                        }
                        
                        ThemedSecureField(placeholder: localizationManager.t("account.currentPassword"), text: $currentPassword, theme: theme, textContentType: .password)
                        ThemedSecureField(placeholder: localizationManager.t("account.newPassword"), text: $newPassword, theme: theme, textContentType: .newPassword)
                        ThemedSecureField(placeholder: localizationManager.t("account.confirmNewPassword"), text: $confirmPassword, theme: theme, textContentType: .newPassword)
                        
                        Button(action: changePassword) {
                            HStack {
                                if isChangingPassword {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(localizationManager.t("account.changePasswordButton"))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: theme.primaryColor))
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                            .cornerRadius(theme.borderRadius)
                        }
                        .disabled(isChangingPassword || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                    }
                    .padding(20)
                    .background(cardBackground)
                    
                    Spacer(minLength: 32)
                    
                    // Log out
                    Button(action: { showLogoutAlert = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .medium))
                            Text(localizationManager.t("account.logOut"))
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(Color(hex: theme.dangerColor))
                        .background(Color(hex: theme.dangerColor).opacity(0.12))
                        .cornerRadius(theme.borderRadius)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(20)
            }
        }
        .navigationTitle(localizationManager.t("account.title"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(localizationManager.t("account.logOutAlertTitle"), isPresented: $showLogoutAlert) {
            Button(localizationManager.t("common.cancel"), role: .cancel) {}
            Button(localizationManager.t("account.logOut"), role: .destructive) {
                Task { await authViewModel.signOut() }
            }
        } message: {
            Text(localizationManager.t("account.logOutAlertMessage"))
        }
    }
    
    private func messageBanner(icon: String, text: String, color: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: color))
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color(hex: color))
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: color).opacity(0.12))
        .cornerRadius(theme.borderRadius)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(hex: theme.cardBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: theme.borderColor).opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color(hex: theme.shadowColor).opacity(0.25), radius: 6, x: 0, y: 2)
    }
    
    private func changePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = localizationManager.t("account.passwordsDoNotMatch")
            return
        }
        guard newPassword.count >= 6 else {
            errorMessage = localizationManager.t("account.passwordTooShort")
            return
        }
        errorMessage = nil
        successMessage = nil
        isChangingPassword = true
        Task {
            do {
                try await authViewModel.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                successMessage = localizationManager.t("account.passwordChanged")
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
                isChangingPassword = false
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                isChangingPassword = false
            }
        }
    }
}
