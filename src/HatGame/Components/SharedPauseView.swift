import SwiftUI

/// Unified pause overlay for all three game modes
struct SharedPauseView: View {
    var onResume: () -> Void
    var onEndGame: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.hatGold)
                Text(L10n.Gameplay.pause)
                    .font(.hatH1)
                    .foregroundStyle(Color.hatTextPrimary)
                HatPrimaryButton(title: L10n.Gameplay.resume, action: onResume)
                Button(action: onEndGame) {
                    HStack(spacing: 6) {
                        Image(systemName: "flag.checkered")
                        Text(L10n.Waiting.endGame)
                    }
                    .font(.hatBody)
                    .foregroundStyle(Color.hatDanger)
                }
                .buttonStyle(.plain)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.thinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.hatGold.opacity(0.3), lineWidth: 1))
            )
            .padding(.horizontal, 32)
        }
    }
}
