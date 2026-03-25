import SwiftUI

struct FreeForAllFinalView: View {
    @ObservedObject var viewModel: FreeForAllGameViewModel
    var onPlayAgain: () -> Void
    var onHome: () -> Void

    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Заголовок
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(Color.hatGold)

                    Text("Игра завершена!")
                        .font(.hatH1)
                        .foregroundStyle(Color.hatTextPrimary)
                }
                .padding(.bottom, 32)

                // Победитель
                if let winner = viewModel.standings.first {
                    winnerCard(winner)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }

                // Полный рейтинг
                VStack(alignment: .leading, spacing: 8) {
                    Text("ИТОГОВЫЙ РЕЙТИНГ")
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                        .tracking(2)
                        .padding(.horizontal, 20)

                    leaderboard
                        .padding(.horizontal, 20)
                }

                Spacer()

                // Кнопки
                VStack(spacing: 12) {
                    HatPrimaryButton(title: "Ещё раз!", action: onPlayAgain)

                    Button(action: onHome) {
                        Text("В меню")
                            .font(.hatBody)
                            .foregroundStyle(Color.hatTextSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(duration: 0.6)) { showConfetti = true }
        }
    }

    // MARK: - Winner card

    private func winnerCard(_ entry: (player: Player, score: Int)) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.hatGold)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.player.name)
                    .font(.hatH2)
                    .foregroundStyle(Color.hatGold)
                Text("\(entry.score) \(pointsEnding(entry.score))")
                    .font(.hatBody)
                    .foregroundStyle(Color.hatTextSecondary)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.hatCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.hatGold, lineWidth: 2)
                )
        )
    }

    // MARK: - Leaderboard

    private var leaderboard: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.standings.enumerated()), id: \.element.player.id) { idx, entry in
                HStack(spacing: 14) {
                    // Место
                    ZStack {
                        Circle()
                            .fill(medalColor(idx))
                            .frame(width: 32, height: 32)
                        Text("\(idx + 1)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(idx < 3 ? Color.hatBackground : Color.hatTextPrimary)
                    }

                    Text(entry.player.name)
                        .font(.hatBody)
                        .foregroundStyle(Color.hatTextPrimary)

                    Spacer()

                    Text("\(entry.score)")
                        .font(.hatButton)
                        .foregroundStyle(Color.hatGold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if idx < viewModel.standings.count - 1 {
                    Divider().background(Color.hatSurface)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.hatCard)
        )
    }

    // MARK: - Helpers

    private func medalColor(_ idx: Int) -> Color {
        switch idx {
        case 0: return Color.hatGold
        case 1: return Color(hex: 0xC0C0C0)
        case 2: return Color(hex: 0xCD7F32)
        default: return Color.hatSurface
        }
    }

    private func pointsEnding(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod100 >= 11 && mod100 <= 14 { return "очков" }
        switch mod10 {
        case 1: return "очко"
        case 2, 3, 4: return "очка"
        default: return "очков"
        }
    }
}
