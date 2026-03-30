import SwiftUI

/// Экран "Кто угадал?" — матрица угаданных слов × игроки
struct FreeForAllAttributionView: View {
    @ObservedObject var viewModel: FreeForAllGameViewModel

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Заголовок
                header

                // Контент
                if viewModel.attributions.isEmpty {
                    emptyState
                } else {
                    wordList
                }

                // Подтвердить
                confirmButton
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            Text(L10n.Turn.whoGuessed.uppercased())
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
                .tracking(3)
            Text(L10n.Turn.attributed(viewModel.attributions.filter { $0.guesser != nil }.count, viewModel.attributions.count))
                .font(.hatH2)
                .foregroundStyle(Color.hatGold)
            if let explainer = viewModel.currentExplainer {
                Text(L10n.Gameplay.explains(explainer.name))
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
            }
            Text(L10n.Turn.whoGuessed2)
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    // MARK: - Word list

    private var wordList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.attributions) { attribution in
                    WordAttributionRow(
                        attribution: attribution,
                        guessers: viewModel.guessers,
                        onSelect: { player in
                            withAnimation(.spring(duration: 0.25)) {
                                viewModel.setGuesser(player, for: attribution.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(Color.hatTextSecondary)
            Text(L10n.Turn.wordsNotGuessed)
                .font(.hatH2)
                .foregroundStyle(Color.hatTextSecondary)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Confirm button

    private var confirmButton: some View {
        let attributed = viewModel.attributions.filter { $0.guesser != nil }.count
        let total = viewModel.attributions.count
        let allDone = total == 0 || attributed == total

        return VStack(spacing: 8) {
            if !viewModel.attributions.isEmpty {
                Text(L10n.Turn.attributed(attributed, total))
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
            }

            HatPrimaryButton(
                title: allDone ? L10n.Nav.continue_ : L10n.Gameplay.skip
            ) {
                viewModel.confirmAttribution()
            }
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

    // wordEnding removed — replaced by L10n.guessedWordsSuffix
}

// MARK: - WordAttributionRow

private struct WordAttributionRow: View {
    let attribution: WordAttribution
    let guessers: [Player]
    let onSelect: (Player?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Слово
            HStack {
                Text(attribution.text)
                    .font(.hatButton)
                    .foregroundStyle(Color.hatTextPrimary)
                Spacer()
                if attribution.guesser != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.hatSuccess)
                }
            }

            // Выбор угадавшего
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // "Никто" кнопка
                    GuesserChip(
                        label: "Никто",
                        icon: "xmark",
                        isSelected: attribution.guesser == nil,
                        color: .hatDanger
                    ) {
                        onSelect(nil)
                    }

                    // Игроки
                    ForEach(guessers) { player in
                        GuesserChip(
                            label: player.name,
                            icon: nil,
                            isSelected: attribution.guesser?.id == player.id,
                            color: .hatGold
                        ) {
                            onSelect(attribution.guesser?.id == player.id ? nil : player)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(attribution.guesser != nil ? Color.hatCard : Color.hatSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            attribution.guesser != nil ? Color.hatSuccess.opacity(0.4) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        )
    }
}

// MARK: - GuesserChip

private struct GuesserChip: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                }
                Text(label)
                    .font(.hatCaption)
            }
            .foregroundStyle(isSelected ? Color.hatBackground : Color.hatTextPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color.hatSurface)
                    .overlay(
                        Capsule().strokeBorder(isSelected ? color : color.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}

#Preview {
    let players = (1...4).map { Player(name: "Игрок \($0)") }
    let config = GameConfig.freeForAll(players: players, difficulty: .medium, turnDuration: 60, hatSize: 100)
    let vm = FreeForAllGameViewModel(config: config)
    vm.attributions = [
        WordAttribution(id: UUID(), text: "Банан", guesser: nil),
        WordAttribution(id: UUID(), text: "Слон", guesser: players[1]),
        WordAttribution(id: UUID(), text: "Ракета", guesser: nil),
    ]
    return FreeForAllAttributionView(viewModel: vm)
}
