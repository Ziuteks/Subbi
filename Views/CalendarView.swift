import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: SubscriptionStore
    @State private var month: Date = AppCal.cal.dateInterval(of: .month, for: .now)?.start ?? .now

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["PN", "WT", "ŚR", "CZ", "PT", "SB", "ND"]

    private var payments: [(sub: Subscription, date: Date)] { store.payments(inMonthOf: month) }

    private var paymentDays: Set<Int> {
        Set(payments.map { AppCal.cal.component(.day, from: $0.date) })
    }

    private var monthTitle: String {
        month.formatted(.dateTime.month(.wide).year().locale(AppCal.locale)).capitalized
    }

    private var cells: [Date?] {
        let cal = AppCal.cal
        guard let first = cal.dateInterval(of: .month, for: month)?.start,
              let count = cal.range(of: .day, in: .month, for: first)?.count else { return [] }
        let weekday = cal.component(.weekday, from: first)
        let offset = (weekday - cal.firstWeekday + 7) % 7
        let days: [Date?] = (0..<count).compactMap { cal.date(byAdding: .day, value: $0, to: first) }
        return Array(repeating: nil, count: offset) + days
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    calendarCard
                    paymentsList
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle("Kalendarz")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var calendarCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text(monthTitle).font(.headline)
                Spacer()
                Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                Button { shift(1) } label: { Image(systemName: "chevron.right") }
                    .padding(.leading, 12)
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdays, id: \.self) { d in
                    Text(d).font(.caption2.weight(.semibold)).foregroundStyle(Theme.muted)
                }
                ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func dayCell(_ date: Date) -> some View {
        let day = AppCal.cal.component(.day, from: date)
        let hasPayment = paymentDays.contains(day)
        let isToday = AppCal.cal.isDateInToday(date)
        return Text("\(day)")
            .font(.system(size: 16, weight: hasPayment ? .bold : .regular))
            .frame(width: 34, height: 34)
            .background(Circle().fill(hasPayment ? Theme.alert : .clear))
            .overlay(Circle().stroke(Theme.accent, lineWidth: isToday && !hasPayment ? 1.5 : 0))
            .frame(maxWidth: .infinity)
    }

    private var paymentsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if payments.isEmpty {
                Text("Brak płatności w tym miesiącu")
                    .foregroundStyle(Theme.muted)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(payments.enumerated()), id: \.offset) { idx, item in
                    HStack(spacing: 12) {
                        ServiceIcon(symbol: item.sub.symbol, color: item.sub.color, size: 30)
                        Text(item.sub.name).font(.subheadline.weight(.medium))
                        Spacer()
                        Text(item.date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(AppCal.locale)))
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                        Text(store.money(item.sub.price))
                            .font(.footnote.weight(.semibold))
                    }
                    .padding(.vertical, 10)
                    if idx < payments.count - 1 { Divider().overlay(Color.white.opacity(0.1)) }
                }
            }
        }
        .cardStyle()
    }

    private func shift(_ value: Int) {
        if let m = AppCal.cal.date(byAdding: .month, value: value, to: month) {
            withAnimation(.easeInOut(duration: 0.2)) { month = m }
        }
    }
}
