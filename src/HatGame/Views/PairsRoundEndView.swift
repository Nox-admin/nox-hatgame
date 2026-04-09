import SwiftUI

/// Экран окончания раунда попарного режима — результаты с коррекцией
struct PairsRoundEndView: View {
    @ObservedObject var viewModel: PairsGameViewModel
    @State private var entries: [RoundWordEntry] = []
    @State private var displayedScore: Int = 0

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                // Заголовок
                VStack(spacing: 8) {
                    Text(L10n.Round.ended)
                        .font(.hatH1)
                        .foregroundStyle(Color.hatTextPrimary)

                    Text("\(displayedScore)")
                        .font(.hatDisplay)
                        .foregroundStyle(Color.hatGold)
                        .contentTransition(.numericText())
                        .animation(.easeOut, value: displayedScore)

                    if let round = viewModel.currentRound {
                        HStack(spacing: 0) {
                            Text("\(round.explainer.name)")
                                .font(.hatBody)
                                .foregroundStyle(Color.hatTextPrimary)

                            Image(systemName: "arrow.right")
                                .font(.hatCaption)
                                .foregroundStyle(Color.hatGold)
                                .padding(.horizontal, 6)

                            Text("\(round.guesser.name)")
                                .font(.hatBody)
                                .foregroundStyle(Color.hatTextPrimary)
                        }
                    }
                }
                .padding(.top, 24)

                // Список слов
                ScrollView {
                    PostRoundWordListView(entries: $entries, onToggle: { id in
                        viewModel.toggleTurnResult(wordId: id)
                    }, onBurn: { id in
                        viewModel.burnWord(wordId: id)
                    })
                    .padding(.horizontal, 20)
                }

                // Подсказка
                Text(L10n.Turn.tapToCorrect)
                    .font(.hatCaption)
                    .foregroundStyle(Color(hex: 0x4A3A80))

                // Кнопка продолжения
                HatPrimaryButton(
                    title: (viewModel.wordDeck.isEmpty || viewModel.isLastRound)
                        ? L10n.Final.results
                        : L10n.Nav.continue_
                ) {
                    HapticService.light()
                    viewModel.confirmRound()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            entries = viewModel.currentTurnGuessed.map {
                RoundWordEntry(id: $0.id, text: $0.text, isGuessed: true)
            } + viewModel.currentTurnSkipped.map {
                RoundWordEntry(id: $0.id, text: $0.text, isGuessed: false)
            }
            animateScore(target: viewModel.turnGuessedCount)
        }
    }

    private func animateScore(target: Int) {
        guard target > 0 else { return }
        let step = max(1, target / 10)
        var current = 0
        Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { timer in
            current = min(current + step, target)
            displayedScore = current
            if current >= target { timer.invalidate() }
        }
    }
}
