//
//  CAGridViewRepresentable.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import SwiftUI
import AppKit

/// CAGridView 的 SwiftUI 包装
struct CAGridViewRepresentable: NSViewRepresentable {
    
    // MARK: - Properties
    
    var applications: [ApplicationInfo]
    var folders: [FolderInfo]
    var gridSize: GridSize
    var currentPage: Int
    var iconSize: CGFloat
    
    var onAppClick: ((ApplicationInfo) -> Void)?
    var onFolderClick: ((FolderInfo) -> Void)?
    
    // MARK: - NSViewRepresentable
    
    func makeNSView(context: Context) -> CAGridView {
        let gridView = CAGridView()
        gridView.updateApplications(applications)
        gridView.updateFolders(folders)
        gridView.gridSize = gridSize
        gridView.setCurrentPage(currentPage)
        gridView.setIconSize(iconSize)
        
        gridView.onAppClick = onAppClick
        gridView.onFolderClick = onFolderClick
        
        return gridView
    }
    
    func updateNSView(_ nsView: CAGridView, context: Context) {
        nsView.updateApplications(applications)
        nsView.updateFolders(folders)
        nsView.gridSize = gridSize
        nsView.setCurrentPage(currentPage)
        nsView.setIconSize(iconSize)
        
        nsView.onAppClick = onAppClick
        nsView.onFolderClick = onFolderClick
    }
}

// MARK: - Modifiers

extension CAGridViewRepresentable {
    
    /// 设置应用点击回调
    func onApplicationClick(_ action: @escaping (ApplicationInfo) -> Void) -> Self {
        var copy = self
        copy.onAppClick = action
        return copy
    }
    
    /// 设置文件夹点击回调
    func onFolderClick(_ action: @escaping (FolderInfo) -> Void) -> Self {
        var copy = self
        copy.onFolderClick = action
        return copy
    }
}
