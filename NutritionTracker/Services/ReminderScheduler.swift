import Foundation
@preconcurrency import UserNotifications

/// Schedules local notifications for prep sessions, expiring inventory, and
/// "time to cook" alerts. All scheduling is deterministic — the AI never
/// decides reminders directly.
public final class ReminderScheduler {

    public static let shared = ReminderScheduler()

    private let center = UNUserNotificationCenter.current()
    private init() {}

    public func requestAuthorization() async {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Silent — the rest of the app works without notifications.
        }
    }

    public func schedulePrepReminders(_ prep: PrepScheduler.Output) async {
        await cancelAll(prefix: "prep-")
        await schedule(id: "prep-sunday",
                       title: "Sunday meal prep",
                       body: "\(prep.sunday.containers.count) container(s) to prep · covers Sun–Wed",
                       at: prep.sunday.date.atHour(9))
        await schedule(id: "prep-wednesday",
                       title: "Wednesday meal prep",
                       body: "\(prep.wednesday.containers.count) container(s) to prep · covers Thu–Sat",
                       at: prep.wednesday.date.atHour(18))
    }

    public func scheduleCookReminders(for day: DayPlan) async {
        await cancelAll(prefix: "cook-")
        for meal in day.meals {
            let hour: Int
            switch meal.mealType {
            case .breakfast: hour = 7
            case .lunch:     hour = 12
            case .dinner:    hour = 19
            case .snack:     hour = 15
            }
            let when = meal.date.atHour(hour)
            let title = "Time for \(meal.mealType.displayName)"
            let body = meal.template?.name ?? "Open the app to see today's plan"
            await schedule(id: "cook-\(meal.mealTypeRaw)-\(Int(when.timeIntervalSince1970))",
                           title: title,
                           body: body,
                           at: when)
        }
    }

    public func scheduleExpiringReminders(_ items: [InventoryItem]) async {
        await cancelAll(prefix: "expire-")
        for item in items {
            guard let food = item.food, let exp = item.expirationDate else { continue }
            let when = exp.atHour(8)
            await schedule(id: "expire-\(food.slug)-\(Int(when.timeIntervalSince1970))",
                           title: "\(food.name) expires soon",
                           body: "Use within today.",
                           at: when)
        }
    }

    // MARK: - Internals

    private func schedule(id: String, title: String, body: String, at date: Date) async {
        guard date > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        do { try await center.add(request) } catch { /* ignore */ }
    }

    private func cancelAll(prefix: String) async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}

private extension Date {
    func atHour(_ hour: Int, minute: Int = 0) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: self)
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? self
    }
}
