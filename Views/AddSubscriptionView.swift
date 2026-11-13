import SwiftUI

struct AddSubscriptionView: View {
    @EnvironmentObject var store: SubscriptionStore
    @Environment(\.dismiss) private var dismiss

    @State private var search = ""
    @State private var selected: Service?
    @State private var name = ""
    @State private var priceText = ""
    @State private var period: BillingPeriod = .month
    @State private var category: SubCategory = .entertainment
    @State private var firstPayment = Date.now

    private var parsedPrice: Double? {
        Double(priceText.replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (parsedPrice ?? 0) > 0
    }

    private var filtered: [Service] {
        let q = search.trimmingCharacters(in: .whitespaces)
        return q.isEmpty ? Service.catalog
            : Service.catalog.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    private var draft: Subscription {
        let match = (selected?.name == name) ? selected : nil
        return Subscription(
            name: name.trimmingCharacters(in: .whitespaces),
            price: parsedPrice ?? 0,
            period: period,
            firstPayment: AppCal.cal.startOfDay(for: firstPayment),
            category: category,
            symbol: match?.symbol ?? "creditcard.fill",
            colorHex: match?.colorHex ?? 0x5E6AD2
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    searchField
                    Text("POPULARNE SERWISY")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                    servicesRow
                    formCard
                    infoText
                    Button(action: save) {
                        Label("Dodaj", systemImage: "plus")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accent.opacity(canSave ? 1 : 0.4),
                                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(!canSave)
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle("Dodaj subskrypcję")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zapisz", action: save).disabled(!canSave)
                }
            }
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted)
            TextField("Szukaj usługi…", text: $search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var servicesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(filtered) { service in
                    Button { choose(service) } label: {
                        VStack(spacing: 6) {
                            ServiceIcon(symbol: service.symbol, color: service.color, size: 48)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Theme.accent, lineWidth: selected?.id == service.id ? 2.5 : 0)
                                )
                            Text(service.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundStyle(.white)
                        }
                        .frame(width: 62)
                    }
                    .buttonStyle(.plain)
                }
                if filtered.isEmpty {
                    Text("Brak wyników – wpisz nazwę ręcznie poniżej.")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                }
            }
        }
    }

    private var formCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Nazwa")
                TextField("np. Netflix", text: $name)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.muted)
            }
            .padding(.vertical, 12)
            Divider().overlay(Color.white.opacity(0.1))

            HStack {
                Text("Cena")
                TextField("0,00", text: $priceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.muted)
                Text(store.currency).font(.caption).foregroundStyle(Theme.muted)
            }
            .padding(.vertical, 12)
            Divider().overlay(Color.white.opacity(0.1))

            HStack {
                Text("Okres")
                Spacer()
                Picker("Okres", selection: $period) {
                    ForEach(BillingPeriod.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            .padding(.vertical, 8)
            Divider().overlay(Color.white.opacity(0.1))

            HStack {
                Text("Kategoria")
                Spacer()
                Picker("Kategoria", selection: $category) {
                    ForEach(SubCategory.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
            }
            .padding(.vertical, 4)
            Divider().overlay(Color.white.opacity(0.1))

            HStack {
                Text("Data pierwszej płatności")
                Spacer()
                Text(firstPayment.formatted(.dateTime.month(.abbreviated).day().year().locale(AppCal.locale)))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.accent.opacity(0.15), in: Capsule())
            }
            .padding(.top, 12)

            DatePicker("Data", selection: $firstPayment, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, AppCal.locale)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    private var infoText: some View {
        if canSave, let next = draft.nextPayment() {
            Text("Odnowi się co \(period == .month ? "miesiąc" : "rok") od daty pierwszej płatności. Twoja następna płatność: \(next.formatted(.dateTime.month(.abbreviated).day().year().locale(AppCal.locale))).")
                .font(.caption)
                .foregroundStyle(Theme.muted)
        }
    }

    private func choose(_ service: Service) {
        selected = service
        name = service.name
        category = service.category
        priceText = String(format: "%.2f", service.price).replacingOccurrences(of: ".", with: ",")
        SoundManager.tap(enabled: store.soundsEnabled)
    }

    private func save() {
        guard canSave else { return }
        store.add(draft)
        dismiss()
    }
}
