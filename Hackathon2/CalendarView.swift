import SwiftUI

struct CalendarView: View {
    @State private var currentMonthAnchor: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var presentedConversation: Conversation? = nil
    
    private let calendar: Calendar = Calendar.current
    private let weekSymbols: [String] = ["S","M","T","W","T","F","S"]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            VStack(spacing: 16) {
                header()
                weekdayHeader()
                monthGrid()
                Divider().background(Color.gray.opacity(0.3))
                conversationList(for: selectedDate)
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .onAppear { info("Calendar loaded for \(currentMonthAnchor.yyyyMM)") }
    }
}

// MARK: - Subviews
private extension CalendarView {
    func header() -> some View {
        HStack {
            Button(action: { stepMonth(by: -1) }) {
                Image(systemName: "chevron.left").foregroundColor(.white)
            }
            Spacer()
            Text(currentMonthAnchor.formatted(.dateTime.year().month()))
                .font(.title2).bold().foregroundColor(.white)
            Spacer()
            Button(action: { stepMonth(by: 1) }) {
                Image(systemName: "chevron.right").foregroundColor(.white)
            }
        }
    }
    
    func weekdayHeader() -> some View {
        HStack {
            ForEach(weekSymbols, id: \.self) { s in
                Text(s)
                    .font(.footnote).bold()
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }
    
    func monthGrid() -> some View {
        let days = buildMonthDays(anchor: currentMonthAnchor)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 11) {
            ForEach(days) { day in
                dayCell(day)
                    .onTapGesture { select(day.date) }
            }
        }
        .padding(.vertical, 4)
    }
    
    func dayCell(_ item: DayItem) -> some View {
        let isSelected = calendar.isDate(item.date, inSameDayAs: selectedDate)
        return ZStack {
            if item.isWithinCurrentMonth {
                Circle()
                    .fill(backgroundColor(for: item))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                    )
            }
            Text("\(calendar.component(.day, from: item.date))")
                .font(.callout)
                .fontWeight(item.isToday ? .bold : .regular)
                .foregroundColor(textColor(for: item))
        }
        .frame(height: 29)
        .opacity(item.isWithinCurrentMonth ? 1 : 0)
        .animation(.easeInOut(duration: 0.15), value: selectedDate)
    }
    
    @ViewBuilder
    func conversationList(for date: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(date.formatted(.dateTime.year().month().day()))
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(mappedEntries(for: date)) { entry in
                        ConversationCard(entry: entry)
                            .onTapGesture {
                                if let conv = ConversationStore.shared.conversation(by: entry.id) {
                                    presentedConversation = conv
                                }
                            }
                    }
                }
                .padding(.bottom, 4)
            }
            .frame(maxHeight: 576)
        }
        .sheet(item: $presentedConversation, onDismiss: { presentedConversation = nil }) { conv in
            ConversationDetailView(conversation: conv)
        }
    }
}

// MARK: - Helpers
private extension CalendarView {
    func stepMonth(by delta: Int) {
        guard let newDate = calendar.date(byAdding: .month, value: delta, to: currentMonthAnchor) else { return }
        currentMonthAnchor = newDate
        // Keep selection within visible month if necessary
        if !calendar.isDate(selectedDate, equalTo: newDate, toGranularity: .month) {
            selectedDate = newDate
        }
        info("Stepped to month \(newDate.yyyyMM)")
    }
    
    func select(_ date: Date) {
        selectedDate = date
        info("Selected date \(date.yyyyMMdd)")
    }
    
