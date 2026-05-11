import Foundation

/// Offline, deterministic implementation used during MVP and in previews.
/// Returns the same JSON-shaped data a real provider would emit, so the
/// downstream Codable validation path is exercised in production code.
///
/// Suggestions are prefs-aware: meals containing avoided foods are filtered,
/// and the order is biased toward preferred proteins. That keeps the
/// onboarding "AI customization" visibly responsive to user input.
public struct MockAIProvider: AIProvider {

    public init() {}

    // MARK: - Research

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

    // MARK: - Suggest meals (prefs-aware)

    public func suggestMeals(targets: NutritionTargets,
                             prefs: FoodPreferences,
                             mealType: MealType) async throws -> AISuggestionResponse {
        // Fake an async hop so onboarding's progress UI gets a chance to render.
        try? await Task.sleep(nanoseconds: 200_000_000)

        let prefs_proteins = prefs.preferredProteins.map { $0.lowercased() }
        let avoid = Set(prefs.avoidedFoods.map { $0.lowercased() })
        let likesShrimp  = prefs_proteins.contains(where: { $0.contains("shrimp") })
        let likesSalmon  = prefs_proteins.contains(where: { $0.contains("salmon") })
        let likesCod     = prefs_proteins.contains(where: { $0.contains("cod") })
        let likesChicken = prefs_proteins.contains(where: { $0.contains("chicken") })

        let pool = catalog(for: mealType)
            .filter { sug in !sug.ingredients.contains(where: { ing in
                let l = ing.lowercased()
                return avoid.contains(where: { l.contains($0) })
            }) }
            .filter { sug in
                // Respect veg/no-poultry/etc preferences: if the user listed no
                // meat proteins, drop suggestions whose primary ingredient is one.
                if prefs_proteins.isEmpty { return true }
                let firstIng = sug.ingredients.first?.lowercased() ?? ""
                if firstIng.contains("chicken") && !likesChicken && !prefs_proteins.contains(where: { firstIng.contains($0) }) {
                    return false
                }
                return true
            }

        // Score: 3 points if first ingredient matches a preferred protein.
        let ranked = pool.sorted { a, b in
            score(a, prefer: [likesShrimp ? "shrimp" : "",
                              likesSalmon ? "salmon" : "",
                              likesCod ? "cod" : "",
                              likesChicken ? "chicken" : ""].filter { !$0.isEmpty })
            >
            score(b, prefer: [likesShrimp ? "shrimp" : "",
                              likesSalmon ? "salmon" : "",
                              likesCod ? "cod" : "",
                              likesChicken ? "chicken" : ""].filter { !$0.isEmpty })
        }

        let picks = Array(ranked.prefix(4))
        return AISuggestionResponse(suggestions: picks)
    }

    // MARK: - Substitutions

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

    // MARK: - Parse free-text preferences

    public func parsePreferences(freeText: String) async throws -> AIPreferenceParseResponse {
        try? await Task.sleep(nanoseconds: 200_000_000)
        let lower = freeText.lowercased()
        var proteins: [String] = []
        for p in ["chicken", "salmon", "cod", "shrimp", "turkey", "tofu", "tempeh", "tuna"] where lower.contains(p) {
            proteins.append(p)
        }
        var avoided: [String] = []
        let avoidedKeywords: [(String, String)] = [
            ("no pork", "pork"), ("no beef", "beef"), ("no dairy", "dairy"),
            ("no gluten", "gluten"), ("egg white", "egg whites"),
            ("no nuts", "nuts"), ("no shellfish", "shellfish")
        ]
        for (needle, label) in avoidedKeywords where lower.contains(needle) {
            avoided.append(label)
        }
        var fruits: [String] = []
        for f in ["raspberries", "blackberries", "blueberries", "strawberries", "apple", "banana"] where lower.contains(f) {
            fruits.append(f)
        }
        var legumes: [String] = []
        for l in ["chickpeas", "lentils", "black beans", "kidney beans", "edamame"] where lower.contains(l) {
            legumes.append(l)
        }
        return AIPreferenceParseResponse(
            preferredProteins: proteins,
            avoidedFoods: avoided,
            legumes: legumes,
            fruits: fruits,
            notes: "Parsed by mock provider (keyword-scan)."
        )
    }

    // MARK: - Internal catalog

