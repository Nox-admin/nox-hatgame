import SwiftUI

/// Главный экран — точка входа в игру
struct HomeView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var hatOffset: CGFloat = 0
    @State private var showRules = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient.heroGradient
                .ignoresSafeArea()

            // Переключатель языка в правом верхнем углу
            // (Settings убраны с главного экрана — BUG-020 — поэтому язык
            //  доступен прямо отсюда)
            LanguagePicker()
                .padding(.top, 8)
                .padding(.trailing, 16)

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
                    Text(L10n.Home.title)
                        .font(.hatH1)
                        .foregroundStyle(Color.hatTextPrimary)
                        .tracking(6)

                    Text(L10n.Home.tagline)
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                }

                Spacer()

                // Кнопки
                VStack(spacing: 14) {
                    HatPrimaryButton(title: L10n.Home.newGame) {
                        viewModel.navigateTo(.playerSetup)
                    }

                    // BUG-020: кнопка "Настройки" убрана с главного экрана по требованию Jack
                    HatSecondaryButton(title: L10n.Home.rules) {
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

// MARK: - Переключатель языка

private struct LanguagePicker: View {
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    languageManager.setLanguage(lang)
                } label: {
                    Text(lang.shortLabel)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(languageManager.currentLanguage == lang
                                         ? Color.hatGold
                                         : Color.hatTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(languageManager.currentLanguage == lang
                                      ? Color.hatGold.opacity(0.25)
                                      : Color.white.opacity(0.08))
                        )
                        .overlay(
                            Circle()
                                .stroke(languageManager.currentLanguage == lang
                                        ? Color.hatGold
                                        : Color.clear,
                                        lineWidth: 2)
                        )
                }
                .accessibilityLabel(lang.displayName)
            }
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
                        Text(L10n.Rules.title)
                            .font(.hatH1)
                            .foregroundStyle(Color.hatTextPrimary)
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.hatTextSecondary)
                        }
                    }

                    ruleItem("1", L10n.Rules.rule1)
                    ruleItem("2", L10n.Rules.rule2)
                    ruleItem("3", L10n.Rules.rule3)
                    ruleItem("4", L10n.Rules.rule4)
                    ruleItem("5", L10n.Rules.rule5)
                    ruleItem("6", L10n.Rules.rule6)
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
