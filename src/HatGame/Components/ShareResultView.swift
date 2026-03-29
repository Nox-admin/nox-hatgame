import SwiftUI

/// Карточка результатов для шаринга — рендерится в UIImage через ImageRenderer.
/// Показывается через ShareSheet (UIActivityViewController).
struct ShareResultCardView: View {
    let result: GameResult

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("🎩")
                    .font(.system(size: 44))
                Text("Шляпа")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.hatGold)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()
                .background(Color.hatGold.opacity(0.3))

            // Standings
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                    HStack(spacing: 12) {
                        // Место
                        ZStack {
                            Circle()
                                .fill(medalColor(idx))
                                .frame(width: 30, height: 30)
                            Text("\(idx + 1)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(idx < 3 ? Color.hatBackground : Color.hatTextPrimary)
                        }

                        if let emoji = row.avatar {
                            Text(emoji).font(.system(size: 18))
                        }

                        Text(row.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(idx == 0 ? Color.hatGold : Color.hatTextPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text("\(row.score)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.hatGold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                    if idx < rows.count - 1 {
                        Divider().background(Color.hatSurface).padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 8)

            Divider()
                .background(Color.hatGold.opacity(0.3))

            // Footer
            Text("hatgame.app")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.hatTextSecondary)
                .padding(.vertical, 12)
        }
        .frame(width: 400)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: 0x2D1B69))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.hatGold.opacity(0.4), lineWidth: 1.5)
        )
    }

    // MARK: - Helpers

    private struct Row {
        let name: String
        let score: Int
        let avatar: String?
    }

    private var rows: [Row] {
        switch result {
        case .players(let standings, _):
            return standings.map { Row(name: $0.player.name, score: $0.score, avatar: $0.player.avatarEmoji) }
        case .teams(let standings):
            return standings.map { Row(name: $0.name, score: $0.score, avatar: nil) }
        }
    }

    private func medalColor(_ idx: Int) -> Color {
        switch idx {
        case 0: return Color.hatGold
        case 1: return Color(hex: 0xC0C0C0)
        case 2: return Color(hex: 0xCD7F32)
        default: return Color.hatSurface
        }
    }
}

// MARK: - Share button

/// Кнопка «Поделиться» — рендерит карточку и открывает iOS Share Sheet.
struct ShareResultButton: View {
    let result: GameResult
    @State private var isSharing = false
    @State private var renderedImage: UIImage? = nil

    var body: some View {
        Button {
            renderAndShare()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                Text("Поделиться")
                    .font(.hatButton)
            }
            .foregroundStyle(Color.hatGold)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.hatGold.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.hatGold.opacity(0.35), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isSharing) {
            if let img = renderedImage {
                ShareSheet(items: [img])
                    .ignoresSafeArea()
            }
        }
    }

    @MainActor
    private func renderAndShare() {
        let card = ShareResultCardView(result: result)
            .environment(\.colorScheme, .dark)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0 // @3x для чёткости

        if let img = renderer.uiImage {
            renderedImage = img
            isSharing = true
        }
    }
}

// MARK: - UIActivityViewController wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let players = (1...4).map { Player(name: "Игрок \($0)", emoji: Player.emojiPalette[$0 - 1]) }
    let standings = players.enumerated().map { (player: $1, score: 12 - $0 * 3) }
    return ZStack {
        Color.hatBackground.ignoresSafeArea()
        VStack(spacing: 20) {
            ShareResultCardView(result: .players(standings: standings, mode: .freeForAll))
            ShareResultButton(result: .players(standings: standings, mode: .freeForAll))
        }
        .padding()
    }
}
