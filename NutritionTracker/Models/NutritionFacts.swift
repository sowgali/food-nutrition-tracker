import Foundation

/// Per-serving (or per-100g) nutrition payload. Used everywhere we need to talk
/// about macros without dragging in SwiftData @Model classes.
public struct NutritionFacts: Codable, Hashable, Sendable {
    public var calories: Double
    public var protein: Double   // grams
    public var carbs: Double     // grams
    public var fat: Double       // grams
    public var fiber: Double     // grams
    public var sugar: Double     // grams
    public var sodium: Double    // milligrams

    public init(calories: Double = 0,
                protein: Double = 0,
                carbs: Double = 0,
                fat: Double = 0,
                fiber: Double = 0,
                sugar: Double = 0,
                sodium: Double = 0) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
    }

    public static let zero = NutritionFacts()

    public static func + (lhs: NutritionFacts, rhs: NutritionFacts) -> NutritionFacts {
        NutritionFacts(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: lhs.fiber + rhs.fiber,
            sugar: lhs.sugar + rhs.sugar,
            sodium: lhs.sodium + rhs.sodium
        )
    }

    public static func * (lhs: NutritionFacts, scalar: Double) -> NutritionFacts {
        NutritionFacts(
            calories: lhs.calories * scalar,
            protein: lhs.protein * scalar,
            carbs: lhs.carbs * scalar,
            fat: lhs.fat * scalar,
            fiber: lhs.fiber * scalar,
            sugar: lhs.sugar * scalar,
            sodium: lhs.sodium * scalar
        )
    }

    public static func += (lhs: inout NutritionFacts, rhs: NutritionFacts) {
        lhs = lhs + rhs
    }
}
