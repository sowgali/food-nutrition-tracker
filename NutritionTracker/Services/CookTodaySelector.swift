import Foundation

/// Deterministic "what to cook now" selector. Picks the meal that:
///   - Is in the user's day plan
///   - Is not yet marked cooked
///   - Falls within the current time-of-day window
/// Falls back to the next uncooked meal if none match the time window.
public struct CookTodaySelector {

    public init() {}

    public func nextMeal(in day: DayPlan, now: Date = Date()) -> Meal? {
        let hour = Calendar.current.component(.hour, from: now)
        let preferred: MealType =
            hour < 10 ? .breakfast :
            hour < 15 ? .lunch :
            hour < 21 ? .dinner :
            .snack
        if let m = day.meals.first(where: { !$0.cooked && $0.mealType == preferred }) {
            return m
        }
        // Fall back to first uncooked meal, breakfast→lunch→dinner→snack order.
        let order: [MealType] = [.breakfast, .lunch, .dinner, .snack]
        for t in order {
            if let m = day.meals.first(where: { !$0.cooked && $0.mealType == t }) {
                return m
            }
        }
        return nil
    }
}
