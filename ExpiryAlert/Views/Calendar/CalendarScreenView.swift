import SwiftUI

struct CalendarScreenView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showAddItem = false
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    private var appLocale: Locale {
        switch localizationManager.currentLanguage {
        case .en: return Locale(identifier: "en_US")
        case .ja: return Locale(identifier: "ja_JP")
        case .ms: return Locale(identifier: "ms_MY")
        case .th: return Locale(identifier: "th_TH")
        case .zh: return Locale(identifier: "zh_Hans")
        }
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    private var itemsForSelectedDate: [FoodItem] {
        dataStore.foodItems.filter { item in
            guard let expiryDate = item.expiryDate else { return false }
            return String(expiryDate.prefix(10)) == selectedDateString
        }
    }
    
    private var months: [String] {
        [localizationManager.t("month.january"), localizationManager.t("month.february"),
         localizationManager.t("month.march"), localizationManager.t("month.april"),
         localizationManager.t("month.may"), localizationManager.t("month.june"),
         localizationManager.t("month.july"), localizationManager.t("month.august"),
         localizationManager.t("month.september"), localizationManager.t("month.october"),
         localizationManager.t("month.november"), localizationManager.t("month.december")]
    }
    
    private var weekDays: [String] {
        [localizationManager.t("weekday.sun"), localizationManager.t("weekday.mon"),
         localizationManager.t("weekday.tue"), localizationManager.t("weekday.wed"),
         localizationManager.t("weekday.thu"), localizationManager.t("weekday.fri"),
         localizationManager.t("weekday.sat")]
    }
    
    var body: some View {
        ZStack {
            Color(hex: theme.backgroundColor).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header – blends with page (same as Settings)
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Text(localizationManager.t("nav.calendar"))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color(hex: theme.textColor))
                    Spacer(minLength: 0)
                }
                .padding(.top, 10)
                .padding(.bottom, 8)
                .padding(.horizontal, 16)
                .background(Color(hex: theme.backgroundColor))
                .overlay(
                    Rectangle()
                        .fill(Color(hex: theme.borderColor).opacity(0.35))
                        .frame(height: 0.5),
                    alignment: .bottom
                )
                .padding(.top, 44)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Calendar card – more inset, less squeezed
                        VStack(spacing: 16) {
                            // Month Navigation
                            HStack {
                                Button(action: { changeMonth(-1) }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: theme.textColor))
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                Spacer()
                                Text("\(months[Calendar.current.component(.month, from: currentMonth) - 1]) \(Calendar.current.component(.year, from: currentMonth))")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color(hex: theme.textColor))
                                Spacer()
                                Button(action: { changeMonth(1) }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: theme.textColor))
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                            }
                            .padding(.horizontal, 4)
                            
                            // Week Days Header – more spacing
                            HStack(spacing: 0) {
                                ForEach(weekDays, id: \.self) { day in
                                    Text(day)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color(hex: theme.placeholderColor))
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.bottom, 6)
                            
                            // Calendar Grid – increased spacing so dates aren’t squeezed
                            let days = getDaysInMonth()
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                                ForEach(days, id: \.date) { dayInfo in
                                    DayCell(
                                        date: dayInfo.date,
                                        isCurrentMonth: dayInfo.isCurrentMonth,
                                        isSelected: Calendar.current.isDate(dayInfo.date, inSameDayAs: selectedDate),
                                        hasItems: hasItemsOnDate(dayInfo.date),
                                        theme: theme
                                    )
                                    .onTapGesture {
                                        selectedDate = dayInfo.date
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(hex: theme.cardBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: theme.borderColor).opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: Color(hex: theme.shadowColor).opacity(0.2), radius: 6, x: 0, y: 2)
                        
                        // Selected date + items section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(localizedLongDateString(from: selectedDate))
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(Color(hex: theme.textColor))
                                    Text("\(itemsForSelectedDate.count) \(localizationManager.t("calendar.items"))")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: theme.textSecondary))
                                }
                                Spacer()
                                Button(action: { showAddItem = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color(hex: theme.primaryColor))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            if itemsForSelectedDate.isEmpty {
                                VStack(spacing: 14) {
                                    Text("📅")
                                        .font(.system(size: 40))
                                    Text(localizationManager.t("calendar.noItems"))
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(hex: theme.textSecondary))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(itemsForSelectedDate) { item in
                                        NavigationLink(destination: ItemDetailView(itemId: item.id)) {
                                            FoodItemRow(item: item, theme: theme, localizationManager: localizationManager)
                                                .padding(.vertical, 10)
                                        }
                                        if item.id != itemsForSelectedDate.last?.id {
                                            Divider()
                                                .padding(.leading, 56)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color(hex: theme.cardBackground))
                                .clipShape(RoundedRectangle(cornerRadius: theme.borderRadius))
                            }
                        }
                        
                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddItem) {
            AddItemView(prefilledDate: selectedDate)
        }
    }
    
    private func localizedLongDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Helpers
    private func changeMonth(_ offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private struct DayInfo: Hashable {
        let date: Date
        let isCurrentMonth: Bool
        func hash(into hasher: inout Hasher) {
            hasher.combine(date)
        }
    }
    
    private func getDaysInMonth() -> [DayInfo] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentMonth)
        let month = calendar.component(.month, from: currentMonth)
        
        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        var days: [DayInfo] = []
        
        // Previous month padding
        if firstWeekday > 1 {
            for i in stride(from: firstWeekday - 2, through: 0, by: -1) {
                if let date = calendar.date(byAdding: .day, value: -(i + 1), to: firstOfMonth) {
                    days.append(DayInfo(date: date, isCurrentMonth: false))
                }
            }
        }
        
        // Current month days
        for day in range {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                days.append(DayInfo(date: date, isCurrentMonth: true))
            }
        }
        
        // Next month padding
        let remaining = 7 - (days.count % 7)
        if remaining < 7, let lastDay = days.last?.date {
            for i in 1...remaining {
                if let date = calendar.date(byAdding: .day, value: i, to: lastDay) {
                    days.append(DayInfo(date: date, isCurrentMonth: false))
                }
            }
        }
        
        return days
    }
    
    private func hasItemsOnDate(_ date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        return dataStore.foodItems.contains { item in
            guard let expiryDate = item.expiryDate else { return false }
            return String(expiryDate.prefix(10)) == dateStr
        }
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isSelected: Bool
    let hasItems: Bool
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(
                    isSelected ? .white :
                    !isCurrentMonth ? Color(hex: theme.textSecondary).opacity(0.4) :
                    Color(hex: theme.textColor)
                )
            
            if hasItems && !isSelected {
                Circle()
                    .fill(Color(hex: theme.primaryColor))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(
            isSelected
            ? Color(hex: theme.primaryColor)
            : hasItems && !isSelected
                ? Color(hex: theme.primaryColor).opacity(0.1)
                : Color.clear
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(hasItems && !isSelected ? Color(hex: theme.primaryColor) : Color.clear, lineWidth: 1)
        )
        .opacity(isCurrentMonth ? 1 : 0.4)
    }
}
