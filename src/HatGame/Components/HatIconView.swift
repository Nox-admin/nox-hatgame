import SwiftUI

/// Иконка шляпы — логотип из Assets (замена emoji 🎩 — BUG-013)
struct HatIconView: View {
    var size: CGFloat = 80

    var body: some View {
        Image(.hatLogo)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

#Preview {
    HatIconView(size: 120)
        .padding()
        .background(Color.hatBackground)
}
