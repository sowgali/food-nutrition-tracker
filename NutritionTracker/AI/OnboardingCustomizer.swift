import Foundation
import SwiftData

/// Orchestrates the onboarding "customize my plan" workflow. The AI part is
/// confined to two clearly-bounded calls (`parsePreferences`, `suggestMeals`).
/// Everything else — schema construction, validation, planning, grocery
/// aggregation, prep scheduling — is deterministic Swift.
@MainActor
public struct OnboardingCustomizer {

    public var ai: AIProvider
    public var planner: MealPlanner
    public var grocery: GroceryListBuilder
    public var prepScheduler: PrepScheduler

    public init(ai: AIProvider,
                planner: MealPlanner = MealPlanner(),
                grocery: GroceryListBuilder = GroceryListBuilder(),
                prepScheduler: PrepScheduler = PrepScheduler()) {
        self.ai = ai
        self.planner = planner
        self.grocery = grocery
        self.prepScheduler = prepScheduler
    }

    // MARK: - Progress reporting

    public enum Stage: String, Equatable {
        case savingProfile
        case parsingPrefs
        case askingLunch
        case askingDinner
        case validating
        case planning
        case shopping
        case prepping
        case done
    }

    public struct Progress: Equatable {
        public var stage: Stage
        public var detail: String
    }

    public enum CustomizeError: Error, LocalizedError {
        case noFoodsInCatalog
        case noUsableTemplates
        case aiReturnedNothing

        public var errorDescription: String? {
            switch self {
            case .noFoodsInCatalog:  return "Food catalog is empty; seed data missing."
            case .noUsableTemplates: return "Couldn't build any valid meal templates from AI suggestions."
            case .aiReturnedNothing: return "AI returned no suggestions."
            }
        }
    }

    // MARK: - Public entry

    /// Builds the profile, queries the AI, validates everything, persists meal
    /// templates, then runs the deterministic planner + grocery + prep
    /// pipelines. The `progress` closure is called on the main actor so the
    /// UI can show step-by-step status.
    public func customize(from state: OnboardingState,
                          in context: ModelContext,
                          progress: @escaping (Progress) -> Void) async throws {

        // 1. Persist profile + targets + workout + preferences from the form.
        progress(.init(stage: .savingProfile, detail: "Saving your profile"))
        let profile = makeProfile(from: state)
        context.insert(profile)
        try context.save()

        // 2. AI-parse the free-text diet description and merge into prefs.
        if !state.freeText.trimmingCharacters(in: .whitespaces).isEmpty {
            progress(.init(stage: .parsingPrefs, detail: "Parsing your diet notes"))
            let parsed = try await ai.parsePreferences(freeText: state.freeText)
            try mergeParsed(parsed, into: profile.preferences!)
            try context.save()
        }

        // 3. Ask the AI for lunch + dinner candidates.
        guard let prefs = profile.preferences, let targets = profile.targets else {
            throw CustomizeError.aiReturnedNothing
        }
        progress(.init(stage: .askingLunch, detail: "Asking AI for lunch ideas"))
        let lunchResp = try await ai.suggestMeals(targets: targets, prefs: prefs, mealType: .lunch)
        progress(.init(stage: .askingDinner, detail: "Asking AI for dinner ideas"))
        let dinnerResp = try await ai.suggestMeals(targets: targets, prefs: prefs, mealType: .dinner)

        let foods = (try? context.fetch(FetchDescriptor<FoodItem>())) ?? []
        guard !foods.isEmpty else { throw CustomizeError.noFoodsInCatalog }

        // 4. Convert AI suggestions to MealTemplate entities. Drop any that
        //    don't validate or that we can't resolve ingredients for.
        progress(.init(stage: .validating, detail: "Validating AI suggestions"))
        let lunchTemplates  = buildTemplates(from: lunchResp.suggestions,
                                             type: .lunch, foods: foods, prefs: prefs)
        let dinnerTemplates = buildTemplates(from: dinnerResp.suggestions,
                                             type: .dinner, foods: foods, prefs: prefs)
        guard !(lunchTemplates.isEmpty && dinnerTemplates.isEmpty) else {
            throw CustomizeError.noUsableTemplates
        }
        // Clear out any prior AI-generated templates so re-runs are clean.
        let priorTemplates = (try? context.fetch(FetchDescriptor<MealTemplate>())) ?? []
        for t in priorTemplates where t.slug.hasPrefix("ai-") { context.delete(t) }
        for t in lunchTemplates  { context.insert(t) }
        for t in dinnerTemplates { context.insert(t) }
        try context.save()

        // 5. Plan the week deterministically.
        progress(.init(stage: .planning, detail: "Building your weekly plan"))
        let allTemplates = (try? context.fetch(FetchDescriptor<MealTemplate>())) ?? []
        let inventory = (try? context.fetch(FetchDescriptor<InventoryItem>())) ?? []
        let inputs = MealPlanner.Inputs(
            profile: profile,
            targets: targets,
            preferences: prefs,
            workout: profile.workout!,
            allTemplates: allTemplates,
            inventory: inventory,
            startDate: Date()
        )
        SeedLoader.resetForReplan(context)
        let plannerResult = planner.plan(inputs)
        context.insert(plannerResult.weekPlan)
        try context.save()

        // 6. Grocery list.
        progress(.init(stage: .shopping, detail: "Aggregating grocery list"))
        let groceries = grocery.build(from: plannerResult.weekPlan,
                                      currentInventory: inventory)
        for item in groceries.items { context.insert(item) }

        // 7. Prep sessions + reminders.
        progress(.init(stage: .prepping, detail: "Scheduling Sunday + Wednesday prep"))
        let preps = prepScheduler.schedule(plan: plannerResult.weekPlan)
        context.insert(preps.sunday)
        context.insert(preps.wednesday)
        try context.save()

        // Best-effort reminder scheduling — fire-and-forget.
        Task { await ReminderScheduler.shared.schedulePrepReminders(preps) }

        progress(.init(stage: .done, detail: "Ready"))
    }

