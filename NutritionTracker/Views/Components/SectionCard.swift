import SwiftUI

/// Card-style background used across screens. Keeps padding/corner consistent.
public struct SectionCard<Content: View>: View {
    let title: String?
    let footer: String?
    @ViewBuilder let content: () -> Content

    public init(title: String? = nil, footer: String? = nil,
                @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.headline)
            }
            content()
            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
