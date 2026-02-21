import AppKit

actor GestureManager {
    private(set) var isPinching = false
    private(set) var isSwiping = false
    
    var onPinch: (() -> Void)?
    var onSwipeLeft: (() -> Void)?
    var onSwipeRight: (() -> Void)?
    
    private let pinchThreshold: CGFloat = 0.5
    private let swipeThreshold: CGFloat = 100
    private var startMagnification: CGFloat = 1.0
    
    func handleMagnify(_ magnification: CGFloat, phase: NSEvent.Phase) {
        switch phase {
        case .began:
            startMagnification = magnification
            isPinching = true
        case .changed:
            if magnification < startMagnification - pinchThreshold {
                onPinch?()
                isPinching = false
            }
        case .ended, .cancelled:
            isPinching = false
        default:
            break
        }
    }
    
    func handleSwipe(deltaX: CGFloat, deltaY: CGFloat) {
        if abs(deltaX) > swipeThreshold && abs(deltaX) > abs(deltaY) {
            isSwiping = true
            if deltaX > 0 {
                onSwipeRight?()
            } else {
                onSwipeLeft?()
            }
            isSwiping = false
        }
    }
    
    func setCallbacks(
        onPinch: @escaping () -> Void,
        onSwipeLeft: @escaping () -> Void,
        onSwipeRight: @escaping () -> Void
    ) {
        self.onPinch = onPinch
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
    }
}
