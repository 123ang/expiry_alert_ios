import Foundation

// MARK: - API Configuration
enum APIConfig {
    // Change this to your VPS URL when deployed
    static var baseURL: String {
        #if DEBUG
        return "http://localhost:3000/api"
        #else
        return "https://your-vps-domain.com/api"
        #endif
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(Int, String)
    case unauthorized
    case networkError(Error)
    case tokenExpired
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
        case .unauthorized: return "Authentication required"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .tokenExpired: return "Session expired. Please login again."
        }
    }
}

// MARK: - Token Manager
class TokenManager {
    static let shared = TokenManager()
    
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let deviceIdKey = "device_id"
    
    private init() {}
    
    var accessToken: String? {
        get { KeychainHelper.get(key: accessTokenKey) }
        set {
            if let value = newValue {
                KeychainHelper.save(key: accessTokenKey, value: value)
            } else {
                KeychainHelper.delete(key: accessTokenKey)
            }
        }
    }
    
    var refreshToken: String? {
        get { KeychainHelper.get(key: refreshTokenKey) }
        set {
            if let value = newValue {
                KeychainHelper.save(key: refreshTokenKey, value: value)
            } else {
                KeychainHelper.delete(key: refreshTokenKey)
            }
        }
    }
    
    var deviceId: String? {
        get { UserDefaults.standard.string(forKey: deviceIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: deviceIdKey) }
    }
    
    func saveTokens(_ tokens: AuthTokens, deviceId: String? = nil) {
        accessToken = tokens.accessToken
        refreshToken = tokens.refreshToken
        if let deviceId = deviceId {
            self.deviceId = deviceId
        }
    }
    
    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        deviceId = nil
    }
    
    var isLoggedIn: Bool {
        accessToken != nil
    }
}

// MARK: - Keychain Helper
enum KeychainHelper {
    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - API Service
class APIService {
    static let shared = APIService()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private var isRefreshing = false
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
        
        decoder = JSONDecoder()
    }
    
    // MARK: - Generic Request
    func request<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        authenticated: Bool = true,
        retryOnUnauth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(APIConfig.baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if authenticated, let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.noData
            }
            
            // Handle 401 - try refresh token
            if httpResponse.statusCode == 401 && authenticated && retryOnUnauth {
                let refreshed = try await refreshAccessToken()
                if refreshed {
                    return try await self.request(
                        endpoint: endpoint,
                        method: method,
                        body: body,
                        authenticated: true,
                        retryOnUnauth: false
                    )
                } else {
                    throw APIError.unauthorized
                }
            }
            
            // Handle error status codes
            if httpResponse.statusCode >= 400 {
                if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(httpResponse.statusCode, errorResponse.error)
                }
                throw APIError.serverError(httpResponse.statusCode, "Unknown error")
            }
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Request without response body
    func requestVoid(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        authenticated: Bool = true
    ) async throws {
        let _: MessageResponse = try await request(
            endpoint: endpoint,
            method: method,
            body: body,
            authenticated: authenticated
        )
    }
    
    // MARK: - Token Refresh
    private func refreshAccessToken() async throws -> Bool {
        guard !isRefreshing else { return false }
        guard let refreshToken = TokenManager.shared.refreshToken else { return false }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            let response: RefreshResponse = try await request(
                endpoint: "/auth/refresh",
                method: "POST",
                body: ["refreshToken": refreshToken],
                authenticated: false,
                retryOnUnauth: false
            )
            TokenManager.shared.saveTokens(response.tokens)
            return true
        } catch {
            TokenManager.shared.clearTokens()
            return false
        }
    }
    
    // MARK: - Image Upload
    func uploadImage(imageData: Data, filename: String) async throws -> String {
        guard let url = URL(string: "\(APIConfig.baseURL)/upload/image") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError(0, "Upload failed")
        }
        
        struct UploadResponse: Codable {
            let url: String?
            let filename: String?
        }
        
        let uploadResponse = try decoder.decode(UploadResponse.self, from: data)
        return uploadResponse.url ?? uploadResponse.filename ?? ""
    }
}

// MARK: - Auth API
extension APIService {
    func register(email: String, password: String, fullName: String?) async throws -> AuthResponse {
        var body: [String: Any] = [
            "email": email,
            "password": password,
            "device_info": [
                "device_uuid": DeviceInfo.current.deviceUuid,
                "device_name": DeviceInfo.current.deviceName ?? "",
                "device_type": DeviceInfo.current.deviceType ?? "phone",
                "platform": "ios"
            ]
        ]
        if let fullName = fullName {
            body["full_name"] = fullName
        }
        return try await request(endpoint: "/auth/register", method: "POST", body: body, authenticated: false)
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "device_info": [
                "device_uuid": DeviceInfo.current.deviceUuid,
                "device_name": DeviceInfo.current.deviceName ?? "",
                "device_type": DeviceInfo.current.deviceType ?? "phone",
                "platform": "ios"
            ]
        ]
        return try await request(endpoint: "/auth/login", method: "POST", body: body, authenticated: false)
    }
    
    func logout() async throws {
        try await requestVoid(endpoint: "/auth/logout", method: "POST")
    }
}

