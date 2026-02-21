//
//  FolderManager.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation
import AppKit

/// 文件夹管理器 Actor
actor FolderManager: FolderManagerProtocol {
    
    // MARK: - Properties
    
    private var folders: [String: FolderInfo] = [:]
    
    // MARK: - Public Methods
    
    /// 创建文件夹
    func createFolder(name: FolderInfo.LocalizedString, applications: [String]) -> FolderInfo {
        let folder = FolderInfo(
            id: UUID().uuidString,
            name: name,
            applications: applications,
            creationDate: Date(),
            modifiedDate: Date(),
            iconPreview: nil,
            colorTheme: .blue
        )
        
        folders[folder.id] = folder
        
        return folder
    }
    
    /// 添加应用到文件夹
    func addToFolder(appId: String, folderId: String) throws {
        guard var folder = folders[folderId] else {
            throw FolderError.folderNotFound(folderId)
        }
        
        if folder.applications.contains(appId) {
            throw FolderError.applicationAlreadyInFolder(appId)
        }
        
        folder.applications.append(appId)
        folder.modifiedDate = Date()
        folders[folder.id] = folder
    }
    
    /// 从文件夹移除应用
    func removeFromFolder(appId: String, folderId: String) throws {
        guard var folder = folders[folderId] else {
            throw FolderError.folderNotFound(folderId)
        }
        
        guard let index = folder.applications.firstIndex(of: appId) else {
            throw FolderError.applicationNotInFolder(appId)
        }
        
        folder.applications.remove(at: index)
        folder.modifiedDate = Date()
        
        // 如果文件夹只有一个应用，自动删除文件夹
        if folder.applications.isEmpty {
            try deleteFolder(folderId: folderId)
        } else {
            folders[folder.id] = folder
        }
    }
    
    /// 重命名文件夹
    func renameFolder(folderId: String, newName: FolderInfo.LocalizedString) throws {
        guard var folder = folders[folderId] else {
            throw FolderError.folderNotFound(folderId)
        }
        
        folder.name = newName
        folder.modifiedDate = Date()
        folders[folder.id] = folder
    }
    
    /// 删除文件夹
    func deleteFolder(folderId: String) throws {
        guard folders[folderId] != nil else {
            throw FolderError.folderNotFound(folderId)
        }
        
        folders.removeValue(forKey: folderId)
    }
    
    /// 生成文件夹图标
    func generateFolderIcon(for folderId: String, apps: [ApplicationInfo]) -> NSImage? {
        guard !apps.isEmpty else { return nil }
        
        // 获取前 4 个应用的图标
        let iconSize: CGFloat = 32
        let totalSize: CGFloat = 64
        let padding: CGFloat = 2
        
        // 创建文件夹图标图像
        let folderImage = NSImage(size: NSSize(width: totalSize, height: totalSize))
        folderImage.lockFocus()
        
        // 绘制背景
        let bgPath = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: totalSize, height: totalSize), xRadius: 12, yRadius: 12)
        NSColor.controlBackgroundColor.withAlphaComponent(0.9).setFill()
        bgPath.fill()
        
        // 绘制应用图标网格
        let itemsToDraw = min(4, apps.count)
        for i in 0..<itemsToDraw {
            let row = i / 2
            let col = i % 2
            let x = CGFloat(col) * (iconSize + padding) + padding
            let y = totalSize - CGFloat(row + 1) * (iconSize + padding) - padding
            
            let appIcon = NSWorkspace.shared.icon(forFile: apps[i].bundleURL.path)
            let iconRect = NSRect(x: x, y: y, width: iconSize, height: iconSize)
            appIcon.size = NSSize(width: iconSize, height: iconSize)
            appIcon.draw(in: iconRect)
        }
        
        folderImage.unlockFocus()
        
        return folderImage
    }
    
    /// 获取所有文件夹
    func getAllFolders() -> [FolderInfo] {
        return Array(folders.values)
    }
    
    /// 获取单个文件夹
    func getFolder(id: String) -> FolderInfo? {
        return folders[id]
    }
}

// MARK: - Errors

enum FolderError: Error, Sendable {
    case folderNotFound(String)
    case applicationAlreadyInFolder(String)
    case applicationNotInFolder(String)
    case encodingError
}
