import SwiftUI
import SwiftData

public struct RootTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Today", systemImage: "sun.max") }

            NavigationStack { WeeklyPlanView() }
                .tabItem { Label("Plan", systemImage: "calendar") }

            NavigationStack { CookTodayView() }
                .tabItem { Label("Cook", systemImage: "frying.pan") }

            NavigationStack { GroceryListView() }
                .tabItem { Label("Grocery", systemImage: "cart") }

            NavigationStack { MealPrepView() }
                .tabItem { Label("Prep", systemImage: "shippingbox") }

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

public struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @State private var confirming = false

    public init() {}

    public var body: some View {
        List {
            Section {
                NavigationLink("Targets") { TargetsView() }
                NavigationLink("Food preferences") { PreferencesView() }
            }
            Section("Reset") {
                Button("Re-run onboarding") { confirming = true }
                    .foregroundStyle(.red)
            }
            Section("About") {
                HStack { Text("App"); Spacer(); Text("NutritionTracker").foregroundStyle(.secondary) }
                HStack { Text("Build"); Spacer(); Text("MVP").foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("Settings")
        .alert("Re-run onboarding?",
               isPresented: $confirming,
               actions: {
                   Button("Cancel", role: .cancel) { }
                   Button("Reset", role: .destructive) { resetEverything() }
               },
               message: { Text("This deletes your profile, plan, grocery list, and prep sessions. Food catalog stays. You'll be returned to the welcome screen.") })
    }

    private func resetEverything() {
        // Cascading deletes handle child relationships, but we also clear
        // anything that's loose (plans, groceries, preps, AI templates).
        let allProfiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        for p in allProfiles { context.delete(p) }
        SeedLoader.resetForReplan(context)
        let aiTemplates = ((try? context.fetch(FetchDescriptor<MealTemplate>())) ?? [])
            .filter { $0.slug.hasPrefix("ai-") }
        for t in aiTemplates { context.delete(t) }
        try? context.save()
    }
}
