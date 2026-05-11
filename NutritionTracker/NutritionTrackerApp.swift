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
            RootTabView()
                .environment(\.app, env)
                .task {
                    await ReminderScheduler.shared.requestAuthorization()
                    SeedLoader.seedIfEmpty(sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
