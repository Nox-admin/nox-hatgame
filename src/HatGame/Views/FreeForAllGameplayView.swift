import SwiftUI

struct FreeForAllGameplayView: View {
    @ObservedObject var viewModel: FreeForAllGameViewModel
    // BUG-001: инициализируем через ObservedObject чтобы таймер тикал в UI
    @ObservedObject private var timerService: TimerService
    var onHome: () -> Void

    @State private var cardId: UUID? = nil
    @State private var cardOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1
    @State private var cardSlideX: CGFloat = 0
    @State private var cardFlashColor: Color = .clear
    @State private var cardFlashOpacity: Double = 0
    @State private var animatedByAction = false
    @State private var timerShakeOffset: CGFloat = 0
    @State private var timerExpiredFlash: Double = 0
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: FreeForAllGameViewModel, onHome: @escaping () -> Void) {
        self.viewModel = viewModel
        self._timerService = ObservedObject(wrappedValue: viewModel.timerService)
        self.onHome = onHome
    }

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Топбар
                topBar

                Spacer()

                // Карточка слова
                if let word = viewModel.currentWord {
                    wordCard(word: word)
                } else {
                    Text(L10n.Gameplay.wordsGone)
                        .font(.hatH2)
                        .foregroundStyle(Color.hatTextSecondary)
                }

                Spacer()

                // Таймер
                timerSection
                    .offset(x: timerShakeOffset)

                // BUG-041: "Завершить ход" отдельно выше, с явным разрывом
                EndTurnButton(action: viewModel.endRound,
                              isDisabled: viewModel.phase != .playing)
                    .padding(.bottom, 20)

                // Кнопки действий
                ffaGameButtons
                    .padding(.bottom, 34)
            }

            Color.hatDanger
                .opacity(timerExpiredFlash)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Пауза оверлей
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
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .inactive, .background:
                viewModel.pauseBySystem()
            case .active:
                if viewModel.isPausedBySystem { viewModel.resumeGame() }
            default: break
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.explainerOrdinal)
                    .font(.hatButton)
                    .foregroundStyle(Color.hatTextPrimary)
                Text(L10n.Waiting.explainsAll)
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(L10n.Gameplay.wordsLeft(viewModel.wordsRemaining))
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
                Text(L10n.Round.guessed(viewModel.roundScore))
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatGold)
            }

            // Пауза
            Button { viewModel.pauseGame() } label: {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.hatTextSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Word card

    private func wordCard(word: Word) -> some View {
        // BUG-040: одна строка, шрифт уменьшается до x0.3 если слово длинное
        Text(word.text)
            .font(.hatDisplay)
            .foregroundStyle(Color.hatTextPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.3)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.hatCard)
                    .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .fill(cardFlashColor)
                    .opacity(cardFlashOpacity)
            )
            .padding(.horizontal, 24)
            .offset(x: cardSlideX, y: cardOffset)
            .opacity(cardOpacity)
            .id(cardId)
    }

    // MARK: - Timer section

    private var timerSection: some View {
        let isLow = timerService.timeRemaining <= 10
        return ZStack {
            // Фоновая дуга
            Circle()
                .stroke(Color.hatSurface, lineWidth: 8)
                .frame(width: 100, height: 100)

            // Прогресс дуга
            Circle()
                .trim(from: 0, to: timerService.progress)
                .stroke(
                    isLow ? Color.hatDanger : Color.hatGold,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: timerService.progress)

            // Время
            Text("\(timerService.timeRemaining)")
                .font(.hatTimer)
                .foregroundStyle(isLow ? Color.hatDanger : Color.hatGold)
                .contentTransition(.numericText())
                .scaleEffect(isLow ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.4).repeatCount(isLow ? .max : 1), value: isLow)
        }
        .padding(.bottom, 20)
    }


    // MARK: - Game Buttons

    // Computed helper — вне @ViewBuilder, без ambiguity
    private var skipActionIfAllowed: (() -> Void)? {
        guard viewModel.config.allowSkip else { return nil }
        return {
            HapticService.medium()
            SoundService.playSkip()
            viewModel.wordSkipped()
            animatedByAction = true
            triggerCardAnimation(newId: viewModel.currentWord?.id, direction: .skip)
        }
    }

    private var ffaGameButtons: some View {
        GameplayButtonsView(
            onGuess: {
                HapticService.success()
                SoundService.playGuess()
                viewModel.wordGuessed()
                animatedByAction = true
                triggerCardAnimation(newId: viewModel.currentWord?.id, direction: .guess)
            },
            onSkip: skipActionIfAllowed,
            isDisabled: viewModel.phase != .playing
        )
    }

    // MARK: - Animation

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
            cardOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(nil) {
                cardSlideX = 0
                cardFlashOpacity = 0
                cardId = newId
            }
            withAnimation(.spring(duration: 0.25, bounce: 0.2)) {
                cardOpacity = 1
                cardOffset = 0
            }
        }
    }
}
