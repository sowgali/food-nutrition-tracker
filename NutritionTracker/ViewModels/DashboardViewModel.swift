import Foundation
import SwiftData

@MainActor
public final class DashboardViewModel: ObservableObject {

    @Published public var today: DayPlan?
    @Published public var nextMeal: Meal?
    @Published public var totals: NutritionFacts = .zero
    @Published public var nextPrep: PrepSession?
    @Published public var expiring: [InventoryItem] = []

    public init() {}

    public func refresh(context: ModelContext, selector: CookTodaySelector, inventoryMgr: InventoryManager) {
        let today = Date.today()
        let allDays = (try? context.fetch(FetchDescriptor<DayPlan>())) ?? []
        let day = allDays.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        self.today = day
        self.totals = day?.nutrition ?? .zero
        self.nextMeal = day.flatMap { selector.nextMeal(in: $0) }

        let preps = (try? context.fetch(FetchDescriptor<PrepSession>())) ?? []
        self.nextPrep = preps.filter { $0.date >= today }.sorted { $0.date < $1.date }.first

        let inv = (try? context.fetch(FetchDescriptor<InventoryItem>())) ?? []
        self.expiring = inventoryMgr.expiring(within: 2, in: inv)
    }
}
