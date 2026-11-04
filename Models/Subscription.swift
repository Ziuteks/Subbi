import Foundation

struct Subscription: Identifiable {
    let id: UUID
    var name: String
    var price: Decimal
    var currencyCode: String
    var billingCycle: BillingCycle
    var nextBillingDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        price: Decimal,
        currencyCode: String = "PLN",
        billingCycle: BillingCycle = .monthly,
        nextBillingDate: Date = .now
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.currencyCode = currencyCode
        self.billingCycle = billingCycle
        self.nextBillingDate = nextBillingDate
    }
}

enum BillingCycle: String, CaseIterable, Identifiable {
    case weekly = "Co tydzień"
    case monthly = "Co miesiąc"
    case yearly = "Co rok"

    var id: String { rawValue }

    var monthlyMultiplier: Decimal {
        switch self {
        case .weekly: return 52 / 12
        case .monthly: return 1
        case .yearly: return 1 / 12
        }
    }
}
