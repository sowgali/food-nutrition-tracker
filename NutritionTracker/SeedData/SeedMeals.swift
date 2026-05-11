import Foundation

/// Builds MealTemplates that reference seeded FoodItems by slug. Caller passes
/// the materialized FoodItem array so we don't have to query SwiftData here.
public enum SeedMeals {

    public static func all(foods: [FoodItem]) -> [MealTemplate] {
        let bySlug = Dictionary(uniqueKeysWithValues: foods.map { ($0.slug, $0) })

        func ing(_ slug: String, _ qty: Double, _ note: String? = nil) -> MealIngredient? {
            guard let f = bySlug[slug] else { return nil }
            return MealIngredient(food: f, quantity: qty, note: note)
        }

        let breakfast = MealTemplate(
            slug: "breakfast-fixed",
            name: "Fixed breakfast",
            mealType: .breakfast,
            effort: .minimal,
            lowVolume: true,
            instructions: [
                "Scramble or fry 2 whole eggs in a non-stick pan, no oil.",
                "Top 200g Greek yogurt with 15g chia and 50–70g berries.",
                "Shake 1 scoop protein powder in water.",
                "Take 5g creatine."
            ],
            ingredients: [
                ing("egg", 2),
                ing("greek-yogurt", 200),
                ing("protein-powder", 1),
                ing("chia", 15),
                ing("raspberries", 60),
                ing("creatine", 5)
            ].compactMap { $0 }
        )

        let lunchChicken = MealTemplate(
            slug: "lunch-chicken-chickpeas",
            name: "Chicken + chickpeas + spinach",
            mealType: .lunch,
            effort: .light,
            lowVolume: true,
            instructions: [
                "Pan-sear 170g chicken breast with salt + pepper.",
                "Warm 120g chickpeas; wilt 80g spinach with a tsp of olive oil.",
                "Combine; squeeze of lemon to finish."
            ],
            ingredients: [
                ing("chicken-breast", 170),
                ing("chickpeas", 120),
                ing("spinach", 80),
                ing("olive-oil", 5)
            ].compactMap { $0 }
        )

        let lunchShrimp = MealTemplate(
            slug: "lunch-shrimp-zucchini",
            name: "Shrimp + zucchini + black beans",
            mealType: .lunch,
            effort: .light,
            lowVolume: true,
            instructions: [
                "Sauté 180g shrimp with olive oil and garlic.",
                "Add 100g zucchini ribbons; cook 2 minutes.",
                "Stir in 100g black beans to warm through."
            ],
            ingredients: [
                ing("shrimp", 180),
                ing("zucchini", 100),
                ing("black-beans", 100),
                ing("olive-oil", 5)
            ].compactMap { $0 }
        )

        let dinnerSalmon = MealTemplate(
            slug: "dinner-salmon-asparagus",
            name: "Salmon + asparagus + blackberries",
            mealType: .dinner,
            effort: .light,
            lowVolume: true,
            instructions: [
                "Roast 170g salmon at 400°F, 12 min.",
                "Roast 120g asparagus with olive oil at the same temp.",
                "Serve with 50g blackberries on the side."
            ],
            ingredients: [
                ing("salmon", 170),
                ing("asparagus", 120),
                ing("blackberries", 50),
                ing("olive-oil", 5)
            ].compactMap { $0 }
        )

        let dinnerCod = MealTemplate(
            slug: "dinner-cod-broccoli",
            name: "Cod + broccoli + chickpeas",
            mealType: .dinner,
            effort: .light,
            lowVolume: true,
            instructions: [
                "Bake 220g cod at 375°F, 14 min.",
                "Steam 150g broccoli until just tender.",
                "Warm 100g chickpeas with olive oil and pepper."
            ],
            ingredients: [
                ing("cod", 220),
                ing("broccoli", 150),
                ing("chickpeas", 100),
                ing("olive-oil", 5)
            ].compactMap { $0 }
        )

        return [breakfast, lunchChicken, lunchShrimp, dinnerSalmon, dinnerCod]
    }
}
