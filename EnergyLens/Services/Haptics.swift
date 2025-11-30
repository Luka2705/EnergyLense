import UIKit

final class Haptics {
    static let shared = Haptics()
    
    private init() {}
    
    enum HapticType {
        case success
        case error
        case light
    }
    
    func play(_ type: HapticType) {
        switch type {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}
