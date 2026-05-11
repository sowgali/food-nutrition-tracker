import Foundation
import SwiftData

/// One-shot seed: inserts profile + foods + meal templates only if the store
/// is empty. Safe to call on every launch.
public enum SeedLoader {

    public static func seedIfEmpty(_ context: ModelContext) {
        // Profile
        let existingProfiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        if existingProfiles.isEmpty {
            let profile = SeedProfile.build()
            context.insert(profile)
        }

        // Foods
        let existingFoods = (try? context.fetch(FetchDescriptor<FoodItem>())) ?? []
        if existingFoods.isEmpty {
            for f in SeedFoods.all() { context.insert(f) }
        }

        // Meal templates (after foods so ingredients can resolve)
        let allFoods = (try? context.fetch(FetchDescriptor<FoodItem>())) ?? []
        let existingMeals = (try? context.fetch(FetchDescriptor<MealTemplate>())) ?? []
        if existingMeals.isEmpty, !allFoods.isEmpty {
            for t in SeedMeals.all(foods: allFoods) { context.insert(t) }
        }

        try? context.save()
    }
}
