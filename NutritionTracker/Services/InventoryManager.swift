import Foundation
import SwiftData

/// Inventory mutations live behind this façade so views never write rows
/// directly — keeps the AI "cannot modify inventory" rule enforceable.
public struct InventoryManager {

    public init() {}

    /// Add a freshly bought grocery to inventory with an inferred expiration.
    public func add(_ grocery: GroceryItem, into context: ModelContext) {
        guard let food = grocery.food else { return }
        let purchased = Date()
        let expires: Date? = food.shelfLifeDays.map { days in
            Calendar.current.date(byAdding: .day, value: days, to: purchased) ?? purchased
        }
        let inv = InventoryItem(food: food,
                                quantity: grocery.quantity,
                                unit: grocery.unit,
                                purchasedDate: purchased,
                                expirationDate: expires)
        context.insert(inv)
    }

    /// Subtract a cooked meal's ingredients from inventory (best-effort).
    public func consume(meal: Meal, from inventory: inout [InventoryItem]) {
        guard let template = meal.template else { return }
        for ing in template.ingredients {
            guard let food = ing.food else { continue }
            var remaining = ing.quantity * meal.portions
            for i in inventory.indices where inventory[i].food?.slug == food.slug && remaining > 0 {
                let take = min(remaining, inventory[i].quantity)
                inventory[i].quantity -= take
                remaining -= take
            }
        }
        inventory.removeAll { $0.quantity <= 0.0001 }
    }

    public func expiring(within days: Int, in inventory: [InventoryItem]) -> [InventoryItem] {
        let cutoff = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return inventory.filter { item in
            if let exp = item.expirationDate {
                return exp <= cutoff
            }
            return false
        }
    }
}
