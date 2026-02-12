import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isSignUp = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSubmitting = false
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 60)
                    
                    // Logo
                    ZStack {
                        Circle()
                            .fill(Color(hex: theme.cardBackground))
                            .frame(width: 120, height: 120)
                            .shadow(radius: 10)
                        
                        Image(systemName: "leaf.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color(hex: theme.primaryColor))
                    }
                    
                    // Title
                    Text(localizationManager.t("app.name"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: theme.textColor))
                    
                    // Form
                    VStack(spacing: 12) {
                        if isSignUp {
                            TextField("Full Name", text: $fullName)
                                .textFieldStyle(ThemedTextFieldStyle(theme: theme))
                                .textContentType(.name)
                                .autocapitalization(.words)
                        }
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(ThemedTextFieldStyle(theme: theme))
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(ThemedTextFieldStyle(theme: theme))
                            .textContentType(isSignUp ? .newPassword : .password)
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
