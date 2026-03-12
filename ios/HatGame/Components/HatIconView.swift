import SwiftUI

/// Иконка шляпы нарисованная через SwiftUI-фигуры (замена emoji 🎩 — BUG-013)
struct HatIconView: View {
    var size: CGFloat = 80

    var body: some View {
        VStack(spacing: 0) {
            // Тулья (верхняя часть)
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.06)
                    .fill(LinearGradient.buttonGradient)
                    .frame(width: size * 0.54, height: size * 0.6)

                // Лента
                Rectangle()
                    .fill(Color.hatWarm)
                    .frame(width: size * 0.54, height: size * 0.1)
                    .offset(y: size * 0.2)
            }

            // Поля (brim)
            RoundedRectangle(cornerRadius: size * 0.04)
                .fill(LinearGradient.buttonGradient)
                .frame(width: size, height: size * 0.14)
                .offset(y: -size * 0.02)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HatIconView(size: 120)
        .padding()
        .background(Color.hatBackground)
}
