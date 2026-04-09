import SwiftUI

/// Экран настроек игры
struct SettingsView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Text(L10n.Settings.title)
                .font(.title)
                .fontWeight(.bold)
                .padding()

            Form {
                // Длительность раунда
                Section(L10n.Settings.turnTime) {
                    Picker("sec", selection: $viewModel.settings.roundDuration) {
                        ForEach(GameSettings.availableDurations, id: \.self) { duration in
                            Text(L10n.secFull(duration)).tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Количество слов
                Section(L10n.Settings.hatSize) {
                    Stepper(
                        L10n.scorePoints(viewModel.settings.wordsCount),
                        value: $viewModel.settings.wordsCount,
                        in: 10...100,
                        step: 10
                    )
                }

                // Сложность
                Section(L10n.Settings.difficulty) {
                    Picker(L10n.Difficulty.choose, selection: $viewModel.settings.difficulty) {
                        Text(L10n.Difficulty.all).tag(nil as WordLevel?)
                        ForEach(WordLevel.allCases, id: \.rawValue) { level in
                            Text(level.displayName)
                                .tag(level as WordLevel?)
                        }
                    }
                }

                // Правила пропуска
                Section(L10n.Settings.skipButton) {
                    Toggle(L10n.Settings.skipSubtitle, isOn: $viewModel.settings.allowSkipping)
                }

                // Язык приложения
                Section(L10n.Settings.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            languageManager.setLanguage(lang)
                        } label: {
                            HStack {
                                Text(lang.shortLabel)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .frame(width: 30)
                                Text(lang.displayName)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                if languageManager.currentLanguage == lang {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.hatGold)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }


                }
            }

            // Кнопка назад
            Button {
                viewModel.goHome()
            } label: {
                Text(L10n.Nav.done)
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
