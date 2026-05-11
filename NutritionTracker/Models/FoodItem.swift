import Foundation
import SwiftData

@Model
public final class FoodItem {
    @Attribute(.unique) public var slug: String
    public var name: String
    public var brand: String?
    public var categoryRaw: String
    public var tagsRaw: [String]

    /// Nutrition is stored "per 100 g" (or per 100 ml for liquids, per 1 piece
    /// for things like an egg). The default unit tells us which scale to use.
    public var perBaseNutrition: NutritionFacts
    public var defaultUnitRaw: String
    public var baseQuantity: Double  // i.e. perBaseNutrition is for THIS many of defaultUnit

    public var costPerBase: Double?   // optional $ per base quantity
    public var shelfLifeDays: Int?    // refrigerated shelf life

    public init(slug: String,
                name: String,
                brand: String? = nil,
                category: FoodCategory,
                tags: [FoodTag] = [],
                perBaseNutrition: NutritionFacts,
                defaultUnit: Unit = .g,
                baseQuantity: Double = 100,
                costPerBase: Double? = nil,
                shelfLifeDays: Int? = nil) {
        self.slug = slug
        self.name = name
        self.brand = brand
        self.categoryRaw = category.rawValue
        self.tagsRaw = tags.map(\.rawValue)
        self.perBaseNutrition = perBaseNutrition
        self.defaultUnitRaw = defaultUnit.rawValue
        self.baseQuantity = baseQuantity
        self.costPerBase = costPerBase
        self.shelfLifeDays = shelfLifeDays
    }

    public var category: FoodCategory {
        get { FoodCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    public var tags: [FoodTag] {
        get { tagsRaw.compactMap(FoodTag.init(rawValue:)) }
        set { tagsRaw = newValue.map(\.rawValue) }
    }
    public var defaultUnit: Unit {
        get { Unit(rawValue: defaultUnitRaw) ?? .g }
        set { defaultUnitRaw = newValue.rawValue }
    }

    /// Macros for `quantity` of `defaultUnit`.
    public func nutrition(for quantity: Double) -> NutritionFacts {
        perBaseNutrition * (quantity / baseQuantity)
    }

    public func contains(tag: FoodTag) -> Bool {
        tagsRaw.contains(tag.rawValue)
    }
}
