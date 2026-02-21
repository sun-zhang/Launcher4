//
//  KeyboardShortcutManager.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation
import Carbon

/// 键盘快捷键管理器 Actor
actor KeyboardShortcutManager {
    
    // MARK: - Properties
    
    private var isRegistered: Bool = false
    private var currentShortcut: AppSettings.ShortcutKey = .f4
    private var hotKeyRef: EventHotKeyRef?
    private var onShortcutPressed: (@Sendable () -> Void)?
    
    // MARK: - Initialization
    
    init() {
        registerDefaultShortcut()
    }
    
    // MARK: - Public Methods
    
    /// 设置快捷键
    func setShortcut(_ shortcut: AppSettings.ShortcutKey) throws {
        unregisterHotKey()
        currentShortcut = shortcut
        try registerHotKey()
    }
    
    /// 设置快捷键回调
    func setCallback(_ callback: @escaping @Sendable () -> Void) {
        onShortcutPressed = callback
    }
    
    /// 获取当前快捷键
    func getCurrentShortcut() -> AppSettings.ShortcutKey {
        return currentShortcut
    }
    
    /// 检查是否已注册
    func isShortcutRegistered() -> Bool {
        return isRegistered
    }
    
    // MARK: - Private Methods
    
    private func registerDefaultShortcut() {
        do {
            try registerHotKey()
        } catch {
            print("Failed to register default shortcut: \(error)")
        }
    }
    
    private func registerHotKey() throws {
        guard !isRegistered else { return }
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        
        // 安装事件处理器
        let handlerRef = UnsafeMutablePointer<EventHandlerRef?>.allocate(capacity: 1)
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, event, _) -> OSStatus in
                // 通知 Actor 快捷键被按下
                Task {
                    await KeyboardShortcutManager.shared?.handleShortcutPressed()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            handlerRef
        )
        
        guard status == noErr else {
            throw ShortcutError.registrationFailed
        }
        
        // 注册热键
        let keyCode = getkeyCode(for: currentShortcut)
        let modifiers = getModifiers(for: currentShortcut)
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.id = 1
        hotKeyID.signature = OSType(0x4C4E4354) // "LNCT"
        
        let hotKeyRefPtr = UnsafeMutablePointer<EventHotKeyRef?>.allocate(capacity: 1)
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            hotKeyRefPtr
        )
        
        guard registerStatus == noErr else {
            throw ShortcutError.registrationFailed
        }
        
        hotKeyRef = hotKeyRefPtr.pointee
        isRegistered = true
    }
    
    private func unregisterHotKey() {
        guard isRegistered, let ref = hotKeyRef else { return }
        
        UnregisterEventHotKey(ref)
        hotKeyRef = nil
        isRegistered = false
    }
    
    private func handleShortcutPressed() {
        onShortcutPressed?()
    }
    
    private func getkeyCode(for shortcut: AppSettings.ShortcutKey) -> UInt32 {
        switch shortcut {
        case .f4:
            return 0x76 // F4 key code
        case .fnF4:
            return 0x76
        case .custom:
            return 0x76 // Default to F4
        }
    }
    
    private func getModifiers(for shortcut: AppSettings.ShortcutKey) -> UInt32 {
        switch shortcut {
        case .f4:
            return 0
        case .fnF4:
            return UInt32(NX_DEVICELCMDKEYMASK)
        case .custom:
            return 0
        }
    }
    
    // MARK: - Shared Instance
    
    private static var shared: KeyboardShortcutManager?
    
    static func setShared(_ manager: KeyboardShortcutManager) {
        shared = manager
    }
}

// MARK: - Errors

enum ShortcutError: Error, Sendable {
    case registrationFailed
    case invalidShortcut
}
