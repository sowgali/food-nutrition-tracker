import Foundation
import SwiftData

@Model
public final class NutritionTargets {
    public var calorieTarget: Double
    public var proteinMin: Double
    public var proteinMax: Double
    public var fiberMin: Double
    public var fiberMax: Double
    public var sugarMax: Double
    public var sodiumTarget: Double
    public var sodiumMax: Double
    public var mealCountMax: Int

    public init(calorieTarget: Double = 1800,
                proteinMin: Double = 100,
                proteinMax: Double = 120,
                fiberMin: Double = 35,
                fiberMax: Double = 38,
                sugarMax: Double = 10,
                sodiumTarget: Double = 2000,
                sodiumMax: Double = 2300,
                mealCountMax: Int = 3) {
        self.calorieTarget = calorieTarget
        self.proteinMin = proteinMin
        self.proteinMax = proteinMax
        self.fiberMin = fiberMin
        self.fiberMax = fiberMax
        self.sugarMax = sugarMax
        self.sodiumTarget = sodiumTarget
        self.sodiumMax = sodiumMax
        self.mealCountMax = mealCountMax
    }

    /// "Allowed wiggle room" around calorie target used by the planner.
    public var calorieTolerance: Double { 100 }
}
