import Foundation

/// Builds the user's seed profile, targets, workout, and preferences from the
/// spec in the project README.
public enum SeedProfile {

    public static func build() -> UserProfile {
        let targets = NutritionTargets(
            calorieTarget: 1800,
            proteinMin: 100,
            proteinMax: 120,
            fiberMin: 35,
            fiberMax: 38,
            sugarMax: 10,
            sodiumTarget: 2000,
            sodiumMax: 2300,
            mealCountMax: 3
        )
        let workout = WorkoutSchedule(
            workoutDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            morningWorkout: true,
            goal: .recomp
        )
        let prefs = FoodPreferences(
            preferredProteins: ["chicken", "salmon", "cod", "shrimp"],
            avoidedFoods: ["egg whites"],
            dairyPreferences: ["greek yogurt"],
            fruits: ["raspberries", "blackberries"],
            legumes: ["chickpeas", "black beans"],
            supplements: ["protein powder", "creatine"],
            redMeatMaxPerWeek: 1,
            mealVolume: .low,
            budget: .moderate,
            cookingEffort: .light,
            maxEggsPerDay: 2,
            allowEggWhites: false
        )
        let bmr = NutritionCalculator.bmr(weightKg: 75, heightCm: 175, age: 30, sex: .male)
        return UserProfile(name: "Me",
                           age: 30,
                           sex: .male,
                           heightCm: 175,
                           weightKg: 75,
                           bmr: bmr,
                           targets: targets,
                           workout: workout,
                           preferences: prefs)
    }
}
