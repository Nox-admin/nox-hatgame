import SwiftUI

/// Экран финальных результатов (Screen 11)
struct FinalResultsView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showConfetti = false
    @State private var revealedCount = 0   // сколько мест уже показано (staged reveal)
    @State private var showWinner = false   // показать карточку победителя

    /// Количество мест в leaderboard (без первого — победитель отдельно)
    private var otherCount: Int {
        max(0, viewModel.standings.count - 1)
    }

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            // Confetti layer
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 24) {
                Spacer()

                // Sparkles header
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                    Image(systemName: "star.fill")
                    Image(systemName: "sparkles")
                }
                .font(.system(size: 40))
                .foregroundStyle(Color.hatGold)

                Text(L10n.Final.gameOver)
                    .font(.hatH1)
                    .foregroundStyle(Color.hatTextPrimary)

                // Winner card — появляется после всех мест
                if showWinner, let winner = viewModel.engine.winner {
                    winnerCard(team: winner)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Other players — staged reveal (последнее место → ... → 2-е)
                otherPlayersSection
                    .padding(.horizontal, 20)

                Spacer()

                // Buttons — показываем после reveal
                if showWinner {
                    VStack(spacing: 12) {
                        HatPrimaryButton(title: L10n.Final.playAgain2) {
                            viewModel.playAgain()
                        }

                        ShareResultButton(result: .teams(standings: viewModel.standings))

                        HatSecondaryButton(title: L10n.Nav.menu) {
                            viewModel.goHome()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { startStagedReveal() }
    }

    // MARK: - Staged Reveal

    private func startStagedReveal() {
        // Reveal от последнего к 2-му месту (индекс otherCount-1 → 0), потом winner
        for step in 0..<otherCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 0.8 + 0.3) {
                withAnimation(.spring(duration: 0.45, bounce: 0.25)) {
                    revealedCount = step + 1
                }
            }
        }
        // Winner card + confetti после всех мест
        let winnerDelay = Double(otherCount) * 0.8 + 0.3 + 0.4
        DispatchQueue.main.asyncAfter(deadline: .now() + winnerDelay) {
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                showWinner = true
            }
            SoundService.playGuess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showConfetti = true
            }
        }
    }

    // MARK: - Winner Card

    private func winnerCard(team: Team) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.hatGold)

            Text(team.name)
                .font(.hatDisplay)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.hatGold, Color.hatWarm],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(L10n.pointsTotal(team.score))
                .font(.hatBody)
                .foregroundStyle(Color.hatTextSecondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.hatCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.hatGold, lineWidth: 2)
        )
        .shadow(color: Color.hatGold.opacity(0.3), radius: 16, y: 4)
    }

    // MARK: - Other Players

    private var otherPlayersSection: some View {
        VStack(spacing: 8) {
            let sorted = viewModel.standings
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, team in
                if index > 0 { // Skip winner (already shown above)
                    let reverseIdx = sorted.count - 1 - index // последнее место появляется первым
                    let isRevealed = reverseIdx < revealedCount

                    HStack {
                        medalBadge(for: index)
                            .frame(width: 30)

                        Text(team.name)
                            .font(.hatBody)
                            .foregroundStyle(Color.hatTextPrimary)

                        Spacer()

                        Text(L10n.pointsShort(team.score))
                            .font(.hatBody)
                            .foregroundStyle(Color.hatTextSecondary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.hatCard)
                    )
                    .opacity(isRevealed ? 1 : 0)
                    .offset(y: isRevealed ? 0 : 20)
                    .animation(.spring(duration: 0.45, bounce: 0.25), value: isRevealed)
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func medalBadge(for index: Int) -> some View {
        ZStack {
            Circle()
                .fill(medalColor(for: index))
                .frame(width: 32, height: 32)
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
    FinalResultsView(viewModel: GameViewModel())
}
