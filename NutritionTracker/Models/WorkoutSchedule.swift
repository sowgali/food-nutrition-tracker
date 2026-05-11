import Foundation
import SwiftData

@Model
public final class WorkoutSchedule {
    public var workoutDayIntsRaw: [Int]
    public var morningWorkout: Bool
    public var goalRaw: String

    public init(workoutDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday],
                morningWorkout: Bool = true,
                goal: WorkoutGoal = .recomp) {
        self.workoutDayIntsRaw = workoutDays.map(\.rawValue).sorted()
        self.morningWorkout = morningWorkout
        self.goalRaw = goal.rawValue
    }

    public var workoutDays: Set<Weekday> {
        get { Set(workoutDayIntsRaw.compactMap(Weekday.init(rawValue:))) }
        set { workoutDayIntsRaw = newValue.map(\.rawValue).sorted() }
    }

    public var goal: WorkoutGoal {
        get { WorkoutGoal(rawValue: goalRaw) ?? .recomp }
        set { goalRaw = newValue.rawValue }
    }
}
