import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: SubscriptionStore
    @State private var showLogoutDialog = false
    @State private var loggedOut = false

    private let currencies = ["PLN", "EUR", "USD", "GBP"]
    private let languages = ["Polski", "English"]

    private var initials: String {
        store.userName.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Konto") {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        HStack(spacing: 12) {
                            Text(initials.isEmpty ? "?" : initials)
                                .font(.headline)
                                .frame(width: 44, height: 44)
                                .background(Theme.accent.opacity(0.25), in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.userName).font(.headline)
                                Text(store.userEmail).font(.caption).foregroundStyle(Theme.muted)
                            }
                        }
                    }
                    .listRowBackground(Theme.card)
                }

                Section("Subskrypcje i płatności") {
                    Picker("Domyślna waluta", selection: $store.currency) {
                        ForEach(currencies, id: \.self) { Text($0).tag($0) }
                    }
                    .listRowBackground(Theme.card)
                }

                Section("Powiadomienia") {
                    Toggle("Przypomnienia o płatnościach", isOn: $store.remindersEnabled)
                        .listRowBackground(Theme.card)
                    if store.remindersEnabled {
                        Stepper(value: $store.reminderDays, in: 0...14) {
                            Text(store.reminderDays == 0
                                 ? "Przypomnij w dniu płatności"
                                 : "Przypomnij \(store.reminderDays) dni przed")
                        }
                        .listRowBackground(Theme.card)
                    }
                    Toggle("Dźwięki", isOn: $store.soundsEnabled)
                        .listRowBackground(Theme.card)
                }

                Section("Bezpieczeństwo i język") {
                    NavigationLink("Zmień hasło") { PasswordView() }
                        .listRowBackground(Theme.card)
                    Picker("Język aplikacji", selection: $store.language) {
                        ForEach(languages, id: \.self) { Text($0).tag($0) }
                    }
                    .listRowBackground(Theme.card)
                }

                Section {
                    Button(role: .destructive) {
                        showLogoutDialog = true
                    } label: {
                        Text("Wyloguj się").frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10).stroke(Theme.alert, lineWidth: 1)
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Ustawienia")
            .confirmationDialog("Czy na pewno chcesz się wylogować?",
                                isPresented: $showLogoutDialog, titleVisibility: .visible) {
                Button("Wyloguj się", role: .destructive) { loggedOut = true }
                Button("Anuluj", role: .cancel) {}
            }
            .alert("Wylogowano", isPresented: $loggedOut) {
                Button("OK") {}
            } message: {
                Text("To wersja demonstracyjna bez serwera kont – dane pozostają na urządzeniu.")
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var store: SubscriptionStore

    var body: some View {
        Form {
            Section("Dane użytkownika") {
                TextField("Imię i nazwisko", text: $store.userName)
                TextField("Adres e-mail", text: $store.userEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .listRowBackground(Theme.card)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Konto")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    @State private var new = ""
    @State private var repeatNew = ""
    @State private var done = false

    private var valid: Bool { new.count >= 8 && new == repeatNew && !current.isEmpty }

    var body: some View {
        Form {
            Section {
                SecureField("Obecne hasło", text: $current)
                SecureField("Nowe hasło (min. 8 znaków)", text: $new)
                SecureField("Powtórz nowe hasło", text: $repeatNew)
            }
            .listRowBackground(Theme.card)

            Section {
                Button("Zapisz") { done = true }
                    .disabled(!valid)
                    .frame(maxWidth: .infinity)
            } footer: {
                if !new.isEmpty && new != repeatNew {
                    Text("Hasła nie są takie same.").foregroundStyle(Theme.alert)
                }
            }
            .listRowBackground(Theme.card)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Zmień hasło")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Hasło zmienione", isPresented: $done) {
            Button("OK") { dismiss() }
        } message: {
            Text("Wersja demonstracyjna – hasło nie jest wysyłane na serwer.")
        }
    }
}
