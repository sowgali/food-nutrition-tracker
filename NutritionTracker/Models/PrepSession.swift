import Foundation
import SwiftData

@Model
public final class PrepContainer {
    public var template: MealTemplate?
    public var portions: Double
    public var labelText: String
    public var instructionsOverride: [String]

    public init(template: MealTemplate? = nil,
                portions: Double = 1,
                labelText: String = "",
                instructionsOverride: [String] = []) {
        self.template = template
        self.portions = portions
        self.labelText = labelText
        self.instructionsOverride = instructionsOverride
    }
}

@Model
public final class PrepSession {
    public var date: Date            // when the prep happens (Sun/Wed)
    public var coversFromDate: Date  // first day this prep covers
    public var coversToDate: Date    // last day this prep covers
    @Relationship(deleteRule: .cascade) public var containers: [PrepContainer]

    public init(date: Date,
                coversFromDate: Date,
                coversToDate: Date,
                containers: [PrepContainer] = []) {
        self.date = date
        self.coversFromDate = coversFromDate
        self.coversToDate = coversToDate
        self.containers = containers
    }

    public var totalPortions: Double {
        containers.reduce(0) { $0 + $1.portions }
    }
}

@Model
public final class SubstitutionRule {
    public var originalFoodSlug: String
    public var substituteFoodSlugs: [String]
    public var ratio: Double  // how many units of sub per unit of original
    public var note: String?

    public init(originalFoodSlug: String,
                substituteFoodSlugs: [String],
                ratio: Double = 1.0,
                note: String? = nil) {
        self.originalFoodSlug = originalFoodSlug
        self.substituteFoodSlugs = substituteFoodSlugs
        self.ratio = ratio
        self.note = note
    }
}
