import Foundation
import SwiftData

@Model
public final class MealIngredient {
    public var food: FoodItem?
    public var quantity: Double  // in food.defaultUnit
    public var note: String?

    public init(food: FoodItem? = nil, quantity: Double = 0, note: String? = nil) {
        self.food = food
        self.quantity = quantity
        self.note = note
    }

    public var nutrition: NutritionFacts {
        guard let food else { return .zero }
        return food.nutrition(for: quantity)
    }
}

@Model
public final class MealTemplate {
    @Attribute(.unique) public var slug: String
    public var name: String
    public var mealTypeRaw: String
    public var effortRaw: String
    public var lowVolume: Bool
    public var containsRedMeat: Bool
    public var instructions: [String]
    @Relationship(deleteRule: .cascade) public var ingredients: [MealIngredient]

    public init(slug: String,
                name: String,
                mealType: MealType,
                effort: CookingEffort = .light,
                lowVolume: Bool = true,
                containsRedMeat: Bool = false,
                instructions: [String] = [],
                ingredients: [MealIngredient] = []) {
        self.slug = slug
        self.name = name
        self.mealTypeRaw = mealType.rawValue
        self.effortRaw = effort.rawValue
        self.lowVolume = lowVolume
        self.containsRedMeat = containsRedMeat
        self.instructions = instructions
        self.ingredients = ingredients
    }

    public var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .lunch }
        set { mealTypeRaw = newValue.rawValue }
    }
    public var effort: CookingEffort {
        get { CookingEffort(rawValue: effortRaw) ?? .light }
        set { effortRaw = newValue.rawValue }
    }

    public var nutrition: NutritionFacts {
        ingredients.reduce(.zero) { $0 + $1.nutrition }
    }
}
