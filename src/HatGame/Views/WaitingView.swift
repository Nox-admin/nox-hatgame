import SwiftUI

/// Экран ожидания перед ходом (Screen 07)
struct WaitingView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showCountdown = false

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                // Round label
                Text("РАУНД \(viewModel.currentRound)")
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
                    .tracking(3)
                    .padding(.top, 24)

                // Scores card
                scoresCard
                    .padding(.horizontal, 20)

                Spacer()

                // Next turn info
                VStack(spacing: 16) {
                    Text("СЛЕДУЮЩИЙ ХОД")
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                        .tracking(2)

                    // Large avatar
                    PlayerAvatarView(
                        player: viewModel.currentExplainerPlayer ?? Player(name: viewModel.currentExplainerName),
                        size: 80,
                        color: Color.hatGold
                    )
                    .shadow(color: Color.hatGold.opacity(0.4), radius: 16, y: 8)

                    Text(viewModel.currentExplainerName)
                        .font(.hatH1)
                        .foregroundStyle(Color.hatTextPrimary)

                    Text("объясняет слова")
                        .font(.hatBody)
                        .foregroundStyle(Color.hatTextSecondary)
                }

                Spacer()

                // Start button
                HatPrimaryButton(title: "Поехали!") {
                    showCountdown = true
                }
                .padding(.horizontal, 20)

                // BUG-016: кнопка выхода на главный экран
                Button {
                    viewModel.goHome()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "house")
                        Text("На главную")
                    }
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
                }
                .padding(.bottom, 32)
            }
            // Countdown overlay
            if showCountdown {
                CountdownOverlay {
                    showCountdown = false
                    viewModel.startTurn()
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Scores Card

    private var scoresCard: some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.standings.enumerated()), id: \.element.id) { index, team in
                HStack {
                    medalBadge(for: index)
                        .frame(width: 30)

                    Text(team.name)
                        .font(.hatBody)
                        .foregroundStyle(Color.hatTextPrimary)

                    Spacer()

                    Text("\(team.score)")
                        .font(.hatH2)
                        .foregroundStyle(Color.hatGold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.hatCard)
        )
    }

    // MARK: - Helpers

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

#Preview {
    WaitingView(viewModel: GameViewModel())
}
