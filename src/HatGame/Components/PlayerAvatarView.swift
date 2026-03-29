import SwiftUI

/// Аватар игрока: эмодзи (если задан) или цветной круг с первой буквой имени.
struct PlayerAvatarView: View {
    let player: Player
    var size: CGFloat = 44
    var color: Color = .hatGold

    var body: some View {
        ZStack {
            Circle()
                .fill(player.avatarEmoji != nil ? Color.hatSurface : color)
                .frame(width: size, height: size)

            if let emoji = player.avatarEmoji {
                Text(emoji)
                    .font(.system(size: size * 0.55))
            } else {
                Text(String(player.name.first ?? "?").uppercased())
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}

/// Пикер эмодзи — небольшая сетка ~20 вариантов.
struct EmojiPickerView: View {
    let selected: String
    var onSelect: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Выбери аватар")
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
                .tracking(1)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Player.emojiPalette, id: \.self) { emoji in
                    Button {
                        onSelect(emoji)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 26))
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selected == emoji
                                          ? Color.hatGold.opacity(0.22)
                                          : Color.hatSurface.opacity(0.5))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(
                                        selected == emoji ? Color.hatGold : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.hatCard)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            PlayerAvatarView(player: Player(name: "Анна", emoji: "🦊"), size: 56)
            PlayerAvatarView(player: Player(name: "Борис", emoji: ""), size: 56, color: .hatWarm)
        }
        EmojiPickerView(selected: "🦊", onSelect: { _ in })
    }
    .padding()
    .background(Color.hatBackground)
}
