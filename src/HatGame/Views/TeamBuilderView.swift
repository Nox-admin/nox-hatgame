import SwiftUI

/// Компонент сборки команд для командного режима (встраивается в ModeSelectionView)
struct TeamBuilderView: View {
    @ObservedObject var viewModel: ModeSetupViewModel

    @State private var selectedPlayer: Player? = nil    // выбранный для назначения
    @State private var targetTeamIndex: Int? = nil      // подсвечиваемая команда

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок + кнопки управления
            HStack {
                Text(L10n.Teams.section)
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
                    .tracking(2)

                Spacer()

                // Авторазбивка
                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        viewModel.autoDistribute()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "shuffle")
                        Text(L10n.Nav.done)
                    }
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.hatGold.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
            }

            // Нераспределённые игроки
            if !viewModel.unassignedPlayers.isEmpty {
                unassignedSection
            }

            // Список команд
            ForEach(Array(viewModel.teams.enumerated()), id: \.element.id) { idx, team in
                TeamSlot(
                    draft: team,
                    index: idx,
                    isHighlighted: targetTeamIndex == idx,
                    selectedPlayer: selectedPlayer,
                    canRemoveTeam: viewModel.teams.count > 2,
                    onAssignSelected: {
                        if let player = selectedPlayer {
                            withAnimation(.spring(duration: 0.3)) {
                                viewModel.assignPlayer(player, to: idx)
                                selectedPlayer = nil
                                targetTeamIndex = nil
                            }
                        }
                    },
                    onRemovePlayer: { player in
                        withAnimation(.spring(duration: 0.3)) {
                            viewModel.removePlayerFromTeam(player, teamIndex: idx)
                        }
                    },
                    onRename: { newName in
                        viewModel.renameTeam(at: idx, to: newName)
                    },
                    onRemoveTeam: {
                        withAnimation(.spring(duration: 0.3)) {
                            viewModel.removeTeam(at: idx)
                        }
                    }
                )
                .onHover { hovered in
                    targetTeamIndex = hovered ? idx : nil
                }
            }

            // Добавить команду
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    viewModel.addTeam()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.hatGold)
                    Text(L10n.Teams.add)
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatGold)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.hatGold.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Нераспределённые игроки

    private var unassignedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Teams.unassignedHint)
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.unassignedPlayers) { player in
                        PlayerChip(
                            player: player,
                            isSelected: selectedPlayer?.id == player.id,
                            color: .hatTextSecondary
                        ) {
                            withAnimation(.spring(duration: 0.25)) {
                                selectedPlayer = (selectedPlayer?.id == player.id) ? nil : player
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.hatSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            selectedPlayer != nil ? Color.hatGold.opacity(0.5) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: selectedPlayer?.id)
    }
}

// MARK: - Слот команды

private struct TeamSlot: View {
    let draft: TeamDraft
    let index: Int
    let isHighlighted: Bool
    let selectedPlayer: Player?
    let canRemoveTeam: Bool

    let onAssignSelected: () -> Void
    let onRemovePlayer: (Player) -> Void
    let onRename: (String) -> Void
    let onRemoveTeam: () -> Void

    @State private var editingName = false
    @State private var localName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Шапка команды
            HStack(spacing: 8) {
                // Цветной маркер
                RoundedRectangle(cornerRadius: 3)
                    .fill(teamColor(for: index))
                    .frame(width: 4, height: 20)

                // Имя команды (редактируемое)
                if editingName {
                    TextField(L10n.Teams.add, text: $localName)
                        .font(.hatButton)
                        .foregroundStyle(Color.hatTextPrimary)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            onRename(localName)
                            editingName = false
                        }
                } else {
                    Text(draft.name)
                        .font(.hatButton)
                        .foregroundStyle(Color.hatTextPrimary)
                }

                Spacer()

                // Кол-во игроков в команде
                if !draft.players.isEmpty {
                    Text("\(draft.players.count)")
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.hatSurface))
                }

                // Переименовать
                Button {
                    localName = draft.name
                    editingName.toggle()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.hatTextSecondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.borderless)

                // Удалить команду
                if canRemoveTeam {
                    Button(action: onRemoveTeam) {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.hatDanger.opacity(0.7))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.borderless)
                }
            }

            // Игроки в команде
            if draft.players.isEmpty {
                // Пустое состояние — кнопка назначить
                Button(action: onAssignSelected) {
                    HStack(spacing: 8) {
                        Image(systemName: selectedPlayer != nil ? "plus.circle.fill" : "person.badge.plus")
                            .foregroundStyle(selectedPlayer != nil ? Color.hatGold : Color.hatTextSecondary)
                        Text(selectedPlayer != nil ? "\(selectedPlayer!.name)" : L10n.Teams.unassignedHint)
                            .font(.hatCaption)
                            .foregroundStyle(selectedPlayer != nil ? Color.hatGold : Color.hatTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .disabled(selectedPlayer == nil)
            } else {
                // Чипы игроков
                FlowLayout(spacing: 6) {
                    ForEach(draft.players) { player in
                        PlayerChip(
                            player: player,
                            isSelected: false,
                            color: teamColor(for: index),
                            showRemove: true
                        ) {
                            onRemovePlayer(player)
                        }
                    }

                    // Кнопка добавить ещё (если есть выбранный)
                    if let player = selectedPlayer {
                        Button(action: onAssignSelected) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                Text(player.name)
                                    .font(.hatCaption)
                            }
                            .foregroundStyle(Color.hatGold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .strokeBorder(Color.hatGold, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isHighlighted && selectedPlayer != nil ? Color.hatCard : Color.hatSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isHighlighted && selectedPlayer != nil ? teamColor(for: index).opacity(0.6) : Color.clear,
                    lineWidth: 2
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isHighlighted)
        .onAppear { localName = draft.name }
    }

    private func teamColor(for index: Int) -> Color {
        let colors: [Color] = [.hatGold, .hatWarm, .hatSuccess, Color(hex: 0x7B6CF6),
                               Color(hex: 0x4ECDC4), Color(hex: 0xFF6B9D)]
        return colors[index % colors.count]
    }
}

// MARK: - Чип игрока

struct PlayerChip: View {
    let player: Player
    let isSelected: Bool
    var color: Color = .hatGold
    var showRemove: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                // Аватар
                ZStack {
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 22, height: 22)
                    Text(String(player.name.first ?? "?").uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                }

                Text(player.name)
                    .font(.hatCaption)
                    .foregroundStyle(isSelected ? Color.hatBackground : Color.hatTextPrimary)

                if showRemove {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.hatTextSecondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color.hatCard)
                    .overlay(
                        Capsule().strokeBorder(isSelected ? color : color.opacity(0.4), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}

// MARK: - FlowLayout (чипы переносятся на новую строку)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    let players = (1...6).map { Player(name: "Игрок \($0)") }
    let vm = ModeSetupViewModel(players: players)
    return ScrollView {
        TeamBuilderView(viewModel: vm)
            .padding(20)
    }
    .background(Color.hatBackground)
}