    // MARK: - Profile assembly

    private func makeProfile(from state: OnboardingState) -> UserProfile {
        let targets = NutritionTargets(
            calorieTarget: state.calorieTarget,
            proteinMin: state.proteinMin,
            proteinMax: state.proteinMax,
            fiberMin: state.fiberMin,
            fiberMax: state.fiberMax,
            sugarMax: state.sugarMax,
            sodiumTarget: state.sodiumTarget,
            sodiumMax: state.sodiumMax,
            mealCountMax: state.mealCountMax
        )
        let workout = WorkoutSchedule(
            workoutDays: state.workoutDays,
            morningWorkout: state.morningWorkout,
            goal: state.workoutGoal
        )
        let prefs = FoodPreferences(
            preferredProteins: state.split(state.preferredProteinsText),
            avoidedFoods:      state.split(state.avoidedFoodsText),
            dairyPreferences:  state.split(state.dairyText),
            fruits:            state.split(state.fruitsText),
            legumes:           state.split(state.legumesText),
            supplements:       state.split(state.supplementsText),
            redMeatMaxPerWeek: state.redMeatMaxPerWeek,
            mealVolume:        state.mealVolume,
            budget:            state.budget,
            cookingEffort:     state.cookingEffort,
            maxEggsPerDay:     state.maxEggsPerDay,
            allowEggWhites:    state.allowEggWhites
        )
        let bmr = NutritionCalculator.bmr(
            weightKg: state.weightKg, heightCm: state.heightCm,
            age: state.age, sex: state.sex
        )
        return UserProfile(
            name: "Me",
            age: state.age,
            sex: state.sex,
            heightCm: state.heightCm,
            weightKg: state.weightKg,
            bmr: bmr,
            targets: targets,
            workout: workout,
            preferences: prefs
        )
    }

    // MARK: - AI response validation

    private func mergeParsed(_ parsed: AIPreferenceParseResponse,
                             into prefs: FoodPreferences) throws {
        // Hard sanity checks — refuse to merge if the AI returned wildly long
        // arrays (sign of an unbounded response).
        guard parsed.preferredProteins.count < 30,
              parsed.avoidedFoods.count < 30,
              parsed.legumes.count < 30,
              parsed.fruits.count < 30
        else { return }
        prefs.preferredProteins = dedup(prefs.preferredProteins + parsed.preferredProteins)
        prefs.avoidedFoods      = dedup(prefs.avoidedFoods + parsed.avoidedFoods)
        prefs.legumes           = dedup(prefs.legumes + parsed.legumes)
        prefs.fruits            = dedup(prefs.fruits + parsed.fruits)
    }

    private func dedup(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for v in values where !v.isEmpty {
            if seen.insert(v.lowercased()).inserted { out.append(v) }
        }
        return out
    }

    private func buildTemplates(from suggestions: [AISuggestionResponse.Suggestion],
                                type: MealType,
                                foods: [FoodItem],
                                prefs: FoodPreferences) -> [MealTemplate] {
        var result: [MealTemplate] = []
        for s in suggestions {
            guard let t = buildTemplate(suggestion: s, type: type, foods: foods, prefs: prefs) else { continue }
            result.append(t)
        }
        return result
    }

