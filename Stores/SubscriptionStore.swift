import SwiftUI

@MainActor
final class SubscriptionStore: ObservableObject {
    private let storageKey = "subscriptions.v1"

    @Published var subscriptions: [Subscription] {
        didSet { persist(); refreshReminders() }
    }
    @Published var currency: String {
        didSet { UserDefaults.standard.set(currency, forKey: "currency"); refreshReminders() }
    }
    @Published var remindersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(remindersEnabled, forKey: "remindersEnabled")
            if remindersEnabled { NotificationManager.requestAuthorization() }
            refreshReminders()
        }
    }
    @Published var reminderDays: Int {
        didSet { UserDefaults.standard.set(reminderDays, forKey: "reminderDays"); refreshReminders() }
    }
    @Published var soundsEnabled: Bool {
        didSet { UserDefaults.standard.set(soundsEnabled, forKey: "soundsEnabled") }
    }
    @Published var language: String {
        didSet { UserDefaults.standard.set(language, forKey: "language") }
    }
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    @Published var userEmail: String {
        didSet { UserDefaults.standard.set(userEmail, forKey: "userEmail") }
    }

    init() {
        let d = UserDefaults.standard
        currency = d.string(forKey: "currency") ?? "PLN"
        remindersEnabled = d.object(forKey: "remindersEnabled") as? Bool ?? true
        reminderDays = d.object(forKey: "reminderDays") as? Int ?? 1
        soundsEnabled = d.object(forKey: "soundsEnabled") as? Bool ?? true
        language = d.string(forKey: "language") ?? "Polski"
        userName = d.string(forKey: "userName") ?? "Jan Kowalski"
        userEmail = d.string(forKey: "userEmail") ?? "jan.kowalski@email.com"

        if let data = d.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Subscription].self, from: data) {
            subscriptions = decoded
        } else {
            subscriptions = Self.sampleData()
        }
    }

    // MARK: - Dane przykładowe (zgodne z makietą)

    private static func sampleData() -> [Subscription] {
        func make(_ name: String, _ price: Double, _ date: Date) -> Subscription {
            let s = Service.catalog.first { $0.name == name }
            return Subscription(name: name, price: price, period: .month, firstPayment: date,
                                category: s?.category ?? .other,
                                symbol: s?.symbol ?? "creditcard.fill",
                                colorHex: s?.colorHex ?? 0x5E6AD2)
        }
        return [
            make("Netflix", 22.99, AppCal.date(2026, 10, 23)),
            make("Spotify", 11.99, AppCal.date(2026, 10, 24)),
            make("YouTube", 13.99, AppCal.date(2026, 10, 26)),
            make("Apple TV+", 9.99, AppCal.date(2026, 10, 28)),
            make("iCloud+", 2.99, AppCal.date(2026, 11, 1)),
            make("Adobe", 52.99, AppCal.date(2026, 11, 3))
        ]
    }

    // MARK: - Utrwalanie

    private func persist() {
        if let data = try? JSONEncoder().encode(subscriptions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func refreshReminders() {
        NotificationManager.reschedule(subscriptions,
                                       enabled: remindersEnabled,
                                       daysBefore: reminderDays,
                                       money: { [currency] in Self.format($0, currency: currency) })
    }

    // MARK: - Operacje

    func add(_ sub: Subscription) {
        subscriptions.append(sub)
        SoundManager.success(enabled: soundsEnabled)
    }

    func delete(_ sub: Subscription) {
        subscriptions.removeAll { $0.id == sub.id }
    }

    // MARK: - Obliczenia

    var monthlyTotal: Double { subscriptions.reduce(0) { $0 + $1.monthlyCost } }
    var yearlyTotal: Double { subscriptions.reduce(0) { $0 + $1.yearlyCost } }

    /// Subskrypcje posortowane po dacie najbliższej płatności.
    var upcoming: [(sub: Subscription, date: Date)] {
        subscriptions
            .compactMap { s in s.nextPayment().map { (s, $0) } }
            .sorted { $0.1 < $1.1 }
    }

    var nextPayment: (sub: Subscription, date: Date)? { upcoming.first }

    func payments(inMonthOf month: Date) -> [(sub: Subscription, date: Date)] {
        guard let interval = AppCal.cal.dateInterval(of: .month, for: month) else { return [] }
        return subscriptions
            .flatMap { s in s.occurrences(from: interval.start, to: interval.end).map { (s, $0) } }
            .sorted { $0.1 < $1.1 }
    }

    /// Sumy płatności z ostatnich `count` miesięcy (łącznie z bieżącym).
    func monthTotals(last count: Int) -> [MonthTotal] {
        let cal = AppCal.cal
        let thisMonth = cal.dateInterval(of: .month, for: .now)?.start ?? .now
        return (0..<count).reversed().compactMap { offset in
            guard let m = cal.date(byAdding: .month, value: -offset, to: thisMonth) else { return nil }
            let sum = payments(inMonthOf: m).reduce(0) { $0 + $1.sub.price }
            return MonthTotal(date: m, amount: sum)
        }
    }

    // MARK: - Formatowanie

    nonisolated static func format(_ v: Double, currency: String) -> String {
        let whole = abs(v.truncatingRemainder(dividingBy: 1)) < 0.005
        return v.formatted(
            .currency(code: currency)
                .locale(AppCal.locale)
                .precision(.fractionLength(whole ? 0 : 2))
        )
    }

    func money(_ v: Double) -> String { Self.format(v, currency: currency) }

    func dayText(_ date: Date) -> String {
        let cal = AppCal.cal
        if cal.isDateInToday(date) { return "Dziś" }
        if cal.isDateInTomorrow(date) { return "Jutro" }
        return date.formatted(.dateTime.day().month(.abbreviated).locale(AppCal.locale))
    }
}
