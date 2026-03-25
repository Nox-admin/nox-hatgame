import SwiftUI

/// Экран ожидания попарного режима — передай телефон следующей паре
struct PairsWaitingView: View {
    @ObservedObject var viewModel: PairsGameViewModel
    var onHome: () -> Void

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
                            playerAvatar(name: round.explainer.name)

                            Image(systemName: "arrow.right")
                                .font(.hatH2)
                                .foregroundStyle(Color.hatGold)

                            playerAvatar(name: round.guesser.name)
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
                    viewModel.startRound()
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
        }
        .navigationBarHidden(true)
    }

    // MARK: - Аватар игрока

    private func playerAvatar(name: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.hatGold, Color.hatWarm],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Text(String(name.prefix(1)).uppercased())
                    .font(.hatH1)
                    .foregroundStyle(.white)
            }

            Text(name)
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
