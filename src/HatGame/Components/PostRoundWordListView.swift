import SwiftUI

/// Состояние слова после раунда
enum WordRoundState {
    case guessed   // угадано
    case missed    // не угадано, вернётся в шляпу
    case burned    // "сожжено" — удалено из шляпы навсегда
}

/// A word entry in the post-round list (stable order)
struct RoundWordEntry: Identifiable {
    let id: UUID
    let text: String
    var isGuessed: Bool
    var isBurned: Bool = false

    var state: WordRoundState {
        if isBurned { return .burned }
        return isGuessed ? .guessed : .missed
    }
}

/// Shared post-round word list. Tap to toggle guessed/missed, long press to burn.
struct PostRoundWordListView: View {
    @Binding var entries: [RoundWordEntry]
    var onToggle: ((UUID) -> Void)? = nil
    var onBurn: ((UUID) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            ForEach(entries.indices, id: \.self) { idx in
                let entry = entries[idx]
                HStack(spacing: 14) {
                    // Иконка состояния
                    Button {
                        if entries[idx].isBurned { return }
                        entries[idx].isGuessed.toggle()
                        onToggle?(entries[idx].id)
                    } label: {
                        Image(systemName: iconName(for: entries[idx]))
                            .font(.system(size: 20))
                            .foregroundStyle(iconColor(for: entries[idx]))
                    }
                    .buttonStyle(.plain)

                    Text(entry.text)
                        .font(.hatBody)
                        .foregroundStyle(entries[idx].isBurned
                                         ? Color.hatTextSecondary
                                         : Color.hatTextPrimary)
                        .strikethrough(entries[idx].isBurned)

                    Spacer()

                    // Кнопка "сжечь" слово
                    Button {
                        entries[idx].isBurned.toggle()
                        if entries[idx].isBurned {
                            entries[idx].isGuessed = false
                        }
                        onBurn?(entries[idx].id)
                    } label: {
                        Image(systemName: entries[idx].isBurned ? "flame.fill" : "flame")
                            .font(.system(size: 16))
                            .foregroundStyle(entries[idx].isBurned ? Color.hatWarm : Color.hatTextSecondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .animation(.easeInOut(duration: 0.15), value: entries[idx].isGuessed)
                .animation(.easeInOut(duration: 0.15), value: entries[idx].isBurned)

                if idx < entries.count - 1 {
                    Divider().background(Color.hatSurface)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.hatCard))
    }

    private func iconName(for entry: RoundWordEntry) -> String {
        if entry.isBurned { return "trash.circle.fill" }
        return entry.isGuessed ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private func iconColor(for entry: RoundWordEntry) -> Color {
        if entry.isBurned { return .hatTextSecondary }
        return entry.isGuessed ? .hatSuccess : .hatDanger
    }
}
