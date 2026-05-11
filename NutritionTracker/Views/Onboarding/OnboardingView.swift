import SwiftUI
import SwiftData

/// First-run onboarding. Collects inputs across six steps, then runs the AI
/// customization + deterministic planner pipeline and hands control back to
/// the dashboard.
public struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.app) private var app
    @StateObject private var state = OnboardingState()
    @State private var step: Step = .welcome
    @State private var running = false
    @State private var stage: OnboardingCustomizer.Stage = .savingProfile
    @State private var stageDetail: String = ""
    @State private var errorMessage: String?

    public var onComplete: () -> Void
    public init(onComplete: @escaping () -> Void) { self.onComplete = onComplete }

    // MARK: - Step enum

    enum Step: Int, CaseIterable, Identifiable {
        case welcome, demographics, goals, schedule, preferences, constraints, generate
        var id: Int { rawValue }
        var title: String {
            switch self {
            case .welcome:      return "Welcome"
            case .demographics: return "About you"
            case .goals:        return "Targets"
            case .schedule:     return "Workout schedule"
            case .preferences:  return "Food preferences"
            case .constraints:  return "Limits & style"
            case .generate:     return "Build my plan"
            }
        }
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                progressDots
                ScrollView {
                    Group {
                        switch step {
                        case .welcome:      welcomeStep
                        case .demographics: demographicsStep
                        case .goals:        goalsStep
                        case .schedule:     scheduleStep
                        case .preferences:  preferencesStep
                        case .constraints:  constraintsStep
                        case .generate:     generateStep
                        }
                    }
                    .padding(.horizontal)
                }
                navButtons
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            .navigationTitle(step.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Progress dots

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: s == step ? 22 : 8, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: step)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Let's plan your week.")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("We'll ask a few questions, hand them to the AI for personalized meal suggestions, then validate everything and build a 7-day plan, grocery list, and meal-prep schedule.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            SectionCard(title: "How AI is used", footer: "Macros and validation are 100% deterministic Swift — AI only suggests, it never sets your targets.") {
                Label("Parses your free-text diet notes into structured preferences.", systemImage: "text.book.closed")
                Label("Generates candidate lunch + dinner ideas tailored to your prefs.", systemImage: "sparkles")
                Label("Suggests ingredient substitutions when something's missing.", systemImage: "arrow.triangle.2.circlepath")
            }
            Button("Use the spec defaults (skip questions)") {
                useDefaultsAndFinish()
            }
            .buttonStyle(.bordered)
        }
    }

    private var demographicsStep: some View {
        SectionCard(title: "Tell us about you",
                    footer: "BMR is computed from these values and used as a sanity floor for your calorie target.") {
            Stepper("Age: \(state.age)", value: $state.age, in: 14...100)
            Picker("Sex", selection: $state.sex) {
                ForEach(Sex.allCases) { Text($0.rawValue.capitalized).tag($0) }
            }
            HStack {
                Text("Height (cm)")
                Spacer()
                TextField("cm", value: $state.heightCm, format: .number)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .frame(width: 100)
            }
            HStack {
                Text("Weight (kg)")
                Spacer()
                TextField("kg", value: $state.weightKg, format: .number)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .frame(width: 100)
            }
            HStack {
                Text("Estimated BMR")
                Spacer()
                Text("\(Int(state.bmr)) kcal/day").foregroundStyle(.secondary)
            }
        }
    }

    private var goalsStep: some View {
        VStack(spacing: 12) {
            SectionCard(title: "Daily macro targets") {
                doubleRow("Calorie target", $state.calorieTarget, range: 1000...4000, step: 50, suffix: "kcal")
                doubleRow("Protein min",    $state.proteinMin,    range: 40...250,    step: 5,  suffix: "g")
                doubleRow("Protein max",    $state.proteinMax,    range: 40...300,    step: 5,  suffix: "g")
                doubleRow("Fiber min",      $state.fiberMin,      range: 10...80,     step: 1,  suffix: "g")
                doubleRow("Fiber max",      $state.fiberMax,      range: 10...80,     step: 1,  suffix: "g")
                doubleRow("Sugar max",      $state.sugarMax,      range: 0...80,      step: 1,  suffix: "g")
                doubleRow("Sodium max",     $state.sodiumMax,     range: 500...4000,  step: 50, suffix: "mg")
                Stepper("Meals per day max: \(state.mealCountMax)", value: $state.mealCountMax, in: 1...6)
            }
        }
    }

    private var scheduleStep: some View {
        VStack(spacing: 12) {
            SectionCard(title: "Workouts") {
                Picker("Goal", selection: $state.workoutGoal) {
                    ForEach(WorkoutGoal.allCases) { Text($0.rawValue.capitalized).tag($0) }
                }
                Toggle("Morning workout", isOn: $state.morningWorkout)
                Text("Which days?").font(.subheadline).foregroundStyle(.secondary)
                ForEach(Weekday.allCases) { day in
                    Toggle(day.shortName, isOn: Binding(
                        get: { state.workoutDays.contains(day) },
                        set: { isOn in
                            if isOn { state.workoutDays.insert(day) }
                            else { state.workoutDays.remove(day) }
                        }
                    ))
                }
            }
        }
    }

    private var preferencesStep: some View {
        VStack(spacing: 12) {
            SectionCard(title: "Foods you like (comma-separated)") {
                csvField("Preferred proteins", $state.preferredProteinsText)
                csvField("Dairy",               $state.dairyText)
                csvField("Fruits",              $state.fruitsText)
                csvField("Legumes",             $state.legumesText)
                csvField("Supplements",         $state.supplementsText)
                csvField("Avoided foods",       $state.avoidedFoodsText)
            }
            SectionCard(title: "Anything else? (AI will parse this)",
                        footer: "Examples: \"no pork, prefer wild-caught fish, allergic to shellfish\". Parsed into structured prefs and merged after validation.") {
                TextEditor(text: $state.freeText)
                    .frame(minHeight: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3))
                    )
            }
        }
    }

    private var constraintsStep: some View {
        SectionCard(title: "Limits & style") {
            Stepper("Red meat max/week: \(state.redMeatMaxPerWeek)",
                    value: $state.redMeatMaxPerWeek, in: 0...7)
            Stepper("Eggs/day max: \(state.maxEggsPerDay)",
                    value: $state.maxEggsPerDay, in: 0...6)
            Toggle("Allow egg whites", isOn: $state.allowEggWhites)
            Picker("Meal volume", selection: $state.mealVolume) {
                ForEach(MealVolume.allCases) { Text($0.rawValue.capitalized).tag($0) }
            }
            Picker("Cooking effort", selection: $state.cookingEffort) {
                ForEach(CookingEffort.allCases) { Text($0.rawValue.capitalized).tag($0) }
            }
            Picker("Budget", selection: $state.budget) {
                ForEach(Budget.allCases) { Text($0.rawValue.capitalized).tag($0) }
            }
        }
    }

    private var generateStep: some View {
        SectionCard(title: running ? "Building…" : "Ready to build",
                    footer: "Tap below to ask the AI for personalized lunch + dinner ideas, validate them against your targets, and build the week.") {
            if running {
                progressList
            } else if let err = errorMessage {
                Text(err).foregroundStyle(.red)
                Button("Try again") { Task { await runCustomize() } }
                    .buttonStyle(.borderedProminent)
            } else {
                summaryList
                Button {
                    Task { await runCustomize() }
                } label: {
                    Label("Build my plan", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    // MARK: - Nav buttons

    private var navButtons: some View {
        HStack {
            if step != .welcome && !running {
                Button("Back") { advance(by: -1) }
                    .buttonStyle(.bordered)
            }
            Spacer()
            if step != .generate {
                Button(step == .welcome ? "Get started" : "Next") { advance(by: 1) }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func advance(by delta: Int) {
        let next = (step.rawValue + delta).clamped(to: 0...(Step.allCases.count - 1))
        withAnimation { step = Step(rawValue: next) ?? .welcome }
    }

    // MARK: - Summary + progress

    private var summaryList: some View {
        VStack(alignment: .leading, spacing: 6) {
            row("Age / Sex / BMR", "\(state.age) · \(state.sex.rawValue) · \(Int(state.bmr)) kcal")
            row("Calories / Protein", "\(Int(state.calorieTarget)) kcal · \(Int(state.proteinMin))–\(Int(state.proteinMax))g")
            row("Fiber / Sugar", "\(Int(state.fiberMin))–\(Int(state.fiberMax))g / ≤\(Int(state.sugarMax))g")
            row("Workout days", state.workoutDays.sorted { $0.rawValue < $1.rawValue }.map(\.shortName).joined(separator: " "))
            row("Preferred proteins", state.preferredProteinsText)
            if !state.freeText.isEmpty {
                row("Notes", "\(state.freeText.prefix(60))\(state.freeText.count > 60 ? "…" : "")")
            }
        }
        .font(.subheadline)
    }

    private var progressList: some View {
        VStack(alignment: .leading, spacing: 10) {
            stageRow(.savingProfile, "Saving your profile")
            stageRow(.parsingPrefs,  "Parsing diet notes")
            stageRow(.askingLunch,   "AI: lunch ideas")
            stageRow(.askingDinner,  "AI: dinner ideas")
            stageRow(.validating,    "Validating macros")
            stageRow(.planning,      "Planning the week")
            stageRow(.shopping,      "Building grocery list")
            stageRow(.prepping,      "Scheduling prep + reminders")
            if !stageDetail.isEmpty {
                Text(stageDetail).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private func stageRow(_ s: OnboardingCustomizer.Stage, _ label: String) -> some View {
        let done = stage.rawValue >= s.rawValue && stage != s
        let active = stage == s
        return HStack(spacing: 10) {
            Group {
                if done {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                } else if active {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "circle").foregroundStyle(.tertiary)
                }
            }
            .frame(width: 22)
            Text(label)
            Spacer()
        }
        .font(.subheadline)
    }

    // MARK: - Run

    private func useDefaultsAndFinish() {
        SeedLoader.seedFullDefaultsIfEmpty(context)
        // Plan + groceries with deterministic seed.
        Task {
            await ReminderScheduler.shared.requestAuthorization()
            let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
            guard let profile = profiles.first,
                  let targets = profile.targets,
                  let prefs   = profile.preferences,
                  let workout = profile.workout else { onComplete(); return }
            let templates = (try? context.fetch(FetchDescriptor<MealTemplate>())) ?? []
            let inventory = (try? context.fetch(FetchDescriptor<InventoryItem>())) ?? []
            SeedLoader.resetForReplan(context)
            let result = app.planner.plan(MealPlanner.Inputs(
                profile: profile, targets: targets, preferences: prefs,
                workout: workout, allTemplates: templates,
                inventory: inventory, startDate: Date()
            ))
            context.insert(result.weekPlan)
            for item in app.grocery.build(from: result.weekPlan, currentInventory: inventory).items {
                context.insert(item)
            }
            let preps = app.prep.schedule(plan: result.weekPlan)
            context.insert(preps.sunday)
            context.insert(preps.wednesday)
            try? context.save()
            await ReminderScheduler.shared.schedulePrepReminders(preps)
            onComplete()
        }
    }

    private func runCustomize() async {
        running = true
        errorMessage = nil
        await ReminderScheduler.shared.requestAuthorization()
        let customizer = OnboardingCustomizer(ai: app.ai,
                                              planner: app.planner,
                                              grocery: app.grocery,
                                              prepScheduler: app.prep)
        do {
            try await customizer.customize(from: state, in: context) { p in
                stage = p.stage
                stageDetail = p.detail
            }
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
            running = false
        }
    }

    // MARK: - Field helpers

    private func doubleRow(_ label: String, _ value: Binding<Double>,
                           range: ClosedRange<Double>, step: Double,
                           suffix: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", value: value, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(maxWidth: 80)
            Text(suffix).foregroundStyle(.secondary).frame(width: 36, alignment: .leading)
            Stepper("", value: value, in: range, step: step).labelsHidden()
        }
    }

    private func csvField(_ label: String, _ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField(label, text: binding)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack { Text(k).foregroundStyle(.secondary); Spacer(); Text(v) }
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
