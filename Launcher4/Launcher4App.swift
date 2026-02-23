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
        cleanMenuBar()
    }
    
    private func configureMainWindow() {
        guard let window = NSApplication.shared.windows.first else { return }
        window.styleMask.insert(.fullSizeContentView)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.center()
        window.makeKeyAndOrderFront(nil)
        // 延迟全屏，确保窗口已显示并为主窗口
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if window.isKeyWindow {
                window.perform(#selector(NSWindow.toggleFullScreen(_:)), with: nil, afterDelay: 0)
            }
        }
    }
    // 清理菜单栏，只保留最简菜单
    private func cleanMenuBar() {
        let mainMenu = NSApplication.shared.mainMenu ?? NSMenu()
        mainMenu.removeAllItems()
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App"
        let appMenu = NSMenuItem()
        appMenu.submenu = NSMenu(title: appName)
        mainMenu.addItem(appMenu)
        NSApplication.shared.mainMenu = mainMenu
    }
}
