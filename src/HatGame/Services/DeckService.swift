import Foundation

/// Сервис загрузки и управления колодой слов
final class DeckService {

    // MARK: - JSON-структуры для парсинга

    private struct WordsFile: Decodable {
        let levels: [LevelData]
    }

    private struct LevelData: Decodable {
        let level: String
        let categories: [CategoryData]
    }

    private struct CategoryData: Decodable {
        let id: String
        let name: String
        let words: [String]
    }

    // Для отдельных файлов (words_easy.json и т.д.)
    private struct SingleLevelFile: Decodable {
        let level: String
        let categories: [CategoryData]
    }

    // Для плоского формата (words_en.json, words_zh.json)
    private struct FlatWordsFile: Decodable {
        let words: [FlatWordEntry]
    }

    private struct FlatWordEntry: Decodable {
        let text: String
        let category: String
        let difficulty: String
    }

    // MARK: - Загрузка слов

    /// Загрузить слова из JSON-файла
    /// - Parameters:
    ///   - level: уровень сложности (nil = все уровни)
    ///   - count: количество слов для колоды
    ///   - resourcePath: путь к директории с ресурсами
    /// - Returns: перемешанный массив слов
    static func loadDeck(
        level: WordLevel? = nil,
        count: Int = 30,
        resourcePath: String? = nil
    ) -> [Word] {
        let allWords = loadAllWords(level: level, resourcePath: resourcePath)
        let shuffled = allWords.shuffled()
        let limited = Array(shuffled.prefix(count))
        return limited
    }

    /// Загрузить все слова из JSON
    static func loadAllWords(
        level: WordLevel? = nil,
        resourcePath: String? = nil
    ) -> [Word] {
        // Пробуем загрузить из бандла приложения
        if let bundleWords = loadFromBundle(level: level), !bundleWords.isEmpty {
            return bundleWords
        }

        // Пробуем загрузить из внешнего пути (../resources/words.json)
        let externalPath = resourcePath ?? resolveResourcePath()
        if let externalWords = loadFromExternalPath(externalPath, level: level), !externalWords.isEmpty {
            return externalWords
        }

        // Фолбэк: встроенные слова
        return fallbackWords()
    }

    // MARK: - Загрузка из бандла

    private static func loadFromBundle(level: WordLevel?) -> [Word]? {
        // Пробуем файл для текущего языка (words_en.json, words_zh.json и т.д.)
        let languageFileName = LanguageManager.shared.currentLanguage.wordsFileName
        if languageFileName != "words",
           let url = Bundle.main.url(forResource: languageFileName, withExtension: "json") {
            if let words = parseMainFile(at: url, level: level), !words.isEmpty {
                return words
            }
        }
        // Фолбэк: базовый русский файл
        guard let url = Bundle.main.url(forResource: "words", withExtension: "json") else {
            return nil
        }
        return parseMainFile(at: url, level: level)
    }

    // MARK: - Загрузка из внешнего файла

    private static func resolveResourcePath() -> String {
        // Путь относительно бандла: ../resources/words.json
        let bundlePath = Bundle.main.bundlePath
        let parentDir = (bundlePath as NSString).deletingLastPathComponent
        return (parentDir as NSString).appendingPathComponent("resources/words.json")
    }

    private static func loadFromExternalPath(_ path: String, level: WordLevel?) -> [Word]? {
        let url = URL(fileURLWithPath: path)
        return parseMainFile(at: url, level: level)
    }

    // MARK: - Парсинг

    private static func parseMainFile(at url: URL, level: WordLevel?) -> [Word]? {
        guard let data = try? Data(contentsOf: url) else { return nil }

        // Пробуем формат с levels[] (words.json)
        if let file = try? JSONDecoder().decode(WordsFile.self, from: data) {
            var words: [Word] = []
            for levelData in file.levels {
                guard let wordLevel = WordLevel(rawValue: levelData.level) else { continue }
                // Фильтрация по уровню
                if let filterLevel = level, filterLevel != wordLevel { continue }
                for category in levelData.categories {
                    for text in category.words {
                        words.append(Word(
                            text: text,
                            level: wordLevel,
                            category: category.id
                        ))
                    }
                }
            }
            return words
        }

        // Пробуем формат одного уровня (words_easy.json)
        if let singleLevel = try? JSONDecoder().decode(SingleLevelFile.self, from: data) {
            guard let wordLevel = WordLevel(rawValue: singleLevel.level) else { return nil }
            if let filterLevel = level, filterLevel != wordLevel { return nil }
            var words: [Word] = []
            for category in singleLevel.categories {
                for text in category.words {
                    words.append(Word(
                        text: text,
                        level: wordLevel,
                        category: category.id
                    ))
                }
            }
            return words
        }

        // Пробуем плоский формат (words_en.json, words_zh.json)
        if let flat = try? JSONDecoder().decode(FlatWordsFile.self, from: data) {
            var words: [Word] = []
            for entry in flat.words {
                guard let wordLevel = WordLevel(rawValue: entry.difficulty) else { continue }
                if let filterLevel = level, filterLevel != wordLevel { continue }
                words.append(Word(
                    text: entry.text,
                    level: wordLevel,
                    category: entry.category
                ))
            }
            return words
        }

        return nil
    }

    // MARK: - Фолбэк (встроенные слова на случай отсутствия JSON)

    private static func fallbackWords() -> [Word] {
        let easyWords = [
            "кот", "собака", "солнце", "луна", "стол", "дом", "машина",
            "книга", "дерево", "мяч", "яблоко", "рыба", "цветок", "часы",
            "птица", "молоко", "хлеб", "окно", "музыка", "дождь",
            "медведь", "лиса", "шоколад", "торт", "телефон",
            "звезда", "река", "лес", "гора", "море"
        ]
        return easyWords.map { Word(text: $0, level: .easy, category: "fallback") }
    }

    // MARK: - Утилиты

    /// Returns a freshly shuffled copy — call before each turn, not just game start
    static func reshuffleDeck(_ deck: [Word]) -> [Word] {
        deck.shuffled()
    }

    /// Перемешать колоду
    static func shuffle(_ deck: inout [Word]) {
        deck.shuffle()
    }

    /// Вернуть пропущенные слова в колоду и перемешать
    /// - Note: BUG-005 — этот метод не используется. Пропущенные слова возвращаются
    ///   в колоду инлайн внутри `GameEngine.wordSkipped()` сразу во время хода.
    ///   Метод оставлен как утилита на случай будущих нужд.
    @available(*, deprecated, message: "Skipped words are returned inline in GameEngine.wordSkipped()")
    static func returnSkippedWords(_ skipped: [Word], to deck: inout [Word]) {
        let returned = skipped.map { word -> Word in
            var w = word
            w.isGuessed = false
            return w
        }
        deck.append(contentsOf: returned)
        deck.shuffle()
    }
}
