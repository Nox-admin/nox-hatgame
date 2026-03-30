import SwiftUI

/// Экран настройки игроков и параметров (Screen 04)
struct TeamSetupView: View {
    @ObservedObject var viewModel: TeamSetupViewModel
    var onBack: () -> Void = {}
    var onContinue: () -> Void = {}

    @State private var selectedDifficulty: DifficultyLevel = .medium

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation bar
                navBar

                ScrollView {
                    VStack(spacing: 24) {
                        // ИГРОКИ section
                        playersSection

                        // ПАРАМЕТРЫ section
                        parametersSection

                        // СЛОВАРЬ section
                        dictionarySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100) // space for bottom button
                }

                // Bottom button
                HatPrimaryButton(title: L10n.Nav.next) {
                    viewModel.difficulty = selectedDifficulty
                    onContinue()
                }
                .disabled(!viewModel.isValid)
                .opacity(viewModel.isValid ? 1 : 0.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            selectedDifficulty = viewModel.difficulty
        }
        .alert(L10n.Final.results, isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button {
                onBack()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(L10n.Nav.back)
                }
                .font(.hatBody)
                .foregroundStyle(Color.hatGold)
            }

            Spacer()

            Text(L10n.Settings.gameSettings)
                .font(.hatButton)
                .foregroundStyle(Color.hatTextPrimary)

            Spacer()

            // Invisible spacer for centering
            Text(L10n.Nav.back)
                .font(.hatBody)
                .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Players Section

    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Teams.playersSection)
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
                .tracking(2)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                    PlayerRow(
                        playerName: player.name,
                        name: Binding(
                            get: { viewModel.players[index].name },
                            set: { viewModel.renamePlayer(at: index, to: $0) }
                        ),
                        isEditing: Binding(
                            get: { viewModel.editingPlayerIndex == index },
                            set: { viewModel.editingPlayerIndex = $0 ? index : nil }
                        ),
                        onDelete: viewModel.players.count > 2 ? {
                            withAnimation {
                                viewModel.removePlayer(at: index)
                            }
                        } : nil
                    )

                    if index < viewModel.players.count - 1 {
                        Divider()
                            .background(Color.hatSurface)
                            .padding(.leading, 60)
                    }
                }

                Divider()
                    .background(Color.hatSurface)
                    .padding(.leading, 60)

                // Add player row
                Button {
                    withAnimation {
                        viewModel.addPlayer()
                    }
                } label: {
                    HStack(spacing: 14) {
                        Circle()
                            .strokeBorder(Color.hatGold, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.hatGold)
                            )

                        Text(L10n.Players.add)
                            .font(.hatBody)
                            .foregroundStyle(Color.hatGold)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.hatCard)
            )
        }
    }

    // MARK: - Parameters Section

    private var parametersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Settings.params)
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
                .tracking(2)

            VStack(spacing: 0) {
                // BUG-012: степпер "Слов на игрока" убран.
                // В классической "Шляпе" все слова идут в общую шляпу — используется весь словарь уровня.

                // Turn duration
                HStack {
                    Text(L10n.Settings.turnTime)
                        .font(.hatBody)
                        .foregroundStyle(Color.hatTextPrimary)

                    Spacer()

                    HStack(spacing: 16) {
                        Button {
                            viewModel.decrementDuration()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(viewModel.turnDurationIndex > 0 ? Color.hatGold : Color.hatSurface)
                        }
                        .disabled(viewModel.turnDurationIndex <= 0)

                        Text("\(viewModel.turnDuration)с")
                            .font(.hatH2)
                            .foregroundStyle(Color.hatGold)
                            .frame(minWidth: 50)

                        Button {
                            viewModel.incrementDuration()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    viewModel.turnDurationIndex < TeamSetupViewModel.allowedDurations.count - 1
                                        ? Color.hatGold : Color.hatSurface
                                )
                        }
                        .disabled(viewModel.turnDurationIndex >= TeamSetupViewModel.allowedDurations.count - 1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.hatCard)
            )
        }
    }

    // MARK: - Dictionary Section

    private var dictionarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Words.section)
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
                .tracking(2)

            NavigationLink {
                DifficultyPickerView(selectedDifficulty: $selectedDifficulty)
            } label: {
                HStack(spacing: 10) {
                    if selectedDifficulty == .custom {
                        Image(systemName: "pencil")
                            .foregroundStyle(Color.hatGold)
                    } else {
                        Circle()
                            .fill(selectedDifficulty.difficultyColor)
                            .frame(width: 14, height: 14)
                    }

                    Text(selectedDifficulty.title)
                        .font(.hatBody)
                        .foregroundStyle(Color.hatTextPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.hatTextSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.hatCard)
                )
            }
        }
    }
}

// MARK: - Player Row

private struct PlayerRow: View {
    let playerName: String
    @Binding var name: String
    @Binding var isEditing: Bool
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            // Avatar — initials instead of emoji
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.hatGold, Color.hatWarm],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Text(String(playerName.first ?? "?").uppercased())
                    .font(.hatButton)
                    .foregroundStyle(.white)
            }

            // Name
            if isEditing {
                TextField(L10n.Players.namePlaceholder, text: $name)
                    .font(.hatBody)
                    .foregroundStyle(Color.hatTextPrimary)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        isEditing = false
                    }
            } else {
                Text(name)
                    .font(.hatBody)
                    .foregroundStyle(Color.hatTextPrimary)
            }

            Spacer()

            // Edit button
            Button {
                isEditing = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.hatTextSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderless)

            // BUG-015: явная кнопка удаления (swipe не всегда заметен)
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.hatDanger)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        // BUG-019: убран .onTapGesture на всю строку — вызывал ghost taps (конфликт с кнопками внутри)
        // Редактирование только через кнопку карандаша
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label(L10n.Nav.back, systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TeamSetupView(viewModel: TeamSetupViewModel())
    }
}
