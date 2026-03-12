import SwiftUI

/// Конфетти через Canvas — без внешних зависимостей
struct ConfettiView: View {
    private let particles: [ConfettiParticle]
    private let startDate = Date()

    private static let confettiColors: [Color] = [
        .hatGold, .hatSuccess,
        Color(hex: 0x7B6CF6), Color(hex: 0xFF6B9D),
        Color(hex: 0x4ECDC4), Color(hex: 0xF5A623)
    ]

    init() {
        particles = (0..<140).map { _ in
            ConfettiParticle(
                x: Double.random(in: 0...1),
                startY: Double.random(in: -0.25...0.05),
                vx: Double.random(in: -0.08...0.08),
                vy: Double.random(in: 0.25...0.65),
                size: Double.random(in: 7...15),
                rotation: Double.random(in: 0...360),
                spin: Double.random(in: -2.5...2.5),
                lifetime: Double.random(in: 2.0...3.5),
                color: Self.confettiColors.randomElement()!
            )
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                for particle in particles {
                    guard elapsed < particle.lifetime else { continue }
                    let progress = elapsed / particle.lifetime
                    let x = particle.x * size.width + particle.vx * elapsed * size.width
                    let y = particle.startY * size.height
                        + particle.vy * elapsed * size.height
                        + 0.5 * 280 * elapsed * elapsed
                    let opacity = max(0, 1.0 - progress * 1.2)
                    let angle = CGFloat((particle.rotation + particle.spin * elapsed * 360)
                        .truncatingRemainder(dividingBy: 360)) * .pi / 180

                    var ctx = context
                    ctx.opacity = opacity
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: Angle(radians: Double(angle)))

                    let rect = CGRect(
                        x: -particle.size / 2,
                        y: -particle.size / 4,
                        width: particle.size,
                        height: particle.size / 2
                    )
                    ctx.fill(Path(rect), with: .color(particle.color))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

private struct ConfettiParticle {
    let x, startY, vx, vy, size, rotation, spin, lifetime: Double
    let color: Color
}
