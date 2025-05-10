import Foundation
import UserNotifications

struct NotificationManager {
    
    static func scheduleMidnightMotivation(wishes: [Wish]) {
        let validWishes = wishes.filter { $0.savedAmount < $0.price }
        guard let randomWish = validWishes.randomElement() else { return }

        let remaining = randomWish.price - randomWish.savedAmount
        let progress = randomWish.savedAmount / randomWish.price * 100

        let content = UNMutableNotificationContent()
        content.title = "✨ Keep Going!"
        content.body = "\"\(randomWish.title)\" is \(Int(progress))% there. You need $\(remaining, specifier: "%.2f") more. Don't give up!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 17 // Thailand midnight = UTC 17:00
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "midnightWishMotivation", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    static func scheduleDueDateReminder(for wish: Wish) {
        guard !wish.isExpired else { return }

        let calendar = Calendar.current
        guard let oneDayBefore = calendar.date(byAdding: .day, value: -1, to: wish.finalDate) else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏰ \"\(wish.title)\" is almost due!"
        content.body = "Only 1 day left to fulfill this wish. Keep pushing!"
        content.sound = .default

        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: oneDayBefore)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: "dueReminder_\(wish.id)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