    private func buildTemplate(suggestion: AISuggestionResponse.Suggestion,
                               type: MealType,
                               foods: [FoodItem],
                               prefs: FoodPreferences) -> MealTemplate? {
        // Parse each "150g chicken breast" line into a MealIngredient.
        var ingredients: [MealIngredient] = []
        for raw in suggestion.ingredients {
            if let mi = parseIngredient(raw, foods: foods) {
                ingredients.append(mi)
            }
        }
        guard ingredients.count >= 2 else { return nil }  // need at least two real foods

        // Reject if it includes an avoided food.
        let avoided = Set(prefs.avoidedFoods.map { $0.lowercased() })
        let hasAvoided = ingredients.contains { ing in
            guard let name = ing.food?.name.lowercased() else { return false }
            return avoided.contains(where: { name.contains($0) })
        }
        if hasAvoided { return nil }

        // Cross-check computed nutrition vs AI's claimed estimate. If the AI
        // is more than 50% off on calories, treat the suggestion as untrusted.
        let computed = ingredients.reduce(NutritionFacts.zero) { $0 + $1.nutrition }
        let claimed = suggestion.estimatedNutrition
        if claimed.calories > 0 {
            let diff = abs(computed.calories - claimed.calories) / claimed.calories
            if diff > 0.5 { return nil }
        }

        let lowVolume = computed.calories < 700 && computed.fiber < 15
        let hasRedMeat = ingredients.contains { ing in
            ing.food?.tags.contains(.redMeat) == true
        }

        let slug = "ai-" + sanitizeSlug(suggestion.name)
        return MealTemplate(
            slug: slug,
            name: suggestion.name,
            mealType: type,
            effort: prefs.cookingEffort,
            lowVolume: lowVolume,
            containsRedMeat: hasRedMeat,
            instructions: defaultInstructions(for: suggestion, ingredients: ingredients),
            ingredients: ingredients
        )
    }

    private func parseIngredient(_ raw: String, foods: [FoodItem]) -> MealIngredient? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        // Pattern: optional number + optional unit + rest
        let pattern = #"^\s*(\d+(?:\.\d+)?)?\s*(g|ml|oz|tbsp|tsp|cup|piece|pcs|scoop)?\s*(.+?)\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let ns = trimmed as NSString
        guard let m = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: ns.length)) else { return nil }

        var qty: Double = 0
        if m.range(at: 1).location != NSNotFound {
            qty = Double(ns.substring(with: m.range(at: 1))) ?? 0
        }
        let nameSubstring = m.range(at: 3).location != NSNotFound
            ? ns.substring(with: m.range(at: 3))
            : trimmed

        // Match food by case-insensitive substring or slug.
        let needle = nameSubstring.lowercased()
        let food = foods.first { item in
            let itemName = item.name.lowercased()
            let slugAsName = item.slug.replacingOccurrences(of: "-", with: " ")
            return itemName.contains(needle) || needle.contains(itemName)
                || needle.contains(slugAsName)
                || slugAsName.contains(needle)
        }
        guard let food else { return nil }

        if qty <= 0 { qty = defaultQuantity(for: food) }
        return MealIngredient(food: food, quantity: qty)
    }

    private func defaultQuantity(for food: FoodItem) -> Double {
        switch food.category {
        case .protein:    return 150
        case .vegetable:  return 100
        case .grain:      return 80
        case .legume:     return 100
        case .fruit:      return 80
        case .fat:        return 5
        case .dairy:      return 150
        case .supplement: return 1
        case .condiment, .beverage, .other: return 50
        }
    }

    private func sanitizeSlug(_ s: String) -> String {
        let allowed = s.lowercased().map { ch -> Character in
            (ch.isLetter || ch.isNumber) ? ch : "-"
        }
        return String(allowed).split(separator: "-", omittingEmptySubsequences: true).joined(separator: "-")
    }

    private func defaultInstructions(for suggestion: AISuggestionResponse.Suggestion,
                                     ingredients: [MealIngredient]) -> [String] {
        var steps: [String] = []
        if let protein = ingredients.first(where: { $0.food?.category == .protein }),
           let p = protein.food {
            let q = Int(protein.quantity)
            steps.append("Cook \(q)\(p.defaultUnit.rawValue) of \(p.name): pan-sear or bake to 165°F internal; rest 3 minutes.")
        }
        if let veg = ingredients.first(where: { $0.food?.category == .vegetable }),
           let v = veg.food {
            steps.append("Roast or steam \(Int(veg.quantity))\(v.defaultUnit.rawValue) \(v.name) until just tender.")
        }
        if let legume = ingredients.first(where: { $0.food?.category == .legume }),
           let l = legume.food {
            steps.append("Warm \(Int(legume.quantity))\(l.defaultUnit.rawValue) \(l.name).")
        }
        if steps.isEmpty {
            steps = ["Prep ingredients per package; combine in bowl and serve."]
        }
        steps.append("Plate, season to taste.")
        return steps
    }
}
