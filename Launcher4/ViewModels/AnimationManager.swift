import SwiftUI
import Combine

@MainActor
class AnimationManager: ObservableObject {
    @Published var reduceMotion: Bool
    
    let defaultDuration: Double = 0.3
    let springResponse: Double = 0.35
    let springDampingFraction: Double = 0.7
    
    init() {
        self.reduceMotion = false
    }
    
    func standardAnimation(_ animation: Animation) -> Animation {
        return reduceMotion ? .linear(duration: 0) : animation
    }
    
    var springAnimation: Animation {
        reduceMotion ? .linear(duration: 0) : .spring(response: springResponse, dampingFraction: springDampingFraction)
    }
    
    var easeInOut: Animation {
        reduceMotion ? .linear(duration: 0) : .easeInOut(duration: defaultDuration)
    }
    
    var shakeAnimation: Animation {
        reduceMotion ? .linear(duration: 0) : .linear(duration: 0.1).repeatForever(autoreverses: true)
    }
    
    func pageTransitionAnimation(from: Int, to: Int) -> Animation {
        reduceMotion ? .linear(duration: 0) : .easeInOut(duration: 0.25)
    }
    
    func launchAnimation() -> Animation {
        reduceMotion ? .linear(duration: 0) : .spring(response: 0.3, dampingFraction: 0.6)
    }
    
    func updateReduceMotion(_ enabled: Bool) {
        reduceMotion = enabled
    }
}
