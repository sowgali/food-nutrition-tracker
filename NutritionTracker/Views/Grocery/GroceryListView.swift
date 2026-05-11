import SwiftUI
import SwiftData

public struct GroceryListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.app) private var app
    @Query(sort: \GroceryItem.weekStart, order: .reverse) private var items: [GroceryItem]

    public init() {}

    public var body: some View {
        List {
            if items.isEmpty {
                Section { Text("No grocery items yet. Generate a plan first.").foregroundStyle(.secondary) }
            } else {
                Section("To buy") {
                    ForEach(items.filter { !$0.bought }, id: \.persistentModelID) { item in
                        row(item)
                    }
                }
                Section("Already bought") {
                    ForEach(items.filter { $0.bought }, id: \.persistentModelID) { item in
                        row(item)
                    }
                }
            }
        }
        .navigationTitle("Grocery list")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear bought") { clearBought() }
                    .disabled(items.allSatisfy { !$0.bought })
            }
        }
    }

    @ViewBuilder
    private func row(_ item: GroceryItem) -> some View {
        Button {
            let wasBought = item.bought
            item.bought.toggle()
            if !wasBought {
                // Newly bought → add to inventory automatically.
                app.inventory.add(item, into: context)
            }
            try? context.save()
        } label: {
            HStack {
                Image(systemName: item.bought ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.bought ? .green : .secondary)
                VStack(alignment: .leading) {
                    Text(item.food?.name ?? "—")
                        .strikethrough(item.bought)
                    Text(Fmt.quantity(item.quantity, unit: item.unit))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private func clearBought() {
        for item in items where item.bought {
            context.delete(item)
        }
        try? context.save()
    }
}
