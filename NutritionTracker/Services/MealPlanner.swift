import Foundation
import SwiftData

/// Generates a 7-day plan from a candidate pool of MealTemplates, applying
/// hard constraints first, then scoring valid plans on soft preferences.
public struct MealPlanner {

    public struct Inputs {
        public var profile: UserProfile
        public var targets: NutritionTargets
        public var preferences: FoodPreferences
        public var workout: WorkoutSchedule
        public var allTemplates: [MealTemplate]
        public var inventory: [InventoryItem]
        public var startDate: Date
        public init(profile: UserProfile,
                    targets: NutritionTargets,
                    preferences: FoodPreferences,
                    workout: WorkoutSchedule,
                    allTemplates: [MealTemplate],
                    inventory: [InventoryItem],
                    startDate: Date) {
            self.profile = profile
            self.targets = targets
            self.preferences = preferences
            self.workout = workout
            self.allTemplates = allTemplates
            self.inventory = inventory
            self.startDate = startDate
        }
    }

    public struct Output {
        public var weekPlan: WeekPlan
        public var rejectedReasons: [String]
    }

    // MARK: - Public entry

    public func plan(_ inputs: Inputs) -> Output {
        let cal = Calendar(identifier: .gregorian)
        let week = startOfSundayWeek(for: inputs.startDate, calendar: cal)

        // Split templates by type, filter out anything we never want to suggest.
        let usable = inputs.allTemplates.filter { isAllowed(template: $0, prefs: inputs.preferences) }
        let breakfasts = usable.filter { $0.mealType == .breakfast }
        let lunches    = usable.filter { $0.mealType == .lunch }
        let dinners    = usable.filter { $0.mealType == .dinner }

        // Lock the fixed breakfast template if there is exactly one allowed —
        // matches the spec "Lock fixed breakfast if user has one."
        let fixedBreakfast: MealTemplate? = breakfasts.count == 1 ? breakfasts.first : nil

        var rejected: [String] = []
        var days: [DayPlan] = []
        var redMeatUsed = 0
        let redMeatCap = inputs.preferences.redMeatMaxPerWeek
        let inventorySlugs = Set(inputs.inventory.compactMap { $0.food?.slug })

        for offset in 0..<7 {
            guard let date = cal.date(byAdding: .day, value: offset, to: week) else { continue }

            let breakfast = fixedBreakfast ?? breakfasts.randomElement()
            let dayMeals = generateDay(
                date: date,
                breakfast: breakfast,
                lunches: lunches,
                dinners: dinners,
                targets: inputs.targets,
                prefs: inputs.preferences,
                inventorySlugs: inventorySlugs,
                allowRedMeat: redMeatUsed < redMeatCap
            )

            // Track red-meat usage across the week.
            if dayMeals.contains(where: { $0.template?.containsRedMeat == true }) {
                redMeatUsed += 1
            }

            // Validate; if it fails we still keep it but record reasons so the
            // UI can flag the day rather than silently producing junk.
            let day = DayPlan(date: date, meals: dayMeals)
            let v = NutritionCalculator.validate(day: day, against: inputs.targets)
            if !v.passes {
                rejected.append("\(formatted(date)): \(v.issues.joined(separator: "; "))")
            }
            days.append(day)
        }

        let week_ = WeekPlan(startDate: week, days: days)
        return Output(weekPlan: week_, rejectedReasons: rejected)
    }

    // MARK: - Day-level generation

    private func generateDay(date: Date,
                             breakfast: MealTemplate?,
                             lunches: [MealTemplate],
                             dinners: [MealTemplate],
                             targets: NutritionTargets,
                             prefs: FoodPreferences,
                             inventorySlugs: Set<String>,
                             allowRedMeat: Bool) -> [Meal] {
        var meals: [Meal] = []

        // Try up to N candidate pairings; pick the one with the best score.
        var bestPair: (lunch: MealTemplate, dinner: MealTemplate, score: Double)?
        let lunchesToTry = lunches.filter { allowRedMeat || !$0.containsRedMeat }
        let dinnersToTry = dinners.filter { allowRedMeat || !$0.containsRedMeat }

        let breakfastFacts = breakfast?.nutrition ?? .zero

        for l in lunchesToTry {
            for d in dinnersToTry {
                let totals = breakfastFacts + l.nutrition + d.nutrition
                guard passesHardConstraints(totals: totals,
                                            targets: targets,
                                            prefs: prefs,
                                            templates: [breakfast, l, d].compactMap { $0 })
                else { continue }
                let score = score(totals: totals,
                                  templates: [l, d],
                                  targets: targets,
                                  prefs: prefs,
                                  inventorySlugs: inventorySlugs)
                if score > (bestPair?.score ?? -Double.greatestFiniteMagnitude) {
                    bestPair = (l, d, score)
                }
            }
        }

        if let b = breakfast {
            meals.append(Meal(date: date, mealType: .breakfast, template: b))
        }
        if let pair = bestPair {
            meals.append(Meal(date: date, mealType: .lunch,  template: pair.lunch))
            meals.append(Meal(date: date, mealType: .dinner, template: pair.dinner))
        } else {
            // Fallback: pick whatever's available even if validation fails so the
            // user always sees something and can swap.
            if let l = lunchesToTry.first ?? lunches.first {
                meals.append(Meal(date: date, mealType: .lunch, template: l))
            }
            if let d = dinnersToTry.first ?? dinners.first {
                meals.append(Meal(date: date, mealType: .dinner, template: d))
            }
        }
        return meals
    }

