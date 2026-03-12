import SwiftUI

/// Экран игрового процесса командного режима
struct TeamsGameplayView: View {
    @ObservedObject var viewModel: TeamsGameViewModel
    var onHome: () -> Void
    /// Явная подписка на TimerService (BUG-001 pattern)
    @ObservedObject private var timerService: TimerService

    @State private var wordCardAppeared = false
    @State private var wordId: UUID? = nil
    @State private var cardSlideX: CGFloat = 0
    @State private var cardFlashColor: Color = .clear
    @State private var cardFlashOpacity: Double = 0
    @State private var animatedByAction = false
    @State private var timerShakeOffset: CGFloat = 0
    @State private var timerExpiredFlash: Double = 0

    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: TeamsGameViewModel, onHome: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onHome = onHome
        self._timerService = ObservedObject(wrappedValue: viewModel.engine.timerService)
    }

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer()

                wordCard
                    .padding(.horizontal, 24)

                Spacer()

                gameControls
            }

            Color.hatDanger
                .opacity(timerExpiredFlash)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if viewModel.isPaused {
                SharedPauseView(onResume: viewModel.resumeGame, onEndGame: viewModel.endGameEarly)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            triggerCardAnimation(newId: viewModel.currentWord?.id)
        }
        .onChange(of: viewModel.currentWord?.id) { _, newId in
            if animatedByAction { animatedByAction = false; return }
            triggerCardAnimation(newId: newId, direction: .neutral)
        }
        .onChange(of: timerService.timeRemaining) { _, remaining in
            if remaining == 0 {
                withAnimation(.easeIn(duration: 0.1)) { timerExpiredFlash = 0.35 }
                withAnimation(.easeOut(duration: 0.3).delay(0.1)) { timerExpiredFlash = 0 }
                withAnimation(.easeInOut(duration: 0.06)) { timerShakeOffset = -8 }
                withAnimation(.easeInOut(duration: 0.06).delay(0.06)) { timerShakeOffset = 8 }
                withAnimation(.easeInOut(duration: 0.06).delay(0.12)) { timerShakeOffset = -6 }
                withAnimation(.easeInOut(duration: 0.06).delay(0.18)) { timerShakeOffset = 0 }
                SoundService.playTimerEnd()
                HapticService.error()
            }
            if remaining <= 5 && remaining > 0 {
                SoundService.playTimerTick()
            }
        }
        // BUG-009: пауза при уходе в фон
        .onChange(of: scenePhase) { _, newPhase in
            guard viewModel.navigationPhase == .playing else { return }
            switch newPhase {
            case .inactive, .background:
                viewModel.pauseBySystem()
            case .active:
                if viewModel.isPausedBySystem {
                    viewModel.resumeGame()
                }
            @unknown default:
                break
            }
        }
    }

    // MARK: - Верхняя панель

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if let team = viewModel.currentTeam {
                    Text(team.name)
                        .font(.hatButton)
                        .foregroundStyle(Color.hatTextPrimary)
                }
                if let explainer = viewModel.currentExplainer {
                    Text("Объясняет: \(explainer.name)")
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                }
            }

            Spacer()

            Text("Осталось: \(viewModel.wordsRemaining) слов")
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
            // BUG-044: пауза в topBar — единое расположение во всех режимах
            Button { viewModel.pauseGame() } label: {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.hatTextSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Карточка слова

    private var wordCard: some View {
        VStack(spacing: 16) {
            if let word = viewModel.currentWord {
                // BUG-040: одна строка, шрифт уменьшается до x0.3 если слово длинное
                Text(word.text)
                    .font(.hatDisplay)
                    .foregroundStyle(Color.hatTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.hatCard)
                            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(cardFlashColor)
                            .opacity(cardFlashOpacity)
                    )
                    .offset(x: cardSlideX, y: wordCardAppeared ? 0 : 60)
                    .opacity(wordCardAppeared ? 1 : 0)
            } else {
                Text("Слова закончились!")
                    .font(.hatH2)
                    .foregroundStyle(Color.hatTextSecondary)
            }
        }
    }

    // MARK: - Таймер

    private var timerSection: some View {
        let isWarning = timerService.timeRemaining <= 10

        return ZStack {
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


    // MARK: - Game Controls

    @ViewBuilder
    private var gameControls: some View {
        if viewModel.navigationPhase == .playing && !viewModel.isPaused {
            timerSection
                .offset(x: timerShakeOffset)
                .padding(.bottom, 16)
            // BUG-041: "Завершить ход" отдельно выше, с явным разрывом
            EndTurnButton(action: viewModel.endTurnEarly,
                          isDisabled: viewModel.navigationPhase != .playing)
                .padding(.bottom, 20)
            gameButtonsRow
                .padding(.bottom, 24)
        }
    }

    private var skipActionIfAllowed: (() -> Void)? {
        guard viewModel.config.allowSkip else { return nil }
        return {
            HapticService.medium()
            SoundService.playSkip()
            viewModel.skipWord()
            animatedByAction = true
            triggerCardAnimation(newId: viewModel.currentWord?.id, direction: .skip)
        }
    }

    private var gameButtonsRow: some View {
        GameplayButtonsView(
            onGuess: {
                HapticService.success()
                SoundService.playGuess()
                viewModel.guessWord()
                animatedByAction = true
                triggerCardAnimation(newId: viewModel.currentWord?.id, direction: .guess)
            },
            onSkip: skipActionIfAllowed,
            isDisabled: viewModel.navigationPhase != .playing
        )
    }

    // MARK: - Анимация

    private enum CardDirection { case guess, skip, neutral }

    private func triggerCardAnimation(newId: UUID?, direction: CardDirection = .neutral) {
        let targetX: CGFloat = direction == .guess ? 300 : direction == .skip ? -300 : 0
        let flashColor: Color = direction == .guess ? .hatSuccess : direction == .skip ? .hatDanger : .clear

        if direction != .neutral {
            withAnimation(.easeIn(duration: 0.08)) {
                cardFlashColor = flashColor
                cardFlashOpacity = 0.6
            }
        }

        withAnimation(.easeIn(duration: 0.12)) {
            cardSlideX = targetX
            wordCardAppeared = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(nil) {
                cardSlideX = 0
                cardFlashOpacity = 0
                wordId = newId
            }
            withAnimation(.spring(duration: 0.25, bounce: 0.2)) {
                wordCardAppeared = true
            }
        }
    }
}
