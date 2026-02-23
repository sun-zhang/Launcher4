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
    
    var gridSize: GridSize = GridSize(columns: 7, rows: 5)
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
        layoutIcons() // 保证启动时执行布局和日志输出
        print("setupView called")
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
        gridSize = GridSize(columns: 7, rows: 5)
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

        // 计算横纵向自适应间距
        let minSpacing: CGFloat = 16
        let maxSpacing: CGFloat = 64
        let columns = 7
        let rows = 5
        let pageItems = columns * rows
        let startIndex = currentPage * pageItems

        let padding: CGFloat = 40
        let gridWidth = bounds.width - padding * 2
        let gridHeight = bounds.height - padding * 2

        // 先用最小间距计算最大格子尺寸
        let cellWidthMax = (gridWidth - CGFloat(columns - 1) * minSpacing) / CGFloat(columns)
        let cellHeightMax = (gridHeight - CGFloat(rows - 1) * minSpacing) / CGFloat(rows)
        // 取横纵向的最小格子尺寸，保证格子不被拉伸
        let cellSize = min(cellWidthMax, cellHeightMax)
        // 再反推实际间距
        let spacingX = (gridWidth - CGFloat(columns) * cellSize) / CGFloat(max(1, columns - 1))
        let spacingY = (gridHeight - CGFloat(rows) * cellSize) / CGFloat(max(1, rows - 1))
        // 限制间距范围
        let finalSpacingX = max(minSpacing, min(maxSpacing, spacingX))
        let finalSpacingY = max(minSpacing, min(maxSpacing, spacingY))

        // 重新计算实际网格区域大小
        let actualGridWidth = CGFloat(columns) * cellSize + CGFloat(columns - 1) * finalSpacingX
        let actualGridHeight = CGFloat(rows) * cellSize + CGFloat(rows - 1) * finalSpacingY
        let offsetX = (gridWidth - actualGridWidth) / 2
        let offsetY = (gridHeight - actualGridHeight) / 2

        // 绘制网格边缘线条
        let borderLayer = CALayer()
        borderLayer.frame = CGRect(x: padding + offsetX, y: padding + offsetY, width: actualGridWidth, height: actualGridHeight)
        borderLayer.borderWidth = 2
        borderLayer.borderColor = NSColor.red.cgColor
        borderLayer.zPosition = -10
        layer?.addSublayer(borderLayer)

        // 列间隔线
        for col in 1..<columns {
            let x = padding + offsetX + CGFloat(col) * (cellSize + finalSpacingX) - finalSpacingX / 2
            let line = CALayer()
            line.frame = CGRect(x: x, y: padding + offsetY, width: 2, height: actualGridHeight)
            line.backgroundColor = NSColor.green.withAlphaComponent(0.7).cgColor
            line.zPosition = -10
            layer?.addSublayer(line)
        }
        // 行间隔线
        for row in 1..<rows {
            let y = padding + offsetY + CGFloat(row) * (cellSize + finalSpacingY) - finalSpacingY / 2
            let line = CALayer()
            line.frame = CGRect(x: padding + offsetX, y: y, width: actualGridWidth, height: 2)
            line.backgroundColor = NSColor.blue.withAlphaComponent(0.7).cgColor
            line.zPosition = -10
            layer?.addSublayer(line)
        }
        // 每格背景和中心点
        for row in 0..<rows {
            for col in 0..<columns {
                let x = padding + offsetX + CGFloat(col) * (cellSize + finalSpacingX)
                let y = padding + offsetY + CGFloat(row) * (cellSize + finalSpacingY)
                let cellLayer = CALayer()
                cellLayer.frame = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                cellLayer.backgroundColor = NSColor.lightGray.withAlphaComponent(0.15).cgColor
                cellLayer.zPosition = -10
                layer?.addSublayer(cellLayer)
                let dot = CALayer()
                dot.frame = CGRect(x: x + cellSize/2 - 3, y: y + cellSize/2 - 3, width: 6, height: 6)
                dot.cornerRadius = 3
                dot.backgroundColor = NSColor.orange.cgColor
                dot.zPosition = -10
                layer?.addSublayer(dot)
            }
        }

        // 先布局文件夹
        for (index, folder) in folders.enumerated() {
            guard index < pageItems else { break }
            let position = CGPoint(
                x: padding + offsetX + CGFloat(index % columns) * (cellSize + finalSpacingX) + cellSize / 2,
                y: padding + offsetY + CGFloat(index / columns) * (cellSize + finalSpacingY) + cellSize / 2
            )
            createFolderLayer(folder, at: position, cellSize: CGSize(width: cellSize, height: cellSize))
        }

        // 布局应用
        let folderCount = min(folders.count, pageItems)
        for (index, app) in applications.enumerated() {
            let adjustedIndex = index + startIndex
            guard adjustedIndex - folderCount < pageItems else { break }
            let position = CGPoint(
                x: padding + offsetX + CGFloat(adjustedIndex % columns) * (cellSize + finalSpacingX) + cellSize / 2,
                y: padding + offsetY + CGFloat(adjustedIndex / columns) * (cellSize + finalSpacingY) + cellSize / 2
            )
            createAppLayer(app, at: position, cellSize: CGSize(width: cellSize, height: cellSize))
        }
        
        print("[CAGridView] gridWidth:", gridWidth, "gridHeight:", gridHeight)
        print("[CAGridView] cellWidthMax:", cellWidthMax, "cellHeightMax:", cellHeightMax, "cellSize:", cellSize)
        print("[CAGridView] spacingX:", spacingX, "spacingY:", spacingY)
        print("[CAGridView] finalSpacingX:", finalSpacingX, "finalSpacingY:", finalSpacingY)
        print("[CAGridView] actualGridWidth:", actualGridWidth, "actualGridHeight:", actualGridHeight)
    }
    
    private func calculatePosition(for index: Int, columns: Int, rows: Int,
                                  cellWidth: CGFloat, cellHeight: CGFloat,
                                  padding: CGFloat, spacing: CGFloat,
                                  gridHeight: CGFloat, totalHeight: CGFloat) -> CGPoint {
        let row = index / columns
        let col = index % columns
        let x = padding + CGFloat(col) * (cellWidth + spacing) + cellWidth / 2
        // 保证网格居中显示
        let y = totalHeight - padding - CGFloat(row) * (cellHeight + spacing) - cellHeight / 2
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
