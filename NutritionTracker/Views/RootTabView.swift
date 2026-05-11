import SwiftUI

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

            NavigationStack {
                List {
                    NavigationLink("Targets") { TargetsView() }
                    NavigationLink("Food preferences") { PreferencesView() }
                }
                .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
