import SwiftUI

// MARK: - Цвета дизайн-системы

extension Color {
    static let hatBackground = Color(hex: 0x1A1040)
    static let hatCard = Color(hex: 0x2A1F5A)
    static let hatGold = Color(hex: 0xF5C842)
    static let hatWarm = Color(hex: 0xFF7A3D)
    static let hatTextPrimary = Color.white
    static let hatTextSecondary = Color(hex: 0xB8A8D9)
    static let hatSuccess = Color(hex: 0x4ECB71)
    static let hatDanger = Color(hex: 0xFF5252)
    static let hatSurface = Color(hex: 0x352870)

    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Градиенты

extension LinearGradient {
    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x1A1040), Color(hex: 0x3D2580)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let buttonGradient = LinearGradient(
        colors: [Color(hex: 0xF5C842), Color(hex: 0xE8A800)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let timerWarningGradient = LinearGradient(
        colors: [Color(hex: 0xFF5252), Color(hex: 0xFF7A3D)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Типографика (SF Pro Rounded)

extension Font {
    static let hatDisplay = Font.system(size: 48, weight: .bold, design: .rounded)
    static let hatH1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let hatH2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let hatBody = Font.system(size: 17, weight: .regular, design: .rounded)
    static let hatCaption = Font.system(size: 13, weight: .regular, design: .rounded)
    static let hatButton = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let hatTimer = Font.system(size: 64, weight: .heavy, design: .rounded)
}