// MARK: - Groups API
extension APIService {
    func getGroups() async throws -> [Group] {
        struct Response: Codable { let groups: [Group] }
        let response: Response = try await request(endpoint: "/groups")
        return response.groups
    }
    
    func createGroup(name: String, description: String?) async throws -> Group {
        var body: [String: Any] = ["name": name]
        if let desc = description { body["description"] = desc }
        let response: SingleItemResponse<Group> = try await request(endpoint: "/groups", method: "POST", body: body)
        return response.item
    }
    
    func getGroupMembers(groupId: String) async throws -> [GroupMembership] {
        struct Response: Codable { let members: [GroupMembership] }
        let response: Response = try await request(endpoint: "/groups/\(groupId)/members")
        return response.members
    }
}

// MARK: - Categories API
extension APIService {
    func getCategories(groupId: String?) async throws -> [Category] {
        var endpoint = "/categories"
        if let groupId = groupId { endpoint += "?group_id=\(groupId)" }
        let response: ItemsResponse<Category> = try await request(endpoint: endpoint)
        return response.items
    }
    
    func createCategory(name: String, icon: String?, groupId: String?) async throws -> Category {
        var body: [String: Any] = ["name": name]
        if let icon = icon { body["icon"] = icon }
        if let groupId = groupId { body["group_id"] = groupId }
        let response: SingleItemResponse<Category> = try await request(endpoint: "/categories", method: "POST", body: body)
        return response.item
    }
    
    func updateCategory(id: String, name: String?, icon: String?) async throws -> Category {
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let icon = icon { body["icon"] = icon }
        let response: SingleItemResponse<Category> = try await request(endpoint: "/categories/\(id)", method: "PATCH", body: body)
        return response.item
    }
    
    func deleteCategory(id: String) async throws {
        try await requestVoid(endpoint: "/categories/\(id)", method: "DELETE")
    }
}

// MARK: - Locations API
extension APIService {
    func getLocations(groupId: String?) async throws -> [Location] {
        var endpoint = "/locations"
        if let groupId = groupId { endpoint += "?group_id=\(groupId)" }
        let response: ItemsResponse<Location> = try await request(endpoint: endpoint)
        return response.items
    }
    
    func createLocation(name: String, icon: String?, groupId: String?) async throws -> Location {
        var body: [String: Any] = ["name": name]
        if let icon = icon { body["icon"] = icon }
        if let groupId = groupId { body["group_id"] = groupId }
        let response: SingleItemResponse<Location> = try await request(endpoint: "/locations", method: "POST", body: body)
        return response.item
    }
    
    func updateLocation(id: String, name: String?, icon: String?) async throws -> Location {
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let icon = icon { body["icon"] = icon }
        let response: SingleItemResponse<Location> = try await request(endpoint: "/locations/\(id)", method: "PATCH", body: body)
        return response.item
    }
    
    func deleteLocation(id: String) async throws {
        try await requestVoid(endpoint: "/locations/\(id)", method: "DELETE")
    }
}

// MARK: - Food Items API
extension APIService {
    func getFoodItems(groupId: String, status: String? = nil) async throws -> [FoodItem] {
        var endpoint = "/food-items?group_id=\(groupId)"
        if let status = status { endpoint += "&status=\(status)" }
        let response: ItemsResponse<FoodItem> = try await request(endpoint: endpoint)
        return response.items
    }
    
    func getFoodItem(id: String) async throws -> FoodItem {
        let response: SingleItemResponse<FoodItem> = try await request(endpoint: "/food-items/\(id)")
        return response.item
    }
    
    func getExpiringItems(groupId: String, days: Int = 3) async throws -> [FoodItem] {
        let response: ItemsResponse<FoodItem> = try await request(
            endpoint: "/food-items/expiring?group_id=\(groupId)&days=\(days)"
        )
        return response.items
    }
    
    func getExpiredItems(groupId: String) async throws -> [FoodItem] {
        let response: ItemsResponse<FoodItem> = try await request(
            endpoint: "/food-items/expired?group_id=\(groupId)"
        )
        return response.items
    }
    
    func createFoodItem(item: [String: Any]) async throws -> FoodItem {
        let response: SingleItemResponse<FoodItem> = try await request(
            endpoint: "/food-items",
            method: "POST",
            body: item
        )
        return response.item
    }
    
    func updateFoodItem(id: String, updates: [String: Any]) async throws -> FoodItem {
        let response: SingleItemResponse<FoodItem> = try await request(
            endpoint: "/food-items/\(id)",
            method: "PATCH",
            body: updates
        )
        return response.item
    }
    
