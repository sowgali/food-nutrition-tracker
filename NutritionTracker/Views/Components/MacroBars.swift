import SwiftUI

/// Reusable progress strip showing calories/protein/fiber/sugar against targets.
public struct MacroBars: View {
    public var totals: NutritionFacts
    public var targets: NutritionTargets

    public init(totals: NutritionFacts, targets: NutritionTargets) {
        self.totals = totals
        self.targets = targets
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            row("Calories",
                value: totals.calories, target: targets.calorieTarget,
                unit: "kcal", overOK: false)
            row("Protein",
                value: totals.protein, target: targets.proteinMin,
                unit: "g", overOK: true)
            row("Fiber",
                value: totals.fiber, target: targets.fiberMin,
                unit: "g", overOK: true)
            row("Sugar",
                value: totals.sugar, target: targets.sugarMax,
                unit: "g", overOK: false, capLine: true)
        }
        .font(.subheadline)
    }

    private func row(_ name: String, value: Double, target: Double, unit: String,
                     overOK: Bool, capLine: Bool = false) -> some View {
        let fraction = target == 0 ? 0 : min(value / target, 1.5)
        let over = value > target
        let tint: Color = capLine
            ? (over ? .red : .green)
            : (over ? (overOK ? .green : .orange) : .accentColor)
        return HStack(spacing: 12) {
            Text(name)
                .frame(width: 70, alignment: .leading)
                .foregroundStyle(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule()
                        .fill(tint)
                        .frame(width: max(4, geo.size.width * min(fraction, 1)))
                }
            }
            .frame(height: 8)
            Text("\(Int(value.rounded()))/\(Int(target))\(unit)")
                .monospacedDigit()
                .foregroundStyle(.primary)
                .frame(width: 110, alignment: .trailing)
        }
    }
}
