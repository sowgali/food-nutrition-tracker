import Foundation

/// Pure deterministic macro/BMR math. No SwiftData. No side effects.
public enum NutritionCalculator {

    /// Mifflin-St Jeor BMR (kcal/day).
    public static func bmr(weightKg: Double, heightCm: Double, age: Int, sex: Sex) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)
        switch sex {
        case .male:   return base + 5
        case .female: return base - 161
        case .other:  return base - 78  // midpoint
        }
    }

    /// Returns macros remaining today given a target and a current total.
    /// Negative values indicate you've gone over.
    public static func remaining(target: NutritionTargets, consumed: NutritionFacts) -> NutritionFacts {
        NutritionFacts(
            calories: target.calorieTarget - consumed.calories,
            protein:  target.proteinMin     - consumed.protein,
            carbs:    0,
            fat:      0,
            fiber:    target.fiberMin       - consumed.fiber,
            sugar:    target.sugarMax       - consumed.sugar,
            sodium:   target.sodiumMax      - consumed.sodium
        )
    }

    /// Validation report for a single day plan against the user's targets.
    public struct DayValidation {
        public var passes: Bool { issues.isEmpty }
        public var issues: [String]
        public var totals: NutritionFacts
    }

    public static func validate(day: DayPlan, against t: NutritionTargets) -> DayValidation {
        let totals = day.nutrition
        var issues: [String] = []
        if totals.calories < t.calorieTarget - t.calorieTolerance {
            issues.append("Low calories: \(Int(totals.calories)) < \(Int(t.calorieTarget - t.calorieTolerance))")
        }
        if totals.calories > t.calorieTarget + t.calorieTolerance {
            issues.append("Over calories: \(Int(totals.calories)) > \(Int(t.calorieTarget + t.calorieTolerance))")
        }
        if totals.protein < t.proteinMin {
            issues.append("Low protein: \(Int(totals.protein))g < \(Int(t.proteinMin))g")
        }
        if totals.protein > t.proteinMax + 20 {
            issues.append("Excess protein: \(Int(totals.protein))g")
        }
        if totals.fiber < t.fiberMin {
            issues.append("Low fiber: \(Int(totals.fiber))g < \(Int(t.fiberMin))g")
        }
        if totals.sugar > t.sugarMax {
            issues.append("Sugar over cap: \(Int(totals.sugar))g > \(Int(t.sugarMax))g")
        }
        if totals.sodium > t.sodiumMax {
            issues.append("Sodium over cap: \(Int(totals.sodium))mg")
        }
        if day.meals.count > t.mealCountMax {
            issues.append("Too many meals: \(day.meals.count)")
        }
        return DayValidation(issues: issues, totals: totals)
    }
}
