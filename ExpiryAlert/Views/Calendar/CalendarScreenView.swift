import SwiftUI

struct CalendarScreenView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showAddItem = false
    
    private var theme: AppTheme { themeManager.currentTheme }
    
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
                // Header
                Text(localizationManager.t("nav.calendar"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: theme.textColor))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: theme.cardBackground))
                
                // Calendar
                VStack(spacing: 12) {
                    // Month Navigation
                    HStack {
                        Button(action: { changeMonth(-1) }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color(hex: theme.textColor))
                        }
                        Spacer()
                        Text("\(months[Calendar.current.component(.month, from: currentMonth) - 1]) \(Calendar.current.component(.year, from: currentMonth))")
                            .font(.headline)
                            .foregroundColor(Color(hex: theme.textColor))
                        Spacer()
                        Button(action: { changeMonth(1) }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(hex: theme.textColor))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Week Days Header
                    HStack {
                        ForEach(weekDays, id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: theme.textSecondary))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Calendar Grid
                    let days = getDaysInMonth()
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
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
                .padding()
                .background(Color(hex: theme.cardBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Items for selected date
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(selectedDate.formatted(date: .long, time: .omitted))
                                .font(.headline)
                                .foregroundColor(Color(hex: theme.textColor))
                            Text("\(itemsForSelectedDate.count) \(localizationManager.t("calendar.items"))")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: theme.textSecondary))
                        }
                        Spacer()
                        Button(action: { showAddItem = true }) {
                            Image(systemName: "plus")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color(hex: theme.primaryColor))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    if itemsForSelectedDate.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Text("📅")
                                .font(.system(size: 48))
                            Text(localizationManager.t("calendar.noItems"))
                                .foregroundColor(Color(hex: theme.textSecondary))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(itemsForSelectedDate) { item in
                                    NavigationLink(destination: ItemDetailView(itemId: item.id)) {
                                        FoodItemRow(item: item, theme: theme, localizationManager: localizationManager)
                                            .padding(.horizontal)
                                            .padding(.vertical, 8)
                                    }
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .background(Color(hex: theme.cardBackground))
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddItem) {
            AddItemView(prefilledDate: selectedDate)
        }
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
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
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
        .frame(height: 36)
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
