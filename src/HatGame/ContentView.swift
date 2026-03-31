import SwiftUI

/// Состояния навигации приложения
enum NavigationState: Equatable {
    case home
    case playerSetup   // v2: ввод игроков
    case modeSelection // v2: выбор режима + сборка команд
    case teamSetup     // v1 legacy
    case wordInput
    case waiting
    case gameplay
    case turnEnd
    case results
    case settings
    // Попарный режим
    case pairsWaiting
    case pairsGameplay
    case pairsRoundEnd
    case pairsCircleEnd  // BUG-042
    case pairsFinal
    // Командный режим
    case teamsWaiting
    case teamsGameplay
    case teamsRoundEnd
    case teamsFinal
    // Режим "Все сразу"
    case freeForAllWaiting
    case freeForAllGameplay
    case freeForAllAttribution
    case freeForAllFinal
}

/// Корневое представление с навигацией между экранами
struct ContentView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    @EnvironmentObject private var setupViewModel: TeamSetupViewModel

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    /// BUG-009: отслеживаем фазу приложения чтобы паузить таймер при уходе в фон
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if !hasSeenOnboarding {
                    OnboardingView(isOnboardingDone: $hasSeenOnboarding)
                } else {
                    mainContent
                }
            }
            .animation(.easeInOut, value: gameViewModel.navigationState)
            .animation(.easeInOut, value: hasSeenOnboarding)
        }
        .fullScreenCover(isPresented: $gameViewModel.showPhoneHandoff) {
            PhoneHandoffView(
                playerName: gameViewModel.currentWordInputPlayer?.name ?? "",
                onReady: {
                    gameViewModel.phoneHandoffDone()
                }
            )
        }
        // BUG-009: пауза/возобновление при уходе в фон / звонке / возврате
        .onChange(of: scenePhase) { _, newPhase in
            guard gameViewModel.navigationState == .gameplay
               || gameViewModel.navigationState == .teamsGameplay else { return }
            switch newPhase {
            case .inactive, .background:
                gameViewModel.pauseGameBySystem()
            case .active:
                // Возобновляем только если игра была на паузе из-за фона (не ручная пауза)
                if gameViewModel.isPausedBySystem {
                    gameViewModel.resumeGame()
                }
            @unknown default:
                break
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch gameViewModel.navigationState {
        case .home:
            HomeView(viewModel: gameViewModel)

        case .playerSetup:
            PlayerSetupView(
                onBack: { gameViewModel.navigateTo(.home) },
                onContinue: { players in
                    gameViewModel.pendingPlayers = players
                    gameViewModel.navigateTo(.modeSelection)
                }
            )

        case .modeSelection:
            ModeSelectionView(
                players: gameViewModel.pendingPlayers,
                onBack: { gameViewModel.navigateTo(.playerSetup) },
                onStart: { config in
                    gameViewModel.startGame(with: config)
                }
            )

        case .teamSetup:
            TeamSetupView(
                viewModel: setupViewModel,
                onBack: {
                    gameViewModel.goHome()
                },
                onContinue: {
                    // BUG-012: wordsPerPlayer убран из вызова
                    gameViewModel.setupWordInput(
                        players: setupViewModel.players,
                        turnDuration: setupViewModel.turnDuration,
                        difficulty: setupViewModel.difficulty
                    )
                }
            )

        case .wordInput:
            WordInputView(viewModel: gameViewModel)

        case .waiting:
            WaitingView(viewModel: gameViewModel)

        case .gameplay:
            GameplayView(viewModel: gameViewModel)

        case .turnEnd:
            TurnEndView(viewModel: gameViewModel)

        case .results:
            FinalResultsView(viewModel: gameViewModel)

        case .settings:
            SettingsView(viewModel: gameViewModel)

        case .pairsWaiting:
            if let vm = gameViewModel.pairsViewModel {
                PairsWaitingView(viewModel: vm, onHome: { gameViewModel.goHome() })
                    .onChange(of: vm.phase) { _, phase in
                        switch phase {
                        case .playing: gameViewModel.navigateTo(.pairsGameplay)
                        case .goHome:  gameViewModel.goHome()
                        default: break
                        }
                    }
            }

        case .pairsGameplay:
            if let vm = gameViewModel.pairsViewModel {
                PairsGameplayView(viewModel: vm)
                    .onChange(of: vm.phase) { _, phase in
                        switch phase {
                        case .roundEnd:    gameViewModel.navigateTo(.pairsRoundEnd)
                        case .circleEnd:   gameViewModel.navigateTo(.pairsCircleEnd)
                        case .waiting:     gameViewModel.navigateTo(.pairsWaiting)
                        case .gameOver:    gameViewModel.navigateTo(.pairsFinal)
                        default: break
                        }
                    }
            }

        case .pairsRoundEnd:
            if let vm = gameViewModel.pairsViewModel {
                PairsRoundEndView(viewModel: vm)
                    .onChange(of: vm.phase) { _, phase in
                        switch phase {
                        case .waiting:     gameViewModel.navigateTo(.pairsWaiting)
                        case .circleEnd:   gameViewModel.navigateTo(.pairsCircleEnd)
                        case .gameOver:    gameViewModel.navigateTo(.pairsFinal)
                        default: break
                        }
                    }
            }

        case .pairsCircleEnd:
            if let vm = gameViewModel.pairsViewModel {
                PairsCircleEndView(viewModel: vm)
                    .onChange(of: vm.phase) { _, phase in
                        switch phase {
                        case .waiting:  gameViewModel.navigateTo(.pairsWaiting)
                        case .gameOver: gameViewModel.navigateTo(.pairsFinal)
                        case .goHome:   gameViewModel.goHome()
                        default: break
                        }
                    }
            }

        case .pairsFinal:
            if let vm = gameViewModel.pairsViewModel {
                UnifiedFinalView(
                    result: vm.gameResult,
                    onNewGame: { gameViewModel.goHome() },
                    onPlayAgain: {
                        vm.restartGame()
                        gameViewModel.navigateTo(.pairsWaiting)
                    }
                )
            }

        case .teamsWaiting:
            if let vm = gameViewModel.teamsViewModel {
                TeamsWaitingView(viewModel: vm, onHome: { gameViewModel.goHome() })
                    .onChange(of: vm.navigationPhase) { _, phase in
                        switch phase {
                        case .playing: gameViewModel.navigateTo(.teamsGameplay)
                        case .goHome:  gameViewModel.goHome()
                        default: break
                        }
                    }
            }

        case .teamsGameplay:
            if let vm = gameViewModel.teamsViewModel {
                TeamsGameplayView(viewModel: vm, onHome: { gameViewModel.goHome() })
                    .onChange(of: vm.navigationPhase) { _, phase in
                        switch phase {
                        case .roundEnd:
                            gameViewModel.navigateTo(.teamsRoundEnd)
                        case .gameOver:
                            gameViewModel.navigateTo(.teamsFinal)
                        case .waiting:
                            gameViewModel.navigateTo(.teamsWaiting)
                        default:
                            break
                        }
                    }
            }

        case .teamsRoundEnd:
            if let vm = gameViewModel.teamsViewModel {
                TeamsRoundEndView(viewModel: vm, onHome: { gameViewModel.goHome() })
                    .onChange(of: vm.navigationPhase) { _, phase in
                        switch phase {
                        case .waiting:
                            gameViewModel.navigateTo(.teamsWaiting)
                        case .gameOver:
                            gameViewModel.navigateTo(.teamsFinal)
                        default:
                            break
                        }
                    }
            }

        case .teamsFinal:
            if let vm = gameViewModel.teamsViewModel {
                UnifiedFinalView(
                    result: vm.gameResult,
                    onNewGame: { gameViewModel.goHome() },
                    onPlayAgain: {
                        vm.restartGame()
                        gameViewModel.navigateTo(.teamsWaiting)
                    }
                )
            }

        case .freeForAllWaiting:
            if let vm = gameViewModel.freeForAllViewModel {
                FreeForAllWaitingView(viewModel: vm, onHome: { gameViewModel.goHome() })
                    .onChange(of: vm.phase) { _, phase in
                        switch phase {
                        case .playing: gameViewModel.navigateTo(.freeForAllGameplay)
                        case .goHome:  gameViewModel.goHome()
                        default: break
                        }
                    }
            }

        case .freeForAllGameplay:
            if let vm = gameViewModel.freeForAllViewModel {
                FreeForAllGameplayView(viewModel: vm, onHome: { gameViewModel.goHome() })
                    .onChange(of: vm.phase) { _, phase in
                        switch phase {
                        case .attribution: gameViewModel.navigateTo(.freeForAllAttribution)
                        case .waiting: gameViewModel.navigateTo(.freeForAllWaiting)
                        case .gameOver: gameViewModel.navigateTo(.freeForAllFinal)
                        default: break
                        }
                    }
            }

        case .freeForAllAttribution:
            if let vm = gameViewModel.freeForAllViewModel {
                FreeForAllAttributionView(viewModel: vm)
                    .onChange(of: vm.phase) { _, phase in
                        switch phase {
                        case .waiting: gameViewModel.navigateTo(.freeForAllWaiting)
                        case .gameOver: gameViewModel.navigateTo(.freeForAllFinal)
                        default: break
                        }
                    }
            }

        case .freeForAllFinal:
            if let vm = gameViewModel.freeForAllViewModel {
                UnifiedFinalView(
                    result: vm.gameResult,
                    onNewGame: { gameViewModel.goHome() },
                    onPlayAgain: {
                        vm.restartGame()
                        gameViewModel.navigateTo(.freeForAllWaiting)
                    }
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
