import SwiftUI

// MARK: - Основная кнопка (золотой градиент)

struct HatPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.hatButton)
                .foregroundStyle(Color.hatBackground)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient.buttonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.hatGold.opacity(0.4), radius: 8, y: 4)
        }
    }
}

// MARK: - Вторичная кнопка (обводка)

struct HatSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.hatButton)
                .foregroundStyle(Color.hatTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.hatSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.hatGold, lineWidth: 1)
                )
        }
    }
}

// MARK: - Круглая игровая кнопка (72pt)

struct HatGameActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    private let generator = UIImpactFeedbackGenerator(style: .heavy)

    var body: some View {
        Button {
            generator.impactOccurred()
            action()
        } label: {
            // BUG-039: Image(systemName:) вместо Text — иначе "xmark"/"checkmark" рендерится как текст
            Image(systemName: icon)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.4), radius: 8, y: 4)
        }
    }
}

#Preview {
    ZStack {
        Color.hatBackground.ignoresSafeArea()
        VStack(spacing: 20) {
            HatPrimaryButton(title: "Новая игра") {}
            HatSecondaryButton(title: "Правила") {}
            HStack(spacing: 40) {
                HatGameActionButton(icon: "xmark", color: .hatDanger) {}
                HatGameActionButton(icon: "checkmark", color: .hatSuccess) {}
            }
        }
        .padding()
    }
}
