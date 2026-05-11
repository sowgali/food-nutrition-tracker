import Foundation
import SwiftUI

/// Shared lightweight DI container. Views read this via @Environment.
@MainActor
public final class AppEnvironment: ObservableObject {
    public let ai: AIProvider
    public let planner: MealPlanner
    public let grocery: GroceryListBuilder
    public let inventory: InventoryManager
    public let prep: PrepScheduler
    public let cookSelector: CookTodaySelector
    public let recipes: CookingInstructionProvider

    public init(ai: AIProvider = MockAIProvider()) {
        self.ai = ai
        self.planner = MealPlanner()
        self.grocery = GroceryListBuilder()
        self.inventory = InventoryManager()
        self.prep = PrepScheduler()
        self.cookSelector = CookTodaySelector()
        self.recipes = CookingInstructionProvider()
    }
}

public struct AppEnvironmentKey: EnvironmentKey {
    @MainActor public static var defaultValue: AppEnvironment { AppEnvironment() }
}

public extension EnvironmentValues {
    var app: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