    private func score(_ s: AISuggestionResponse.Suggestion, prefer terms: [String]) -> Int {
        let first = s.ingredients.first?.lowercased() ?? ""
        return terms.reduce(0) { $0 + (first.contains($1) ? 3 : 0) }
    }

    private func catalog(for type: MealType) -> [AISuggestionResponse.Suggestion] {
        switch type {
        case .lunch: return lunchPool
        case .dinner: return dinnerPool
        case .breakfast: return breakfastPool
        case .snack: return []
        }
    }

    private let lunchPool: [AISuggestionResponse.Suggestion] = [
        .init(name: "Grilled chicken + chickpeas + spinach",
              rationale: "Hits protein, low sugar, low volume.",
              ingredients: ["170g chicken breast", "120g chickpeas", "80g spinach", "5ml olive oil"],
              estimatedNutrition: NutritionFacts(calories: 520, protein: 48, carbs: 28, fat: 18, fiber: 9, sugar: 3, sodium: 380)),
        .init(name: "Shrimp + zucchini + black beans",
              rationale: "Light volume, complete macros, fast cook.",
              ingredients: ["180g shrimp", "100g zucchini", "100g black beans", "5ml olive oil"],
              estimatedNutrition: NutritionFacts(calories: 460, protein: 50, carbs: 24, fat: 9, fiber: 9, sugar: 2, sodium: 410)),
        .init(name: "Cod + broccoli + chickpeas",
              rationale: "Ultra-lean white fish, high fiber sides.",
              ingredients: ["200g cod", "150g broccoli", "100g chickpeas", "5ml olive oil"],
              estimatedNutrition: NutritionFacts(calories: 470, protein: 52, carbs: 28, fat: 8, fiber: 10, sugar: 4, sodium: 290)),
        .init(name: "Chicken + asparagus + chickpeas",
              rationale: "Variation on the staple lunch, swaps spinach for asparagus.",
              ingredients: ["170g chicken breast", "120g asparagus", "100g chickpeas", "5ml olive oil"],
              estimatedNutrition: NutritionFacts(calories: 510, protein: 51, carbs: 26, fat: 14, fiber: 8, sugar: 4, sodium: 320)),
    ]

    private let dinnerPool: [AISuggestionResponse.Suggestion] = [
        .init(name: "Salmon + asparagus + blackberries",
              rationale: "Omega-3 dinner; berries on the side keep sugar low.",
              ingredients: ["170g salmon", "120g asparagus", "50g blackberries", "5ml olive oil"],
              estimatedNutrition: NutritionFacts(calories: 540, protein: 42, carbs: 12, fat: 32, fiber: 6, sugar: 4, sodium: 220)),
        .init(name: "Cod + broccoli + chickpeas (dinner)",
              rationale: "Light, fiber-forward dinner; pairs with morning workouts.",
              ingredients: ["220g cod", "150g broccoli", "100g chickpeas", "5ml olive oil"],
              estimatedNutrition: NutritionFacts(calories: 480, protein: 56, carbs: 28, fat: 8, fiber: 11, sugar: 4, sodium: 280)),
        .init(name: "Shrimp + spinach + black beans",
              rationale: "Quick dinner, big protein hit, low effort.",
              ingredients: ["180g shrimp", "100g spinach", "100g black beans", "5ml olive oil"],
              estimatedNutrition: NutritionFacts(calories: 440, protein: 51, carbs: 22, fat: 8, fiber: 10, sugar: 2, sodium: 380)),
        .init(name: "Chicken + zucchini + chickpeas (dinner)",
              rationale: "Variety pick if you want a non-fish dinner.",
              ingredients: ["170g chicken breast", "150g zucchini", "100g chickpeas", "5ml olive oil"],
              estimatedNutrition: NutritionFacts(calories: 500, protein: 50, carbs: 26, fat: 14, fiber: 8, sugar: 5, sodium: 300)),
    ]

    private let breakfastPool: [AISuggestionResponse.Suggestion] = [
        .init(name: "Eggs + greek yogurt + berries",
              rationale: "Spec-aligned breakfast.",
              ingredients: ["2 egg", "200g greek yogurt", "1 protein powder", "15g chia", "60g raspberries"],
              estimatedNutrition: NutritionFacts(calories: 480, protein: 48, carbs: 24, fat: 18, fiber: 13, sugar: 7, sodium: 280)),
    ]
}
