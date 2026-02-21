//
//  CAGridView.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import AppKit

/// Core Animation 高性能网格视图
class CAGridView: NSView, NSDraggingSource {
    
    // MARK: - Properties
    
    var iconLayers: [String: CALayer] = [:]
    var displayLink: CVDisplayLink?
    var applications: [ApplicationInfo] = []
    var folders: [FolderInfo] = []
    
    var gridSize: GridSize = .default
    var currentPage: Int = 0
    var iconSize: CGFloat = 64
    var spacing: CGFloat = 16
    
    // MARK: - Callbacks
    
    var onAppClick: ((ApplicationInfo) -> Void)?
    var onFolderClick: ((FolderInfo) -> Void)?
    var onRightClick: ((GridItemInfo, CGPoint) -> Void)?
    var onDrop: ((GridItemInfo, Int) -> Void)?
    var onScrollLeft: (() -> Void)?
    var onScrollRight: (() -> Void)?
    var onNavigateLeft: (() -> Void)?
    var onNavigateRight: (() -> Void)?
    var onNavigateUp: (() -> Void)?
    var onNavigateDown: (() -> Void)?
    var onCancel: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    // MARK: - Public Methods
    
    /// 更新应用列表
    func updateApplications(_ apps: [ApplicationInfo]) {
        applications = apps
        needsLayout = true
    }
    
    /// 更新文件夹列表
    func updateFolders(_ folders: [FolderInfo]) {
        self.folders = folders
        needsLayout = true
    }
    
    /// 切换页面
    func setCurrentPage(_ page: Int) {
        currentPage = page
        needsLayout = true
    }
    
    /// 设置图标大小
    func setIconSize(_ size: CGFloat) {
        iconSize = size
        needsLayout = true
    }
    
    /// 设置网格尺寸
    func setGridSize(_ size: GridSize) {
        gridSize = size
        needsLayout = true
    }
    
    // MARK: - Layout
    
    override func layout() {
        super.layout()
        layoutIcons()
    }
    
    func layoutIcons() {
        layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        iconLayers.removeAll()
        
        let pageItems = gridSize.itemsPerPage
        let startIndex = currentPage * pageItems
        
        // 计算网格区域
        let padding: CGFloat = 40
        let gridWidth = bounds.width - padding * 2
        let gridHeight = bounds.height - padding * 2
        
        let cellWidth = (gridWidth - CGFloat(gridSize.columns - 1) * spacing) / CGFloat(gridSize.columns)
        let cellHeight = (gridHeight - CGFloat(gridSize.rows - 1) * spacing) / CGFloat(gridSize.rows)
        
        // 先布局文件夹
        for (index, folder) in folders.enumerated() {
            guard index < pageItems else { break }
            let position = calculatePosition(for: index, columns: gridSize.columns, rows: gridSize.rows, 
                                            cellWidth: cellWidth, cellHeight: cellHeight, padding: padding, spacing: spacing)
            createFolderLayer(folder, at: position, cellSize: CGSize(width: cellWidth, height: cellHeight))
        }
        
        // 布局应用
        let folderCount = min(folders.count, pageItems)
        for (index, app) in applications.enumerated() {
            let adjustedIndex = index + startIndex
            guard adjustedIndex - folderCount < pageItems else { break }
            let position = calculatePosition(for: adjustedIndex, columns: gridSize.columns, rows: gridSize.rows,
                                            cellWidth: cellWidth, cellHeight: cellHeight, padding: padding, spacing: spacing)
            createAppLayer(app, at: position, cellSize: CGSize(width: cellWidth, height: cellHeight))
        }
    }
    
    private func calculatePosition(for index: Int, columns: Int, rows: Int, 
                                    cellWidth: CGFloat, cellHeight: CGFloat, 
                                    padding: CGFloat, spacing: CGFloat) -> CGPoint {
        let row = index / columns
        let col = index % columns
        
        let x = padding + CGFloat(col) * (cellWidth + spacing) + cellWidth / 2
        let y = bounds.height - padding - CGFloat(row) * (cellHeight + spacing) - cellHeight / 2
        
        return CGPoint(x: x, y: y)
    }
    
