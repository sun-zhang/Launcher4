import AppKit
import SwiftUI
import Combine

@MainActor
class WindowController: ObservableObject {
    @Published var isWindowVisible = false
    @Published var isAnimating = false
    
    private var window: NSWindow?
    
    func configureWindow(_ window: NSWindow) {
        self.window = window
        
        window.styleMask = [.borderless, .fullSizeContentView]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = false
        window.hidesOnDeactivate = true
        
        centerWindow()
    }
    
    func centerWindow() {
        guard let window = window else { return }
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowRect = window.frame
            let x = (screenRect.width - windowRect.width) / 2
            let y = (screenRect.height - windowRect.height) / 2
            window.setFrameOrigin(CGPoint(x: x + screenRect.origin.x, y: y + screenRect.origin.y))
        }
    }
    
    func showWindow() {
        guard let window = window, !isWindowVisible else { return }
        isAnimating = true
        
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        } completionHandler: {
            Task { @MainActor in
                self.isWindowVisible = true
                self.isAnimating = false
            }
        }
    }
    
    func hideWindow() {
        guard let window = window, isWindowVisible else { return }
        isAnimating = true
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: {
            Task { @MainActor in
                window.orderOut(nil)
                self.isWindowVisible = false
                self.isAnimating = false
            }
        }
    }
    
    func toggleWindow() {
        if isWindowVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
}
