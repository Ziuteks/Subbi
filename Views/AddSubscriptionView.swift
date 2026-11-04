import SwiftUI

struct AddSubscriptionView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var price = ""
    @State private var billingCycle: BillingCycle = .monthly
    @State private var nextBillingDate = Date.now

    private var parsedPrice: Decimal? {
        Decimal(string: price.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Szczegóły") {
                    TextField("Nazwa, np. Netflix", text: $name)
                    TextField("Cena (PLN)", text: $price)
                        .keyboardType(.decimalPad)
                    Picker("Okres rozliczenia", selection: $billingCycle) {
                        ForEach(BillingCycle.allCases) { cycle in
                            Text(cycle.rawValue).tag(cycle)
                        }
                    }
                    DatePicker("Następna płatność", selection: $nextBillingDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Nowa subskrypcja")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || parsedPrice == nil || parsedPrice! <= 0)
                }
            }
        }
    }

    private func save() {
        guard let parsedPrice else { return }
        let subscription = Subscription(
            name: name.trimmingCharacters(in: .whitespaces),
            price: parsedPrice,
            billingCycle: billingCycle,
            nextBillingDate: nextBillingDate
        )
        store.add(subscription)
        dismiss()
    }
}
