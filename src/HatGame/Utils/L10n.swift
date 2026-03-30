import Foundation

/// Namespace for all localized strings.
/// Usage: Text(L10n.Home.title) or Text(L10n.Final.playAgain)
///
/// Keys map 1:1 to Localizable.strings entries.
/// All properties are computed so they react to LanguageManager changes.
enum L10n {

    // MARK: - App
    static var appName: String { "app.name".localized }

    // MARK: - Home
    enum Home {
        static var title: String   { "home.title".localized }
        static var tagline: String { "home.tagline".localized }
        static var newGame: String { "home.new_game".localized }
        static var rules: String   { "home.rules".localized }
    }

    // MARK: - Rules
    enum Rules {
        static var title: String { "rules.title".localized }
        static var rule1: String { "rules.1".localized }
        static var rule2: String { "rules.2".localized }
        static var rule3: String { "rules.3".localized }
        static var rule4: String { "rules.4".localized }
        static var rule5: String { "rules.5".localized }
        static var rule6: String { "rules.6".localized }
    }

    // MARK: - Navigation
    enum Nav {
        static var back: String     { "nav.back".localized }
        static var players: String  { "nav.players".localized }
        static var done: String     { "nav.done".localized }
        static var skip: String     { "nav.skip".localized }
        static var home: String     { "nav.home".localized }
        static var menu: String     { "nav.menu".localized }
        static var next: String     { "nav.next".localized }
        static var continue_: String { "nav.continue".localized }
    }

    // MARK: - Onboarding
    enum Onboarding {
        static var slide1Title: String    { "onboarding.slide1.title".localized }
        static var slide1Subtitle: String { "onboarding.slide1.subtitle".localized }
        static var slide2Title: String    { "onboarding.slide2.title".localized }
        static var slide2Subtitle: String { "onboarding.slide2.subtitle".localized }
        static var slide3Title: String    { "onboarding.slide3.title".localized }
        static var slide3Subtitle: String { "onboarding.slide3.subtitle".localized }
        static var start: String          { "onboarding.start".localized }
    }

    // MARK: - Players
    enum Players {
        static var add: String             { "players.add".localized }
        static var namePlaceholder: String { "players.name_placeholder".localized }
        static var duplicateNames: String  { "players.duplicate_names".localized }
        static var emptyNames: String      { "players.empty_names".localized }
        static var avatarPicker: String    { "players.avatar_picker_title".localized }
        static func defaultName(_ n: Int) -> String {
            "players.default_name".localized(with: n)
        }
        static func cannotDelete(min: Int) -> String {
            "players.cannot_delete".localized(with: min)
        }
        static func minRequired(_ n: Int) -> String {
            "players.min_required".localized(with: n)
        }
    }

    // MARK: - Mode
    enum Mode {
        static var title: String       { "mode.title".localized }
        static var section: String     { "mode.section".localized }
        static var start: String       { "mode.start".localized }
        static var teamsTitle: String  { "mode.teams.title".localized }
        static var teamsDesc: String   { "mode.teams.description".localized }
        static var pairsTitle: String  { "mode.pairs.title".localized }
        static var pairsDesc: String   { "mode.pairs.description".localized }
        static var ffaTitle: String    { "mode.ffa.title".localized }
        static var ffaDesc: String     { "mode.ffa.description".localized }
        static func minPlayers(_ n: Int) -> String {
            "mode.min_players".localized(with: n)
        }
    }

    // MARK: - Settings
    enum Settings {
        static var section: String      { "settings.section".localized }
        static var title: String        { "settings.title".localized }
        static var gameSettings: String { "settings.game_settings".localized }
        static var params: String       { "settings.params".localized }
        static var turnTime: String     { "settings.turn_time".localized }
        static var hatSize: String      { "settings.hat_size".localized }
        static var skipButton: String   { "settings.skip_button".localized }
        static var skipSubtitle: String { "settings.skip_subtitle".localized }
        static var difficulty: String   { "settings.difficulty".localized }
    }

    // MARK: - Difficulty
    enum Difficulty {
        static var easy: String        { "difficulty.easy".localized }
        static var medium: String      { "difficulty.medium".localized }
        static var hard: String        { "difficulty.hard".localized }
        static var all: String         { "difficulty.all".localized }
        static var choose: String      { "difficulty.choose".localized }
        static var easyExample: String { "difficulty.easy.description".localized }
        static var hardExample: String { "difficulty.hard.description".localized }
    }

    // MARK: - Teams
    enum Teams {
        static var section: String        { "teams.section".localized }
        static var add: String            { "teams.add".localized }
        static var playersSection: String { "teams.players_section".localized }
        static var unassignedHint: String { "teams.unassigned_hint".localized }
        static var assignAll: String      { "teams.assign_all".localized }
        static var minTwo: String         { "teams.min_two".localized }
        static func defaultName(_ n: Int) -> String {
            "teams.default_name".localized(with: n)
        }
        static func emptyWarning(_ name: String) -> String {
            "teams.empty_warning".localized(with: name)
        }
    }

