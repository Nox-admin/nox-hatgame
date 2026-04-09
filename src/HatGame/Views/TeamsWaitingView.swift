import SwiftUI

/// Экран ожидания командного режима — передай телефон объясняющему
struct TeamsWaitingView: View {
    @ObservedObject var viewModel: TeamsGameViewModel
    var onHome: () -> Void
    @State private var showCountdown = false

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                // Номер раунда
                Text(L10n.Round.label(viewModel.currentRound + 1).uppercased())
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
                    .tracking(3)
                    .padding(.top, 24)

                Spacer()

                // Кто объясняет
                VStack(spacing: 16) {
                    Text(L10n.Waiting.nextTurn)
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                        .tracking(2)

                    if let explainer = viewModel.currentExplainer {
                        PlayerAvatarView(player: explainer, size: 80, color: Color.hatGold)
                            .shadow(color: Color.hatGold.opacity(0.4), radius: 16, y: 8)

                        Text(explainer.name)
                            .font(.hatH1)
                            .foregroundStyle(Color.hatTextPrimary)
                    }

                    if let team = viewModel.currentTeam {
                        HStack(spacing: 4) {
                            Text(L10n.Waiting.explainsFor)
                                .font(.hatBody)
                                .foregroundStyle(Color.hatTextSecondary)
                            Text(team.name)
                                .font(.hatBody)
                                .foregroundStyle(Color.hatGold)
                        }
                    }
                }

                Spacer()

                // Кнопка старта
                HatPrimaryButton(title: L10n.Waiting.go) {
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
                        Text(L10n.Waiting.endGame)
                    }
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
                }
                .padding(.bottom, 32)
            }

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

    // MARK: - Таблица очков команд

    private var scoresCard: some View {
        VStack(spacing: 8) {
            let ranked = viewModel.standings
            ForEach(Array(ranked.enumerated()), id: \.element.id) { index, team in
                let isCurrent = team.id == viewModel.currentTeam?.id
                HStack {
                    rankCircle(index: index)
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
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.hatCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? Color.hatGold : Color.clear, lineWidth: 2)
                )
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.hatSurface.opacity(0.3))
        )
    }

    @ViewBuilder
    private func rankCircle(index: Int) -> some View {
        let color: Color = switch index {
        case 0: Color.hatGold
        case 1: Color(hex: 0xC0C0C0)
        case 2: Color(hex: 0xCD7F32)
        default: Color.hatSurface
        }
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
            Text("\(index + 1)")
                .font(.hatCaption)
                .foregroundStyle(.white)
                .fontWeight(.bold)
        }
    }
}
