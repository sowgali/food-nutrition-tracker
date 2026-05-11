import Foundation

/// Wraps a meal's instructions with substitution awareness. Falls back to the
/// template's baked-in steps, then to a generic step list.
public struct CookingInstructionProvider {

    public struct Recipe {
        public var title: String
        public var ingredients: [String]   // human-readable lines
        public var steps: [String]
        public var substitutions: [String] // optional suggestions if inventory short
    }

    public init() {}

    public func recipe(for meal: Meal,
                       inventory: [InventoryItem],
                       substitutions: [SubstitutionRule]) -> Recipe? {
        guard let template = meal.template else { return nil }

        let stockBySlug: [String: Double] = inventory.reduce(into: [:]) { dict, item in
            guard let s = item.food?.slug else { return }
            dict[s, default: 0] += item.quantity
        }

        var lines: [String] = []
        var subs: [String] = []
        for ing in template.ingredients {
            guard let food = ing.food else { continue }
            let needed = ing.quantity * meal.portions
            let qtyText = formatQuantity(needed, unit: food.defaultUnit)
            lines.append("• \(qtyText) \(food.name)")
            let have = stockBySlug[food.slug] ?? 0
            if have < needed,
               let rule = substitutions.first(where: { $0.originalFoodSlug == food.slug }) {
                let s = rule.substituteFoodSlugs.joined(separator: ", ")
                subs.append("Out of \(food.name)? Try: \(s) (×\(rule.ratio))")
            }
        }

        let steps = template.instructions.isEmpty
            ? defaultSteps(for: template)
            : template.instructions

        return Recipe(title: template.name,
                      ingredients: lines,
                      steps: steps,
                      substitutions: subs)
    }

    // MARK: - Helpers

    private func defaultSteps(for template: MealTemplate) -> [String] {
        var steps: [String] = []
        let hasGrain = template.ingredients.contains(where: { $0.food?.category == .grain })
        let hasProtein = template.ingredients.contains(where: { $0.food?.category == .protein })
        let hasVeg = template.ingredients.contains(where: { $0.food?.category == .vegetable })
        if hasGrain   { steps.append("Cook the grain per package instructions.") }
        if hasProtein { steps.append("Sear/bake the protein to internal temp; rest 3 minutes.") }
        if hasVeg     { steps.append("Roast or steam vegetables until just tender.") }
        steps.append("Combine in bowl, season, and serve.")
        return steps
    }

    private func formatQuantity(_ value: Double, unit: Unit) -> String {
        let rounded = (value * 10).rounded() / 10
        let s = rounded.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(rounded))
            : String(rounded)
        return "\(s)\(unit.rawValue)"
    }
}
