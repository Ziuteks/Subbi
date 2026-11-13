import SwiftUI
import Charts

enum StatRange: String, CaseIterable, Identifiable {
    case day = "Dzień", week = "Tydzień", month = "Miesiąc", year = "Rok"
    var id: String { rawValue }
    /// Przez ile dzielimy koszt roczny, aby dostać kwotę dla zakresu.
    var divisor: Double {
        switch self {
        case .day: return 365
        case .week: return 52
        case .month: return 12
        case .year: return 1
        }
    }
}

struct StatsView: View {
    @EnvironmentObject var store: SubscriptionStore
    @State private var range: StatRange = .week
    @State private var showDetails = false
    @State private var showTop = false

    private var amounts: [(sub: Subscription, amount: Double)] {
        store.subscriptions.map { ($0, $0.yearlyCost / range.divisor) }
    }

    private var total: Double { amounts.reduce(0) { $0 + $1.amount } }

    private var byCategory: [CategoryAmount] {
        SubCategory.allCases.compactMap { cat in
            let sum = amounts.filter { $0.sub.category == cat }.reduce(0) { $0 + $1.amount }
            return sum > 0 ? CategoryAmount(category: cat, amount: sum) : nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Zakres", selection: $range) {
                        ForEach(StatRange.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text(Date.now.formatted(.dateTime.month(.wide).locale(AppCal.locale)).capitalized)
                            .font(.headline)
                        Spacer()
                        Text(Date.now.formatted(.dateTime.year().locale(AppCal.locale)))
                            .foregroundStyle(Theme.muted)
                    }

                    pieCard
                    barCard
                    detailsCard
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle("Statystyki")
        }
    }

    // MARK: Wykres kołowy

    private var pieCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wydatki").font(.headline)

            if total > 0 {
                HStack(spacing: 20) {
                    Chart(byCategory) { item in
                        SectorMark(angle: .value("Kwota", item.amount),
                                   innerRadius: .ratio(0.62),
                                   angularInset: 1.5)
                            .foregroundStyle(item.category.color)
                    }
                    .frame(width: 130, height: 130)
                    .overlay {
                        VStack(spacing: 0) {
                            Text(store.money(total))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                            Text("razem").font(.caption2).foregroundStyle(Theme.muted)
                        }
                        .frame(width: 80)
                    }

                    VStack(spacing: 10) {
                        ForEach(byCategory) { item in
                            HStack(spacing: 8) {
                                Circle().fill(item.category.color).frame(width: 8, height: 8)
                                Text(item.category.title).font(.footnote)
                                Spacer()
                                Text(store.money(item.amount)).font(.footnote.weight(.semibold))
                            }
                        }
                    }
                }
                Divider().overlay(Color.white.opacity(0.1))
                Text("Średnio \(store.money(store.yearlyTotal / 52)) tygodniowo")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
            } else {
                Text("Dodaj subskrypcje, aby zobaczyć statystyki.")
                    .foregroundStyle(Theme.muted)
            }
        }
        .cardStyle()
    }

    // MARK: Wykres słupkowy

    private var barCard: some View {
        let totals = store.monthTotals(last: 6)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Wydatki (ostatnie 6 mies.)").font(.headline)
            Chart(totals) { item in
                BarMark(x: .value("Miesiąc", item.date, unit: .month),
                        y: .value("Kwota", item.amount))
                    .foregroundStyle(Theme.accent)
                    .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).locale(AppCal.locale))
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 140)
        }
        .cardStyle()
    }

    // MARK: Rozwijane sekcje

    private var detailsCard: some View {
        VStack(spacing: 0) {
            DisclosureGroup("Szczegółowy podział", isExpanded: $showDetails) {
                VStack(spacing: 8) {
                    ForEach(amounts.sorted { $0.amount > $1.amount }, id: \.sub.id) { item in
                        row(item.sub, item.amount)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 10)

            Divider().overlay(Color.white.opacity(0.1))

            DisclosureGroup("Najdroższe usługi", isExpanded: $showTop) {
                VStack(spacing: 8) {
                    ForEach(store.subscriptions.sorted { $0.yearlyCost > $1.yearlyCost }.prefix(3)) { sub in
                        row(sub, sub.yearlyCost, suffix: "rocznie")
                    }
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 10)
        }
        .tint(.white)
        .padding(.horizontal, 16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func row(_ sub: Subscription, _ amount: Double, suffix: String? = nil) -> some View {
        HStack(spacing: 10) {
            ServiceIcon(symbol: sub.symbol, color: sub.color, size: 28)
            Text(sub.name).font(.subheadline)
            Spacer()
            Text(store.money(amount) + (suffix.map { " \($0)" } ?? ""))
                .font(.subheadline.weight(.semibold))
        }
    }
}
