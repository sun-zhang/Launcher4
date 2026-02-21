//
//  GridPosition.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation

/// 网格位置
struct GridPosition: Codable, Equatable, Hashable, Sendable {
    let page: Int
    let row: Int
    let column: Int
    
    static let zero = GridPosition(page: 0, row: 0, column: 0)
    
    /// 计算下一个位置
    func next(in gridSize: GridSize) -> GridPosition {
        var newColumn = column + 1
        var newRow = row
        var newPage = page
        
        if newColumn >= gridSize.columns {
            newColumn = 0
            newRow += 1
            
            if newRow >= gridSize.rows {
                newRow = 0
                newPage += 1
            }
        }
        
        return GridPosition(page: newPage, row: newRow, column: newColumn)
    }
    
    /// 计算线性索引
    func linearIndex(in gridSize: GridSize) -> Int {
        return page * gridSize.columns * gridSize.rows + row * gridSize.columns + column
    }
    
    /// 从线性索引创建位置
    static func from(linearIndex: Int, gridSize: GridSize) -> GridPosition {
        let itemsPerPage = gridSize.columns * gridSize.rows
        let page = linearIndex / itemsPerPage
        let remaining = linearIndex % itemsPerPage
        let row = remaining / gridSize.columns
        let column = remaining % gridSize.columns
        return GridPosition(page: page, row: row, column: column)
    }
}
