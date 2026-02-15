import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSavingEmail = false
    @State private var isChangingPassword = false
    @State private var showLogoutAlert = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let err = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color(hex: theme.dangerColor))
                            Text(err)
                                .font(.subheadline)
                                .foregroundColor(Color(hex: theme.dangerColor))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: theme.dangerColor).opacity(0.12))
                        .cornerRadius(theme.borderRadius)
                    }
                    if let ok = successMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: theme.successColor))
                            Text(ok)
                                .font(.subheadline)
                                .foregroundColor(Color(hex: theme.successColor))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: theme.successColor).opacity(0.12))
                        .cornerRadius(theme.borderRadius)
                    }
                    
                    // Email
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localizationManager.t("account.email"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: theme.placeholderColor))
                            .textCase(.uppercase)
                        ThemedTextField(placeholder: localizationManager.t("account.email"), text: $email, theme: theme, keyboardType: .emailAddress, textContentType: .emailAddress, autocapitalization: .never)
                        Button(action: saveEmail) {
                            HStack {
                                if isSavingEmail {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(localizationManager.t("account.saveEmail"))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: theme.primaryColor))
                            .foregroundColor(.white)
                            .cornerRadius(theme.borderRadius)
                        }
                        .disabled(isSavingEmail || email.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    
                    // Change password
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localizationManager.t("account.changePasswordSection"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: theme.placeholderColor))
                            .textCase(.uppercase)
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
                            .padding(.vertical, 12)
                            .background(Color(hex: theme.primaryColor))
                            .foregroundColor(.white)
                            .cornerRadius(theme.borderRadius)
                        }
                        .disabled(isChangingPassword || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Log out
                    Button(action: { showLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text(localizationManager.t("account.logOut"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
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
        .onAppear {
            email = authViewModel.user?.email ?? ""
        }
        .alert(localizationManager.t("account.logOutAlertTitle"), isPresented: $showLogoutAlert) {
            Button(localizationManager.t("common.cancel"), role: .cancel) {}
            Button(localizationManager.t("account.logOut"), role: .destructive) {
                Task { await authViewModel.signOut() }
            }
        } message: {
            Text(localizationManager.t("account.logOutAlertMessage"))
        }
    }
    
    private func saveEmail() {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        errorMessage = nil
        successMessage = nil
        isSavingEmail = true
        Task {
            do {
                try await authViewModel.updateEmail(trimmed)
                successMessage = localizationManager.t("account.emailUpdated")
                isSavingEmail = false
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                isSavingEmail = false
            }
        }
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
