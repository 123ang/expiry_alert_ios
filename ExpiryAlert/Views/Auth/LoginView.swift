import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var isSignUp = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSubmitting = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showLanguagePicker = false
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)
                    
                    // Language selector – choose language before logging in
                    Button(action: { showLanguagePicker = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(.subheadline)
                            Text(localizationManager.currentLanguage.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(Color(hex: theme.primaryColor))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: theme.primaryColor).opacity(0.12))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer().frame(height: 20)
                    
                    // Logo
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .shadow(radius: 10)
                    
                    // Title
                    Text(localizationManager.t("app.name"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: theme.textColor))
                    
                    // Form – use contrasting colors: white text for dark themes (Black, Dark Brown, Dark Gold), dark for others
                    let inputTextColor = theme.calendarTextColor
                    let inputPlaceholderColor = theme.subtitleOnCard
                    VStack(spacing: 12) {
                        if isSignUp {
                            ThemedTextField(placeholder: localizationManager.t("auth.fullName"), text: $fullName, theme: theme, textContentType: .name, autocapitalization: .words, textColorOverride: inputTextColor, placeholderColorOverride: inputPlaceholderColor)
                        }
                        
                        ThemedTextField(placeholder: localizationManager.t("auth.email"), text: $email, theme: theme, keyboardType: .emailAddress, textContentType: .emailAddress, autocapitalization: .never, textColorOverride: inputTextColor, placeholderColorOverride: inputPlaceholderColor)
                        
                        // Password with eye toggle
                        HStack {
                            if showPassword {
                                ThemedTextField(placeholder: localizationManager.t("auth.password"), text: $password, theme: theme, textContentType: isSignUp ? .newPassword : .password, autocapitalization: .never, textColorOverride: inputTextColor, placeholderColorOverride: inputPlaceholderColor)
                            } else {
                                ThemedSecureField(placeholder: localizationManager.t("auth.password"), text: $password, theme: theme, textContentType: isSignUp ? .newPassword : .password, textColorOverride: inputTextColor, placeholderColorOverride: inputPlaceholderColor)
                            }
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(Color(hex: inputPlaceholderColor))
                                    .frame(width: 44, height: 44)
                            }
                        }
                        
                        if isSignUp {
                            // Confirm Password with eye toggle
                            HStack {
                                if showConfirmPassword {
                                    ThemedTextField(placeholder: localizationManager.t("auth.confirmPassword"), text: $confirmPassword, theme: theme, textContentType: .newPassword, autocapitalization: .never, textColorOverride: inputTextColor, placeholderColorOverride: inputPlaceholderColor)
                                } else {
                                    ThemedSecureField(placeholder: localizationManager.t("auth.confirmPassword"), text: $confirmPassword, theme: theme, textContentType: .newPassword, textColorOverride: inputTextColor, placeholderColorOverride: inputPlaceholderColor)
                                }
                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(Color(hex: inputPlaceholderColor))
                                        .frame(width: 44, height: 44)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Submit Button
                    Button(action: handleSubmit, label: {
                        ZStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isSignUp ? localizationManager.t("auth.signUp") : localizationManager.t("auth.login"))
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color(hex: theme.primaryColor))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    })
                    .disabled(isSubmitting)
                    .padding(.horizontal, 20)
                    
                    // Toggle Sign Up / Login
                    Button(action: { withAnimation { isSignUp.toggle() } }, label: {
                        Text(isSignUp ? localizationManager.t("auth.alreadyHaveAccount") : localizationManager.t("auth.dontHaveAccount"))
                            .foregroundColor(Color(hex: theme.primaryColor))
                            .font(.subheadline)
                    })
                    
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showLanguagePicker) {
            languagePickerSheet
        }
        .onChange(of: isSignUp) { _, newValue in
            if !newValue { confirmPassword = "" }
        }
        .alert(localizationManager.t("alert.error"), isPresented: $showError) {
            Button(localizationManager.t("common.ok"), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var languagePickerSheet: some View {
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
            .navigationTitle(localizationManager.t("auth.language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: theme.backgroundColor), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.t("common.close")) { showLanguagePicker = false }
                        .foregroundColor(Color(hex: theme.primaryColor))
                }
            }
        }
    }
    
    private func handleSubmit() {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        if isSignUp {
            guard !confirmPassword.isEmpty else {
                errorMessage = "Please confirm your password"
                showError = true
                return
            }
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match"
                showError = true
                return
            }
        }
        
        isSubmitting = true
        Task {
            do {
                if isSignUp {
                    try await authViewModel.signUp(
                        email: email.trimmingCharacters(in: .whitespaces),
                        password: password,
                        fullName: fullName.isEmpty ? nil : fullName
                    )
                } else {
                    try await authViewModel.signIn(
                        email: email.trimmingCharacters(in: .whitespaces),
                        password: password
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isSubmitting = false
        }
    }
}

// MARK: - Themed Text Field Style
struct ThemedTextFieldStyle: TextFieldStyle {
    let theme: AppTheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(15)
            .background(Color(hex: theme.cardBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: theme.borderColor), lineWidth: 1)
            )
            .foregroundColor(Color(hex: theme.textColor))
    }
}

// MARK: - Themed Text Field with visible placeholder (theme-based contrast)
struct ThemedTextField: View {
    let placeholder: String
    @Binding var text: String
    let theme: AppTheme
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences
    /// Override for input text color (e.g. theme.calendarTextColor on login for readability).
    var textColorOverride: String? = nil
    /// Override for placeholder color (e.g. theme.subtitleOnCard).
    var placeholderColorOverride: String? = nil
    
    private var inputTextColor: String { textColorOverride ?? theme.textColor }
    private var inputPlaceholderColor: String { placeholderColorOverride ?? theme.placeholderColor }
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundColor(Color(hex: inputPlaceholderColor))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
            }
            TextField("", text: $text)
                .font(.body)
                .foregroundColor(Color(hex: inputTextColor))
                .padding(15)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
        }
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
        )
    }
}

// MARK: - Themed Secure Field with visible placeholder
struct ThemedSecureField: View {
    let placeholder: String
    @Binding var text: String
    let theme: AppTheme
    var textContentType: UITextContentType?
    var textColorOverride: String? = nil
    var placeholderColorOverride: String? = nil
    
    private var inputTextColor: String { textColorOverride ?? theme.textColor }
    private var inputPlaceholderColor: String { placeholderColorOverride ?? theme.placeholderColor }
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundColor(Color(hex: inputPlaceholderColor))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
            }
            SecureField("", text: $text)
                .font(.body)
                .foregroundColor(Color(hex: inputTextColor))
                .padding(15)
                .textContentType(textContentType)
        }
        .background(Color(hex: theme.cardBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: theme.borderColor), lineWidth: 1)
        )
    }
}
