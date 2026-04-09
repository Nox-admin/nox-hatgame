import SwiftUI

struct FreeForAllWaitingView: View {
    @ObservedObject var viewModel: FreeForAllGameViewModel
    var onHome: () -> Void
    @State private var showCountdown = false

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Заголовок
                VStack(spacing: 4) {
                    Text(viewModel.roundLabel.uppercased())
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                        .tracking(3)
                    Text(L10n.Waiting.wordsInHat(viewModel.wordsRemaining))
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatGold)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)

                // Объяснитель
                if let explainer = viewModel.currentExplainer {
                    VStack(spacing: 20) {
                        // Аватар
                        PlayerAvatarView(player: explainer, size: 100, color: Color.hatGold)
                            .shadow(color: Color.hatGold.opacity(0.4), radius: 16, y: 8)

                        VStack(spacing: 6) {
                            Text(explainer.name)
                                .font(.hatH1)
                                .foregroundStyle(Color.hatTextPrimary)
                            Text(L10n.Waiting.explainsAll)
                                .font(.hatBody)
                                .foregroundStyle(Color.hatTextSecondary)
                        }
                    }
                    .padding(.bottom, 36)
                }

                Spacer()

                Spacer()

                // Кнопки
                VStack(spacing: 12) {
                    HatPrimaryButton(title: L10n.Waiting.go) {
                        HapticService.light()
                        showCountdown = true
                    }

                    Button {
                        viewModel.endGameEarly()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "flag.checkered")
                                .font(.system(size: 14))
                            Text(L10n.Waiting.endGame)
                        }
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
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
}
