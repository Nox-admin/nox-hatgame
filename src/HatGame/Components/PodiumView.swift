import SwiftUI
import AudioToolbox

/// Анимированный пьедестал: 3-е → 2-е → 1-е место с паузами и конфетти.
/// Использует staged reveal с задержкой между местами.
struct PodiumView: View {

    struct Entry: Identifiable {
        let id = UUID()
        let rank: Int
        let name: String
        let score: Int
        let avatar: String?
    }

    let entries: [Entry]          // передать отсортированные standings (1-е место первым)
    var onFinish: () -> Void = {} // вызывается когда анимация завершена

    // Сколько мест показываем на пьедестале (не больше 3 и не больше entries.count)
    private var podiumCount: Int { min(3, entries.count) }

    // Порядок появления: 3-е → 2-е → 1-е
    private var revealOrder: [Int] {
        // Для 1 игрока — сразу первый; для 2 — 2-й затем 1-й; для 3+ — 3-й, 2-й, 1-й
        switch podiumCount {
        case 1: return [0]
        case 2: return [1, 0]
        default: return [2, 1, 0]
        }
    }

    @State private var revealedCount: Int = 0
    @State private var showConfetti: Bool = false
    @State private var scaleEffect: [Bool]

    init(entries: [Entry], onFinish: @escaping () -> Void = {}) {
        self.entries = entries
        self.onFinish = onFinish
        _scaleEffect = State(initialValue: Array(repeating: false, count: entries.count))
    }

    var body: some View {
        ZStack {
            Color.hatBackground.ignoresSafeArea()

            // Конфетти — поверх всего
            if showConfetti {
                ConfettiView().ignoresSafeArea().allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                Spacer()

                // Подпись
                Text(L10n.Final.podium)
                    .font(.hatCaption)
                    .foregroundStyle(Color.hatTextSecondary)
                    .tracking(3)
                    .padding(.bottom, 32)

                // Пьедестал
                HStack(alignment: .bottom, spacing: 16) {
                    // Порядок колонок на экране: 3-е | 1-е | 2-е (визуальный пьедестал)
                    if podiumCount >= 3, let third = entryAt(rank: 3) {
                        podiumColumn(entry: third, podiumHeight: 80, shown: revealedCount >= (podiumCount == 3 ? 1 : 0))
                    }
                    if podiumCount >= 1, let first = entryAt(rank: 1) {
                        podiumColumn(entry: first, podiumHeight: 140, shown: revealedCount >= podiumCount)
                    }
                    if podiumCount >= 2, let second = entryAt(rank: 2) {
                        podiumColumn(entry: second, podiumHeight: 110, shown: revealedCount >= (podiumCount >= 2 ? podiumCount - 1 : 0))
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Кнопка — появляется после финального reveal
                if revealedCount >= podiumCount {
                    Button(action: onFinish) {
                        Text(L10n.Nav.continue_)
                            .font(.hatButton)
                            .foregroundStyle(Color.hatBackground)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.hatGold)
                            )
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 48)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { startReveal() }
    }

    // MARK: - Колонка пьедестала

    @ViewBuilder
    private func podiumColumn(entry: Entry, podiumHeight: CGFloat, shown: Bool) -> some View {
        VStack(spacing: 8) {
            // Аватар + медаль
            if shown {
                VStack(spacing: 4) {
                    // Эмодзи-аватар
                    if let emoji = entry.avatar {
                        Text(emoji)
                            .font(.system(size: entry.rank == 1 ? 48 : 36))
                    } else {
                        ZStack {
                            Circle()
                                .fill(medalColor(entry.rank))
                                .frame(width: entry.rank == 1 ? 64 : 52,
                                       height: entry.rank == 1 ? 64 : 52)
                            Text(String(entry.name.prefix(1)).uppercased())
                                .font(.system(size: entry.rank == 1 ? 26 : 20,
                                              weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }

                    // Медаль
                    Text(medalEmoji(entry.rank))
                        .font(.system(size: entry.rank == 1 ? 26 : 20))

                    // Имя
                    Text(entry.name)
                        .font(.system(size: entry.rank == 1 ? 15 : 13,
                                      weight: .bold, design: .rounded))
                        .foregroundStyle(entry.rank == 1 ? Color.hatGold : Color.hatTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: entry.rank == 1 ? 100 : 80)

                    // Очки
                    Text("\(entry.score)")
                        .font(.system(size: entry.rank == 1 ? 18 : 15,
                                      weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.hatGold)
                }
                .transition(.scale(scale: 0.3).combined(with: .opacity))
            } else {
                // Заглушка чтобы колонки не прыгали
                Color.clear
                    .frame(width: entry.rank == 1 ? 100 : 80,
                           height: entry.rank == 1 ? 140 : 110)
            }

            // Тумба
            RoundedRectangle(cornerRadius: 8)
                .fill(shown ? medalColor(entry.rank).opacity(0.35) : Color.hatSurface.opacity(0.15))
                .frame(width: entry.rank == 1 ? 100 : 80, height: podiumHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            shown ? medalColor(entry.rank).opacity(0.6) : Color.clear,
                            lineWidth: 1.5
                        )
                )
                .overlay(
                    Text("#\(entry.rank)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(shown ? medalColor(entry.rank) : Color.hatSurface)
                        .padding(.top, 10),
                    alignment: .top
                )
        }
        .animation(.spring(duration: 0.55, bounce: 0.35), value: shown)
    }

    // MARK: - Animation sequence

    private func startReveal() {
        // Показываем места поочерёдно: 3-е, 2-е, 1-е — с интервалом 0.8с
        for (step, _) in revealOrder.enumerated() {
            let delay = Double(step) * 0.8
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.4) {
                withAnimation {
                    revealedCount = step + 1
                }
                // Звук на каждый шаг
                AudioServicesPlaySystemSound(step == revealOrder.count - 1 ? 1057 : 1104)
                // Конфетти на 1-е место
                if step == revealOrder.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showConfetti = true
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func entryAt(rank: Int) -> Entry? {
        entries.first { $0.rank == rank }
    }

    private func medalColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color.hatGold
        case 2: return Color(hex: 0xC0C0C0)
        case 3: return Color(hex: 0xCD7F32)
        default: return Color.hatSurface
        }
    }

    private func medalEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
}

#Preview {
    let entries = [
        PodiumView.Entry(rank: 1, name: "Анна", score: 14, avatar: "🦊"),
        PodiumView.Entry(rank: 2, name: "Борис", score: 11, avatar: "🐸"),
        PodiumView.Entry(rank: 3, name: "Вика", score: 8, avatar: "🎩"),
    ]
    return PodiumView(entries: entries, onFinish: {})
}
