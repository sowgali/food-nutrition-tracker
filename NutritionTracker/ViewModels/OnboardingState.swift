import Foundation
import SwiftUI

/// Captures every input the onboarding form collects. The view binds directly
/// to these published properties; OnboardingCustomizer reads them at the end
/// to build a UserProfile and run the planner.
@MainActor
public final class OnboardingState: ObservableObject {

    // Demographics
    @Published public var age: Int = 30
    @Published public var sex: Sex = .male
    @Published public var heightCm: Double = 175
    @Published public var weightKg: Double = 75

    // Targets (defaults match the spec; user can adjust)
    @Published public var calorieTarget: Double = 1800
    @Published public var proteinMin: Double = 100
    @Published public var proteinMax: Double = 120
    @Published public var fiberMin: Double = 35
    @Published public var fiberMax: Double = 38
    @Published public var sugarMax: Double = 10
    @Published public var sodiumTarget: Double = 2000
    @Published public var sodiumMax: Double = 2300
    @Published public var mealCountMax: Int = 3

    // Workout
    @Published public var workoutDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @Published public var morningWorkout: Bool = true
    @Published public var workoutGoal: WorkoutGoal = .recomp

    // Preferences — comma-separated strings for easy text-field editing
    @Published public var preferredProteinsText: String = "chicken, salmon, cod, shrimp"
    @Published public var avoidedFoodsText: String = "egg whites"
    @Published public var dairyText: String = "greek yogurt"
    @Published public var fruitsText: String = "raspberries, blackberries"
    @Published public var legumesText: String = "chickpeas, black beans"
    @Published public var supplementsText: String = "protein powder, creatine"
    @Published public var freeText: String = ""

    // Constraints
    @Published public var redMeatMaxPerWeek: Int = 1
    @Published public var maxEggsPerDay: Int = 2
    @Published public var allowEggWhites: Bool = false
    @Published public var mealVolume: MealVolume = .low
    @Published public var cookingEffort: CookingEffort = .light
    @Published public var budget: Budget = .moderate

    public init() {}

    /// Live-derived BMR via Mifflin-St Jeor — shown on the demographics step.
    public var bmr: Double {
        NutritionCalculator.bmr(weightKg: weightKg, heightCm: heightCm, age: age, sex: sex)
    }

    public func split(_ csv: String) -> [String] {
        csv.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