    func buildMonthDays(anchor: Date) -> [DayItem] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: anchor),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: anchor)) else { return [] }
        let firstWeekdayIndex = calendar.component(.weekday, from: firstOfMonth) - 1 // 0..6, Sunday first
        var items: [DayItem] = []
        items.reserveCapacity(firstWeekdayIndex + monthRange.count)
        for _ in 0..<firstWeekdayIndex { items.append(DayItem(date: Date(), isWithinCurrentMonth: false, isToday: false)) }
        for day in monthRange {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) else { continue }
            let isToday = calendar.isDateInToday(date)
            items.append(DayItem(date: date, isWithinCurrentMonth: true, isToday: isToday))
        }
        return items
    }
    
    func backgroundColor(for item: DayItem) -> Color {
        guard item.isWithinCurrentMonth else { return .clear }
        // Only color dates from Aug 11 to Aug 18 (inclusive). Others are neutral.
        let comps = calendar.dateComponents([.year, .month, .day], from: item.date)
        if comps.year == 2025, comps.month == 8, let d = comps.day, d >= 11 && d <= 18 {
            // Past vs future neutralization
            let today = Date()
            if calendar.compare(item.date, to: today, toGranularity: .day) == .orderedDescending {
                return Color.white.opacity(0.08)
            }
            // Deterministic pseudo-random based on yyyymmdd
            let seed = item.date.yyyyMMdd.hashValue
            return (seed % 4 == 0 || seed % 4 == 1) ? Color(red: 0.16, green: 0.5, blue: 0.3) : Color(red: 0.45, green: 0.1, blue: 0.1)
        } else {
            return Color.white.opacity(0.08)
        }
    }
    
    func textColor(for item: DayItem) -> Color {
        guard item.isWithinCurrentMonth else { return .clear }
        let today = Date()
        if calendar.compare(item.date, to: today, toGranularity: .day) == .orderedDescending {
            return .gray
        }
        return .white
    }
    
    func info(_ message: String) {
        print("[Calendar] \(message)")
    }
    
    func mappedEntries(for date: Date) -> [ConversationEntry] {
        let convs = ConversationStore.shared.conversations(on: date)
        return convs.prefix(3).enumerated().map { _, c in
            let top = c.messages.first?.timestamp ?? c.startTime
            let bottom = c.messages.last?.timestamp ?? c.endTime
            let lines: [String] = Array(allLines(from: c).prefix(3))
            return ConversationEntry(
                id: c.id,
                title: c.title.uppercased(),
                times: [DateFormatter.HHmm.string(from: top), DateFormatter.HHmm.string(from: bottom)],
                lines: lines,
                tags: Array(c.tags.prefix(3))
            )
        }
    }
    
    func allLines(from c: Conversation) -> [String] {
        // Convert entire transcript to displayable lines
        c.messages.sorted { $0.timestamp < $1.timestamp }.map { m in
            let prefix = m.role.lowercased() == "user" ? "Me: " : "Aura: "
            return prefix + m.content
        }
    }
}

// MARK: - Models
private struct DayItem: Identifiable {
    let id = UUID()
    let date: Date
    let isWithinCurrentMonth: Bool
    let isToday: Bool
}

struct ConversationEntry: Identifiable {
    let id: String
    let title: String
    let times: [String] // [top, bottom]
    let lines: [String]
    let tags: [String]
}

// MARK: - Cards
private struct ConversationCard: View {
    let entry: ConversationEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            timestampColumn()
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.title)
                    .font(.subheadline).bold().foregroundColor(.white)
                conversationBody()
                tagRow()
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .contentShape(Rectangle())
    }
    
    private func timestampColumn() -> some View {
        VStack {
            Text(entry.times.first ?? "")
                .font(.caption).foregroundColor(.white.opacity(0.8))
            Spacer(minLength: 18)
            Text(entry.times.dropFirst().first ?? "")
                .font(.caption).foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 44)
    }
    
    private func conversationBody() -> some View {
        Text(entry.lines.joined(separator: "\n"))
            .font(.caption)
            .foregroundColor(.white.opacity(0.9))
            .lineLimit(3)
            .multilineTextAlignment(.leading)
    }
    
    private func tagRow() -> some View {
        HStack(spacing: 8) {
            ForEach(entry.tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
            }
        }
    }
}

// MARK: - Date helpers
private extension Date {
    var yyyyMM: String { formatted(.dateTime.year().month()) }
    var yyyyMMdd: String { formatted(.dateTime.year().month().day()) }
}

#Preview {
    CalendarView()
}


