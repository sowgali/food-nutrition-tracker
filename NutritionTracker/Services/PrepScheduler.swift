import Foundation

/// Splits the week into a Sunday prep (covers Sun–Wed) and Wednesday prep
/// (covers Thu–Sat), producing container-level instructions.
public struct PrepScheduler {

    public struct Output {
        public var sunday: PrepSession
        public var wednesday: PrepSession
    }

    public init() {}

    public func schedule(plan: WeekPlan) -> Output {
        let cal = Calendar(identifier: .gregorian)
        let sunday = plan.startDate
        let wednesday = cal.date(byAdding: .day, value: 3, to: sunday) ?? sunday
        let saturday = cal.date(byAdding: .day, value: 6, to: sunday) ?? sunday

        let sortedDays = plan.sortedDays
        let firstHalf = sortedDays.prefix(4)  // Sun..Wed
        let secondHalf = sortedDays.suffix(3) // Thu..Sat

        let sundayContainers = containers(from: Array(firstHalf), label: "Sun–Wed")
        let wednesdayContainers = containers(from: Array(secondHalf), label: "Thu–Sat")

        let s = PrepSession(date: sunday,
                            coversFromDate: sunday,
                            coversToDate: wednesday,
                            containers: sundayContainers)
        let w = PrepSession(date: wednesday,
                            coversFromDate: wednesday,
                            coversToDate: saturday,
                            containers: wednesdayContainers)
        return Output(sunday: s, wednesday: w)
    }

    private func containers(from days: [DayPlan], label: String) -> [PrepContainer] {
        // Group identical template+portions across days into one container batch.
        var grouped: [String: (template: MealTemplate, portions: Double)] = [:]
        for day in days {
            for meal in day.meals where meal.mealType != .breakfast {
                guard let t = meal.template else { continue }
                let key = t.slug
                if let existing = grouped[key] {
                    grouped[key] = (existing.template, existing.portions + meal.portions)
                } else {
                    grouped[key] = (t, meal.portions)
                }
            }
        }
        return grouped.values
            .sorted { $0.template.name < $1.template.name }
            .map { entry in
                PrepContainer(
                    template: entry.template,
                    portions: entry.portions,
                    labelText: "\(label) · \(entry.template.name) ×\(Int(entry.portions))",
                    instructionsOverride: entry.template.instructions
                )
            }
    }
}
