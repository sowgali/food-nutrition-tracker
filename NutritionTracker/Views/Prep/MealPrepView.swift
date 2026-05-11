import SwiftUI
import SwiftData

public struct MealPrepView: View {
    @Query(sort: \PrepSession.date) private var preps: [PrepSession]

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if preps.isEmpty {
                    SectionCard {
                        Text("No prep sessions yet. Generate a plan to schedule Sunday & Wednesday prep.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(preps, id: \.persistentModelID) { prep in
                        SectionCard(title: "\(prep.date.fullDayLabel) · prep",
                                    footer: "Covers \(prep.coversFromDate.shortDayLabel) → \(prep.coversToDate.shortDayLabel)") {
                            if prep.containers.isEmpty {
                                Text("Nothing to prep.").foregroundStyle(.secondary)
                            } else {
                                ForEach(prep.containers, id: \.persistentModelID) { container in
                                    containerRow(container)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Meal prep")
    }

    @ViewBuilder
    private func containerRow(_ c: PrepContainer) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(c.template?.name ?? "—").font(.headline)
                Spacer()
                Text("×\(Int(c.portions))")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.thinMaterial))
                    .font(.caption.bold())
            }
            if !c.instructionsOverride.isEmpty {
                ForEach(Array(c.instructionsOverride.enumerated()), id: \.offset) { _, step in
                    Text("• \(step)").font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
