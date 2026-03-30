import SwiftUI

/// Финальный экран попарного режима — итоговые результаты
struct PairsFinalView: View {
    @ObservedObject var viewModel: PairsGameViewModel
    var onPlayAgain: () -> Void
    var onHome: () -> Void

    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            if showConfetti {
                PairsConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 24) {
                Spacer()

                // Заголовок
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                    Image(systemName: "star.fill")
                    Image(systemName: "sparkles")
                }
                .font(.system(size: 40))
                .foregroundStyle(Color.hatGold)

                Text(L10n.Final.gameOver2)
                    .font(.hatH1)
                    .foregroundStyle(Color.hatTextPrimary)

                // Подиум победителя
                let sorted = viewModel.standings
                if let winner = sorted.first {
                    winnerCard(player: winner.player, score: winner.score)
                        .padding(.horizontal, 20)
                }

                // Остальные игроки
                leaderboard(standings: sorted)
                    .padding(.horizontal, 20)

                Spacer()

                // Кнопки
                VStack(spacing: 12) {
                    HatPrimaryButton(title: L10n.Final.playAgain2) {
                        onPlayAgain()
                    }
                    HatSecondaryButton(title: L10n.Nav.menu) {
                        onHome()
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

    // MARK: - Карточка победителя

    private func winnerCard(player: Player, score: Int) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.hatGold)

            Text(player.name)
                .font(.hatDisplay)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.hatGold, Color.hatWarm],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("\(score) очков")
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

    // MARK: - Таблица лидеров

    private func leaderboard(standings: [(player: Player, score: Int)]) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(standings.enumerated()), id: \.element.player.id) { index, entry in
                if index > 0 {
                    HStack {
                        medalBadge(for: index)
                            .frame(width: 30)

                        Text(entry.player.name)
                            .font(.hatBody)
                            .foregroundStyle(Color.hatTextPrimary)

                        Spacer()

                        Text("\(entry.score) очков")
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

// MARK: - Confetti

private struct PairsConfettiView: View {
    @State private var particles: [PairsConfettiParticle] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let elapsed = now - particle.startTime
                    let x = particle.x * size.width + sin(elapsed * particle.wobbleSpeed) * 30
                    let y = particle.startY + elapsed * particle.fallSpeed
                    guard y < size.height + 20 else { continue }
                    let rect = CGRect(x: x - 5, y: y - 5, width: 10, height: 10)
                    context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                }
            }
        }
        .onAppear {
            let colors: [Color] = [.hatGold, .hatWarm, .hatSuccess, .hatDanger, .white]
            let now = Date.timeIntervalSinceReferenceDate
            particles = (0..<50).map { _ in
                PairsConfettiParticle(
                    x: CGFloat.random(in: 0...1),
                    startY: CGFloat.random(in: -100...(-20)),
                    fallSpeed: CGFloat.random(in: 60...180),
                    wobbleSpeed: Double.random(in: 2...6),
                    color: colors.randomElement() ?? .hatGold,
                    startTime: now + Double.random(in: 0...1.5)
                )
            }
        }
    }
}

private struct PairsConfettiParticle {
    let x: CGFloat
    let startY: CGFloat
    let fallSpeed: CGFloat
    let wobbleSpeed: Double
    let color: Color
    let startTime: TimeInterval
}
