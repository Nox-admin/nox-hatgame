import SwiftUI

/// Экран ввода игроков — переиспользуется во всех режимах v2
/// Передаёт финальный список через onContinue callback
struct PlayerSetupView: View {
    @StateObject private var viewModel = PlayerSetupViewModel()

    var onBack: () -> Void = {}
    var onContinue: ([Player]) -> Void = { _ in }

    @State private var editingIndex: Int? = nil
    @State private var emojiPickerIndex: Int? = nil  // показывать пикер для этого индекса
    @FocusState private var focusedIndex: Int?

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                ScrollView {
                    VStack(spacing: 24) {
                        playersList
                        addButton
                        if let error = viewModel.validationError {
                            validationBanner(error)
                        }
                        // Пикер эмодзи — показывается под списком при тапе на аватар
                        if let idx = emojiPickerIndex, viewModel.players.indices.contains(idx) {
                            EmojiPickerView(
                                selected: viewModel.players[idx].emoji,
                                onSelect: { emoji in
                                    viewModel.setEmoji(emoji, at: idx)
                                }
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }

            // Фиксированная кнопка внизу
            VStack {
                Spacer()
                bottomBar
            }
        }
        .navigationBarHidden(true)
        .onChange(of: focusedIndex) { _, newIdx in
            editingIndex = newIdx
            if newIdx == nil { viewModel.validateNames() }
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(L10n.Nav.back)
                }
                .font(.hatBody)
                .foregroundStyle(Color.hatGold)
            }

            Spacer()

            Text(L10n.Nav.players)
                .font(.hatButton)
                .foregroundStyle(Color.hatTextPrimary)

            Spacer()

            // Счётчик
            Text("\(viewModel.players.count)")
                .font(.hatButton)
                .foregroundStyle(Color.hatGold)
                .frame(minWidth: 28)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Список игроков

    private var playersList: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                PlayerInputRow(
                    player: player,
                    index: index,
                    isDuplicate: viewModel.isDuplicateName(at: index),
                    canDelete: viewModel.canRemove(at: index),
                    isFocused: focusedIndex == index,
                    onNameChange: { newName in
                        viewModel.renamePlayer(at: index, to: newName)
                    },
                    onFocusTap: {
                        focusedIndex = index
                        editingIndex = index
                    },
                    onDelete: {
                        if focusedIndex == index { focusedIndex = nil }
                        if emojiPickerIndex == index { emojiPickerIndex = nil }
                        viewModel.removePlayer(at: index)
                    },
                    onAvatarTap: {
                        withAnimation(.spring(duration: 0.3)) {
                            emojiPickerIndex = (emojiPickerIndex == index) ? nil : index
                        }
                    },
                    avatarColor: viewModel.avatarColor(for: index)
                )

                if index < viewModel.players.count - 1 {
                    Divider()
                        .background(Color.hatSurface)
                        .padding(.leading, 72)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.hatCard)
        )
        .animation(.spring(duration: 0.3), value: viewModel.players.count)
    }

    // MARK: - Кнопка добавления

    private var addButton: some View {
        Button {
            viewModel.addPlayer()
            // Фокус на новый элемент
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                focusedIndex = viewModel.players.count - 1
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            Color.hatGold,
                            style: StrokeStyle(lineWidth: 2, dash: [5, 4])
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.hatGold)
                }

                Text(L10n.Players.add)
                    .font(.hatBody)
                    .foregroundStyle(Color.hatGold)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.hatGold.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.hatGold.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Validation banner

    private func validationBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.hatWarm)
            Text(message)
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.hatWarm.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.hatWarm.opacity(0.4), lineWidth: 1)
                )
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 8) {
            // Подсказка о кол-ве игроков
            if viewModel.players.count < viewModel.minPlayers {
                Text(L10n.Players.minRequired(viewModel.minPlayers))
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
            }

            HatPrimaryButton(title: L10n.Nav.next) {
                viewModel.validateNames()
                guard viewModel.canProceed else { return }
                onContinue(viewModel.players)
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

// MARK: - Строка игрока

private struct PlayerInputRow: View {
    let player: Player
    let index: Int
    let isDuplicate: Bool
    let canDelete: Bool
    let isFocused: Bool
    let onNameChange: (String) -> Void
    let onFocusTap: () -> Void
    let onDelete: () -> Void
    let onAvatarTap: () -> Void
    let avatarColor: Color

    @State private var localName: String = ""

    var body: some View {
        HStack(spacing: 14) {
            // Аватар — эмодзи или первая буква; тап открывает пикер
            Button(action: onAvatarTap) {
                PlayerAvatarView(
                    player: player,
                    size: 44,
                    color: avatarColor.opacity(isDuplicate ? 0.4 : 1.0)
                )
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isDuplicate)

            // Поле имени
            TextField(L10n.Players.namePlaceholder, text: $localName)
                .font(.hatBody)
                .foregroundStyle(isDuplicate ? Color.hatDanger : Color.hatTextPrimary)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .onAppear { localName = player.name }
                .onChange(of: localName) { _, new in onNameChange(new) }
                .onChange(of: player.name) { _, new in
                    if new != localName { localName = new }
                }

            // Индикатор дубля
            if isDuplicate {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Color.hatDanger)
                    .font(.system(size: 16))
                    .transition(.scale.combined(with: .opacity))
            }

            // Кнопка удаления
            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.hatDanger.opacity(0.8))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderless)
            } else {
                // Заглушка для выравнивания
                Color.clear.frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: canDelete) {
            if canDelete {
                Button(role: .destructive, action: onDelete) {
                    Label(L10n.Nav.back, systemImage: "trash")
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isDuplicate)
    }
}

#Preview {
    PlayerSetupView(
        onBack: {},
        onContinue: { players in print("Players: \(players.map(\.name))") }
    )
}
