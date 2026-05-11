import Foundation
import SwiftData

/// Two-stage seeding.
///
/// `seedCatalogIfEmpty` runs on every launch and only inserts the static food
/// catalog plus the spec-defined fixed breakfast template. It never creates a
/// `UserProfile` — that's the onboarding flow's job.
///
/// `seedFullDefaultsIfEmpty` is the "use spec defaults" path: it builds the
/// profile + targets + preferences + workout + the original lunch/dinner
/// templates, so a user who taps "use my defaults" on the welcome screen skips
/// onboarding entirely.
public enum SeedLoader {

    /// Foods + fixed breakfast. Safe on every launch.
    public static func seedCatalogIfEmpty(_ context: ModelContext) {
        let existingFoods = (try? context.fetch(FetchDescriptor<FoodItem>())) ?? []
        if existingFoods.isEmpty {
            for f in SeedFoods.all() { context.insert(f) }
        }
        // Materialize foods we just inserted so MealTemplate ingredients can
        // resolve their references.
        let foods = (try? context.fetch(FetchDescriptor<FoodItem>())) ?? []

        let existingTemplates = (try? context.fetch(FetchDescriptor<MealTemplate>())) ?? []
        let hasBreakfast = existingTemplates.contains { $0.mealType == .breakfast }
        if !hasBreakfast, !foods.isEmpty,
           let breakfast = SeedMeals.all(foods: foods).first(where: { $0.mealType == .breakfast }) {
            context.insert(breakfast)
        }
        try? context.save()
    }

    /// Full seed: profile + targets + workout + prefs + spec lunches/dinners.
    /// Idempotent — bails if a profile already exists.
    public static func seedFullDefaultsIfEmpty(_ context: ModelContext) {
        seedCatalogIfEmpty(context)

        let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        if profiles.isEmpty {
            context.insert(SeedProfile.build())
        }

        let foods = (try? context.fetch(FetchDescriptor<FoodItem>())) ?? []
        let templates = (try? context.fetch(FetchDescriptor<MealTemplate>())) ?? []
        let hasNonBreakfast = templates.contains { $0.mealType != .breakfast }
        if !hasNonBreakfast {
            for t in SeedMeals.all(foods: foods) where t.mealType != .breakfast {
                context.insert(t)
            }
        }
        try? context.save()
    }

    /// Used by onboarding when the user wants to start fresh: wipes plans,
    /// groceries, prep, and any AI-generated templates so the next run rebuilds
    /// everything from scratch. Foods and the fixed breakfast are kept.
    public static func resetForReplan(_ context: ModelContext) {
        let plans = (try? context.fetch(FetchDescriptor<WeekPlan>())) ?? []
        for p in plans { context.delete(p) }
        let groceries = (try? context.fetch(FetchDescriptor<GroceryItem>())) ?? []
        for g in groceries { context.delete(g) }
        let preps = (try? context.fetch(FetchDescriptor<PrepSession>())) ?? []
        for p in preps { context.delete(p) }
        try? context.save()
    }
}
