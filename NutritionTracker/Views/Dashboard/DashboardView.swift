import SwiftUI
import SwiftData

public struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.app) private var app
    @Query private var profiles: [UserProfile]
    @StateObject private var vm = DashboardViewModel()

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                macrosCard
                nextMealCard
                prepCard
                groceryCard
            }
            .padding()
        }
        .navigationTitle("Today")
        .background(Color(.systemBackground))
        .onAppear { vm.refresh(context: context, selector: app.cookSelector, inventoryMgr: app.inventory) }
    }

    // MARK: -

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date().fullDayLabel)
                .font(.title2.bold())
            if let p = profiles.first {
                Text("Goal: \(p.workout?.goal.rawValue.capitalized ?? "—") · BMR \(Int(p.bmr)) kcal")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var macrosCard: some View {
        SectionCard(title: "Remaining today") {
            if let t = profiles.first?.targets {
                MacroBars(totals: vm.totals, targets: t)
            } else {
                Text("Set your targets to see progress.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var nextMealCard: some View {
        SectionCard(title: "What to cook now") {
            if let meal = vm.nextMeal, let template = meal.template {
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.name).font(.headline)
                    Text(meal.mealType.displayName + " · " + Fmt.kcal(meal.nutrition.calories))
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    NavigationLink("Open recipe") {
                        CookTodayView()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("No remaining meals scheduled for today.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var prepCard: some View {
        SectionCard(title: "Next meal prep") {
            if let prep = vm.nextPrep {
                Text(prep.date.fullDayLabel).font(.headline)
                Text("\(prep.containers.count) container(s) · covers through \(prep.coversToDate.shortDayLabel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Generate a weekly plan to see prep.").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var groceryCard: some View {
        SectionCard(title: "Grocery alerts") {
            if vm.expiring.isEmpty {
                Text("Nothing expiring in the next 48 hours.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vm.expiring, id: \.persistentModelID) { item in
                    HStack {
                        Text(item.food?.name ?? "—")
                        Spacer()
                        Text("expires \(item.expirationDate?.shortDayLabel ?? "")")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}
