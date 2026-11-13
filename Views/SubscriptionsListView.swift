import SwiftUI
import Charts

/// „Moje subskrypcje" – lista aktywnych usług z podsumowaniem i mini wykresem trendu.
struct SubscriptionsListView: View {
    @EnvironmentObject var store: SubscriptionStore

    private var totals: [MonthTotal] { store.monthTotals(last: 6) }

    private var change: Double {
        guard totals.count >= 2 else { return 0 }
        return totals[totals.count - 1].amount - totals[totals.count - 2].amount
    }

    var body: some View {
        List {
            Section {
                header
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section {
                ForEach(store.upcoming, id: \.sub.id) { item in
                    row(item.sub, item.date)
                        .listRowBackground(Theme.card)
                        .swipeActions {
                            Button(role: .destructive) {
                                withAnimation { store.delete(item.sub) }
                            } label: {
                                Label("Usuń", systemImage: "trash")
                            }
                        }
                }
            } header: {
                HStack {
                    Text("Aktywne subskrypcje")
                    Spacer()
                    Text("\(store.subscriptions.count)")
                }
            } footer: {
                Label("Posortowane według daty płatności", systemImage: "arrow.up.arrow.down")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Moje subskrypcje")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Miesięczne wydatki")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                Spacer()
            }
            HStack(alignment: .center) {
                Text(store.money(store.monthlyTotal))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Spacer()
                Chart(totals) { item in
                    LineMark(x: .value("Miesiąc", item.date), y: .value("Kwota", item.amount))
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(width: 90, height: 40)
            }
            changeLabel
        }
        .cardStyle()
    }

    @ViewBuilder
    private var changeLabel: some View {
        if abs(change) < 0.005 {
            Text("Bez zmian w porównaniu z poprzednim miesiącem")
                .font(.caption)
                .foregroundStyle(Theme.muted)
        } else if change < 0 {
            Text("▼ \(store.money(-change)) mniej niż w poprzednim miesiącu")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
        } else {
            Text("▲ \(store.money(change)) więcej niż w poprzednim miesiącu")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.alert)
        }
    }

    private func row(_ sub: Subscription, _ date: Date) -> some View {
        HStack(spacing: 12) {
            ServiceIcon(symbol: sub.symbol, color: sub.color, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(sub.name).font(.subheadline.weight(.semibold))
                Text(store.dayText(date))
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(store.money(sub.price)).font(.subheadline.weight(.semibold))
                Text(sub.period.adverb)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(.vertical, 4)
    }
}
