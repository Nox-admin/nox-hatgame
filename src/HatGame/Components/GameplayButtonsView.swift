import SwiftUI

/// Shared gameplay action buttons — skip / guess
/// "Завершить ход" вынесена за пределы этого компонента (BUG-041)
struct GameplayButtonsView: View {
    var onGuess: () -> Void
    var onSkip: (() -> Void)?    // nil = кнопка скрыта (BUG-030: allowSkip)
    var isDisabled: Bool = false

    var body: some View {
        HStack(spacing: 20) {
            if let onSkip {
                HatGameActionButton(icon: "xmark", color: .hatDanger, action: onSkip)
                    .disabled(isDisabled)
            }
            HatGameActionButton(icon: "checkmark", color: .hatSuccess, action: onGuess)
                .disabled(isDisabled)
        }
        .padding(.horizontal, 20)
    }
}

/// BUG-041: отдельный компонент для кнопки завершения хода —
/// рендерится ВЫШЕ GameplayButtonsView с явным визуальным разрывом
struct EndTurnButton: View {
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(L10n.Gameplay.endEarly)
                .font(.hatCaption)
                .foregroundStyle(Color.hatTextSecondary.opacity(0.7))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
