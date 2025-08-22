import SwiftUI

struct CalendarView: View {
    @State private var baseDate: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var presentedConversation: Conversation? = nil
    
    private let calendar: Calendar = Calendar.current
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 20) {
                header()
                weekStrip()
                timeline()
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }
}

// MARK: - Header
private extension CalendarView {
    func header() -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(white: 0.95))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                )
                .onTapGesture { stepWeek(by: -1) }
            Text("My Calendar")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 2)
    }
}

// MARK: - Week Strip
private extension CalendarView {
    func weekStrip() -> some View {
        let days = buildWeekDays(anchor: baseDate)
        return GeometryReader { geo in
            let spacing: CGFloat = 12
            let pillWidth = max(46, floor((geo.size.width - spacing * 6) / 7))
            let pillHeight = pillWidth * 1.18
            HStack(spacing: spacing) {
                ForEach(days) { item in
                    dayPill(item, size: CGSize(width: pillWidth, height: pillHeight))
                        .onTapGesture { selectedDate = item.date }
                }
            }
            .frame(width: geo.size.width, alignment: .leading)
        }
        .frame(height: 92)
    }
    
    func dayPill(_ item: DayItem, size: CGSize) -> some View {
        let isSelected = calendar.isDate(item.date, inSameDayAs: selectedDate)
        return VStack(spacing: 6) {
            Text(item.weekday)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.gray)
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.black.opacity(0.7) : Color.gray.opacity(0.35), lineWidth: isSelected ? 2.5 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(isSelected ? 0.18 : 0.06), radius: isSelected ? 8 : 4, y: 2)
                    )
                    .frame(width: size.width, height: size.height)
                VStack(spacing: 4) {
                    Text(item.dayString)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                    Circle()
                        .fill(isSelected ? Color(red: 0.63, green: 0.78, blue: 0.53) : Color.gray.opacity(0.5))
                        .frame(width: 6, height: 6)
                        .opacity(item.hasDot ? 1 : 0)
                }
            }
        }
    }
}

// MARK: - Timeline
private extension CalendarView {
    func timeline() -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let lineWidth: CGFloat = 3
            let gap: CGFloat = 14
            let columnWidth = (width - lineWidth - gap * 2) / 2
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Timeline")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.leading, 6)
                ZStack(alignment: .top) {
                    // subtle section background fade like mock
                    VStack(spacing: 0) {
                        LinearGradient(colors: [Color.orange.opacity(0.06), .clear], startPoint: .top, endPoint: .bottom)
                            .frame(height: 24)
                        Spacer(minLength: 0)
                        LinearGradient(colors: [.clear, Color.orange.opacity(0.06)], startPoint: .top, endPoint: .bottom)
                            .frame(height: 24)
                    }
                    
                    // Center vertical line
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color(red: 0.73, green: 0.80, blue: 0.67))
                            .frame(width: lineWidth)
                            .padding(.vertical, 8)
                        Spacer()
                    }
                    
                    // Green marker on the line
                    Circle()
                        .fill(Color(red: 0.63, green: 0.78, blue: 0.53))
                        .frame(width: 10, height: 10)
                        .position(x: width / 2, y: 110)
                    
                    // Cards in two columns
                    VStack(spacing: 16) {
                        // Left row
                        HStack(spacing: gap) {
                            timelineCardLeft(
                                title: "Work-related\nstress is killing me",
                                subtitle: "I felt anxious today\nduring the team\nmeeting. Too much\nwork load recently.",
                                iconColor: Color.purple,
                                metric: "96bpm"
                            )
                            .frame(width: columnWidth)
                            Spacer()
                        }
                        // Right row
                        HStack(spacing: gap) {
                            Spacer()
                            timelineCardRight(
                                title: "Felt Bad, but it's all\nOK.",
                                subtitle: "xxxxxxx",
                                iconColor: Color.yellow
                            )
                            .frame(width: columnWidth)
                        }
                        Spacer(minLength: 10)
                    }
                }
            }
        }
        .frame(height: 520)
    }
    
func timelineCardLeft(title: String, subtitle: String, iconColor: Color, metric: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .center, spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 56, height: 56)
                Circle()
                    .fill(iconColor)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "face.smiling")
                            .foregroundColor(.white)
                    )
            }
            HStack(spacing: 4) {
                Image(systemName: "bolt.heart.fill")
                    .foregroundColor(.gray)
                Text(metric)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(height: 56)
        }
        Text(title)
            .font(.headline)
            .foregroundColor(.black)
            .fixedSize(horizontal: false, vertical: true)
        Text(subtitle)
            .font(.subheadline)
            .foregroundColor(.gray)
            .fixedSize(horizontal: false, vertical: true)
    }
    .padding(16)
    .background(
        RoundedRectangle(cornerRadius: 22)
            .fill(Color.white)
            .shadow(color: Color.orange.opacity(0.15), radius: 12, y: 6)
    )
}
    
    func timelineCardRight(title: String, subtitle: String, iconColor: Color) -> some View {
        VStack() {
            HStack(alignment: .top, spacing: 0) {
                ZStack {
                    Circle().fill(iconColor.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Circle().fill(iconColor)
                        .frame(width: 28, height: 28)
                        .overlay(Image(systemName: "lightbulb.fill").foregroundColor(.white))
                }
                Spacer()
            }
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.orange.opacity(0.15), radius: 12, y: 6)
        )
    }
}

// MARK: - Helpers
private extension CalendarView {
    func stepWeek(by delta: Int) {
        guard let newDate = calendar.date(byAdding: .day, value: 7 * delta, to: baseDate) else { return }
        baseDate = newDate
        if !calendar.isDate(selectedDate, equalTo: newDate, toGranularity: .weekOfYear) {
            selectedDate = newDate
        }
    }
    
    func buildWeekDays(anchor: Date) -> [DayItem] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: anchor)) ?? anchor
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else { return nil }
            let w = calendar.shortWeekdaySymbols[(calendar.component(.weekday, from: date) + 6) % 7]
            return DayItem(date: date, weekday: w, dayString: String(calendar.component(.day, from: date)), hasDot: true)
        }
    }
}

// MARK: - Models
private struct DayItem: Identifiable {
    let id = UUID()
    let date: Date
    let weekday: String
    let dayString: String
    let hasDot: Bool
}

#Preview {
    CalendarView()
}