    private func createAppLayer(_ app: ApplicationInfo, at position: CGPoint, cellSize: CGSize) {
        let containerLayer = CALayer()
        containerLayer.frame = CGRect(x: position.x - cellSize.width / 2, 
                                       y: position.y - cellSize.height / 2,
                                       width: cellSize.width, height: cellSize.height)
        
        // 图标图层
        let iconLayer = CALayer()
        let iconSize = min(cellSize.width, cellSize.height) * 0.7
        iconLayer.frame = CGRect(x: (cellSize.width - iconSize) / 2,
                                 y: (cellSize.height - iconSize) / 2 + 10,
                                 width: iconSize, height: iconSize)
        
        // 加载图标
        let icon = NSWorkspace.shared.icon(forFile: app.bundleURL.path)
        icon.size = NSSize(width: iconSize, height: iconSize)
        iconLayer.contents = icon
        
        containerLayer.addSublayer(iconLayer)
        
        // 标签图层
        let textLayer = CATextLayer()
        textLayer.frame = CGRect(x: 0, y: 0, width: cellSize.width, height: 20)
        textLayer.string = app.displayName
        textLayer.fontSize = 11
        textLayer.foregroundColor = NSColor.white.cgColor
        textLayer.alignmentMode = .center
        textLayer.truncationMode = .end
        
        containerLayer.addSublayer(textLayer)
        
        layer?.addSublayer(containerLayer)
        iconLayers[app.bundleIdentifier] = containerLayer
    }
    
    private func createFolderLayer(_ folder: FolderInfo, at position: CGPoint, cellSize: CGSize) {
        let containerLayer = CALayer()
        containerLayer.frame = CGRect(x: position.x - cellSize.width / 2,
                                       y: position.y - cellSize.height / 2,
                                       width: cellSize.width, height: cellSize.height)
        
        // 文件夹图标
        let folderIcon = createFolderIcon()
        let iconSize = min(cellSize.width, cellSize.height) * 0.7
        let iconLayer = CALayer()
        iconLayer.frame = CGRect(x: (cellSize.width - iconSize) / 2,
                                 y: (cellSize.height - iconSize) / 2 + 10,
                                 width: iconSize, height: iconSize)
        iconLayer.contents = folderIcon
        
        containerLayer.addSublayer(iconLayer)
        
        // 标签
        let textLayer = CATextLayer()
        textLayer.frame = CGRect(x: 0, y: 0, width: cellSize.width, height: 20)
        textLayer.string = folder.name.currentLanguage
        textLayer.fontSize = 11
        textLayer.foregroundColor = NSColor.white.cgColor
        textLayer.alignmentMode = .center
        
        containerLayer.addSublayer(textLayer)
        
        layer?.addSublayer(containerLayer)
        iconLayers[folder.id] = containerLayer
    }
    
    private func createFolderIcon() -> NSImage {
        let size: CGFloat = 64
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // 绘制文件夹背景
        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        let path = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
        NSColor.controlBackgroundColor.withAlphaComponent(0.9).setFill()
        path.fill()
        
        image.unlockFocus()
        return image
    }
    
    // MARK: - Mouse Events
    
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        handleItemClick(at: location)
    }
    
    private func handleItemClick(at location: CGPoint) {
        // 检查文件夹点击
        for (id, layer) in iconLayers {
            if layer.frame.contains(location) {
                if let folder = folders.first(where: { $0.id == id }) {
                    onFolderClick?(folder)
                    return
                }
                if let app = applications.first(where: { $0.bundleIdentifier == id }) {
                    onAppClick?(app)
                    return
                }
            }
        }
    }
}

extension CAGridView {
    nonisolated func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return context == .outsideApplication ? .copy : [.move, .copy]
    }
}
