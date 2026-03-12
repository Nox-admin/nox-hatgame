import SwiftUI

/// Экран финальных результатов (Screen 11)
struct FinalResultsView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showConfetti = false

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

                Text("Игра завершена!")
                    .font(.hatH1)
                    .foregroundStyle(Color.hatTextPrimary)

                // Winner card
                if let winner = viewModel.engine.winner {
                    winnerCard(team: winner)
                        .padding(.horizontal, 20)
                }

                // Other players
                otherPlayersSection
                    .padding(.horizontal, 20)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    HatPrimaryButton(title: "Ещё раз!") {
                        viewModel.playAgain()
                    }

                    HatSecondaryButton(title: "В меню") {
                        viewModel.goHome()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
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

            Text("набрала \(team.score) очков")
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
                    HStack {
                        medalBadge(for: index)
                            .frame(width: 30)

                        Text(team.name)
                            .font(.hatBody)
                            .foregroundStyle(Color.hatTextPrimary)

                        Spacer()

                        Text("\(team.score) очков")
                            .font(.hatBody)
                            .foregroundStyle(Color.hatTextSecondary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.hatCard)
                    )
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
