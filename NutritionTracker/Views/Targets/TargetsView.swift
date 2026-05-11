import SwiftUI
import SwiftData

public struct TargetsView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    public init() {}

    public var body: some View {
        Form {
            if let profile = profiles.first {
                Section("Demographics") {
                    HStack { Text("Name"); Spacer(); TextField("Name", text: bind(\.name, on: profile)).multilineTextAlignment(.trailing) }
                    Stepper("Age: \(profile.age)", value: bind(\.age, on: profile), in: 14...100)
                    Picker("Sex", selection: bindSex(profile)) {
                        ForEach(Sex.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    HStack { Text("Height (cm)"); Spacer(); TextField("", value: bind(\.heightCm, on: profile), format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    HStack { Text("Weight (kg)"); Spacer(); TextField("", value: bind(\.weightKg, on: profile), format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    HStack { Text("BMR (kcal)"); Spacer(); Text(Int(profile.bmr).description).foregroundStyle(.secondary) }
                    Button("Recompute BMR") {
                        profile.bmr = NutritionCalculator.bmr(weightKg: profile.weightKg,
                                                              heightCm: profile.heightCm,
                                                              age: profile.age,
                                                              sex: profile.sex)
                    }
                }

                if let t = profile.targets {
                    Section("Nutrition") {
                        stepper("Calorie target", value: bind(\.calorieTarget, on: t), range: 1000...4000, step: 50)
                        stepper("Protein min (g)", value: bind(\.proteinMin, on: t), range: 40...250)
                        stepper("Protein max (g)", value: bind(\.proteinMax, on: t), range: 40...300)
                        stepper("Fiber min (g)", value: bind(\.fiberMin, on: t), range: 10...80)
                        stepper("Fiber max (g)", value: bind(\.fiberMax, on: t), range: 10...80)
                        stepper("Sugar max (g)", value: bind(\.sugarMax, on: t), range: 0...80)
                        stepper("Sodium target (mg)", value: bind(\.sodiumTarget, on: t), range: 500...4000, step: 50)
                        stepper("Sodium max (mg)", value: bind(\.sodiumMax, on: t), range: 500...4000, step: 50)
                        Stepper("Meals per day max: \(t.mealCountMax)", value: bind(\.mealCountMax, on: t), in: 1...6)
                    }
                }

                if let w = profile.workout {
                    Section("Workout") {
                        Toggle("Morning workout", isOn: bind(\.morningWorkout, on: w))
                        Picker("Goal", selection: bindGoal(w)) {
                            ForEach(WorkoutGoal.allCases) { Text($0.rawValue.capitalized).tag($0) }
                        }
                        ForEach(Weekday.allCases) { day in
                            Toggle(day.shortName, isOn: weekdayBinding(day, on: w))
                        }
                    }
                }
            } else {
                Text("No profile yet.")
            }
        }
        .navigationTitle("Targets")
    }

    // MARK: - Bindings

    private func bind<Root: AnyObject, Value>(_ key: ReferenceWritableKeyPath<Root, Value>, on root: Root) -> Binding<Value> {
        Binding(
            get: { root[keyPath: key] },
            set: { root[keyPath: key] = $0; try? context.save() }
        )
    }

    private func bindSex(_ p: UserProfile) -> Binding<Sex> {
        Binding(get: { p.sex }, set: { p.sex = $0; try? context.save() })
    }

    private func bindGoal(_ w: WorkoutSchedule) -> Binding<WorkoutGoal> {
        Binding(get: { w.goal }, set: { w.goal = $0; try? context.save() })
    }

    private func weekdayBinding(_ day: Weekday, on w: WorkoutSchedule) -> Binding<Bool> {
        Binding(
            get: { w.workoutDays.contains(day) },
            set: { isOn in
                var s = w.workoutDays
                if isOn { s.insert(day) } else { s.remove(day) }
                w.workoutDays = s
                try? context.save()
            }
        )
    }

    private func stepper(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double = 1) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", value: value, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(maxWidth: 100)
            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
        }
    }
}
