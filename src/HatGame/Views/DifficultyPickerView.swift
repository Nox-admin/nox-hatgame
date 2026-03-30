import SwiftUI

/// Уровень сложности для выбора (включая «свои слова»)
enum DifficultyLevel: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy:   return L10n.Difficulty.easy
        case .medium: return L10n.Difficulty.medium
        case .hard:   return L10n.Difficulty.hard
        case .custom: return String(localized: "difficulty.custom",
                                   defaultValue: "Custom Words")
        }
    }

    var difficultyColor: Color {
        switch self {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .red
        case .custom: return .hatGold
        }
    }

    var symbolName: String {
        switch self {
        case .easy, .medium, .hard: return ""
        case .custom: return "pencil"
        }
    }

    var description: String {
        switch self {
        case .easy:   return String(localized: "difficulty.easy.full_description",  defaultValue: "Simple words: objects, animals, well-known things")
        case .medium: return String(localized: "difficulty.medium.description",      defaultValue: "Mixed words: people, places, concepts")
        case .hard:   return L10n.Difficulty.hardExample
        case .custom: return String(localized: "difficulty.custom.description",      defaultValue: "Players enter their own words")
        }
    }

    /// Маппинг на WordLevel движка (nil для custom)
    var wordLevel: WordLevel? {
        switch self {
        case .easy: return .easy
        case .medium: return .medium
        case .hard: return .hard
        case .custom: return nil
        }
    }
}

/// Экран выбора уровня сложности слов
struct DifficultyPickerView: View {
    @Binding var selectedDifficulty: DifficultyLevel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Выбери уровень слов")
                    .font(.hatH2)
                    .foregroundStyle(Color.hatTextPrimary)
                    .padding(.top, 32)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(DifficultyLevel.allCases) { level in
                            DifficultyCard(
                                level: level,
                                isSelected: selectedDifficulty == level
                            ) {
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedDifficulty = level
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                HatPrimaryButton(title: "Выбрать") {
                    dismiss()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Карточка уровня сложности

private struct DifficultyCard: View {
    let level: DifficultyLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if level == .custom {
                    Image(systemName: "pencil")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.hatGold)
                        .frame(width: 32, height: 32)
                } else {
                    Circle()
                        .fill(level.difficultyColor)
                        .frame(width: 16, height: 16)
                        .frame(width: 32, height: 32)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title)
                        .font(.hatButton)
                        .foregroundStyle(Color.hatTextPrimary)
                    Text(level.description)
                        .font(.hatCaption)
                        .foregroundStyle(Color.hatTextSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.hatGold)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.hatCard : Color.hatSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.hatGold : .clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.3), radius: isSelected ? 8 : 4, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DifficultyPickerView(selectedDifficulty: .constant(.medium))
}
