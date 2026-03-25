import SwiftUI

/// Главный экран — точка входа в игру
struct HomeView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var hatOffset: CGFloat = 0
    @State private var showRules = false

    var body: some View {
        ZStack {
            LinearGradient.heroGradient
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Шляпа с анимацией покачивания
                HatIconView(size: 80)
                    .offset(y: hatOffset)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true)
                        ) {
                            hatOffset = -12
                        }
                    }

                // Заголовок
                VStack(spacing: 8) {
                    Text("ШЛЯПА")
                        .font(.hatH1)
                        .foregroundStyle(Color.hatTextPrimary)
                        .tracking(6)

                    Text("Игра в слова для компании")
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                }

                Spacer()

                // Кнопки
                VStack(spacing: 14) {
                    HatPrimaryButton(title: "Новая игра") {
                        viewModel.navigateTo(.playerSetup)
                    }

                    // BUG-020: кнопка "Настройки" убрана с главного экрана по требованию Jack
                    HatSecondaryButton(title: "Правила") {
                        showRules = true
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showRules) {
            RulesSheet()
        }
    }
}

// MARK: - Экран правил

private struct RulesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Правила игры")
                            .font(.hatH1)
                            .foregroundStyle(Color.hatTextPrimary)
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.hatTextSecondary)
                        }
                    }

                    ruleItem("1", "Разделитесь на команды по 2+ игрока.")
                    ruleItem("2", "В шляпу попадают слова выбранной сложности.")
                    ruleItem("3", "Один игрок объясняет слово, остальные угадывают.")
                    ruleItem("4", "За каждое угаданное слово команда получает очко.")
                    ruleItem("5", "Время ограничено — успейте угадать как можно больше!")
                    ruleItem("6", "Побеждает команда с наибольшим количеством очков.")
                }
                .padding(24)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func ruleItem(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.hatH2)
                .foregroundStyle(Color.hatGold)
                .frame(width: 28)
            Text(text)
                .font(.hatBody)
                .foregroundStyle(Color.hatTextPrimary)
        }
    }
}

#Preview {
    HomeView(viewModel: GameViewModel())
}
