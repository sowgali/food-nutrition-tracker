import Foundation

/// Aggregates ingredients from a WeekPlan and subtracts current inventory.
public struct GroceryListBuilder {

    public struct Result {
        public var items: [GroceryItem]
    }

    public init() {}

    public func build(from plan: WeekPlan,
                      currentInventory: [InventoryItem]) -> Result {

        // 1. Aggregate the plan: slug -> total quantity in base units.
        var needed: [String: (food: FoodItem, quantity: Double, unit: Unit)] = [:]
        for day in plan.days {
            for meal in day.meals {
                guard let template = meal.template else { continue }
                for ing in template.ingredients {
                    guard let food = ing.food else { continue }
                    let q = ing.quantity * meal.portions
                    if var existing = needed[food.slug] {
                        existing.quantity += q
                        needed[food.slug] = existing
                    } else {
                        needed[food.slug] = (food, q, food.defaultUnit)
                    }
                }
            }
        }

        // 2. Subtract on-hand inventory of matching slug + unit.
        var stock: [String: Double] = [:]
        for inv in currentInventory {
            guard let f = inv.food else { continue }
            stock[f.slug, default: 0] += inv.quantity
        }

        // 3. Emit GroceryItems for the remainder.
        var items: [GroceryItem] = []
        for (slug, entry) in needed.sorted(by: { $0.value.food.name < $1.value.food.name }) {
            let toBuy = max(0, entry.quantity - (stock[slug] ?? 0))
            guard toBuy > 0 else { continue }
            items.append(GroceryItem(
                food: entry.food,
                quantity: toBuy,
                unit: entry.unit,
                bought: false,
                weekStart: plan.startDate
            ))
        }
        return Result(items: items)
    }
}
