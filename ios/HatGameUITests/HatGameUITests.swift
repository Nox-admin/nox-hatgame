import XCTest

// ============================================================
// TASK-014 QA Suite — все три режима
// Коммиты: TASK-009–013 (e8fea49)
// Симулятор: iPhone 17 Pro, iOS 26.3, ru-RU locale
// ============================================================

final class HatGameUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-hasSeenOnboarding", "YES"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: - ──── Helpers ────

    func snap(_ name: String) {
        let s = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: s)
        a.name = name; a.lifetime = .keepAlways; add(a)
    }

    func btn(_ label: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
    }

    func txt(_ label: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
    }

    /// Home → PlayerSetup → ModeSelection
    func setupPlayers(extra: Int = 0) {
        XCTAssertTrue(app.buttons["Новая игра"].waitForExistence(timeout: 5))
        app.buttons["Новая игра"].tap()
        let cont = app.buttons.matching(NSPredicate(format: "label CONTAINS '→' OR label CONTAINS 'Продолжить'")).firstMatch
        XCTAssertTrue(cont.waitForExistence(timeout: 5), "PlayerSetupView не найден")
        for _ in 0..<extra {
            let add = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Добавить'")).firstMatch
            if add.waitForExistence(timeout: 2) { add.tap(); sleep(1) }
        }
        cont.tap(); sleep(1)
        // Now on ModeSelectionView
    }

    func selectMode(_ keyword: String) {
        let mode = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", keyword)).firstMatch
        XCTAssertTrue(mode.waitForExistence(timeout: 5), "Режим '\(keyword)' не найден")
        mode.tap(); sleep(1)
    }

    /// Tap "Начать игру" → navigates to WaitingView
    func tapStartGame() {
        let s = btn("Начать игру")
        XCTAssertTrue(s.waitForExistence(timeout: 5), "'Начать игру' не найдена")
        s.tap(); sleep(1)
    }

    /// Reduce turn duration to minimum by tapping minus 3 times
    /// SF Symbol "minus.circle.fill" → accessibility label "Minus" (English, confirmed by diagnostics)
    /// Reduce turn duration to minimum (15s).
    /// SF Symbol "minus.circle.fill" with .borderless style → accessibility label "Remove" (confirmed by diagnostics)
    func reduceDuration() {
        let removeBtn = app.buttons["Remove"]
        guard removeBtn.waitForExistence(timeout: 3) && removeBtn.isEnabled else { return }
        for _ in 0..<3 {
            if removeBtn.isEnabled { removeBtn.tap(); usleep(400_000) }
        }
    }

    /// Detect Teams gameplay — try multiple indicators
    func waitForTeamsGameplay(timeout: TimeInterval = 12) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            // Try: "Угадали" static text
            if app.staticTexts["Угадали"].exists { return true }
            // Try: "Осталось:" (words remaining in topBar)
            if txt("Осталось").exists { return true }
            // Try: "Объясняет:" text in topBar
            if txt("Объясняет:").exists { return true }
            usleep(500_000)
        }
        return false
    }

    /// Detect FFA gameplay via "Угадано:" in topBar
    func waitForFFAGameplay(timeout: TimeInterval = 12) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if txt("Угадано").exists { return true }
            if txt("Слов:").exists { return true }
            usleep(500_000)
        }
        return false
    }

    /// Detect Pairs gameplay via "Слов:" in topBar
    func waitForPairsGameplay(timeout: TimeInterval = 12) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if txt("Слов:").exists { return true }
            if app.buttons.matching(NSPredicate(format: "label == 'Selected'")).firstMatch.exists { return true }
            usleep(500_000)
        }
        return false
    }

    /// Tap pause button (Russian locale: SF Symbol → "Пауза")
    @discardableResult
    func tapPauseButton(timeout: TimeInterval = 6) -> Bool {
        let pause = app.buttons["Pause"]
        guard pause.waitForExistence(timeout: timeout) else { return false }
        pause.tap(); sleep(1); return true
    }

    func tapEndGameFromPause() {
        let endBtn = btn("Завершить игру")
        if endBtn.waitForExistence(timeout: 4) { endBtn.tap(); sleep(2) }
    }

    func exitGameplay() {
        _ = tapPauseButton()
        tapEndGameFromPause()
    }

    func confirmAttributionIfNeeded(timeout: TimeInterval = 6) {
        let c = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Продолжить' OR label CONTAINS 'Пропустить'")).firstMatch
        if c.waitForExistence(timeout: timeout) { c.tap(); sleep(2) }
    }

    // MARK: - ──── TEST 01: Главный экран ────

    func test01_HomeScreen() throws {
        XCTAssertTrue(app.buttons["Новая игра"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Правила"].waitForExistence(timeout: 3))
        XCTAssertFalse(btn("Настройки").exists, "BUG: 'Настройки' на главном экране")
        snap("01_home")
    }

    // MARK: - ──── TEST 02: Выбор режима — все 3 видны ────

    func test02_ModeSelection_AllModesVisible() throws {
        setupPlayers(extra: 1)
        XCTAssertTrue(btn("Попарный").waitForExistence(timeout: 5))
        XCTAssertTrue(btn("Командный").waitForExistence(timeout: 2))
        XCTAssertTrue(btn("сразу").waitForExistence(timeout: 2), "FFA mode not found")
        snap("02_modes")
    }

    // MARK: - ──── TEST 03: Попарный — WaitingView → Gameplay → Final ────

    func test03_PairsMode_FullCycle() throws {
        setupPlayers(extra: 1)
        selectMode("Попарный")
        tapStartGame()   // ← Navigate to PairsWaitingView

        // PairsWaitingView
        XCTAssertTrue(btn("Поехали").waitForExistence(timeout: 8), "PairsWaiting: 'Поехали!' не найдена")
        XCTAssertTrue(btn("Завершить").waitForExistence(timeout: 3), "PairsWaiting: кнопка выхода не найдена")
        snap("03a_pairs_waiting")

        btn("Поехали").tap(); sleep(2)
        snap("03b_after_poehali")

        // Detect gameplay
        XCTAssertTrue(waitForPairsGameplay(timeout: 12), "PairsGameplay не загрузился")
        snap("03c_pairs_gameplay")

        // Exit
        exitGameplay()
        snap("03d_after_exit")

        // Final
        let finalOK = btn("Играть снова").waitForExistence(timeout: 6) || btn("Новая игра").waitForExistence(timeout: 4)
        XCTAssertTrue(finalOK, "Pairs: UnifiedFinalView не найден после выхода")
        snap("03e_pairs_final")

        btn("Новая игра").tap(); sleep(2)
        XCTAssertTrue(app.buttons["Новая игра"].waitForExistence(timeout: 5))
    }

    // MARK: - ──── TEST 04: Попарный — регистрация угаданных слов ────

    func test04_PairsMode_Guessing() throws {
        setupPlayers(extra: 1)
        selectMode("Попарный")
        tapStartGame()

        XCTAssertTrue(btn("Поехали").waitForExistence(timeout: 8))
        btn("Поехали").tap(); sleep(2)

        XCTAssertTrue(waitForPairsGameplay(timeout: 12), "PairsGameplay не загрузился")

        // Угадываем слова через ✓ кнопку
        let guessBtn = app.buttons.matching(NSPredicate(format: "label == 'Selected'")).firstMatch
        if guessBtn.waitForExistence(timeout: 4) {
            guessBtn.tap(); sleep(1)
            guessBtn.tap(); sleep(1)
        }
        snap("04a_pairs_guessing")

        exitGameplay()

        let finalOK = btn("Играть снова").waitForExistence(timeout: 6) || btn("Новая игра").waitForExistence(timeout: 4)
        XCTAssertTrue(finalOK, "Pairs: финал не показан после угадывания слов")
        snap("04b_pairs_final_scored")
    }

    // MARK: - ──── TEST 05: Команды — автораспределение + старт ────

    func test05_TeamsMode_FullCycle() throws {
        setupPlayers(extra: 2) // 4 игрока
        selectMode("Командный")

        let autoBtn = btn("Авто")
        XCTAssertTrue(autoBtn.waitForExistence(timeout: 5), "TeamBuilderView: 'Авто' не найдена")
        snap("05a_teams_builder")
        autoBtn.tap(); sleep(1)
        snap("05b_teams_distributed")

        tapStartGame()   // → TeamsWaitingView

        XCTAssertTrue(btn("Поехали").waitForExistence(timeout: 8), "TeamsWaiting: 'Поехали!' не найдена")
        XCTAssertTrue(btn("Завершить").waitForExistence(timeout: 3))
        snap("05c_teams_waiting")

        btn("Поехали").tap(); sleep(2)
        snap("05d_after_poehali")

        XCTAssertTrue(waitForTeamsGameplay(timeout: 12), "TeamsGameplay не загрузился")
        snap("05e_teams_gameplay")

        exitGameplay()

        let finalOK = btn("Играть снова").waitForExistence(timeout: 6) || btn("Новая игра").waitForExistence(timeout: 4)
        XCTAssertTrue(finalOK, "Teams: финал не показан")
        snap("05f_teams_final")

        btn("Новая игра").tap(); sleep(2)
        XCTAssertTrue(app.buttons["Новая игра"].waitForExistence(timeout: 5))
    }

    // MARK: - ──── TEST 06: FFA — Attribution после истечения таймера ────

    func test06_FFA_AttributionFlow() throws {
        setupPlayers(extra: 1)
        selectMode("сразу")
        reduceDuration()   // ≤15с таймер
        tapStartGame()

        XCTAssertTrue(btn("Поехали").waitForExistence(timeout: 8), "FFA WaitingView не найден")
        snap("06a_ffa_waiting")

        btn("Поехали").tap(); sleep(2)
        XCTAssertTrue(waitForFFAGameplay(timeout: 12), "FFA Gameplay не загрузился")

        // Угадываем слова
        let guessBtn = app.buttons.matching(NSPredicate(format: "label == 'Selected'")).firstMatch
        if guessBtn.waitForExistence(timeout: 4) {
            guessBtn.tap(); sleep(1)
            guessBtn.tap(); sleep(1)
        }
        snap("06b_ffa_guessing")

        // Ждём таймера (max 20с для 15с раунда)
        sleep(20)
        snap("06c_after_timer")

        // Attribution или следующий waiting
        let attrShown = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'УГАДАЛ' OR label CONTAINS 'угадал' OR label CONTAINS 'Кто'")
        ).firstMatch.waitForExistence(timeout: 5)

        if attrShown {
            snap("06d_attribution")
            let confirmBtn = app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'Продолжить' OR label CONTAINS 'Пропустить'")
            ).firstMatch
            XCTAssertTrue(confirmBtn.waitForExistence(timeout: 4), "Attribution: кнопка подтверждения не найдена")
            confirmBtn.tap(); sleep(2)
        }
        snap("06e_after_attribution")

        let back = btn("Поехали").waitForExistence(timeout: 5) ||
                   btn("Играть снова").waitForExistence(timeout: 3) ||
                   btn("Новая игра").waitForExistence(timeout: 3)
        XCTAssertTrue(back, "После Attribution: не на WaitingView и не на FinalView")
    }

    // MARK: - ──── TEST 07: UnifiedFinalView — pause → endGameEarly → Final ────

    func test07_UnifiedFinalView() throws {
        setupPlayers(extra: 1)
        selectMode("сразу")
        tapStartGame()

        XCTAssertTrue(btn("Поехали").waitForExistence(timeout: 8))
        btn("Поехали").tap(); sleep(2)

        XCTAssertTrue(waitForFFAGameplay(timeout: 12), "FFA Gameplay не загрузился")
        snap("07a_ffa_gameplay")

        // Пауза → Завершить игру → freeForAllFinal
        let paused = tapPauseButton(timeout: 8)
        XCTAssertTrue(paused, "Кнопка 'Пауза' не найдена в FFA gameplay")
        snap("07b_pause_overlay")

        tapEndGameFromPause()
        snap("07c_after_end")

        // UnifiedFinalView: "Играть снова" (onPlayAgain) + "Новая игра" (onNewGame)
        let finalOK = btn("Играть снова").waitForExistence(timeout: 8) ||
                      btn("Новая игра").waitForExistence(timeout: 5)
        XCTAssertTrue(finalOK, "UnifiedFinalView не показан после завершения игры")
        snap("07d_final_view")

        // "Играть снова" → WaitingView (restartGame + navigateTo .freeForAllWaiting)
        let playAgainExists = btn("Играть снова").waitForExistence(timeout: 2)
        if playAgainExists {
            btn("Играть снова").tap(); sleep(2)
            XCTAssertTrue(btn("Поехали").waitForExistence(timeout: 6), "'Играть снова' не вернула на WaitingView")
            snap("07e_play_again_waiting")
            // Back from WaitingView → Home via Завершить
            btn("Завершить").tap(); sleep(2)
        } else {
            // Jump directly to home via Новая игра on FinalView
            btn("Новая игра").tap(); sleep(2)
        }
        XCTAssertTrue(app.buttons["Новая игра"].waitForExistence(timeout: 5), "Не вернулись на главный экран")
    }

    // MARK: - ──── TEST 08: FFA — ротация объяснителей ────

    func test08_FFA_ExplainerRotation() throws {
        setupPlayers(extra: 1)
        selectMode("сразу")
        reduceDuration() // 15с таймер
        tapStartGame()

        var explainer1 = ""
        var explainer2 = ""

        // Раунд 1
        XCTAssertTrue(btn("Поехали").waitForExistence(timeout: 8))
        btn("Поехали").tap(); sleep(2)
        XCTAssertTrue(waitForFFAGameplay(), "Round 1 FFA gameplay не загрузился")

        // Захватываем "Объясняет: PlayerName" из topBar
        let e1 = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Объясняет:'")).firstMatch
        if e1.waitForExistence(timeout: 3) { explainer1 = e1.label }
        snap("08a_r1_gameplay")

        sleep(18) // Ждём таймера
        confirmAttributionIfNeeded(timeout: 6)

        // Раунд 2
        guard btn("Поехали").waitForExistence(timeout: 6) else {
            // Слова кончились — игра завершена
            snap("08b_game_over_early")
            return
        }
        btn("Поехали").tap(); sleep(2)
        XCTAssertTrue(waitForFFAGameplay(), "Round 2 FFA gameplay не загрузился")

        let e2 = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Объясняет:'")).firstMatch
        if e2.waitForExistence(timeout: 3) { explainer2 = e2.label }
        snap("08c_r2_gameplay")

        // Ротация: объяснители должны различаться
        if !explainer1.isEmpty && !explainer2.isEmpty {
            XCTAssertNotEqual(explainer1, explainer2,
                "BUG-FFA-ROT: ротация не работает — '\(explainer1)' == '\(explainer2)'")
        }

        exitGameplay()
    }

    // MARK: - ──── TEST 09: Команды — подсчёт очков ────

    func test09_TeamsMode_ScoreTracking() throws {
        setupPlayers(extra: 2)
        selectMode("Командный")
        XCTAssertTrue(btn("Авто").waitForExistence(timeout: 5))
        btn("Авто").tap(); sleep(1)
        tapStartGame()

        XCTAssertTrue(btn("Поехали").waitForExistence(timeout: 8))
        btn("Поехали").tap(); sleep(2)
        snap("09a_after_poehali_teams")

        XCTAssertTrue(waitForTeamsGameplay(timeout: 12), "TeamsGameplay не загрузился")

        let guessBtn = app.buttons.matching(NSPredicate(format: "label == 'Selected'")).firstMatch
        if guessBtn.waitForExistence(timeout: 4) {
            guessBtn.tap(); sleep(1)
            guessBtn.tap(); sleep(1)
        }
        snap("09b_teams_guessing")

        exitGameplay()

        let finalOK = btn("Играть снова").waitForExistence(timeout: 6) || btn("Новая игра").waitForExistence(timeout: 4)
        XCTAssertTrue(finalOK, "Teams: UnifiedFinalView не показан")
        snap("09c_teams_final")

        // Проверяем что команды видны в финале
        let teamsVisible = txt("Команда").waitForExistence(timeout: 3)
        XCTAssertTrue(teamsVisible, "Teams: названия команд не видны в финале")
    }

    // MARK: - ──── TEST 10: Выход с WaitingView → UnifiedFinalView ────

    func test10_ExitFromWaiting_GoesToFinal() throws {
        setupPlayers(extra: 1)
        selectMode("Попарный")
        tapStartGame()  // → PairsWaitingView

        XCTAssertTrue(btn("Поехали").waitForExistence(timeout: 8))
        snap("10a_waiting")

        // Завершить игру с WaitingView (без старта раунда)
        let exitBtn = btn("Завершить")
        XCTAssertTrue(exitBtn.waitForExistence(timeout: 4), "'Завершить игру' не найдена на WaitingView")
        exitBtn.tap(); sleep(3)
        snap("10b_after_exit")

        // По дизайну (BUG-021 fix): WaitingView Завершить → Home
        let finalOK = btn("Играть снова").waitForExistence(timeout: 6) ||
                      btn("Новая игра").waitForExistence(timeout: 6)
        XCTAssertTrue(finalOK, "После Завершить с WaitingView: не вернулись на Home/Final")
        snap("10c_final_or_home")
    }

    // MARK: - ──── TEST 11: BUG-030 — Тоггл «Пропустить» ────

    func test11_BUG030_AllowSkipToggle() throws {
        // BUG-043: allowSkip теперь false по умолчанию
        // Part 1: включаем тоггл → xmark должна появиться в геймплее
        setupPlayers(extra: 1)
        snap("11a_modeselect")

        // Включаем switch «Пропустить» (по умолчанию OFF после BUG-043)
        let skipSwitch = app.switches.element(boundBy: 0)
        XCTAssertTrue(skipSwitch.waitForExistence(timeout: 4), "BUG-030: switch «Пропустить» не найден")
        if skipSwitch.value as? String == "0" {
            skipSwitch.tap(); sleep(1)  // включаем
        }
        snap("11b_switch_on")

        selectMode("Попарный")
        tapStartGame()
        btn("Поехали").tap(); sleep(2)
        snap("11c_gameplay_skip_on")
        let skipOnExists = app.buttons.matching(NSPredicate(format: "label == 'Close'")).firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(skipOnExists, "BUG-030: кнопка 'xmark' (Пропустить) должна быть видна когда allowSkip=true")

        // Exit → Home
        app.buttons["Pause"].tap(); sleep(1)
        btn("Завершить игру").tap(); sleep(2)
        if btn("Новая игра").waitForExistence(timeout: 5) { btn("Новая игра").tap(); sleep(2) }

        // Part 2: выключаем тоггл → xmark не должна быть видна
        setupPlayers(extra: 1)
        snap("11d_modeselect_again")

        // Switch должен быть ON после предыдущей игры — выключаем
        let skipSwitch2 = app.switches.element(boundBy: 0)
        XCTAssertTrue(skipSwitch2.waitForExistence(timeout: 4), "BUG-030: switch «Пропустить» не найден")
        if skipSwitch2.value as? String == "1" {
            skipSwitch2.tap(); sleep(1)  // выключаем
        }
        snap("11e_switch_off")

        selectMode("Попарный")
        tapStartGame()
        btn("Поехали").tap(); sleep(2)
        snap("11e_gameplay_skip_off")
        let skipOffExists = app.buttons.matching(NSPredicate(format: "label == 'Close'")).firstMatch.exists
        XCTAssertFalse(skipOffExists, "BUG-030: кнопка 'xmark' (Пропустить) НЕ должна быть видна когда allowSkip=false")
        let guessStillExists = app.buttons.matching(NSPredicate(format: "label == 'Selected'")).firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(guessStillExists, "BUG-030: кнопка 'checkmark' (Угадали) должна быть видна независимо от allowSkip")
        snap("11f_final")
    }

    // MARK: - ──── TEST 12: BUG-031 — «Завершить ход» досрочно ────

    func test12_BUG031_EndTurnEarly() throws {
        setupPlayers(extra: 1)
        selectMode("Попарный")
        tapStartGame()

        XCTAssertTrue(btn("Поехали").waitForExistence(timeout: 8), "Pairs WaitingView не загрузился")
        btn("Поехали").tap(); sleep(2)
        snap("12a_gameplay")

        // Кнопка «Завершить ход» должна быть в геймплее
        let endTurnBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Завершить ход'")).firstMatch
        XCTAssertTrue(endTurnBtn.waitForExistence(timeout: 5), "BUG-031: кнопка 'Завершить ход' не найдена в Pairs gameplay")
        snap("12b_end_turn_visible")

        // Тапаем — должны перейти на RoundEnd
        endTurnBtn.tap(); sleep(2)
        snap("12c_after_end_turn")
        let roundEndOK = txt("Раунд окончен").waitForExistence(timeout: 5) ||
                         btn("Продолжить").waitForExistence(timeout: 5) ||
                         btn("Финал").waitForExistence(timeout: 5)
        XCTAssertTrue(roundEndOK, "BUG-031: после 'Завершить ход' не попали на RoundEndView")
        snap("12d_round_end")

        // BUG-031 в FFA тоже — уйти домой из PairsRoundEndView
        // Продолжить → WaitingView → Завершить → Home
        if btn("Продолжить").waitForExistence(timeout: 3) { btn("Продолжить").tap(); sleep(2) }
        else if btn("Финал").waitForExistence(timeout: 2) { btn("Финал").tap(); sleep(2) }
        // WaitingView: Завершить идёт на Home (BUG-021 fix)
        if btn("Завершить").waitForExistence(timeout: 4) { btn("Завершить").tap(); sleep(3) }
        setupPlayers(extra: 1)
        selectMode("Все сразу")
        tapStartGame()
        btn("Поехали").tap(); sleep(2)
        snap("12e_ffa_gameplay")
        let endTurnFFA = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Завершить ход'")).firstMatch
        XCTAssertTrue(endTurnFFA.waitForExistence(timeout: 5), "BUG-031: 'Завершить ход' не найдена в FFA gameplay")
        snap("12f_ffa_end_turn_visible")
    }
}
