import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = true
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    init() {
        checkExistingSession()
    }
    
    private func checkExistingSession() {
        if TokenManager.shared.isLoggedIn {
            Task {
                do {
                    let user = try await APIService.shared.getCurrentUser()
                    self.user = user
                    self.isAuthenticated = true
                } catch {
                    // Token expired or invalid
                    TokenManager.shared.clearTokens()
                    self.isAuthenticated = false
                }
                self.isLoading = false
            }
        } else {
            isLoading = false
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let response = try await APIService.shared.login(email: email, password: password)
            TokenManager.shared.saveTokens(response.tokens, deviceId: response.device?.id)
            self.user = response.user
            self.isAuthenticated = true
        } catch let error as APIError {
            self.errorMessage = error.errorDescription
            throw error
        }
    }
    
    func signUp(email: String, password: String, fullName: String?) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let response = try await APIService.shared.register(email: email, password: password, fullName: fullName)
            TokenManager.shared.saveTokens(response.tokens, deviceId: response.device?.id)
            self.user = response.user
            self.isAuthenticated = true
        } catch let error as APIError {
            self.errorMessage = error.errorDescription
            throw error
        }
    }
    
    func signOut() async {
        do {
            try await APIService.shared.logout()
        } catch {
            // Still sign out locally even if API call fails
        }
        TokenManager.shared.clearTokens()
        self.user = nil
        self.isAuthenticated = false
    }
    
    func updateEmail(_ email: String) async throws {
        let updated = try await APIService.shared.updateProfile(fullName: nil, languagePreference: nil, email: email)
        self.user = updated
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        try await APIService.shared.changePassword(currentPassword: currentPassword, newPassword: newPassword)
    }
}
