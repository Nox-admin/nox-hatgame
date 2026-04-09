import SwiftUI

/// BUG-042: Экран "Круг завершён" в попарном режиме
struct PairsCircleEndView: View {
    @ObservedObject var viewModel: PairsGameViewModel

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Иконка и заголовок
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.hatGold.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: "arrow.circlepath")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(Color.hatGold)
                    }

                    Text(L10n.Round.circleEnded)
                        .font(.hatH1)
                        .foregroundStyle(Color.hatTextPrimary)

                    Text(L10n.Waiting.allPairsDone)
                        .font(.hatBody)
                        .foregroundStyle(Color.hatTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)

                // Мини-рейтинг
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.Waiting.score.uppercased())
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                        .tracking(2)
                        .padding(.horizontal, 20)

                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.standings.enumerated()), id: \.element.player.id) { idx, entry in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(idx == 0 ? Color.hatGold : Color.hatSurface)
                                        .frame(width: 30, height: 30)
                                    Text("\(idx + 1)")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(idx == 0 ? Color.hatBackground : Color.hatTextPrimary)
                                }
                                Text(entry.player.name)
                                    .font(.hatBody)
                                    .foregroundStyle(idx == 0 ? Color.hatGold : Color.hatTextPrimary)
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
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.hatCard))
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)

                Spacer()

                // Кнопки
                VStack(spacing: 12) {
                    HatPrimaryButton(title: L10n.Final.playAgain2) {
                        viewModel.continueNextCircle()
                    }

                    Button {
                        viewModel.endGameEarly()
                    } label: {
                        Text(L10n.Waiting.endGame)
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
    }
}
