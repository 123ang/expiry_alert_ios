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
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 60)
                    
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
                    
                    // Form
                    VStack(spacing: 12) {
                        if isSignUp {
                            ThemedTextField(placeholder: "Full Name", text: $fullName, theme: theme, textContentType: .name, autocapitalization: .words)
                        }
                        
                        ThemedTextField(placeholder: "Email", text: $email, theme: theme, keyboardType: .emailAddress, textContentType: .emailAddress, autocapitalization: .never)
                        
                        // Password with eye toggle
                        HStack {
                            if showPassword {
                                ThemedTextField(placeholder: "Password", text: $password, theme: theme, textContentType: isSignUp ? .newPassword : .password, autocapitalization: .never)
                            } else {
                                ThemedSecureField(placeholder: "Password", text: $password, theme: theme, textContentType: isSignUp ? .newPassword : .password)
                            }
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(Color(hex: theme.placeholderColor))
                                    .frame(width: 44, height: 44)
                            }
                        }
                        
                        if isSignUp {
                            // Confirm Password with eye toggle
                            HStack {
                                if showConfirmPassword {
                                    ThemedTextField(placeholder: "Confirm Password", text: $confirmPassword, theme: theme, textContentType: .newPassword, autocapitalization: .never)
                                } else {
                                    ThemedSecureField(placeholder: "Confirm Password", text: $confirmPassword, theme: theme, textContentType: .newPassword)
                                }
                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(Color(hex: theme.placeholderColor))
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
                                Text(isSignUp ? "Sign Up" : "Login")
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
                        Text(isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up")
                            .foregroundColor(Color(hex: theme.primaryColor))
                            .font(.subheadline)
                    })
                    
                    Spacer()
                }
            }
        }
        .onChange(of: isSignUp) { _, newValue in
            if !newValue { confirmPassword = "" }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
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
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundColor(Color(hex: theme.placeholderColor))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
            }
            TextField("", text: $text)
                .font(.body)
                .foregroundColor(Color(hex: theme.textColor))
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
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundColor(Color(hex: theme.placeholderColor))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
            }
            SecureField("", text: $text)
                .font(.body)
                .foregroundColor(Color(hex: theme.textColor))
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
