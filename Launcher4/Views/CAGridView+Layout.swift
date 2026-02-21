//
//  CAGridView+Layout.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import AppKit

// MARK: - Layout Extensions

extension CAGridView {
    
    // MARK: - Layout Calculations
    
    /// 计算网格布局
    func calculateGridLayout() -> GridLayoutInfo {
        let padding: CGFloat = 40
        let gridWidth = bounds.width - padding * 2
        let gridHeight = bounds.height - padding * 2
        
        let cellWidth = (gridWidth - CGFloat(gridSize.columns - 1) * spacing) / CGFloat(gridSize.columns)
        let cellHeight = (gridHeight - CGFloat(gridSize.rows - 1) * spacing) / CGFloat(gridSize.rows)
        
        return GridLayoutInfo(
            padding: padding,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            gridWidth: gridWidth,
            gridHeight: gridHeight
        )
    }
    
    /// 计算指定索引的位置
    func positionForIndex(_ index: Int, layout: GridLayoutInfo) -> CGPoint {
        let row = index / gridSize.columns
        let col = index % gridSize.columns
        
        let x = layout.padding + CGFloat(col) * (layout.cellWidth + spacing) + layout.cellWidth / 2
        let y = bounds.height - layout.padding - CGFloat(row) * (layout.cellHeight + spacing) - layout.cellHeight / 2
        
        return CGPoint(x: x, y: y)
    }
    
    /// 计算指定位置的索引
    func indexForPosition(_ position: CGPoint, layout: GridLayoutInfo) -> Int? {
        guard position.x >= layout.padding && position.x <= bounds.width - layout.padding &&
              position.y >= layout.padding && position.y <= bounds.height - layout.padding else {
            return nil
        }
        
        let col = Int((position.x - layout.padding) / (layout.cellWidth + spacing))
        let row = Int((bounds.height - position.y - layout.padding) / (layout.cellHeight + spacing))
        
        guard col >= 0 && col < gridSize.columns && row >= 0 && row < gridSize.rows else {
            return nil
        }
        
        return row * gridSize.columns + col
    }
    
    /// 获取当前页的项目范围
    func currentPageRange() -> Range<Int> {
        let startIndex = currentPage * gridSize.itemsPerPage
        let endIndex = min(startIndex + gridSize.itemsPerPage, applications.count + folders.count)
        return startIndex..<endIndex
    }
    
    /// 计算需要的总页数
    func totalPageCount() -> Int {
        let totalItems = applications.count + folders.count
        return max(1, (totalItems + gridSize.itemsPerPage - 1) / gridSize.itemsPerPage)
    }
    
    // MARK: - Animation Support
    
    /// 动画更新布局
    func animateLayoutChange(duration: CFTimeInterval = 0.3) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        
        layoutIcons()
        
        CATransaction.commit()
    }
    
    /// 滑动到指定页面
    func animatePageTransition(from: Int, to: Int, completion: (() -> Void)? = nil) {
        let direction: CGFloat = to > from ? 1 : -1
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        CATransaction.setCompletionBlock {
            completion?()
        }
        
        // 滑动动画
        let transition = CATransition()
        transition.type = .push
        transition.subtype = direction > 0 ? .fromRight : .fromLeft
        
        layer?.add(transition, forKey: "pageTransition")
        layoutIcons()
        
        CATransaction.commit()
    }
}

// MARK: - Layout Info Structure

struct GridLayoutInfo {
    let padding: CGFloat
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let gridWidth: CGFloat
    let gridHeight: CGFloat
}
