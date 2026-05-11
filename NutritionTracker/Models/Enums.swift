import Foundation

/// All cross-cutting enums kept in one place so models stay short.

public enum Sex: String, Codable, CaseIterable, Identifiable {
    case male, female, other
    public var id: String { rawValue }
}

public enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    public var id: String { rawValue }
    public var displayName: String { rawValue.capitalized }
}

public enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    public var id: Int { rawValue }
    public var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

public enum WorkoutGoal: String, Codable, CaseIterable, Identifiable {
    case maintain, recomp, cut, bulk, endurance
    public var id: String { rawValue }
}

public enum CookingEffort: String, Codable, CaseIterable, Identifiable {
    case minimal, light, moderate, involved
    public var id: String { rawValue }
}

public enum MealVolume: String, Codable, CaseIterable, Identifiable {
    case low, medium, high
    public var id: String { rawValue }
}

public enum Budget: String, Codable, CaseIterable, Identifiable {
    case tight, moderate, flexible
    public var id: String { rawValue }
}

public enum FoodCategory: String, Codable, CaseIterable, Identifiable {
    case protein, dairy, grain, legume, vegetable, fruit, fat, supplement, condiment, beverage, other
    public var id: String { rawValue }
}

public enum FoodTag: String, Codable, CaseIterable, Identifiable {
    case redMeat, poultry, seafood, egg, plantBased, highProtein, highFiber, lowSugar, lowVolume
    public var id: String { rawValue }
}

public enum Unit: String, Codable, CaseIterable, Identifiable {
    case g, ml, piece, scoop, tsp, tbsp, cup
    public var id: String { rawValue }
}
