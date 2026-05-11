import Foundation
import SwiftData

/// A scheduled meal on a specific day (an instance of a MealTemplate).
@Model
public final class Meal {
    public var date: Date
    public var mealTypeRaw: String
    public var portions: Double
    public var cooked: Bool
    public var template: MealTemplate?

    public init(date: Date,
                mealType: MealType,
                portions: Double = 1.0,
                cooked: Bool = false,
                template: MealTemplate? = nil) {
        self.date = date
        self.mealTypeRaw = mealType.rawValue
        self.portions = portions
        self.cooked = cooked
        self.template = template
    }

    public var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .lunch }
        set { mealTypeRaw = newValue.rawValue }
    }

    public var nutrition: NutritionFacts {
        (template?.nutrition ?? .zero) * portions
    }
}

@Model
public final class DayPlan {
    public var date: Date
    @Relationship(deleteRule: .cascade) public var meals: [Meal]

    public init(date: Date, meals: [Meal] = []) {
        self.date = date
        self.meals = meals
    }

    public var nutrition: NutritionFacts {
        meals.reduce(.zero) { $0 + $1.nutrition }
    }

    public func meal(of type: MealType) -> Meal? {
        meals.first { $0.mealTypeRaw == type.rawValue }
    }
}

@Model
public final class WeekPlan {
    public var startDate: Date  // a Sunday
    @Relationship(deleteRule: .cascade) public var days: [DayPlan]

    public init(startDate: Date, days: [DayPlan] = []) {
        self.startDate = startDate
        self.days = days
    }

    public var sortedDays: [DayPlan] {
        days.sorted { $0.date < $1.date }
    }
}
