import SwiftUI

/// Экран ввода слов игроком (Screen 06)
struct WordInputView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var currentWordText: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.isCurrentPlayerDone {
                    completionView
                } else {
                    inputView
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Input View

    private var inputView: some View {
        VStack(spacing: 24) {
            // Privacy badge
            privacyBadge
                .padding(.top, 16)

            // Player heading
            Text("\(viewModel.currentWordInputPlayer?.name ?? "")\(L10n.Handoff.enterWordsSuffix)")
                .font(.hatH1)
                .foregroundStyle(Color.hatTextPrimary)

            // Progress text — BUG-012: нет фиксированного лимита, показываем сколько добавлено
            let addedCount = viewModel.enteredWordsForCurrentPlayer.count
            Text(addedCount == 0 ? L10n.Words.alreadyAdded : L10n.Round.guessed(addedCount))
                .font(.hatBody)
                .foregroundStyle(addedCount == 0 ? Color.hatTextSecondary : Color.hatGold)

            Spacer()

            // Text field
            VStack(spacing: 16) {
                TextField(L10n.Players.namePlaceholder, text: $currentWordText)
                    .font(.hatH2)
                    .foregroundStyle(Color.hatTextPrimary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.hatCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isTextFieldFocused ? Color.hatGold : Color.clear, lineWidth: 2)
                    )
                    .focused($isTextFieldFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit {
                        submitWord()
                    }

                // Already added words
                if !viewModel.enteredWordsForCurrentPlayer.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Words.alreadyAdded)
                            .font(.hatCaption)
                            .foregroundStyle(Color.hatTextSecondary)

                        // BUG-018: Int.random() в ForEach вызывал краш (нестабильный count на каждый ре-рендер)
                        ForEach(Array(viewModel.enteredWordsForCurrentPlayer.enumerated()), id: \.offset) { idx, _ in
                            HStack(spacing: 6) {
                                // Фиксированное кол-во точек (детерминировано от индекса)
                                ForEach(0..<(5 + (idx % 4)), id: \.self) { _ in
                                    Circle()
                                        .fill(Color.hatTextSecondary.opacity(0.4))
                                        .frame(width: 8, height: 8)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            // Add button
            HatPrimaryButton(title: L10n.Mode.start) {
                submitWord()
            }
            .disabled(currentWordText.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(currentWordText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            .padding(.horizontal, 20)

            // BUG-012: кнопка "Готово" появляется как только добавлено ≥1 слово (нет фиксированного лимита)
            if viewModel.enteredWordsForCurrentPlayer.count >= 1 {
                HatSecondaryButton(title: L10n.Nav.done) {
                    viewModel.isCurrentPlayerDone = true
                }
                .padding(.horizontal, 20)
            }
            Spacer().frame(height: 24)
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Done card
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.hatSuccess)

                Text("\(viewModel.currentWordInputPlayer?.name ?? "")\(L10n.Handoff.readySuffix)")
                    .font(.hatH1)
                    .foregroundStyle(Color.hatTextPrimary)
                    .multilineTextAlignment(.center)

                if !viewModel.isLastPlayer, let nextPlayer = viewModel.nextWordInputPlayer {
                    VStack(spacing: 8) {
                        Text(L10n.Handoff.title)
                            .font(.hatBody)
                            .foregroundStyle(Color.hatTextSecondary)

                        HStack(spacing: 6) {
                            Text(nextPlayer.name)
                                .font(.hatH2)
                                .foregroundStyle(Color.hatGold)
                            Image(systemName: "arrow.down")
                                .font(.hatH2)
                                .foregroundStyle(Color.hatGold)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.hatCard)
                    )
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            // Continue button
            HatPrimaryButton(title: viewModel.isLastPlayer ? L10n.Onboarding.start : L10n.Nav.done) {
                viewModel.moveToNextPlayer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Components

    private var privacyBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "eye.slash.fill")
                .foregroundStyle(Color.hatGold)
            Text(L10n.Handoff.privateScreen)
                .font(.hatCaption)
                .foregroundStyle(Color.hatGold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.hatGold.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.hatGold.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func submitWord() {
        let text = currentWordText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        viewModel.addWord(text)
        currentWordText = ""
        isTextFieldFocused = true
    }
}

#Preview {
    WordInputView(viewModel: GameViewModel())
}
