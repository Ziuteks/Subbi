import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @State private var isShowingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Miesięcznie wydajesz")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(store.monthlyTotal, format: .currency(code: "PLN"))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                    }
                    .padding(.vertical, 8)
                }

                Section("Twoje subskrypcje") {
                    if store.subscriptions.isEmpty {
                        ContentUnavailableView(
                            "Brak subskrypcji",
                            systemImage: "repeat",
                            description: Text("Dodaj pierwszą subskrypcję, aby śledzić wydatki.")
                        )
                    } else {
                        ForEach(store.subscriptions) { subscription in
                            SubscriptionRow(subscription: subscription)
                        }
                        .onDelete(perform: store.delete)
                    }
                }
            }
            .navigationTitle("Subskrypcje")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddSheet = true
                    } label: {
                        Label("Dodaj", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddSubscriptionView()
            }
        }
    }
}