    func deleteFoodItem(id: String) async throws {
        try await requestVoid(endpoint: "/food-items/\(id)", method: "DELETE")
    }
    
    func logFoodItemEvent(itemId: String, eventType: String, quantityAffected: Int, disposalReason: String? = nil) async throws -> FoodItemEvent {
        var body: [String: Any] = [
            "event_type": eventType,
            "quantity_affected": quantityAffected
        ]
        if let reason = disposalReason { body["disposal_reason"] = reason }
        let response: SingleItemResponse<FoodItemEvent> = try await request(
            endpoint: "/food-items/\(itemId)/events",
            method: "POST",
            body: body
        )
        return response.item
    }
}

// MARK: - Shopping Items API
extension APIService {
    func getShoppingItems(groupId: String, includePurchased: Bool = false) async throws -> [ShoppingItem] {
        let endpoint = "/shopping-items?group_id=\(groupId)&include_purchased=\(includePurchased)"
        let response: ItemsResponse<ShoppingItem> = try await request(endpoint: endpoint)
        return response.items
    }
    
    func createShoppingItem(item: [String: Any]) async throws -> ShoppingItem {
        let response: SingleItemResponse<ShoppingItem> = try await request(
            endpoint: "/shopping-items", method: "POST", body: item
        )
        return response.item
    }
    
    func updateShoppingItem(id: String, updates: [String: Any]) async throws -> ShoppingItem {
        let response: SingleItemResponse<ShoppingItem> = try await request(
            endpoint: "/shopping-items/\(id)", method: "PATCH", body: updates
        )
        return response.item
    }
    
    func deleteShoppingItem(id: String) async throws {
        try await requestVoid(endpoint: "/shopping-items/\(id)", method: "DELETE")
    }
    
    func toggleShoppingItem(id: String) async throws -> ShoppingItem {
        let response: SingleItemResponse<ShoppingItem> = try await request(
            endpoint: "/shopping-items/\(id)/toggle", method: "POST"
        )
        return response.item
    }
}

// MARK: - Wish Items API
extension APIService {
    func getWishItems(groupId: String) async throws -> [WishItem] {
        let response: ItemsResponse<WishItem> = try await request(
            endpoint: "/wish-items?group_id=\(groupId)"
        )
        return response.items
    }
    
    func createWishItem(item: [String: Any]) async throws -> WishItem {
        let response: SingleItemResponse<WishItem> = try await request(
            endpoint: "/wish-items", method: "POST", body: item
        )
        return response.item
    }
    
    func updateWishItem(id: String, updates: [String: Any]) async throws -> WishItem {
        let response: SingleItemResponse<WishItem> = try await request(
            endpoint: "/wish-items/\(id)", method: "PATCH", body: updates
        )
        return response.item
    }
    
    func deleteWishItem(id: String) async throws {
        try await requestVoid(endpoint: "/wish-items/\(id)", method: "DELETE")
    }
}

// MARK: - Invitations API
extension APIService {
    func getPendingInvitations() async throws -> [Invitation] {
        struct Response: Codable { let invitations: [Invitation] }
        let response: Response = try await request(endpoint: "/invitations")
        return response.invitations
    }
    
    func sendInvitation(groupId: String, email: String, role: String = "member") async throws {
        let body: [String: Any] = [
            "group_id": groupId,
            "email": email,
            "role": role
        ]
        try await requestVoid(endpoint: "/invitations/send", method: "POST", body: body)
    }
    
    func acceptInvitation(id: String) async throws {
        try await requestVoid(endpoint: "/invitations/\(id)/accept", method: "POST")
    }
    
    func declineInvitation(id: String) async throws {
        try await requestVoid(endpoint: "/invitations/\(id)/decline", method: "POST")
    }
    
    func joinGroupByCode(code: String) async throws {
        try await requestVoid(endpoint: "/invitations/join", method: "POST", body: ["invite_code": code])
    }
}

// MARK: - User API
extension APIService {
    func getCurrentUser() async throws -> User {
        struct Response: Codable { let user: User }
        let response: Response = try await request(endpoint: "/users/me")
        return response.user
    }
    
    func updateProfile(fullName: String?, languagePreference: String?) async throws -> User {
        var body: [String: Any] = [:]
        if let name = fullName { body["full_name"] = name }
        if let lang = languagePreference { body["language_preference"] = lang }
        struct Response: Codable { let user: User }
        let response: Response = try await request(endpoint: "/users/me", method: "PATCH", body: body)
        return response.user
    }
    
    func getUserSettings() async throws -> UserSettings {
        struct Response: Codable { let settings: UserSettings }
        let response: Response = try await request(endpoint: "/users/me/settings")
        return response.settings
    }
    
    func updateUserSettings(_ settings: [String: Any]) async throws -> UserSettings {
        struct Response: Codable { let settings: UserSettings }
        let response: Response = try await request(endpoint: "/users/me/settings", method: "PATCH", body: settings)
        return response.settings
    }
}
