import SwiftUI

/// Экран игрового процесса — объяснение слов
struct GameplayView: View {
    @ObservedObject var viewModel: GameViewModel
    /// Явная подписка на TimerService — иначе @Published изменения таймера не триггерят ре-рендер (BUG-001 fix)
    @ObservedObject private var timerService: TimerService

    @State private var wordCardAppeared = false
    @State private var wordId: UUID? = nil

    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        self._timerService = ObservedObject(wrappedValue: viewModel.engine.timerService)
    }

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Верхняя панель
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer()

                if viewModel.gameState == .roundEnd {
                    roundEndView
                } else if viewModel.isPaused {
                    pausedView
                } else {
                    // Карточка слова
                    wordCard
                        .padding(.horizontal, 24)
                }

                Spacer()

                // Таймер
                if viewModel.gameState == .playing {
                    timerSection(timerService: timerService)
                        .padding(.bottom, 16)
                }

                // Кнопки действий
                if viewModel.gameState == .playing && !viewModel.isPaused {
                    gameActionButtons
                        .padding(.bottom, 24)
                } else if viewModel.gameState == .roundEnd {
                    roundEndButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // BUG-014: первое слово не триггерит onChange — запускаем анимацию вручную при появлении экрана
            triggerCardAnimation(newId: viewModel.currentWord?.id)
        }
        .onChange(of: viewModel.currentWord?.id) { _, newId in
            triggerCardAnimation(newId: newId)
        }
    }

    // MARK: - Верхняя панель

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentTeam?.name ?? "Команда")
                    .font(.hatButton)
                    .foregroundStyle(Color.hatTextPrimary)
                if let explainer = viewModel.currentTeam?.currentExplainer {
                    Text("Объясняет: \(explainer.name)")
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                }
            }
            Spacer()
            Text("Осталось: \(viewModel.wordsRemaining) слов")
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
        }
    }

    // MARK: - Карточка слова

    private var wordCard: some View {
        VStack(spacing: 16) {
            if let word = viewModel.currentWord {
                Text(word.text)
                    .font(.hatDisplay)
                    .foregroundStyle(Color.hatTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.hatCard)
                            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                    )
                    .offset(y: wordCardAppeared ? 0 : 60)
                    .opacity(wordCardAppeared ? 1 : 0)
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: wordCardAppeared)
            } else {
                Text("Слова закончились!")
                    .font(.hatH2)
                    .foregroundStyle(Color.hatTextSecondary)
            }
        }
    }

    // MARK: - Секция таймера

    private func timerSection(timerService: TimerService) -> some View {
        let isWarning = timerService.timeRemaining <= 10

        return ZStack {
            // Круговой прогресс
            Circle()
                .stroke(Color.hatSurface, lineWidth: 6)
                .frame(width: 140, height: 140)

            Circle()
                .trim(from: 0, to: timerService.progress)
                .stroke(
                    isWarning ? Color.hatDanger : Color.hatGold,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerService.timeRemaining)

            // Число таймера
            Text("\(timerService.timeRemaining)")
                .font(.hatTimer)
                .foregroundStyle(isWarning ? Color.hatDanger : Color.hatGold)
                .contentTransition(.numericText())
                .scaleEffect(isWarning ? 1.05 : 1.0)
                .animation(
                    isWarning
                        ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                        : .default,
                    value: isWarning
                )
        }
    }

    // MARK: - Кнопки действий

    private var gameActionButtons: some View {
        HStack(spacing: 40) {
            if viewModel.settings.allowSkipping {
                VStack(spacing: 8) {
                    HatGameActionButton(icon: "✕", color: .hatDanger) {
                        viewModel.skipWord()
                    }
                    Text("Пропустить")
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                }
            }

            VStack(spacing: 8) {
                HatGameActionButton(icon: "✓", color: .hatSuccess) {
                    viewModel.guessWord()
                }
                Text("Угадали")
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
            }

            // Пауза
            VStack(spacing: 8) {
                Button {
                    viewModel.pauseGame()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.title3)
                        .foregroundStyle(Color.hatTextSecondary)
                        .frame(width: 44, height: 44)
                        .background(Color.hatSurface)
                        .clipShape(Circle())
                }
                Text("Пауза")
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
            }
        }
    }

    // MARK: - Пауза

    private var pausedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.hatGold)
            Text("Пауза")
                .font(.hatH1)
                .foregroundStyle(Color.hatTextPrimary)

            HatPrimaryButton(title: "Продолжить") {
                viewModel.resumeGame()
            }
            .padding(.horizontal, 40)

            // BUG-016: выход доступен из паузы
            Button {
                viewModel.goHome()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "house")
                    Text("Закончить игру")
                }
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
            }
        }
    }

    // MARK: - Экран завершения раунда

    private var roundEndView: some View {
        VStack(spacing: 20) {
            Image(systemName: "timer")
                .font(.system(size: 56))
                .foregroundStyle(Color.hatGold)

            Text("Раунд завершён!")
                .font(.hatH1)
                .foregroundStyle(Color.hatTextPrimary)

            Text("Очков за раунд: \(viewModel.roundScore)")
                .font(.hatH2)
                .foregroundStyle(Color.hatGold)

            if let team = viewModel.currentTeam {
                Text("\(team.name): \(team.score) очков всего")
                    .font(.hatBody)
                    .foregroundStyle(Color.hatTextSecondary)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.hatCard)
                .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        )
        .padding(.horizontal, 24)
    }

    private var roundEndButtons: some View {
        HatPrimaryButton(title: "Ход следующей команды") {
            viewModel.nextTeam()
        }
    }

    // MARK: - Анимация карточки

    private func triggerCardAnimation(newId: UUID?) {
        wordCardAppeared = false
        wordId = newId
        withAnimation {
            wordCardAppeared = true
        }
    }
}

#Preview {
    GameplayView(viewModel: GameViewModel())
}
