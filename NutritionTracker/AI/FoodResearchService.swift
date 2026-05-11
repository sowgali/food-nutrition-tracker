import Foundation

/// Bridges the AIProvider into a SwiftData-friendly shape. The AI returns raw
/// per-100g numbers; this service validates them and produces a FoodItem
/// candidate the caller can persist. The service does NOT save directly —
/// that's the caller's job — preserving the rule that AI never mutates state.
public struct FoodResearchService {

    public var provider: AIProvider

    public init(provider: AIProvider) {
        self.provider = provider
    }

    public func researchAndBuild(name: String,
                                 category: FoodCategory = .other,
                                 tags: [FoodTag] = []) async throws -> FoodItem {
        let dto = try await provider.research(food: name)
        try validate(dto.per100g)
        let slug = name.lowercased().replacingOccurrences(of: " ", with: "-")
        return FoodItem(slug: slug,
                        name: name,
                        category: category,
                        tags: tags,
                        perBaseNutrition: dto.per100g,
                        defaultUnit: .g,
                        baseQuantity: 100)
    }

    private func validate(_ f: NutritionFacts) throws {
        // Sanity checks — reject obviously bogus AI output.
        guard f.calories >= 0, f.calories < 1000 else { throw AIError.decodingFailed }
        guard f.protein  >= 0, f.protein  < 100  else { throw AIError.decodingFailed }
        guard f.fat      >= 0, f.fat      < 100  else { throw AIError.decodingFailed }
        guard f.fiber    >= 0, f.fiber    < 100  else { throw AIError.decodingFailed }
        guard f.sugar    >= 0, f.sugar    < 100  else { throw AIError.decodingFailed }
        guard f.sodium   >= 0, f.sodium   < 10000 else { throw AIError.decodingFailed }
    }
}
