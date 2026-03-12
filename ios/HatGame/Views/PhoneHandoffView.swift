import SwiftUI

/// Экран передачи телефона следующему игроку (Screen 14)
/// Представляется как fullScreenCover
struct PhoneHandoffView: View {
    let playerName: String
    let onReady: () -> Void

    @State private var showButton = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Пульсирующая иконка
                ZStack {
                    Circle()
                        .fill(Color.hatGold.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulse ? 1.2 : 1.0)
                        .opacity(pulse ? 0 : 0.6)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false), value: pulse)

                    Circle()
                        .fill(Color.hatGold.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(Color.hatGold)
                }

                VStack(spacing: 16) {
                    Text("ЗАКРОЙ ГЛАЗА")
                        .font(.hatDisplay)
                        .foregroundStyle(Color.hatTextPrimary)
                        .tracking(4)

                    Text("Передай телефон игроку")
                        .font(.hatH2)
                        .foregroundStyle(Color.hatTextSecondary)

                    Text(playerName)
                        .font(.hatH1)
                        .foregroundStyle(Color.hatGold)
                }

                Spacer()

                // Кнопка появляется через 2 секунды
                if showButton {
                    HatPrimaryButton(title: "Готов") { onReady() }
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Color.clear.frame(height: 56) // placeholder
                }

                Spacer(minLength: 34)
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            pulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(duration: 0.5)) { showButton = true }
            }
        }
    }
}

#Preview {
    PhoneHandoffView(playerName: "Игрок 2") {}
}
