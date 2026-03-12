import SwiftUI

/// Экран окончания хода командного режима — результаты с коррекцией
struct TeamsRoundEndView: View {
    @ObservedObject var viewModel: TeamsGameViewModel
    var onHome: () -> Void
    @State private var entries: [RoundWordEntry] = []
    @State private var displayedScore: Int = 0

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                // Заголовок
                VStack(spacing: 8) {
                    if let team = viewModel.currentTeam {
                        Text("Ход команды \(team.name) завершён")
                            .font(.hatH1)
                            .foregroundStyle(Color.hatTextPrimary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Ход завершён")
                            .font(.hatH1)
                            .foregroundStyle(Color.hatTextPrimary)
                    }

                    Text("\(displayedScore)")
                        .font(.hatDisplay)
                        .foregroundStyle(Color.hatGold)
                        .contentTransition(.numericText())
                        .animation(.easeOut, value: displayedScore)

                    Text("угадано слов")
                        .font(.hatBody)
                        .foregroundStyle(Color.hatTextSecondary)
                }
                .padding(.top, 24)

                // Список слов
                ScrollView {
                    PostRoundWordListView(entries: $entries) { id in
                        if let idx = viewModel.turnResults.firstIndex(where: { $0.id == id }) {
                            viewModel.toggleResult(at: idx)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Подсказка
                Text("Нажми на слово, чтобы исправить")
                    .font(.hatCaption)
                    .foregroundStyle(Color(hex: 0x4A3A80))

                // Кнопка продолжения
                HatPrimaryButton(title: "Продолжить") {
                    HapticService.light()
                    viewModel.confirmRound()
                }
                .padding(.horizontal, 20)

                // На главную
                Button {
                    onHome()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "house")
                        Text("На главную")
                    }
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            entries = viewModel.turnResults.map {
                RoundWordEntry(id: $0.id, text: $0.text, isGuessed: $0.guessed)
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
