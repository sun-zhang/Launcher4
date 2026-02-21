//
//  ContextMenuManager.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation
import AppKit

/// 上下文菜单管理器
@MainActor
class ContextMenuManager {
    
    // MARK: - Properties
    
    private let folderManager: FolderManager
    private let eventBus: EventBus
    
    // MARK: - Initialization
    
    init(folderManager: FolderManager, eventBus: EventBus) {
        self.folderManager = folderManager
        self.eventBus = eventBus
    }
    
    // MARK: - Public Methods
    
    /// 创建应用上下文菜单
    func createAppMenu(for app: ApplicationInfo, isEditing: Bool) -> NSMenu {
        let menu = NSMenu()
        
        // 打开
        let openItem = NSMenuItem(title: NSLocalizedString("action.open", comment: ""), action: #selector(openApp(_:)), keyEquivalent: "")
        openItem.representedObject = app
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 在 Finder 中显示
        let showInFinderItem = NSMenuItem(title: NSLocalizedString("action.showInFinder", comment: ""), action: #selector(showInFinder(_:)), keyEquivalent: "")
        showInFinderItem.representedObject = app
        menu.addItem(showInFinderItem)
        
        // 获取信息
        let getInfoItem = NSMenuItem(title: NSLocalizedString("action.getInfo", comment: ""), action: #selector(getInfo(_:)), keyEquivalent: "i")
        getInfoItem.representedObject = app
        menu.addItem(getInfoItem)
        
        // 编辑模式下显示删除选项
        if isEditing && app.canBeDeleted {
            menu.addItem(NSMenuItem.separator())
            
            let deleteItem = NSMenuItem(title: NSLocalizedString("action.delete", comment: ""), action: #selector(deleteApp(_:)), keyEquivalent: "")
            deleteItem.representedObject = app
            deleteItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
            menu.addItem(deleteItem)
        }
        
        return menu
    }
    
    /// 创建文件夹上下文菜单
    func createFolderMenu(for folder: FolderInfo) -> NSMenu {
        let menu = NSMenu()
        
        // 打开文件夹
        let openItem = NSMenuItem(title: NSLocalizedString("action.open", comment: ""), action: #selector(openFolder(_:)), keyEquivalent: "")
        openItem.representedObject = folder
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 重命名
        let renameItem = NSMenuItem(title: NSLocalizedString("folder.rename", comment: ""), action: #selector(renameFolder(_:)), keyEquivalent: "")
        renameItem.representedObject = folder
        menu.addItem(renameItem)
        
        // 删除
        let deleteItem = NSMenuItem(title: NSLocalizedString("folder.delete", comment: ""), action: #selector(deleteFolder(_:)), keyEquivalent: "")
        deleteItem.representedObject = folder
        deleteItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
        menu.addItem(deleteItem)
        
        return menu
    }
    
    /// 创建空白区域上下文菜单
    func createEmptySpaceMenu() -> NSMenu {
        let menu = NSMenu()
        
        // 刷新
        let refreshItem = NSMenuItem(title: NSLocalizedString("empty.refresh", comment: ""), action: #selector(refreshApps(_:)), keyEquivalent: "r")
        menu.addItem(refreshItem)
        
        return menu
    }
    
    // MARK: - Menu Actions
    
    @objc private func openApp(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? ApplicationInfo else { return }
        Task {
            let config = NSWorkspace.OpenConfiguration()
            try? await NSWorkspace.shared.openApplication(at: app.bundleURL, configuration: config)
        }
    }
    
    @objc private func showInFinder(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? ApplicationInfo else { return }
        NSWorkspace.shared.activateFileViewerSelecting([app.bundleURL])
    }
    
    @objc private func getInfo(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? ApplicationInfo else { return }
        NSWorkspace.shared.activateFileViewerSelecting([app.bundleURL])
        // 显示信息窗口通过 AppleScript
        let script = """
        tell application "Finder"
            open information window of (POSIX file "\(app.bundleURL.path)" as alias)
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
    }
    
    @objc private func deleteApp(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? ApplicationInfo else { return }
        Task {
            try? FileManager.default.trashItem(at: app.bundleURL, resultingItemURL: nil)
            eventBus.publishApplicationRemoved(app.bundleIdentifier)
        }
    }
    
    @objc private func openFolder(_ sender: NSMenuItem) {
        guard let folder = sender.representedObject as? FolderInfo else { return }
        // 通知 UI 展开文件夹
        NotificationCenter.default.post(name: .openFolder, object: folder.id)
    }
    
    @objc private func renameFolder(_ sender: NSMenuItem) {
        guard let folder = sender.representedObject as? FolderInfo else { return }
        // 通知 UI 开始重命名
        NotificationCenter.default.post(name: .renameFolder, object: folder.id)
    }
    
    @objc private func deleteFolder(_ sender: NSMenuItem) {
        guard let folder = sender.representedObject as? FolderInfo else { return }
        Task {
            try? await folderManager.deleteFolder(folderId: folder.id)
        }
    }
    
    @objc private func refreshApps(_ sender: NSMenuItem) {
        // 通知刷新应用列表
        NotificationCenter.default.post(name: .refreshApplications, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openFolder = Notification.Name("openFolder")
    static let renameFolder = Notification.Name("renameFolder")
    static let refreshApplications = Notification.Name("refreshApplications")
}
