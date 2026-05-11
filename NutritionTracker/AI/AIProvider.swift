import Foundation

// MARK: - Codable DTOs the AI is required to return.
//
// Every AI response is parsed into one of these structs and re-validated by
// deterministic Swift before being shown or persisted. The AI never edits
// targets, inventory, or schedules directly.

public struct AIResearchResponse: Codable, Equatable, Sendable {
    public var food: String
    public var per100g: NutritionFacts
    public var notes: String?
}

public struct AISuggestionResponse: Codable, Equatable, Sendable {
    public struct Suggestion: Codable, Equatable, Sendable {
        public var name: String
        public var rationale: String
        public var ingredients: [String]  // free text; planner re-parses
        public var estimatedNutrition: NutritionFacts
    }
    public var suggestions: [Suggestion]
}

public struct AISubstitutionResponse: Codable, Equatable, Sendable {
    public struct Sub: Codable, Equatable, Sendable {
        public var original: String
        public var replacement: String
        public var ratio: Double
        public var why: String
    }
    public var substitutions: [Sub]
}

public struct AIPreferenceParseResponse: Codable, Equatable, Sendable {
    public var preferredProteins: [String]
    public var avoidedFoods: [String]
    public var legumes: [String]
    public var fruits: [String]
    public var notes: String?
}

// MARK: - Provider protocol

public protocol AIProvider: Sendable {
    func research(food: String) async throws -> AIResearchResponse
    func suggestMeals(targets: NutritionTargets,
                      prefs: FoodPreferences,
                      mealType: MealType) async throws -> AISuggestionResponse
    func suggestSubstitutions(missing: [String],
                              prefs: FoodPreferences) async throws -> AISubstitutionResponse
    func parsePreferences(freeText: String) async throws -> AIPreferenceParseResponse
}

public enum AIError: Error {
    case decodingFailed
    case empty
    case provider(String)
}
