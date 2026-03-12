import SwiftUI

/// Единый финальный экран для всех трёх режимов
struct UnifiedFinalView: View {
    let result: GameResult
    var onNewGame: () -> Void        // На главный экран
    var onPlayAgain: (() -> Void)?   // Переиграть (те же игроки)

    @State private var appeared = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 32)

                    // Заголовок
                    headerSection
                        .padding(.bottom, 32)

                    // Победитель
                    if !result.isEmpty {
                        winnerCard
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }

                    // Полный рейтинг
                    leaderboard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)

                    // Кнопки
                    buttons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 48)
                }
            }
        }
        .overlay { if showConfetti { ConfettiView().ignoresSafeArea() } }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(duration: 0.5).delay(0.1)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showConfetti = true }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Color.hatGold)
                .scaleEffect(appeared ? 1 : 0.4)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.5), value: appeared)

            Text("Игра завершена!")
                .font(.hatH1)
                .foregroundStyle(Color.hatTextPrimary)

            modeLabel
        }
    }

    @ViewBuilder
    private var modeLabel: some View {
        switch result {
        case .players(_, let mode):
            Text(mode.title)
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.hatSurface))
        case .teams:
            Text(GameMode.teams.title)
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.hatSurface))
        }
    }

    // MARK: - Winner card

    @ViewBuilder
    private var winnerCard: some View {
        switch result {
        case .players(let standings, _):
            if let top = standings.first {
                WinnerCard(name: top.player.name, score: top.score, label: "победитель")
            }
        case .teams(let standings):
            if let top = standings.first {
                WinnerCard(name: top.name, score: top.score, label: "победившая команда")
            }
        }
    }

    // MARK: - Leaderboard

    @ViewBuilder
    private var leaderboard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ИТОГОВЫЙ РЕЙТИНГ")
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
                .tracking(2)

            switch result {
            case .players(let standings, _):
                playersLeaderboard(standings)
            case .teams(let standings):
                teamsLeaderboard(standings)
            }
        }
    }

    private func playersLeaderboard(_ standings: [(player: Player, score: Int)]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(standings.enumerated()), id: \.element.player.id) { idx, entry in
                LeaderboardRow(
                    rank: idx + 1,
                    name: entry.player.name,
                    score: entry.score,
                    isWinner: idx == 0
                )
                if idx < standings.count - 1 {
                    Divider().background(Color.hatSurface)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.hatCard))
    }

    private func teamsLeaderboard(_ standings: [Team]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(standings.enumerated()), id: \.element.id) { idx, team in
                LeaderboardRow(
                    rank: idx + 1,
                    name: team.name,
                    score: team.score,
                    isWinner: idx == 0
                )
                if idx < standings.count - 1 {
                    Divider().background(Color.hatSurface)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.hatCard))
    }

    // MARK: - Buttons

    private var buttons: some View {
        VStack(spacing: 12) {
            if let onPlayAgain {
                HatPrimaryButton(title: "Играть снова", action: onPlayAgain)
            }
            Button(action: onNewGame) {
                Text("Новая игра")
                    .font(.hatBody)
                    .foregroundStyle(onPlayAgain != nil ? Color.hatTextSecondary : Color.hatGold)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - WinnerCard

private struct WinnerCard: View {
    let name: String
    let score: Int
    let label: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color.hatGold)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.hatH2)
                    .foregroundStyle(Color.hatGold)
                HStack(spacing: 6) {
                    Text(label)
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                    Text("·")
                        .foregroundStyle(Color.hatTextSecondary)
                    Text("\(score) \(pointsEnding(score))")
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                }
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.hatCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.hatGold, lineWidth: 2)
                )
        )
    }

    private func pointsEnding(_ count: Int) -> String {
        let mod10 = count % 10, mod100 = count % 100
        if mod100 >= 11 && mod100 <= 14 { return "очков" }
        switch mod10 {
        case 1: return "очко"
        case 2, 3, 4: return "очка"
        default: return "очков"
        }
    }
}

// MARK: - LeaderboardRow

private struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let score: Int
    let isWinner: Bool

    private static let medalColors: [Color] = [.hatGold, Color(hex: 0xC0C0C0), Color(hex: 0xCD7F32)]

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(rank <= 3 ? Self.medalColors[rank - 1] : Color.hatSurface)
                    .frame(width: 34, height: 34)
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(rank <= 3 ? Color.hatBackground : Color.hatTextPrimary)
            }

            Text(name)
                .font(.hatBody)
                .foregroundStyle(isWinner ? Color.hatGold : Color.hatTextPrimary)

            Spacer()

            Text("\(score)")
                .font(.hatButton)
                .foregroundStyle(Color.hatGold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}

#Preview {
    let players = (1...4).map { Player(name: "Игрок \($0)") }
    let standings = players.enumerated().map { (player: $1, score: 10 - $0 * 2) }
    return UnifiedFinalView(
        result: .players(standings: standings, mode: .freeForAll),
        onNewGame: {},
        onPlayAgain: {}
    )
}
