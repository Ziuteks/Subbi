import Foundation
import UserNotifications
import AudioToolbox
import UIKit

enum NotificationManager {
    static func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Planuje przypomnienia o najbliższych płatnościach (domyślny dźwięk systemowy).
    static func reschedule(_ subs: [Subscription],
                           enabled: Bool,
                           daysBefore: Int,
                           money: (Double) -> String) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard enabled else { return }

        let cal = AppCal.cal
        let start = cal.startOfDay(for: .now)
        guard let end = cal.date(byAdding: .day, value: 120, to: start) else { return }

        for sub in subs {
            for date in sub.occurrences(from: start, to: end).prefix(3) {
                guard let fire = cal.date(byAdding: .day, value: -daysBefore, to: date) else { continue }
                var comps = cal.dateComponents([.year, .month, .day], from: fire)
                comps.hour = 9
                guard let triggerDate = cal.date(from: comps), triggerDate > .now else { continue }

                let when: String
                switch daysBefore {
                case 0: when = "dziś"
                case 1: when = "jutro"
                default: when = "za \(daysBefore) dni"
                }

                let content = UNMutableNotificationContent()
                content.title = "Zbliża się płatność"
                content.body = "\(sub.name): \(money(sub.price)) – \(when)"
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let id = "\(sub.id.uuidString)-\(Int(date.timeIntervalSince1970))"
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
    }
}

enum SoundManager {
    /// Krótki sygnał potwierdzający kluczową akcję (np. dodanie subskrypcji).
    static func success(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1057)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func tap(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1104)
    }
}
