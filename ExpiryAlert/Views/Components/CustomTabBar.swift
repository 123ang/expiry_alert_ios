import SwiftUI

// MARK: - Tab Items
enum TabItem: Int, CaseIterable {
    case home = 0
    case calendar
    case add
    case list
    case settings
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .list: return "list.bullet"
        case .add: return "plus"
        case .calendar: return "calendar"
        case .settings: return "gearshape.fill"
        }
    }
    
    func title(using lm: LocalizationManager) -> String {
        switch self {
        case .home: return lm.t("nav.home")
        case .list: return lm.t("nav.list")
        case .add: return ""
        case .calendar: return lm.t("nav.calendar")
        case .settings: return lm.t("nav.settings")
        }
    }
    
    var isAddButton: Bool {
        return self == .add
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    @Binding var showAddItem: Bool
    let theme: AppTheme
    let localizationManager: LocalizationManager
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main tab bar container
            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { item in
                    if item.isAddButton {
                        // Spacer for the floating button – keep compact so menu icons sit closer
                        Spacer()
                            .frame(width: 44)
                    } else {
                        TabBarButton(
                            item: item,
                            isSelected: selectedTab == item,
                            theme: theme,
                            localizationManager: localizationManager,
                            action: {
                                selectedTab = item
                            }
                        )
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, bottomPadding) // Single use of safe area: content sits above home indicator; background extends to screen bottom
            .background(
                Color(hex: theme.backgroundColor)
                    .ignoresSafeArea(edges: .bottom)
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color(hex: theme.borderColor))
                    .frame(height: 1)
            }
            .shadow(
                color: Color(hex: theme.shadowColor),
                radius: 4,
                x: 0,
                y: -2
            )
            
            // Floating add button – sit closer to bar to reduce gap
            FloatingAddButton(
                showAddItem: $showAddItem,
                theme: theme
            )
            .offset(y: -20)
        }
    }
    
    /// Bottom inset applied once: keeps icons above home indicator; no extra padding.
    private var bottomPadding: CGFloat {
        #if os(iOS)
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        let bottomInset = window?.safeAreaInsets.bottom ?? 0
        return bottomInset > 0 ? bottomInset : 12
        #else
        return 12
        #endif
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let item: TabItem
    let isSelected: Bool
    let theme: AppTheme
    let localizationManager: LocalizationManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                
                if !item.title(using: localizationManager).isEmpty {
                    Text(item.title(using: localizationManager))
                        .font(.system(size: 12))
                        .foregroundColor(textColor)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var iconColor: Color {
        Color(hex: isSelected ? theme.primaryColor : theme.textSecondary)
    }
    
    private var textColor: Color {
        Color(hex: isSelected ? theme.primaryColor : theme.textSecondary)
    }
}

// MARK: - Floating Add Button
struct FloatingAddButton: View {
    @Binding var showAddItem: Bool
    let theme: AppTheme
    
    var body: some View {
        Button(action: {
            showAddItem = true
        }) {
            ZStack {
                Circle()
                    .fill(Color(hex: theme.primaryColor))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .shadow(
            color: Color(hex: theme.shadowColor),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}
