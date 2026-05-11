import Foundation
import SwiftData

@Model
public final class FoodPreferences {
    public var preferredProteins: [String]
    public var avoidedFoods: [String]
    public var dairyPreferences: [String]
    public var fruits: [String]
    public var legumes: [String]
    public var supplements: [String]
    public var redMeatMaxPerWeek: Int
    public var mealVolumeRaw: String
    public var budgetRaw: String
    public var cookingEffortRaw: String
    public var maxEggsPerDay: Int
    public var allowEggWhites: Bool

    public init(preferredProteins: [String] = ["chicken", "salmon", "cod", "shrimp"],
                avoidedFoods: [String] = ["egg whites"],
                dairyPreferences: [String] = ["greek yogurt"],
                fruits: [String] = ["raspberries", "blackberries"],
                legumes: [String] = ["chickpeas", "black beans"],
                supplements: [String] = ["protein powder", "creatine"],
                redMeatMaxPerWeek: Int = 1,
                mealVolume: MealVolume = .low,
                budget: Budget = .moderate,
                cookingEffort: CookingEffort = .light,
                maxEggsPerDay: Int = 2,
                allowEggWhites: Bool = false) {
        self.preferredProteins = preferredProteins
        self.avoidedFoods = avoidedFoods
        self.dairyPreferences = dairyPreferences
        self.fruits = fruits
        self.legumes = legumes
        self.supplements = supplements
        self.redMeatMaxPerWeek = redMeatMaxPerWeek
        self.mealVolumeRaw = mealVolume.rawValue
        self.budgetRaw = budget.rawValue
        self.cookingEffortRaw = cookingEffort.rawValue
        self.maxEggsPerDay = maxEggsPerDay
        self.allowEggWhites = allowEggWhites
    }

    public var mealVolume: MealVolume {
        get { MealVolume(rawValue: mealVolumeRaw) ?? .low }
        set { mealVolumeRaw = newValue.rawValue }
    }
    public var budget: Budget {
        get { Budget(rawValue: budgetRaw) ?? .moderate }
        set { budgetRaw = newValue.rawValue }
    }
    public var cookingEffort: CookingEffort {
        get { CookingEffort(rawValue: cookingEffortRaw) ?? .light }
        set { cookingEffortRaw = newValue.rawValue }
    }
}
