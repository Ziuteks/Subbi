import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: SubscriptionStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    StatCard(title: "Twoje miesięczne wydatki", value: store.money(store.monthlyTotal))
                    StatCard(title: "Twoje roczne wydatki", value: store.money(store.yearlyTotal))
                    nextPaymentCard
                    allSubscriptionsLink
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle("Ekran główny")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var nextPaymentCard: some View {
        HStack(spacing: 12) {
            if let next = store.nextPayment {
                ServiceIcon(symbol: next.sub.symbol, color: next.sub.color, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Następna płatność")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                    Text(next.sub.name)
                        .font(.headline)
                    Text("\(store.dayText(next.date)) · \(store.money(next.sub.price))")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
            } else {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
                Text("Brak nadchodzących płatności")
                    .foregroundStyle(Theme.muted)
                Spacer()
            }
        }
        .cardStyle()
    }

    private var allSubscriptionsLink: some View {
        NavigationLink {
            SubscriptionsListView()
        } label: {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                Text("Moje subskrypcje")
                    .font(.headline)
                Spacer()
                Text("\(store.subscriptions.count)")
                    .foregroundStyle(Theme.muted)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.muted)
            }
            .foregroundStyle(.white)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
            Text(value)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .cardStyle()
    }
}
