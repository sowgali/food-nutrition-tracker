import SwiftUI
import SwiftData

public struct CookTodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.app) private var app
    @Query private var dayPlans: [DayPlan]
    @Query private var inventory: [InventoryItem]
    @Query private var rules: [SubstitutionRule]
    @State private var subSuggestions: [String] = []
    @State private var loadingSubs = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let meal = nextMeal,
                   let recipe = app.recipes.recipe(for: meal, inventory: inventory, substitutions: rules) {
                    SectionCard(title: recipe.title) {
                        let summary = "\(meal.mealType.displayName) · \(Fmt.kcal(meal.nutrition.calories)) · \(Fmt.g(meal.nutrition.protein)) protein"
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    SectionCard(title: "Ingredients") {
                        ForEach(recipe.ingredients, id: \.self) { Text($0) }
                    }

                    SectionCard(title: "Steps") {
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(i+1).").bold().frame(width: 22, alignment: .leading)
                                Text(step)
                            }
                        }
                    }

                    if !recipe.substitutions.isEmpty || !subSuggestions.isEmpty {
                        SectionCard(title: "Substitutions") {
                            ForEach(recipe.substitutions, id: \.self) { Text("• \($0)") }
                            ForEach(subSuggestions, id: \.self) { Text("• \($0)").foregroundStyle(Color.accentColor) }
                        }
                    }

                    Button {
                        Task { await loadAISubstitutions(for: meal) }
                    } label: {
                        if loadingSubs { ProgressView() }
                        else { Label("Suggest substitutions (AI)", systemImage: "sparkles") }
                    }
                    .buttonStyle(.bordered)

                    Button {
                        meal.cooked = true
                        try? context.save()
                    } label: {
                        Label("Mark cooked", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(meal.cooked)
                } else {
                    SectionCard {
                        Text("No meal to cook right now. Either you're done for the day or there's no plan yet.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Cook")
    }

    private var nextMeal: Meal? {
        let today = Date.today()
        guard let day = dayPlans.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) else {
            return nil
        }
        return app.cookSelector.nextMeal(in: day)
    }

    private func loadAISubstitutions(for meal: Meal) async {
        guard let template = meal.template, let prefs = userPreferences else { return }
        loadingSubs = true
        defer { loadingSubs = false }
        let missing = template.ingredients.compactMap { ing -> String? in
            guard let f = ing.food else { return nil }
            let have = inventory.filter { $0.food?.slug == f.slug }.reduce(0) { $0 + $1.quantity }
            return have < ing.quantity * meal.portions ? f.name : nil
        }
        guard !missing.isEmpty else {
            subSuggestions = ["You have everything you need — no subs needed."]
            return
        }
        do {
            let result = try await app.ai.suggestSubstitutions(missing: missing, prefs: prefs)
            // Validate: ratio must be in a sane range; drop anything bad.
            subSuggestions = result.substitutions
                .filter { $0.ratio > 0.1 && $0.ratio < 10 && !$0.replacement.isEmpty }
                .map { "Swap \($0.original) → \($0.replacement) (×\($0.ratio)) — \($0.why)" }
        } catch {
            subSuggestions = ["AI suggestions unavailable."]
        }
    }

    private var userPreferences: FoodPreferences? {
        let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        return profiles.first?.preferences
    }
}
