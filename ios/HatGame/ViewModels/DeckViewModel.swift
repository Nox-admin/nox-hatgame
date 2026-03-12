import Foundation

/// ViewModel для управления колодой слов
@MainActor
final class DeckViewModel: ObservableObject {

    @Published var availableWords: [Word] = []
    @Published var selectedLevel: WordLevel? = nil
    @Published var wordCount: Int = 30
    @Published var isLoading: Bool = false

    /// Загрузить доступные слова
    func loadWords() {
        isLoading = true
        let words = DeckService.loadAllWords(level: selectedLevel)
        availableWords = words
        isLoading = false
    }

    /// Сформировать колоду для игры
    func buildDeck() -> [Word] {
        return DeckService.loadDeck(
            level: selectedLevel,
            count: wordCount
        )
    }

    /// Количество доступных слов для выбранного уровня
    var availableCount: Int {
        availableWords.count
    }

    /// Описание выбранного уровня
    var levelDescription: String {
        guard let level = selectedLevel else {
            return "Все уровни (микс)"
        }
        return level.displayName
    }
}