    // MARK: - Filters / scoring

    private func isAllowed(template: MealTemplate, prefs: FoodPreferences) -> Bool {
        let avoided = Set(prefs.avoidedFoods.map { $0.lowercased() })
        for ing in template.ingredients {
            guard let food = ing.food else { continue }
            let name = food.name.lowercased()
            if avoided.contains(where: { name.contains($0) }) { return false }
            if !prefs.allowEggWhites && name.contains("egg white") { return false }
        }
        return true
    }

    private func passesHardConstraints(totals: NutritionFacts,
                                       targets: NutritionTargets,
                                       prefs: FoodPreferences,
                                       templates: [MealTemplate]) -> Bool {
        // Egg cap across the day.
        let eggs = templates.flatMap { $0.ingredients }
            .filter { ($0.food?.name.lowercased().contains("egg") ?? false) }
            .reduce(0.0) { $0 + $1.quantity }
        if eggs > Double(prefs.maxEggsPerDay) { return false }

        // Macro envelopes.
        if totals.calories < targets.calorieTarget - targets.calorieTolerance { return false }
        if totals.calories > targets.calorieTarget + targets.calorieTolerance { return false }
        if totals.protein  < targets.proteinMin { return false }
        if totals.sugar    > targets.sugarMax  { return false }
        if totals.sodium   > targets.sodiumMax { return false }
        // Fiber min is treated as soft below the strict cutoff: only fail if we're
        // way under.
        if totals.fiber    < targets.fiberMin * 0.7 { return false }
        return true
    }

    private func score(totals: NutritionFacts,
                       templates: [MealTemplate],
                       targets: NutritionTargets,
                       prefs: FoodPreferences,
                       inventorySlugs: Set<String>) -> Double {
        var score = 0.0

        // Closer to calorie target = better.
        score -= abs(totals.calories - targets.calorieTarget) / 10

        // Protein in the sweet spot.
        let proteinMid = (targets.proteinMin + targets.proteinMax) / 2
        score -= abs(totals.protein - proteinMid) * 2

        // Fiber: bonus for hitting min, more for hitting middle of band.
        let fiberMid = (targets.fiberMin + targets.fiberMax) / 2
        score -= abs(totals.fiber - fiberMid)

        // Low-sugar preference always — every gram under cap is a small win.
        score += max(0, targets.sugarMax - totals.sugar) * 0.5

        // Volume preference.
        if prefs.mealVolume == .low {
            score += templates.filter { $0.lowVolume }.count > 0 ? 5 : 0
        }

        // Effort match.
        if templates.contains(where: { $0.effort == prefs.cookingEffort }) {
            score += 3
        }

        // Reuse existing inventory.
        let usedSlugs = Set(templates.flatMap { $0.ingredients.compactMap { $0.food?.slug } })
        score += Double(usedSlugs.intersection(inventorySlugs).count) * 2

        // Variety bonus (no duplicate template within the same day).
        if Set(templates.map(\.slug)).count == templates.count { score += 2 }

        return score
    }

    // MARK: - Helpers

    private func startOfSundayWeek(for date: Date, calendar: Calendar) -> Date {
        var cal = calendar
        cal.firstWeekday = 1  // Sunday
        let weekday = cal.component(.weekday, from: date)  // 1 = Sunday
        return cal.date(byAdding: .day, value: -(weekday - 1), to: cal.startOfDay(for: date))
            ?? cal.startOfDay(for: date)
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f.string(from: date)
    }

    public init() {}
}
