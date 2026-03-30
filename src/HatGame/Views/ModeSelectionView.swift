import SwiftUI

/// Экран выбора режима игры + настройки + сборка команд для командного режима
struct ModeSelectionView: View {
    @StateObject private var viewModel: ModeSetupViewModel

    var onBack: () -> Void = {}
    var onStart: (GameConfig) -> Void = { _ in }

    init(players: [Player], onBack: @escaping () -> Void, onStart: @escaping (GameConfig) -> Void) {
        _viewModel = StateObject(wrappedValue: ModeSetupViewModel(players: players))
        self.onBack = onBack
        self.onStart = onStart
    }

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                ScrollView {
                    VStack(spacing: 24) {
                        // Выбор режима
                        modeSection

                        // Командный режим — сборка команд
                        if viewModel.selectedMode == .teams {
                            TeamBuilderView(viewModel: viewModel)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Настройки игры
                        settingsSection

                        // Сообщение валидации
                        if let msg = viewModel.validationMessage {
                            validationNote(msg)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                    .animation(.spring(duration: 0.4), value: viewModel.selectedMode)
                }
            }

            // Фиксированная кнопка
            VStack {
                Spacer()
                startButton
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(L10n.Nav.players)
                }
                .font(.hatBody)
                .foregroundStyle(Color.hatGold)
            }
            Spacer()
            Text(L10n.Mode.title)
                .font(.hatButton)
                .foregroundStyle(Color.hatTextPrimary)
            Spacer()
            // Счётчик игроков
            HStack(spacing: 4) {
                Image(systemName: "person.fill")
                    .font(.caption)
                Text("\(viewModel.players.count)")
            }
            .font(.hatCaption)
            .foregroundStyle(Color.hatTextSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Выбор режима

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Mode.section)
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
                .tracking(2)

            VStack(spacing: 10) {
                ForEach(GameMode.allCases) { mode in
                    ModeCard(
                        mode: mode,
                        isSelected: viewModel.selectedMode == mode,
                        isAvailable: viewModel.players.count >= mode.minPlayers
                    ) {
                        withAnimation(.spring(duration: 0.3)) {
                            viewModel.selectedMode = mode
                            if mode == .teams { viewModel.resetTeams() }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Настройки

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Settings.section)
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
                .tracking(2)

            VStack(spacing: 0) {
                // Сложность
                NavigationLink {
                    DifficultyPickerView(selectedDifficulty: $viewModel.difficulty)
                } label: {
                    HStack {
                        Text(L10n.Settings.difficulty)
                            .font(.hatBody)
                            .foregroundStyle(Color.hatTextPrimary)
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(viewModel.difficulty.difficultyColor)
                                .frame(width: 10, height: 10)
                            Text(viewModel.difficulty.title)
                                .font(.hatBody)
                                .foregroundStyle(Color.hatTextSecondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.hatTextSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }

                Divider().background(Color.hatSurface)

                // Время хода
                HStack {
                    Text(L10n.Settings.turnTime)
                        .font(.hatBody)
                        .foregroundStyle(Color.hatTextPrimary)
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            if viewModel.turnDurationIndex > 0 { viewModel.turnDurationIndex -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(viewModel.turnDurationIndex > 0 ? Color.hatGold : Color.hatSurface)
                        }
                        .buttonStyle(.borderless)
                        .disabled(viewModel.turnDurationIndex <= 0)

                        Text("\(viewModel.turnDuration)с")
                            .font(.hatH2)
                            .foregroundStyle(Color.hatGold)
                            .frame(minWidth: 48)

                        Button {
                            let max = ModeSetupViewModel.allowedDurations.count - 1
                            if viewModel.turnDurationIndex < max { viewModel.turnDurationIndex += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(viewModel.turnDurationIndex < ModeSetupViewModel.allowedDurations.count - 1 ? Color.hatGold : Color.hatSurface)
                        }
                        .buttonStyle(.borderless)
                        .disabled(viewModel.turnDurationIndex >= ModeSetupViewModel.allowedDurations.count - 1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider().background(Color.hatSurface)

                // TASK-027: Слов в шляпе
                HStack {
                    Text(L10n.Settings.hatSize)
                        .font(.hatBody)
                        .foregroundStyle(Color.hatTextPrimary)
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            if viewModel.hatSizeIndex > 0 { viewModel.hatSizeIndex -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(viewModel.hatSizeIndex > 0 ? Color.hatGold : Color.hatSurface)
                        }
                        .buttonStyle(.borderless)
                        .disabled(viewModel.hatSizeIndex <= 0)

                        Text("\(viewModel.hatSize)")
                            .font(.hatH2)
                            .foregroundStyle(Color.hatGold)
                            .frame(minWidth: 48)

                        Button {
                            let max = ModeSetupViewModel.allowedHatSizes.count - 1
                            if viewModel.hatSizeIndex < max { viewModel.hatSizeIndex += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(viewModel.hatSizeIndex < ModeSetupViewModel.allowedHatSizes.count - 1 ? Color.hatGold : Color.hatSurface)
                        }
                        .buttonStyle(.borderless)
                        .disabled(viewModel.hatSizeIndex >= ModeSetupViewModel.allowedHatSizes.count - 1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider().background(Color.hatSurface)

                // BUG-030: Тоггл "Пропустить"
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.Settings.skipButton)
                            .font(.hatBody)
                            .foregroundStyle(Color.hatTextPrimary)
                        Text(L10n.Settings.skipSubtitle)
                            .font(.hatCaption)
                            .foregroundStyle(Color.hatTextSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.allowSkip)
                        .labelsHidden()
                        .tint(Color.hatGold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.hatCard)
            )
        }
    }

    // MARK: - Validation note

    private func validationNote(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.hatGold)
            Text(message)
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.hatGold.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.hatGold.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Start button

    private var startButton: some View {
        VStack(spacing: 6) {
            HatPrimaryButton(title: L10n.Mode.start) {
                onStart(viewModel.buildConfig())
            }
            .disabled(!viewModel.canProceed)
            .opacity(viewModel.canProceed ? 1 : 0.5)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .padding(.top, 12)
        .background(
            Color.hatBackground
                .shadow(color: .black.opacity(0.3), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Карточка режима

private struct ModeCard: View {
    let mode: GameMode
    let isSelected: Bool
    let isAvailable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Иконка режима
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.hatGold : Color.hatSurface)
                        .frame(width: 48, height: 48)
                    Image(systemName: mode.symbolName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.hatBackground : (isAvailable ? Color.hatTextPrimary : Color.hatSurface))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.localizedTitle)
                        .font(.hatButton)
                        .foregroundStyle(isAvailable ? Color.hatTextPrimary : Color.hatTextSecondary)
                    Text(mode.localizedDescription)
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    if !isAvailable {
                        Text("Нужно минимум \(mode.minPlayers) игроков")
                            .font(.hatCaption)
                            .foregroundStyle(Color.hatDanger.opacity(0.8))
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.hatGold)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.hatCard : Color.hatSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.hatGold : .clear, lineWidth: 2)
            )
            .opacity(isAvailable ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
    }
}

#Preview {
    let players = (1...4).map { Player(name: "Игрок \($0)") }
    return NavigationStack {
        ModeSelectionView(players: players, onBack: {}, onStart: { _ in })
    }
}
