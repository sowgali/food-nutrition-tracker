import Foundation
import SwiftData

@Model
public final class UserProfile {
    public var name: String
    public var age: Int
    public var sexRaw: String
    public var heightCm: Double
    public var weightKg: Double

    // Derived but cached so we don't recalc every render.
    public var bmr: Double

    @Relationship(deleteRule: .cascade) public var targets: NutritionTargets?
    @Relationship(deleteRule: .cascade) public var workout: WorkoutSchedule?
    @Relationship(deleteRule: .cascade) public var preferences: FoodPreferences?

    public init(name: String = "Me",
                age: Int = 30,
                sex: Sex = .male,
                heightCm: Double = 175,
                weightKg: Double = 75,
                bmr: Double = 1700,
                targets: NutritionTargets? = nil,
                workout: WorkoutSchedule? = nil,
                preferences: FoodPreferences? = nil) {
        self.name = name
        self.age = age
        self.sexRaw = sex.rawValue
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.bmr = bmr
        self.targets = targets
        self.workout = workout
        self.preferences = preferences
    }

    public var sex: Sex {
        get { Sex(rawValue: sexRaw) ?? .other }
        set { sexRaw = newValue.rawValue }
    }
}
