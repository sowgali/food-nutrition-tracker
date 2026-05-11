import Foundation

public extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    static func today() -> Date { Calendar.current.startOfDay(for: Date()) }

    static func sundayOf(week date: Date = Date()) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        let weekday = cal.component(.weekday, from: date)
        return cal.date(byAdding: .day, value: -(weekday - 1), to: cal.startOfDay(for: date))
            ?? cal.startOfDay(for: date)
    }

    var shortDayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE d"
        return f.string(from: self)
    }

    var fullDayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: self)
    }
}
