import SwiftUI

/// Экран ожидания попарного режима — передай телефон следующей паре
struct PairsWaitingView: View {
    @ObservedObject var viewModel: PairsGameViewModel
    var onHome: () -> Void
    @State private var showCountdown = false

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                // Прогресс
                if let round = viewModel.currentRound {
                    VStack(spacing: 4) {
                        Text("Раунд \(viewModel.currentRoundIndex + 1) из \(viewModel.schedule.totalRounds)")
                            .font(.hatCaption)
                            .foregroundStyle(Color.hatTextSecondary)
                            .tracking(2)

                        Text("Круг \(round.circle)")
                            .font(.hatCaption)
                            .foregroundStyle(Color.hatTextSecondary)
                    }
                    .padding(.top, 24)
                }

                Spacer()

                // Пара: объясняющий -> угадывающий
                if let round = viewModel.currentRound {
                    VStack(spacing: 20) {
                        HStack(spacing: 24) {
                            playerAvatar(round.explainer)

                            Image(systemName: "arrow.right")
                                .font(.hatH2)
                                .foregroundStyle(Color.hatGold)

                            playerAvatar(round.guesser)
                        }

                        Text("\(round.explainer.name) объясняет")
                            .font(.hatH1)
                            .foregroundStyle(Color.hatTextPrimary)
                            .multilineTextAlignment(.center)

                        Text("\(round.guesser.name) угадывает")
                            .font(.hatBody)
                            .foregroundStyle(Color.hatTextSecondary)
                    }
                }

                Spacer()

                // Мини-таблица лидеров (топ-3)
                leaderboardCard
                    .padding(.horizontal, 20)

                Spacer()

                // Кнопка старта
                HatPrimaryButton(title: "Поехали!") {
                    HapticService.light()
                    showCountdown = true
                }
                .padding(.horizontal, 20)

                // Завершить игру досрочно → финальный экран
                Button {
                    viewModel.endGameEarly()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "flag.checkered")
                        Text("Завершить игру")
                    }
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
                }
                .padding(.bottom, 32)
            }

            if showCountdown {
                CountdownOverlay {
                    showCountdown = false
                    viewModel.startRound()
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Аватар игрока

    private func playerAvatar(_ player: Player) -> some View {
        VStack(spacing: 8) {
            PlayerAvatarView(player: player, size: 64, color: Color.hatGold)
            Text(player.name)
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextPrimary)
                .lineLimit(1)
        }
    }

    // MARK: - Мини-таблица лидеров

    private var leaderboardCard: some View {
        VStack(spacing: 8) {
            let top = Array(viewModel.standings.prefix(3))
            ForEach(Array(top.enumerated()), id: \.element.player.id) { index, entry in
                HStack {
                    medalBadge(for: index)
                        .frame(width: 30)

                    if let emoji = entry.player.avatarEmoji {
                        Text(emoji)
                            .font(.system(size: 18))
                    }

                    Text(entry.player.name)
                        .font(.hatBody)
                        .foregroundStyle(Color.hatTextPrimary)

                    Spacer()

                    Text("\(entry.score)")
                        .font(.hatH2)
                        .foregroundStyle(Color.hatGold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.hatCard)
        )
    }

    @ViewBuilder
    private func medalBadge(for index: Int) -> some View {
        ZStack {
            Circle()
                .fill(medalColor(for: index))
                .frame(width: 28, height: 28)
            Text("\(index + 1)")
                .font(.hatCaption)
                .foregroundStyle(.white)
                .fontWeight(.bold)
        }
    }

    private func medalColor(for index: Int) -> Color {
        switch index {
        case 0: return Color.hatGold
        case 1: return Color(hex: 0xC0C0C0)
        case 2: return Color(hex: 0xCD7F32)
        default: return Color.hatSurface
        }
    }
}
