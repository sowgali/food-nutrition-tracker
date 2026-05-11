import SwiftUI
import SwiftData

@main
struct NutritionTrackerApp: App {
    @StateObject private var env = AppEnvironment()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            NutritionTargets.self,
            WorkoutSchedule.self,
            FoodPreferences.self,
            FoodItem.self,
            MealIngredient.self,
            MealTemplate.self,
            Meal.self,
            DayPlan.self,
            WeekPlan.self,
            GroceryItem.self,
            InventoryItem.self,
            PrepSession.self,
            PrepContainer.self,
            SubstitutionRule.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer failed: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environment(\.app, env)
        }
        .modelContainer(sharedModelContainer)
    }
}

/// Decides between onboarding and the main tab UI based on whether a
/// `UserProfile` exists. Kept separate from `@main` so we can use
/// `@Environment(\.modelContext)` and `@Query`.
struct RootContainerView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @State private var bootstrapped = false

    var body: some View {
        Group {
            if !bootstrapped {
                // First frame: seed the catalog + show a brief launch view.
                Color(.systemBackground).overlay(ProgressView())
            } else if profiles.isEmpty {
                OnboardingView(onComplete: { /* @Query will re-render us into RootTabView */ })
            } else {
                RootTabView()
            }
        }
        .task {
            await ReminderScheduler.shared.requestAuthorization()
            SeedLoader.seedCatalogIfEmpty(context)
            bootstrapped = true
        }
    }
}
