import Foundation
import SwiftData

@Model
public final class GroceryItem {
    public var food: FoodItem?
    public var quantity: Double
    public var unitRaw: String
    public var bought: Bool
    public var weekStart: Date

    public init(food: FoodItem? = nil,
                quantity: Double = 0,
                unit: Unit = .g,
                bought: Bool = false,
                weekStart: Date = Date()) {
        self.food = food
        self.quantity = quantity
        self.unitRaw = unit.rawValue
        self.bought = bought
        self.weekStart = weekStart
    }

    public var unit: Unit {
        get { Unit(rawValue: unitRaw) ?? .g }
        set { unitRaw = newValue.rawValue }
    }
}

@Model
public final class InventoryItem {
    public var food: FoodItem?
    public var quantity: Double
    public var unitRaw: String
    public var purchasedDate: Date
    public var expirationDate: Date?

    public init(food: FoodItem? = nil,
                quantity: Double = 0,
                unit: Unit = .g,
                purchasedDate: Date = Date(),
                expirationDate: Date? = nil) {
        self.food = food
        self.quantity = quantity
        self.unitRaw = unit.rawValue
        self.purchasedDate = purchasedDate
        self.expirationDate = expirationDate
    }

    public var unit: Unit {
        get { Unit(rawValue: unitRaw) ?? .g }
        set { unitRaw = newValue.rawValue }
    }

    public var isExpiringSoon: Bool {
        guard let expirationDate else { return false }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
        return days >= 0 && days <= 2
    }

    public var isExpired: Bool {
        guard let expirationDate else { return false }
        return expirationDate < Date()
    }
}
