import Foundation

/// Static nutrition data per 100g (or per item where unit differs).
/// Sourced from USDA-style approximations; tweak as you refine.
public enum SeedFoods {

    public static func all() -> [FoodItem] {
        [
            // Proteins
            food(slug: "egg", name: "Egg (whole, large)",
                 category: .protein, tags: [.egg, .highProtein],
                 nutrition: .init(calories: 78, protein: 6, carbs: 0.6, fat: 5, fiber: 0, sugar: 0.6, sodium: 62),
                 defaultUnit: .piece, base: 1, shelfLifeDays: 21),

            food(slug: "chicken-breast", name: "Chicken breast",
                 category: .protein, tags: [.poultry, .highProtein, .lowVolume],
                 nutrition: .init(calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, sugar: 0, sodium: 74),
                 shelfLifeDays: 3),

            food(slug: "salmon", name: "Salmon",
                 category: .protein, tags: [.seafood, .highProtein],
                 nutrition: .init(calories: 208, protein: 20, carbs: 0, fat: 13, fiber: 0, sugar: 0, sodium: 59),
                 shelfLifeDays: 2),

            food(slug: "cod", name: "Cod",
                 category: .protein, tags: [.seafood, .highProtein, .lowVolume],
                 nutrition: .init(calories: 82, protein: 18, carbs: 0, fat: 0.7, fiber: 0, sugar: 0, sodium: 54),
                 shelfLifeDays: 2),

            food(slug: "shrimp", name: "Shrimp",
                 category: .protein, tags: [.seafood, .highProtein, .lowVolume],
                 nutrition: .init(calories: 99, protein: 24, carbs: 0.2, fat: 0.3, fiber: 0, sugar: 0, sodium: 111),
                 shelfLifeDays: 2),

            // Dairy
            food(slug: "greek-yogurt", name: "Greek yogurt, plain non-fat",
                 category: .dairy, tags: [.highProtein, .lowSugar, .lowVolume],
                 nutrition: .init(calories: 59, protein: 10, carbs: 3.6, fat: 0.4, fiber: 0, sugar: 3.2, sodium: 36),
                 shelfLifeDays: 10),

            // Supplements
            food(slug: "protein-powder", name: "Protein powder (whey)",
                 category: .supplement, tags: [.highProtein, .lowSugar],
                 nutrition: .init(calories: 120, protein: 24, carbs: 3, fat: 1.5, fiber: 1, sugar: 1, sodium: 60),
                 defaultUnit: .scoop, base: 1, shelfLifeDays: 365),

            food(slug: "creatine", name: "Creatine monohydrate",
                 category: .supplement, tags: [],
                 nutrition: .init(),
                 defaultUnit: .g, base: 5, shelfLifeDays: 730),

            // Seeds / fats
            food(slug: "chia", name: "Chia seeds",
                 category: .fat, tags: [.highFiber, .plantBased],
                 nutrition: .init(calories: 486, protein: 17, carbs: 42, fat: 31, fiber: 34, sugar: 0, sodium: 16),
                 shelfLifeDays: 180),

            food(slug: "olive-oil", name: "Olive oil",
                 category: .fat, tags: [],
                 nutrition: .init(calories: 884, protein: 0, carbs: 0, fat: 100, fiber: 0, sugar: 0, sodium: 2),
                 defaultUnit: .ml, base: 100, shelfLifeDays: 365),

            // Fruits
            food(slug: "raspberries", name: "Raspberries",
                 category: .fruit, tags: [.highFiber, .lowSugar, .plantBased],
                 nutrition: .init(calories: 52, protein: 1.2, carbs: 12, fat: 0.7, fiber: 6.5, sugar: 4.4, sodium: 1),
                 shelfLifeDays: 4),

            food(slug: "blackberries", name: "Blackberries",
                 category: .fruit, tags: [.highFiber, .lowSugar, .plantBased],
                 nutrition: .init(calories: 43, protein: 1.4, carbs: 10, fat: 0.5, fiber: 5.3, sugar: 4.9, sodium: 1),
                 shelfLifeDays: 4),

            // Legumes
            food(slug: "chickpeas", name: "Chickpeas, cooked",
                 category: .legume, tags: [.highFiber, .plantBased],
                 nutrition: .init(calories: 164, protein: 9, carbs: 27, fat: 2.6, fiber: 8, sugar: 5, sodium: 7),
                 shelfLifeDays: 5),

            food(slug: "black-beans", name: "Black beans, cooked",
                 category: .legume, tags: [.highFiber, .plantBased],
                 nutrition: .init(calories: 132, protein: 9, carbs: 24, fat: 0.5, fiber: 8.7, sugar: 0.3, sodium: 1),
                 shelfLifeDays: 5),

            // Vegetables
            food(slug: "broccoli", name: "Broccoli",
                 category: .vegetable, tags: [.highFiber, .lowSugar],
                 nutrition: .init(calories: 34, protein: 2.8, carbs: 6.6, fat: 0.4, fiber: 2.6, sugar: 1.7, sodium: 33),
                 shelfLifeDays: 5),

            food(slug: "zucchini", name: "Zucchini",
                 category: .vegetable, tags: [.lowSugar, .lowVolume],
                 nutrition: .init(calories: 17, protein: 1.2, carbs: 3.1, fat: 0.3, fiber: 1.0, sugar: 2.5, sodium: 8),
                 shelfLifeDays: 5),

            food(slug: "spinach", name: "Spinach",
                 category: .vegetable, tags: [.highFiber, .lowSugar],
                 nutrition: .init(calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2, sugar: 0.4, sodium: 79),
                 shelfLifeDays: 4),

            food(slug: "asparagus", name: "Asparagus",
                 category: .vegetable, tags: [.highFiber, .lowSugar],
                 nutrition: .init(calories: 20, protein: 2.2, carbs: 3.9, fat: 0.1, fiber: 2.1, sugar: 1.9, sodium: 2),
                 shelfLifeDays: 4),
        ]
    }

    // MARK: - Helper

    private static func food(slug: String,
                             name: String,
                             category: FoodCategory,
                             tags: [FoodTag],
                             nutrition: NutritionFacts,
                             defaultUnit: Unit = .g,
                             base: Double = 100,
                             shelfLifeDays: Int? = nil) -> FoodItem {
        FoodItem(slug: slug,
                 name: name,
                 category: category,
                 tags: tags,
                 perBaseNutrition: nutrition,
                 defaultUnit: defaultUnit,
                 baseQuantity: base,
                 shelfLifeDays: shelfLifeDays)
    }
}
