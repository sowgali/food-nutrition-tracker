import SwiftUI
import SwiftData

public struct PreferencesView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.app) private var app
    @Query private var profiles: [UserProfile]
    @State private var freeText: String = ""
    @State private var parseError: String?

    public init() {}

    public var body: some View {
        Form {
            if let prefs = profiles.first?.preferences {
                Section("Proteins") {
                    listEditor("Preferred proteins", values: bind(\.preferredProteins, on: prefs))
                }
                Section("Avoided") {
                    listEditor("Avoided foods", values: bind(\.avoidedFoods, on: prefs))
                }
                Section("Dairy & fruit") {
                    listEditor("Dairy preferences", values: bind(\.dairyPreferences, on: prefs))
                    listEditor("Fruits", values: bind(\.fruits, on: prefs))
                }
                Section("Legumes & supplements") {
                    listEditor("Legumes", values: bind(\.legumes, on: prefs))
                    listEditor("Supplements", values: bind(\.supplements, on: prefs))
                }
                Section("Limits") {
                    Stepper("Red meat max/week: \(prefs.redMeatMaxPerWeek)",
                            value: bind(\.redMeatMaxPerWeek, on: prefs), in: 0...7)
                    Stepper("Eggs/day max: \(prefs.maxEggsPerDay)",
                            value: bind(\.maxEggsPerDay, on: prefs), in: 0...6)
                    Toggle("Allow egg whites", isOn: bind(\.allowEggWhites, on: prefs))
                    Picker("Meal volume", selection: bindVolume(prefs)) {
                        ForEach(MealVolume.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    Picker("Budget", selection: bindBudget(prefs)) {
                        ForEach(Budget.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    Picker("Cooking effort", selection: bindEffort(prefs)) {
                        ForEach(CookingEffort.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }
                }
                Section("Describe your diet (AI-assisted)") {
                    TextEditor(text: $freeText)
                        .frame(minHeight: 100)
                    Button("Parse with AI") {
                        Task { await parseWithAI(into: prefs) }
                    }
                    if let parseError {
                        Text(parseError).foregroundStyle(.red).font(.footnote)
                    }
                    Text("AI suggestions are merged only after structured validation. Edit anything before saving.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No preferences yet.")
            }
        }
        .navigationTitle("Preferences")
    }

    private func parseWithAI(into prefs: FoodPreferences) async {
        do {
            let result = try await app.ai.parsePreferences(freeText: freeText)
            // Validation: merge non-empty arrays only, dedupe.
            prefs.preferredProteins = mergeDedup(prefs.preferredProteins, result.preferredProteins)
            prefs.avoidedFoods      = mergeDedup(prefs.avoidedFoods,      result.avoidedFoods)
            prefs.legumes           = mergeDedup(prefs.legumes,           result.legumes)
            prefs.fruits            = mergeDedup(prefs.fruits,            result.fruits)
            try? context.save()
            parseError = nil
        } catch {
            parseError = "AI parse failed: \(error.localizedDescription)"
        }
    }

    private func mergeDedup(_ a: [String], _ b: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for v in (a + b) where !v.isEmpty {
            if seen.insert(v.lowercased()).inserted { out.append(v) }
        }
        return out
    }

    // MARK: - Bindings

    private func bind<Root: AnyObject, Value>(_ key: ReferenceWritableKeyPath<Root, Value>, on root: Root) -> Binding<Value> {
        Binding(get: { root[keyPath: key] },
                set: { root[keyPath: key] = $0; try? context.save() })
    }

    private func bindVolume(_ p: FoodPreferences) -> Binding<MealVolume> {
        Binding(get: { p.mealVolume }, set: { p.mealVolume = $0; try? context.save() })
    }
    private func bindBudget(_ p: FoodPreferences) -> Binding<Budget> {
        Binding(get: { p.budget }, set: { p.budget = $0; try? context.save() })
    }
    private func bindEffort(_ p: FoodPreferences) -> Binding<CookingEffort> {
        Binding(get: { p.cookingEffort }, set: { p.cookingEffort = $0; try? context.save() })
    }

    @ViewBuilder
    private func listEditor(_ label: String, values: Binding<[String]>) -> some View {
        DisclosureGroup(label) {
            ForEach(values.wrappedValue.indices, id: \.self) { i in
                HStack {
                    TextField(label, text: Binding(
                        get: { values.wrappedValue[i] },
                        set: { v in var arr = values.wrappedValue; arr[i] = v; values.wrappedValue = arr }
                    ))
                    Button(role: .destructive) {
                        var arr = values.wrappedValue
                        arr.remove(at: i)
                        values.wrappedValue = arr
                    } label: { Image(systemName: "minus.circle") }
                    .buttonStyle(.plain)
                }
            }
            Button {
                values.wrappedValue.append("")
            } label: {
                Label("Add", systemImage: "plus.circle")
            }
        }
    }
}
