import Foundation

/// Один раунд попарной игры: кто кому объясняет
struct PairsRound: Identifiable {
    let id: UUID
    let circle: Int        // 1..N-1
    let roundInCircle: Int // 1..N (позиция внутри круга)
    let explainer: Player
    let guesser: Player
    var guessedWords: [Word]
    var skippedWords: [Word]

    init(
        id: UUID = UUID(),
        circle: Int,
        roundInCircle: Int,
        explainer: Player,
        guesser: Player,
        guessedWords: [Word] = [],
        skippedWords: [Word] = []
    ) {
        self.id = id
        self.circle = circle
        self.roundInCircle = roundInCircle
        self.explainer = explainer
        self.guesser = guesser
        self.guessedWords = guessedWords
        self.skippedWords = skippedWords
    }
}

/// Расписание попарной игры: round-robin N*(N-1) раундов
struct PairsSchedule {
    let rounds: [PairsRound]

    /// Генерация полного расписания для N игроков.
    /// В круге k (1..N-1) игрок i объясняет игроку (i+k) % N.
    static func generate(players: [Player]) -> PairsSchedule {
        let n = players.count
        guard n >= 2 else { return PairsSchedule(rounds: []) }

        var rounds: [PairsRound] = []
        for k in 1...(n - 1) {
            for i in 0...(n - 1) {
                let explainer = players[i]
                let guesser = players[(i + k) % n]
                rounds.append(PairsRound(
                    circle: k,
                    roundInCircle: i + 1,
                    explainer: explainer,
                    guesser: guesser
                ))
            }
        }
        return PairsSchedule(rounds: rounds)
    }

    var totalRounds: Int { rounds.count }
}
