import Foundation

@MainActor
final class SubscriptionStore: ObservableObject {
    @Published private(set) var subscriptions: [Subscription] = [
        Subscription(name: "Netflix", price: 43.00, nextBillingDate: .now),
        Subscription(name: "Spotify", price: 23.99, nextBillingDate: Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now),
        Subscription(name: "iCloud+", price: 4.99, nextBillingDate: Calendar.current.date(byAdding: .day, value: 12, to: .now) ?? .now)
    ]

    var monthlyTotal: Decimal {
        subscriptions.reduce(0) { $0 + ($1.price * $1.billingCycle.monthlyMultiplier) }
    }

    func add(_ subscription: Subscription) {
        subscriptions.append(subscription)
    }

    func delete(at offsets: IndexSet) {
        subscriptions.remove(atOffsets: offsets)
    }
}
