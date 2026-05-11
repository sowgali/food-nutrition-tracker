import SwiftUI
import SwiftData

public struct WeeklyPlanView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.app) private var app
    @Query private var profiles: [UserProfile]
    @Query private var templates: [MealTemplate]
    @Query private var inventory: [InventoryItem]
    @Query(sort: \WeekPlan.startDate, order: .reverse) private var weekPlans: [WeekPlan]
    @State private var rejected: [String] = []
    @State private var working = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    Text("Weekly plan").font(.title2.bold())
                    Spacer()
                    Button(action: regenerate) {
                        if working { ProgressView() } else { Label("Regenerate", systemImage: "arrow.clockwise") }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(working)
                }

                if let plan = weekPlans.first {
                    ForEach(plan.sortedDays, id: \.persistentModelID) { day in
                        dayCard(day, target: profiles.first?.targets)
                    }
                } else {
                    SectionCard {
                        Text("No plan yet. Tap Regenerate to build one from your seed data.")
                            .foregroundStyle(.secondary)
                    }
                }

                if !rejected.isEmpty {
                    SectionCard(title: "Validator notes", footer: "Days flagged here failed at least one target check; tap a meal to swap.") {
                        ForEach(rejected, id: \.self) { issue in
                            Text("• \(issue)").font(.footnote)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Plan")
    }

    @ViewBuilder
    private func dayCard(_ day: DayPlan, target: NutritionTargets?) -> some View {
        SectionCard(title: day.date.fullDayLabel) {
            ForEach(day.meals, id: \.persistentModelID) { meal in
                NavigationLink {
                    SwapMealView(meal: meal)
                } label: {
                    mealRow(meal)
                }
                .buttonStyle(.plain)
            }
            if let target {
                Divider().padding(.vertical, 4)
                let v = NutritionCalculator.validate(day: day, against: target)
                MacroBars(totals: v.totals, targets: target)
                if !v.passes {
                    Text(v.issues.joined(separator: " · "))
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func mealRow(_ meal: Meal) -> some View {
        HStack {
            Text(meal.mealType.displayName.prefix(1))
                .frame(width: 22, height: 22)
                .background(Circle().fill(.thinMaterial))
                .font(.caption.bold())
            VStack(alignment: .leading) {
                Text(meal.template?.name ?? "—")
                Text(Fmt.kcal(meal.nutrition.calories) + " · " + Fmt.g(meal.nutrition.protein) + " protein")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
    }

    private func regenerate() {
        guard let profile = profiles.first,
              let targets = profile.targets,
              let prefs = profile.preferences,
              let workout = profile.workout
        else { return }
        working = true
        defer { working = false }

        // Wipe old plans + grocery + prep tied to the same week.
        let existing = (try? context.fetch(FetchDescriptor<WeekPlan>())) ?? []
        for p in existing { context.delete(p) }
        let oldGroceries = (try? context.fetch(FetchDescriptor<GroceryItem>())) ?? []
        for g in oldGroceries { context.delete(g) }
        let oldPreps = (try? context.fetch(FetchDescriptor<PrepSession>())) ?? []
        for p in oldPreps { context.delete(p) }

        let inputs = MealPlanner.Inputs(
            profile: profile,
            targets: targets,
            preferences: prefs,
            workout: workout,
            allTemplates: templates,
            inventory: inventory,
            startDate: Date()
        )
        let result = app.planner.plan(inputs)
        context.insert(result.weekPlan)

        // Grocery list
        let g = app.grocery.build(from: result.weekPlan, currentInventory: inventory)
        for item in g.items { context.insert(item) }

        // Prep sessions
        let preps = app.prep.schedule(plan: result.weekPlan)
        context.insert(preps.sunday)
        context.insert(preps.wednesday)

        rejected = result.rejectedReasons
        try? context.save()

        // Fire-and-forget reminder scheduling.
        Task { await ReminderScheduler.shared.schedulePrepReminders(preps) }
    }
}

public struct SwapMealView: View {
    @Environment(\.modelContext) private var context
    @Query private var templates: [MealTemplate]
    public var meal: Meal

    public var body: some View {
        List {
            Section("Replace \(meal.template?.name ?? "this meal")") {
                ForEach(templates.filter { $0.mealType == meal.mealType }, id: \.persistentModelID) { t in
                    Button {
                        meal.template = t
                        try? context.save()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(t.name)
                            Text("\(Int(t.nutrition.calories)) kcal · \(Int(t.nutrition.protein))g protein")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Swap meal")
    }
}
