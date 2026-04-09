import SwiftUI

/// Экран онбординга — 3 слайда с описанием игры
struct OnboardingView: View {
    @Binding var isOnboardingDone: Bool
    @State private var currentPage = 0

    private var slides: [(symbolName: String, title: String, subtitle: String)] {[
        ("theatermasks.fill", L10n.Onboarding.slide1Title, L10n.Onboarding.slide1Subtitle),
        ("bubble.left.and.bubble.right.fill", L10n.Onboarding.slide2Title, L10n.Onboarding.slide2Subtitle),
        ("trophy.fill", L10n.Onboarding.slide3Title, L10n.Onboarding.slide3Subtitle)
    ]}

    var body: some View {
        ZStack {
            LinearGradient.heroGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        isOnboardingDone = true
                    } label: {
                        Text(L10n.Nav.skip)
                            .font(.hatCaption)
                            .foregroundStyle(Color.hatTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 12)

                // Slides
                TabView(selection: $currentPage) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                        slideView(symbolName: slide.symbolName, title: slide.title, subtitle: slide.subtitle)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentPage)

                // Bottom button
                VStack(spacing: 16) {
                    if currentPage == slides.count - 1 {
                        HatPrimaryButton(title: L10n.Onboarding.start) {
                            isOnboardingDone = true
                        }
                    } else {
                        HatPrimaryButton(title: L10n.Nav.next) {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    private func slideView(symbolName: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: symbolName)
                .font(.system(size: 80))
                .foregroundStyle(Color.hatGold)

            VStack(spacing: 12) {
                Text(title)
                    .font(.hatH1)
                    .foregroundStyle(Color.hatTextPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.hatBody)
                    .foregroundStyle(Color.hatTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isOnboardingDone: .constant(false))
}
