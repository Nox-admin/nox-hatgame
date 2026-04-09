import AudioToolbox
import Foundation

/// Звуковые эффекты через системные звуки iOS (файлы не нужны)
enum SoundService {
    static func playGuess()     { AudioServicesPlaySystemSound(1057) } // Tink — позитивный
    static func playSkip()      { AudioServicesPlaySystemSound(1105) } // Camera shutter — нейтральный
    static func playTimerTick() { AudioServicesPlaySystemSound(1054) } // Key press — тихий клик
    static func playTimerEnd()  { AudioServicesPlaySystemSound(1005) } // Low power — финальный тон
}
