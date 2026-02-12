# Expiry Alert - iOS (Swift)

A native iOS food expiry tracking app built with **SwiftUI**, connecting to the **expiry-alert-api** backend (Express.js + PostgreSQL).

## Features

- **Food Item Tracking** - Add, edit, delete food items with expiry dates
- **Dashboard** - Overview of total, fresh, expiring, and expired items  
- **Calendar View** - Visual calendar showing items by expiry date
- **Categories & Locations** - Manage custom food categories and storage locations
- **Shopping List** - Track items you need to buy
- **Wish List** - Track items you want to buy
- **Group Sharing** - Share food tracking with family/household members
- **11 Themes** - Original, Recycled, Dark Brown, Black, Blue, Green, Soft Pink, Bright Pink, Yellow, Mint-Red, Dark Gold
- **5 Languages** - English, Japanese, Malay, Thai, Chinese
- **Push Notifications** - Alerts for expiring and expired items
- **Image Support** - Take photos or choose from gallery for food items

## Architecture

```
ExpiryAlert/
├── App/                    # App entry point & main navigation
│   ├── ExpiryAlertApp.swift
│   └── ContentView.swift
├── Models/
│   └── Models.swift        # All data models matching backend schema
├── Services/
│   ├── APIService.swift    # REST API client with JWT auth & token refresh
│   ├── AuthViewModel.swift # Authentication state management
│   ├── DataStore.swift     # Central data store (groups, items, categories...)
│   └── NotificationService.swift
├── Theme/
│   └── ThemeManager.swift  # 11 themes with Color(hex:) support
├── Localization/
│   ├── LocalizationManager.swift
│   └── Translations.swift  # EN, JA, MS, TH, ZH translations
├── Views/
│   ├── Auth/               # Login & Registration
│   ├── Dashboard/          # Home screen with stats & quick actions
│   ├── FoodList/           # Searchable, filterable food list
│   ├── Calendar/           # Calendar view with item dots
│   ├── AddEdit/            # Add/Edit food items
│   ├── ItemDetail/         # Item detail with use/throw actions
│   ├── Settings/           # Settings, theme picker, language picker
│   ├── Notifications/      # Notification preferences
│   ├── Categories/         # Category management
│   └── Locations/          # Location management
└── Assets.xcassets/        # App icons and images
```

## API Connection

The app connects to the **expiry-alert-api** backend:

- **Base URL**: Configure in `APIService.swift` → `APIConfig.baseURL`
- **Auth**: JWT with device-bound refresh tokens
- **Endpoints**: `/api/auth/*`, `/api/food-items/*`, `/api/categories/*`, `/api/locations/*`, `/api/groups/*`, `/api/shopping-items/*`, `/api/wish-items/*`, `/api/upload/*`

### Configuration

1. Open `ExpiryAlert/Services/APIService.swift`
2. Update `APIConfig.baseURL` with your VPS URL:

```swift
enum APIConfig {
    static var baseURL: String {
        #if DEBUG
        return "http://localhost:3000/api"  // Local dev
        #else
        return "https://your-vps-domain.com/api"  // Production
        #endif
    }
}
```

## Setup

### Prerequisites
- Xcode 15+ 
- iOS 15+ device or simulator
- Backend API running (see backend README)

### Build & Run

1. Open `ExpiryAlert.xcodeproj` in Xcode (or use `Package.swift` with SPM)
2. Select your target device/simulator
3. Configure the API base URL in `APIService.swift`
4. Build and run (Cmd + R)

### Creating Xcode Project

Since this is source-only, to create a proper `.xcodeproj`:

1. Open Xcode → File → New → Project
2. Choose "App" template
3. Product Name: **ExpiryAlert**
4. Interface: **SwiftUI**, Language: **Swift**
5. Replace the generated source files with files from this `ExpiryAlert/` directory
6. Set deployment target to **iOS 15.0**
7. Add Info.plist values from the provided `Info.plist`

## Security

- Tokens stored in iOS Keychain (not UserDefaults)
- Automatic token refresh on 401 responses
- Device-bound refresh tokens
- HTTPS enforced in production (ATS configured)

## Backend

The backend (`expiry-alert-api`) provides:
- Express.js + TypeScript
- PostgreSQL database
- JWT authentication with device-bound refresh tokens  
- Full REST API for all app features
- Image upload via Multer
- Email invitations via Nodemailer
