//
//  Launcher4App.swift
//  Launcher4
//
//  Created by Sam Zhang on 2026/2/21.
//

import SwiftUI

@main
struct Launcher4App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            LaunchpadView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 800, height: 600)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        setupDependencyInjection()
    }
    
    private func setupDependencyInjection() {
        let container = DIContainer.shared
        
        container.register(ApplicationScannerProtocol.self, scope: .singleton) { _ in
            ApplicationScanner()
        }
        container.register(FolderManagerProtocol.self, scope: .singleton) { _ in
            FolderManager()
        }
        container.register(SettingsManagerProtocol.self, scope: .singleton) { _ in
            SettingsManager()
        }
        container.register(IconCacheProtocol.self, scope: .singleton) { _ in
            IconCache()
        }
        container.register(LauncherStateManagerProtocol.self, scope: .singleton) { _ in
            LauncherStateManager()
        }
        container.register(EventBusProtocol.self, scope: .singleton) { _ in
            EventBus()
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMainWindow()
    }
    
    private func configureMainWindow() {
        guard let window = NSApplication.shared.windows.first else { return }
        window.styleMask.insert(.borderless)
        window.styleMask.insert(.fullSizeContentView)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.center()
        // 自动全屏
        DispatchQueue.main.async {
            window.toggleFullScreen(nil)
        }
    }
}
