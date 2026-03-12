import SwiftUI

/// A word entry in the post-round list (stable order)
struct RoundWordEntry: Identifiable {
    let id: UUID
    let text: String
    var isGuessed: Bool
}

/// Shared post-round word list. Words keep their original order when toggled (no jumping).
struct PostRoundWordListView: View {
    @Binding var entries: [RoundWordEntry]
    var onToggle: ((UUID) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            ForEach(entries.indices, id: \.self) { idx in
                let entry = entries[idx]
                Button {
                    entries[idx].isGuessed.toggle()
                    onToggle?(entries[idx].id)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: entries[idx].isGuessed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(entries[idx].isGuessed ? Color.hatSuccess : Color.hatDanger)
                        Text(entry.text)
                            .font(.hatBody)
                            .foregroundStyle(Color.hatTextPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: entries[idx].isGuessed)

                if idx < entries.count - 1 {
                    Divider().background(Color.hatSurface)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.hatCard))
    }
}