    // MARK: - Words
    enum Words {
        static var section: String      { "words.section".localized }
        static var alreadyAdded: String { "words.already_added".localized }
    }

    // MARK: - Phone Handoff
    enum Handoff {
        static var title: String            { "handoff.title".localized }
        static var passTo: String           { "handoff.pass_to".localized }
        static var closeEyes: String        { "handoff.close_eyes".localized }
        static var privateScreen: String    { "handoff.private_screen".localized }
        static var readySuffix: String      { "handoff.ready_suffix".localized }
        static var enterWordsSuffix: String { "handoff.enter_words_suffix".localized }
    }

    // MARK: - Waiting
    enum Waiting {
        static var nextTurn: String     { "waiting.next_turn".localized }
        static var go: String           { "waiting.go".localized }
        static var explainsWords: String { "waiting.explains_words".localized }
        static var explainsAll: String  { "waiting.explains_all".localized }
        static var explainsFor: String  { "waiting.explains_for".localized }
        static var explains: String     { "waiting.explains".localized }
        static var guesses: String      { "waiting.guesses".localized }
        static var score: String        { "waiting.score".localized }
        static var endGame: String      { "waiting.end_game".localized }
        static var allPairsDone: String { "waiting.all_pairs_done".localized }
        static func wordsInHat(_ n: Int) -> String {
            "waiting.words_in_hat".localized(with: n)
        }
    }

    // MARK: - Gameplay
    enum Gameplay {
        static var wordsGone: String  { "gameplay.words_gone".localized }
        static var wordsGone2: String { "gameplay.words_gone2".localized }
        static var guessed: String    { "gameplay.guessed".localized }
        static var skip: String       { "gameplay.skip".localized }
        static var pause: String      { "gameplay.pause".localized }
        static var resume: String     { "gameplay.resume".localized }
        static var endEarly: String   { "gameplay.end_early".localized }
        static func wordsLeft(_ n: Int) -> String {
            "gameplay.words_left".localized(with: n)
        }
        static func explains(_ name: String) -> String {
            "gameplay.explains".localized(with: name)
        }
    }

    // MARK: - Round
    enum Round {
        static var ended: String       { "round.ended".localized }
        static var ended2: String      { "round.ended2".localized }
        static var circleEnded: String { "round.circle_ended".localized }
        static func label(_ n: Int) -> String {
            "round.label".localized(with: n)
        }
        static func of(_ current: Int, _ total: Int) -> String {
            "round.of".localized(with: current, total)
        }
        static func score(_ n: Int) -> String {
            "round.score".localized(with: n)
        }
        static func guessed(_ n: Int) -> String {
            "round.guessed".localized(with: n)
        }
    }

    // MARK: - Turn
    enum Turn {
        static var ended: String          { "turn.ended".localized }
        static var ended2: String         { "turn.ended2".localized }
        static var whoGuessed: String     { "turn.who_guessed".localized }
        static var whoGuessed2: String    { "turn.who_guessed2".localized }
        static var tapToCorrect: String   { "turn.tap_to_correct".localized }
        static var tapWhoGuessed: String  { "turn.tap_who_guessed".localized }
        static var wordsNotGuessed: String { "turn.words_not_guessed".localized }
        static var nextTeam: String       { "turn.next_team".localized }
        static func endedTeam(_ name: String) -> String {
            "turn.ended_team".localized(with: name)
        }
        static func attributed(_ done: Int, _ total: Int) -> String {
            "turn.attributed".localized(with: done, total)
        }
    }

    // MARK: - Final
    enum Final {
        static var gameOver: String    { "final.game_over".localized }
        static var gameOver2: String   { "final.game_over2".localized }
        static var leaderboard: String { "final.leaderboard".localized }
        static var podium: String      { "final.podium".localized }
        static var winner: String      { "final.winner".localized }
        static var winningTeam: String { "final.winning_team".localized }
        static var playAgain: String   { "final.play_again".localized }
        static var playAgain2: String  { "final.play_again2".localized }
        static var newGame: String     { "final.new_game".localized }
        static var share: String       { "final.share".localized }
        static var winnerLabel: String { "final.winner_label".localized }
        static var results: String     { "final.results".localized }
    }

    // MARK: - Misc
    static func secondsAbbr(_ n: Int) -> String {
        "seconds_abbr".localized(with: n)
    }
    static func secFull(_ n: Int) -> String {
        "sec_full".localized(with: n)
    }
    static func scorePoints(_ n: Int) -> String {
        "score_points".localized(with: n)
    }
    static func scoreTotal(team: String, score: Int) -> String {
        "score_total".localized(with: team, score)
    }
    static var guessedWordsSuffix: String { "guessed_words_suffix".localized }
}
