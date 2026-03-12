import SwiftUI

/// Экран настроек игры
struct SettingsView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text("Настройки")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            Form {
                // Длительность раунда
                Section("Время раунда") {
                    Picker("Секунды", selection: $viewModel.settings.roundDuration) {
                        ForEach(GameSettings.availableDurations, id: \.self) { duration in
                            Text("\(duration) сек").tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Количество слов
                Section("Количество слов") {
                    Stepper(
                        "\(viewModel.settings.wordsCount) слов",
                        value: $viewModel.settings.wordsCount,
                        in: 10...100,
                        step: 10
                    )
                }

                // Сложность
                Section("Сложность") {
                    Picker("Уровень", selection: $viewModel.settings.difficulty) {
                        Text("Все уровни (микс)").tag(nil as WordLevel?)
                        ForEach(WordLevel.allCases, id: \.rawValue) { level in
                            Text(level.displayName)
                                .tag(level as WordLevel?)
                        }
                    }
                }

                // Правила пропуска
                Section("Правила") {
                    Toggle("Разрешить пропуск слов", isOn: $viewModel.settings.allowSkipping)
                    if viewModel.settings.allowSkipping {
                        Toggle("Штраф за пропуск (-1 очко)", isOn: $viewModel.settings.penaltyForSkip)
                    }
                }
            }

            // Кнопка назад
            Button {
                viewModel.goHome()
            } label: {
                Text("Готово")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding()
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    SettingsView(viewModel: GameViewModel())
}
