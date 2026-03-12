import SwiftUI

/// Экран окончания хода — результаты с возможностью коррекции (Screen 09)
struct TurnEndView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Ход окончен!")
                        .font(.hatH1)
                        .foregroundStyle(Color.hatTextPrimary)

                    // BUG-006 fix: нейтральная формулировка без захардкоженного рода
                    HStack(spacing: 0) {
                        Text("\(viewModel.currentExplainerName): ")
                            .font(.hatBody)
                            .foregroundStyle(Color.hatTextSecondary)

                        Text("\(viewModel.turnGuessedCount)")
                            .font(.hatH2)
                            .foregroundStyle(Color.hatGold)

                        Text(" угаданных слов")
                            .font(.hatBody)
                            .foregroundStyle(Color.hatTextSecondary)
                    }
                }
                .padding(.top, 24)

                // Word results list
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(viewModel.turnResults.enumerated()), id: \.element.id) { index, result in
                            Button {
                                withAnimation(.spring(duration: 0.3)) {
                                    viewModel.toggleTurnResult(at: index)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: result.guessed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(result.guessed ? Color.hatSuccess : Color.hatDanger)

                                    Text(result.text)
                                        .font(.hatBody)
                                        .foregroundStyle(result.guessed
                                            ? Color.hatTextPrimary
                                            : Color.hatTextSecondary)
                                        .strikethrough(!result.guessed, color: Color.hatTextSecondary.opacity(0.5))

                                    Spacer()
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.hatCard)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Hint
                Text("Нажми на слово, чтобы исправить")
                    .font(.hatCaption)
                    .foregroundStyle(Color(hex: 0x4A3A80))

                // Continue button
                HatPrimaryButton(title: "Продолжить →") {
                    viewModel.confirmTurnResults()
                }
                .padding(.horizontal, 20)

                // BUG-016: выход на главную
                Button {
                    viewModel.goHome()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "house")
                        Text("На главную")
                    }
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    TurnEndView(viewModel: GameViewModel())
}
