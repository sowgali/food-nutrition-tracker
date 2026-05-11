import Foundation

/// Offline, deterministic implementation used during MVP and in previews.
/// Returns the same JSON-shaped data a real provider would emit, so the
/// downstream Codable validation path is exercised in production code.
public struct MockAIProvider: AIProvider {

    public init() {}

    public func research(food: String) async throws -> AIResearchResponse {
        let key = food.lowercased()
        let facts: NutritionFacts
        switch key {
        case _ where key.contains("salmon"):
            facts = NutritionFacts(calories: 208, protein: 20, carbs: 0, fat: 13, fiber: 0, sugar: 0, sodium: 59)
        case _ where key.contains("chicken"):
            facts = NutritionFacts(calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, sugar: 0, sodium: 74)
        case _ where key.contains("chickpea"):
            facts = NutritionFacts(calories: 164, protein: 9, carbs: 27, fat: 2.6, fiber: 8, sugar: 5, sodium: 7)
        case _ where key.contains("egg"):
            facts = NutritionFacts(calories: 78, protein: 6, carbs: 0.6, fat: 5, fiber: 0, sugar: 0.6, sodium: 62)
        default:
            facts = NutritionFacts(calories: 100, protein: 5, carbs: 10, fat: 3, fiber: 2, sugar: 1, sodium: 50)
        }
        return AIResearchResponse(food: food,
                                  per100g: facts,
                                  notes: "Mock data — replace with live provider.")
    }

    public func suggestMeals(targets: NutritionTargets,
                             prefs: FoodPreferences,
                             mealType: MealType) async throws -> AISuggestionResponse {
        let s: [AISuggestionResponse.Suggestion] = [
            .init(name: "Grilled chicken & chickpeas",
                  rationale: "Hits protein target, low sugar, low volume.",
                  ingredients: ["150g chicken breast", "100g chickpeas", "spinach", "olive oil"],
                  estimatedNutrition: NutritionFacts(calories: 520, protein: 48, carbs: 28, fat: 18, fiber: 9, sugar: 3, sodium: 380)),
            .init(name: "Salmon + asparagus bowl",
                  rationale: "Omega-3s; pairs with breakfast for daily fiber.",
                  ingredients: ["170g salmon", "150g asparagus", "olive oil"],
                  estimatedNutrition: NutritionFacts(calories: 540, protein: 42, carbs: 8, fat: 32, fiber: 5, sugar: 2, sodium: 220))
        ]
        return AISuggestionResponse(suggestions: s)
    }

    public func suggestSubstitutions(missing: [String],
                                     prefs: FoodPreferences) async throws -> AISubstitutionResponse {
        let subs = missing.map { food -> AISubstitutionResponse.Sub in
            switch food.lowercased() {
            case let s where s.contains("salmon"):
                return .init(original: food, replacement: "cod", ratio: 1.1,
                             why: "Lower fat, similar protein.")
            case let s where s.contains("chickpea"):
                return .init(original: food, replacement: "black beans", ratio: 1.0,
                             why: "Comparable fiber and protein.")
            case let s where s.contains("raspberr"):
                return .init(original: food, replacement: "blackberries", ratio: 1.0,
                             why: "Same low-sugar profile.")
            default:
                return .init(original: food, replacement: "chicken breast", ratio: 1.0,
                             why: "Safe high-protein default.")
            }
        }
        return AISubstitutionResponse(substitutions: subs)
    }

    public func parsePreferences(freeText: String) async throws -> AIPreferenceParseResponse {
        // Naive keyword scan — good enough to demonstrate the validation pipeline.
        let lower = freeText.lowercased()
        var proteins: [String] = []
        for p in ["chicken", "salmon", "cod", "shrimp", "turkey", "tofu"] where lower.contains(p) {
            proteins.append(p)
        }
        var avoided: [String] = []
        if lower.contains("no pork") { avoided.append("pork") }
        if lower.contains("no beef") { avoided.append("beef") }
        if lower.contains("egg white") { avoided.append("egg whites") }
        return AIPreferenceParseResponse(preferredProteins: proteins.isEmpty ? ["chicken", "salmon"] : proteins,
                                         avoidedFoods: avoided,
                                         legumes: ["chickpeas", "black beans"],
                                         fruits: ["raspberries", "blackberries"],
                                         notes: "Parsed by mock provider.")
    }
}
