//
//  FolderManagerProtocol.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation
import AppKit

/// 文件夹管理器协议
protocol FolderManagerProtocol: Sendable {
    /// 创建文件夹
    func createFolder(name: FolderInfo.LocalizedString, applications: [String]) async -> FolderInfo
    
    /// 添加应用到文件夹
    func addToFolder(appId: String, folderId: String) async throws
    
    /// 从文件夹移除应用
    func removeFromFolder(appId: String, folderId: String) async throws
    
    /// 重命名文件夹
    func renameFolder(folderId: String, newName: FolderInfo.LocalizedString) async throws
    
    /// 删除文件夹
    func deleteFolder(folderId: String) async throws
    
    /// 生成文件夹图标
    func generateFolderIcon(for folderId: String, apps: [ApplicationInfo]) async -> NSImage?
    
    /// 获取所有文件夹
    func getAllFolders() async -> [FolderInfo]
    
    /// 获取单个文件夹
    func getFolder(id: String) async -> FolderInfo?
}
