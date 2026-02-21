//
//  CAGridView+Input.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import AppKit

extension CAGridView {
    
    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        handleMouseUp(at: location)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        handleMouseDragged(at: location)
    }
    
    override func rightMouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        handleRightClick(at: location)
    }
    
    // MARK: - Input Handlers
    
    private func handleMouseDown(at location: CGPoint) {
        // 检查是否点击了图标
        if let itemInfo = getItemAtLocation(location) {
            startDragIfNeeded = true
            dragStartLocation = location
            selectedItemInfo = itemInfo
        }
    }
    
    private func handleMouseUp(at location: CGPoint) {
        defer {
            startDragIfNeeded = false
            selectedItemInfo = nil
            isDragging = false
        }
        
        guard let itemInfo = selectedItemInfo else { return }
        
        // 如果是拖拽结束
        if isDragging {
            handleDrop(at: location, itemInfo: itemInfo)
            return
        }
        
        // 否则是点击
        handleClick(on: itemInfo)
    }
    
    private func handleMouseDragged(at location: CGPoint) {
        guard startDragIfNeeded, let itemInfo = selectedItemInfo else { return }
        
        let distance = hypot(location.x - dragStartLocation.x, location.y - dragStartLocation.y)
        
        // 超过阈值开始拖拽
        if distance > 5 {
            isDragging = true
            startDrag(with: itemInfo, at: location)
        }
        
        if isDragging {
            updateDrag(at: location)
        }
    }
    
    private func handleRightClick(at location: CGPoint) {
        guard let itemInfo = getItemAtLocation(location) else { return }
        onRightClick?(itemInfo, location)
    }
    
    // MARK: - Item Detection
    
    private func getItemAtLocation(_ location: CGPoint) -> GridItemInfo? {
        for (id, layer) in iconLayers {
            let frame = layer.convert(layer.bounds, to: self.layer)
            if frame.contains(location) {
                if let folder = folders.first(where: { $0.id == id }) {
                    return .folder(folder)
                }
                if let app = applications.first(where: { $0.bundleIdentifier == id }) {
                    return .application(app)
                }
            }
        }
        return nil
    }
    
    // MARK: - Click Handling
    
    private func handleClick(on itemInfo: GridItemInfo) {
        switch itemInfo {
        case .application(let app):
            onAppClick?(app)
        case .folder(let folder):
            onFolderClick?(folder)
        }
    }
    
    // MARK: - Drag and Drop
    
    private func startDrag(with itemInfo: GridItemInfo, at location: CGPoint) {
        // 创建拖拽图像
        let dragImage: NSImage
        switch itemInfo {
        case .application(let app):
            dragImage = NSWorkspace.shared.icon(forFile: app.bundleURL.path)
        case .folder:
            dragImage = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil) ?? NSImage()
        }
        
        // 开始拖拽会话
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(itemInfo.id, forType: .string)
        
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(CGRect(origin: location, size: CGSize(width: 64, height: 64)), contents: dragImage)
        
        beginDraggingSession(with: [draggingItem], event: NSApp.currentEvent!, source: self as NSDraggingSource)
    }
    
    private func updateDrag(at location: CGPoint) {
        // 更新拖拽位置
        // 可以添加视觉反馈
    }
    
    private func handleDrop(at location: CGPoint, itemInfo: GridItemInfo) {
        let layout = calculateGridLayout()
        guard let targetIndex = indexForPosition(location, layout: layout) else { return }
        onDrop?(itemInfo, targetIndex)
    }
    
    // MARK: - Scroll Events
    
    override func scrollWheel(with event: NSEvent) {
        // 水平滚动切换页面
        if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) {
            if event.scrollingDeltaX > 0 {
                onScrollLeft?()
            } else {
                onScrollRight?()
            }
        }
    }
    
    // MARK: - Keyboard Events
    
    override func keyDown(with event: NSEvent) {
        handleKeyPress(event)
    }
    
    private func handleKeyPress(_ event: NSEvent) {
        guard let keyCode = KeyCode(rawValue: event.keyCode) else { return }
        
        switch keyCode {
        case .leftArrow:
            onNavigateLeft?()
        case .rightArrow:
            onNavigateRight?()
        case .upArrow:
            onNavigateUp?()
        case .downArrow:
            onNavigateDown?()
        case .returnKey:
            if let itemInfo = selectedItemInfo {
                handleClick(on: itemInfo)
            }
        case .escape:
            onCancel?()
        default:
            break
        }
    }
    
    override var acceptsFirstResponder: Bool { true }
}

// MARK: - Supporting Types

enum GridItemInfo {
    case application(ApplicationInfo)
    case folder(FolderInfo)
    
    var id: String {
        switch self {
        case .application(let app): return app.bundleIdentifier
        case .folder(let folder): return folder.id
        }
    }
}

enum KeyCode: UInt16 {
    case leftArrow = 123
    case rightArrow = 124
    case downArrow = 125
    case upArrow = 126
    case returnKey = 36
    case escape = 53
}

// MARK: - Stored Properties

private var startDragIfNeededKey: UInt8 = 0
private var dragStartLocationKey: UInt8 = 0
private var selectedItemInfoKey: UInt8 = 0
private var isDraggingKey: UInt8 = 0

extension CAGridView {
    var startDragIfNeeded: Bool {
        get { objc_getAssociatedObject(self, &startDragIfNeededKey) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &startDragIfNeededKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    var dragStartLocation: CGPoint {
        get { objc_getAssociatedObject(self, &dragStartLocationKey) as? CGPoint ?? .zero }
        set { objc_setAssociatedObject(self, &dragStartLocationKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    var selectedItemInfo: GridItemInfo? {
        get { objc_getAssociatedObject(self, &selectedItemInfoKey) as? GridItemInfo }
        set { objc_setAssociatedObject(self, &selectedItemInfoKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    var isDragging: Bool {
        get { objc_getAssociatedObject(self, &isDraggingKey) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &isDraggingKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
