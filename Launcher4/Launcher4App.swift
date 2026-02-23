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
        // 注册 KeyboardShortcutManager 为单例
        let shortcutManager = KeyboardShortcutManager()
        KeyboardShortcutManager.setShared(shortcutManager)
        container.register(KeyboardShortcutManager.self, instance: shortcutManager)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMainWindow()
        cleanMenuBar()
        setupGlobalShortcut()
        setupEscKeyToHideWindow()
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
        let mainMenu = NSMenu()
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App"
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: appName)
        // 设置菜单项
        let settingsItem = NSMenuItem(title: "设置...", action: #selector(showPreferences), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        appMenu.addItem(NSMenuItem.separator())
        // 退出菜单项
        let quitItem = NSMenuItem(title: "退出 \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApplication.shared.mainMenu = mainMenu
    }
    // 设置菜单项的回调
    @objc private func showPreferences() {
        // TODO: 实现设置窗口弹出逻辑
    }
    // 注册全局快捷键 F4，按下时显示主窗口
    private func setupGlobalShortcut() {
        let shortcutManager = KeyboardShortcutManager()
        KeyboardShortcutManager.setShared(shortcutManager)
        Task {
            await shortcutManager.setCallback { [weak self] in
                DispatchQueue.main.async {
                    self?.showMainWindow()
                }
            }
        }
    }
    // 监听 ESC 键，按下时隐藏窗口
    private func setupEscKeyToHideWindow() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // 53 = ESC
                NSApplication.shared.hide(nil)
                return nil // 阻止默认行为
            }
            return event
        }
    }
    // 显示主窗口
    private func showMainWindow() {
        guard let window = NSApplication.shared.windows.first else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
