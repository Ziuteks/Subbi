import SwiftUI

enum AppCal {
    static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2 // poniedziałek
        c.locale = Locale(identifier: "pl_PL")
        return c
    }()
    static let locale = Locale(identifier: "pl_PL")

    static func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d)) ?? .now
    }
}

enum BillingPeriod: String, Codable, CaseIterable, Identifiable {
    case month, year
    var id: String { rawValue }
    var title: String { self == .month ? "Miesiąc" : "Rok" }
    var adverb: String { self == .month ? "miesięcznie" : "rocznie" }
    var component: Calendar.Component { self == .month ? .month : .year }
}

enum SubCategory: String, Codable, CaseIterable, Identifiable {
    case entertainment, tools, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .entertainment: return "Rozrywka"
        case .tools: return "Narzędzia"
        case .other: return "Inne"
        }
    }
    var color: Color {
        switch self {
        case .entertainment: return Color(hex: 0xFF3B30)
        case .tools: return Color(hex: 0x0A84FF)
        case .other: return Color(hex: 0xFF9F0A)
        }
    }
}

struct Subscription: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var price: Double
    var period: BillingPeriod
    var firstPayment: Date
    var category: SubCategory
    var symbol: String
    var colorHex: UInt32

    var color: Color { Color(hex: colorHex) }
    var monthlyCost: Double { period == .month ? price : price / 12 }
    var yearlyCost: Double { period == .month ? price * 12 : price }

    /// Daty płatności w przedziale [start, end).
    func occurrences(from start: Date, to end: Date) -> [Date] {
        var result: [Date] = []
        var n = 0
        while let d = AppCal.cal.date(byAdding: period.component, value: n, to: firstPayment), d < end {
            if d >= start { result.append(d) }
            n += 1
            if n > 5000 { break }
        }
        return result
    }

    func nextPayment(after ref: Date = .now) -> Date? {
        let start = AppCal.cal.startOfDay(for: ref)
        guard let end = AppCal.cal.date(byAdding: .day, value: 400, to: start) else { return nil }
        return occurrences(from: start, to: end).first
    }
}

struct Service: Identifiable {
    var id: String { name }
    let name: String
    let symbol: String
    let colorHex: UInt32
    let category: SubCategory
    let price: Double

    var color: Color { Color(hex: colorHex) }

    static let catalog: [Service] = [
        Service(name: "Netflix", symbol: "play.rectangle.fill", colorHex: 0xE50914, category: .entertainment, price: 22.99),
        Service(name: "Spotify", symbol: "music.note", colorHex: 0x1DB954, category: .entertainment, price: 11.99),
        Service(name: "YouTube", symbol: "play.fill", colorHex: 0xFF0000, category: .entertainment, price: 13.99),
        Service(name: "Adobe", symbol: "paintbrush.pointed.fill", colorHex: 0xFA0F00, category: .tools, price: 52.99),
        Service(name: "iCloud+", symbol: "icloud.fill", colorHex: 0x3B82F6, category: .tools, price: 2.99),
        Service(name: "Apple TV+", symbol: "appletv.fill", colorHex: 0x2C2C2E, category: .entertainment, price: 9.99),
        Service(name: "HBO Max", symbol: "tv.fill", colorHex: 0x6C2BD9, category: .entertainment, price: 29.99),
        Service(name: "Prime Video", symbol: "play.tv.fill", colorHex: 0x00A8E1, category: .entertainment, price: 10.99),
        Service(name: "Disney+", symbol: "sparkles", colorHex: 0x113CCF, category: .entertainment, price: 28.99),
        Service(name: "Microsoft 365", symbol: "square.grid.2x2.fill", colorHex: 0xD83B01, category: .tools, price: 29.99),
        Service(name: "Dropbox", symbol: "shippingbox.fill", colorHex: 0x0061FF, category: .tools, price: 49.99),
        Service(name: "Notion", symbol: "doc.text.fill", colorHex: 0x3A3A3C, category: .tools, price: 39.99)
    ]
}

struct CategoryAmount: Identifiable {
    let category: SubCategory
    let amount: Double
    var id: SubCategory { category }
}

struct MonthTotal: Identifiable {
    let date: Date
    let amount: Double
    var id: Date { date }
}
