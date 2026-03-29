import SwiftUI
import AudioToolbox

/// Анимированный оверлей 3→2→1→🎩 перед началом хода.
/// Вызывать поверх любого экрана через .overlay или ZStack.
/// Таймер хода не запускать пока onFinish не вызван.
struct CountdownOverlay: View {
    var onFinish: () -> Void

    private let steps: [String] = ["3", "2", "1", "🎩"]
    private let stepDuration: Double = 0.8

    @State private var current: Int = 0
    @State private var scale: CGFloat = 1.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Затемнение фона
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            Text(steps[current])
                .font(.system(size: current == steps.count - 1 ? 96 : 108,
                              weight: .heavy,
                              design: .rounded))
                .foregroundStyle(
                    current == steps.count - 1
                        ? Color.hatGold
                        : Color.hatTextPrimary
                )
                .scaleEffect(scale)
                .opacity(opacity)
                .id(current) // force re-render per step
        }
        .onAppear { showNext() }
    }

    private func showNext() {
        // Появляемся: scale 1.5 → 1.0 + fade in
        scale = 1.5
        opacity = 0
        withAnimation(.easeOut(duration: stepDuration * 0.5)) {
            scale = 1.0
            opacity = 1.0
        }

        // Звук на каждый шаг
        let isHat = current == steps.count - 1
        AudioServicesPlaySystemSound(isHat ? 1057 : 1104)

        // Уходим через stepDuration, потом следующий
        DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * 0.7) {
            withAnimation(.easeIn(duration: stepDuration * 0.3)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * 0.3) {
                if current < steps.count - 1 {
                    current += 1
                    showNext()
                } else {
                    onFinish()
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.hatBackground.ignoresSafeArea()
        CountdownOverlay(onFinish: {})
    }
}
